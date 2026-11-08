"""Discovery: finding listings of any category, and the price rollup it needs.

One query builder serves the whole filter set in docs/original-concept.md —
category, location, date, price, keywords and free text — so the central
calendar, the map, search and the "For You" feed of a filter profile all ask the
same question with different arguments.

Only published listings in a live market are ever returned.
"""

import math
from dataclasses import dataclass, field, replace
from datetime import UTC, date, datetime, timedelta
from uuid import UUID

from sqlalchemy import Select, func, or_, select
from sqlalchemy.orm import Session

from app.models import (
    Country,
    Listing,
    ListingStatus,
    ListingTag,
    ListingType,
    TicketTier,
)

# Degrees of latitude per kilometre. Longitude is scaled by the cosine of the
# latitude in `bounds_around`.
_KM_PER_DEGREE = 111.045

MAX_LIMIT = 200


class Sort:
    date = "date"
    price_low = "price_low"
    price_high = "price_high"
    newest = "newest"

    all = (date, price_low, price_high, newest)


@dataclass
class Bounds:
    """A map viewport, or a square around a point."""

    south: float
    west: float
    north: float
    east: float


def bounds_around(latitude: float, longitude: float, radius_km: float) -> Bounds:
    """A square that contains the circle of this radius.

    An approximation on purpose: it over-selects at the corners, and it is what
    a plain B-tree index can answer on both Postgres and SQLite. True distance
    ordering wants PostGIS, which the Supabase cutover would bring; until then
    discovery is "around here", not a measured radius.
    """
    lat_span = radius_km / _KM_PER_DEGREE
    # Guard the poles, where the cosine collapses and the span explodes.
    cos_lat = max(math.cos(math.radians(latitude)), 0.01)
    lon_span = radius_km / (_KM_PER_DEGREE * cos_lat)
    return Bounds(
        south=latitude - lat_span,
        west=longitude - lon_span,
        north=latitude + lat_span,
        east=longitude + lon_span,
    )


@dataclass
class Filters:
    """What a viewer is looking for. Every field is optional.

    This is also the stored shape of a filter profile, so the two cannot drift.
    """

    types: list[ListingType] = field(default_factory=list)
    country_code: str | None = None
    city: str | None = None
    query: str | None = None
    tags: list[str] = field(default_factory=list)
    starts_after: datetime | None = None
    starts_before: datetime | None = None
    price_min_minor: int | None = None
    price_max_minor: int | None = None
    free_only: bool = False
    paid_only: bool = False
    bounds: Bounds | None = None
    organisation_id: UUID | None = None
    sort: str = Sort.date
    limit: int = 50
    offset: int = 0


def _base(*columns) -> Select:
    """Published listings in a live market. Nothing else is ever discoverable."""
    return (
        select(*(columns or (Listing,)))
        .join(Country, Country.code == Listing.country_code)
        .where(Listing.status == ListingStatus.published, Country.is_live.is_(True))
    )


def _apply(stmt: Select, f: Filters) -> Select:
    if f.types:
        stmt = stmt.where(Listing.type.in_(f.types))
    if f.country_code:
        stmt = stmt.where(Listing.country_code == f.country_code.upper())
    if f.city:
        stmt = stmt.where(func.lower(Listing.city) == f.city.lower())
    if f.organisation_id:
        stmt = stmt.where(Listing.organisation_id == f.organisation_id)
    if f.query:
        # Enough for one island's catalogue. Full-text search is a later
        # problem, and a real one: this cannot use an index.
        like = f"%{f.query.strip().lower()}%"
        stmt = stmt.where(
            or_(
                func.lower(Listing.title).like(like),
                func.lower(Listing.description).like(like),
                func.lower(Listing.venue_name).like(like),
            )
        )
    if f.tags:
        wanted = [ListingTag.normalise(t) for t in f.tags]
        # Match any, which is how a filter profile's keyword interests read.
        stmt = stmt.where(
            select(ListingTag.listing_id)
            .where(ListingTag.listing_id == Listing.id, ListingTag.tag.in_(wanted))
            .exists()
        )
    if f.starts_after:
        stmt = stmt.where(Listing.starts_at >= f.starts_after)
    if f.starts_before:
        stmt = stmt.where(Listing.starts_at <= f.starts_before)
    # Price. A listing matches a window when its own range overlaps it, and a
    # listing with nothing priced yet matches no price filter at all.
    if f.free_only:
        stmt = stmt.where(Listing.price_min_minor == 0)
    elif f.paid_only:
        # Something in it costs money. A listing with both a free RSVP tier and
        # a paid tier counts: there is something to buy.
        stmt = stmt.where(Listing.price_max_minor > 0)
    else:
        if f.price_min_minor is not None:
            stmt = stmt.where(Listing.price_max_minor >= f.price_min_minor)
        if f.price_max_minor is not None:
            stmt = stmt.where(Listing.price_min_minor <= f.price_max_minor)
    if f.bounds:
        b = f.bounds
        stmt = stmt.where(
            Listing.latitude.is_not(None),
            Listing.longitude.is_not(None),
            Listing.latitude.between(b.south, b.north),
            Listing.longitude.between(b.west, b.east),
        )
    return stmt


def _order(stmt: Select, sort: str) -> Select:
    if sort == Sort.price_low:
        return stmt.order_by(Listing.price_min_minor.asc().nulls_last(), Listing.starts_at.asc())
    if sort == Sort.price_high:
        return stmt.order_by(Listing.price_max_minor.desc().nulls_last(), Listing.starts_at.asc())
    if sort == Sort.newest:
        return stmt.order_by(Listing.created_at.desc())
    # Soonest first, and listings with no date (a service, a store) after them.
    return stmt.order_by(Listing.starts_at.asc().nulls_last(), Listing.title.asc())


def discover(db: Session, f: Filters) -> list[Listing]:
    stmt = _order(_apply(_base(), f), f.sort)
    stmt = stmt.limit(min(f.limit, MAX_LIMIT)).offset(f.offset)
    return list(db.scalars(stmt).unique())


def count(db: Session, f: Filters) -> int:
    inner = _apply(_base(), f).subquery()
    return db.scalar(select(func.count()).select_from(inner)) or 0


def calendar(db: Session, f: Filters, start: date, end: date) -> dict[date, int]:
    """How many listings fall on each day, for the concept's central calendar.

    Dates are grouped in the market's own timezone, because "what's on
    Saturday" is a local question. Days with nothing on are left out.
    """
    tz = _timezone_of(db, f.country_code)
    window = replace(
        f,
        starts_after=_day_start(start, tz),
        starts_before=_day_start(end + timedelta(days=1), tz) - timedelta(microseconds=1),
    )

    stmt = _apply(_base(Listing.starts_at), window).where(Listing.starts_at.is_not(None))

    tally: dict[date, int] = {}
    for starts_at in db.scalars(stmt):
        # SQLite hands back naive datetimes; they are stored as UTC.
        aware = starts_at if starts_at.tzinfo else starts_at.replace(tzinfo=UTC)
        day = aware.astimezone(tz).date()
        tally[day] = tally.get(day, 0) + 1
    return dict(sorted(tally.items()))


def _timezone_of(db: Session, country_code: str | None):
    from zoneinfo import ZoneInfo

    from app.services import countries

    country = countries.get(db, country_code)
    return ZoneInfo(country.timezone if country else "UTC")


def _day_start(day: date, tz) -> datetime:
    return datetime(day.year, day.month, day.day, tzinfo=tz)


# ---------- Price rollup ----------


def refresh_price_range(db: Session, listing_id: UUID) -> None:
    """Recompute a listing's price span from its own sellable inventory.

    Events price through ticket tiers. As categories arrive each gets a branch
    here — or, once the `Offer` base exists, this collapses into one query over
    it. The caller commits.
    """
    listing = db.get(Listing, listing_id)
    if listing is None:
        return
    if listing.type == ListingType.event:
        lo, hi = db.execute(
            select(func.min(TicketTier.price_minor), func.max(TicketTier.price_minor)).where(
                TicketTier.event_id == listing_id
            )
        ).one()
    else:
        lo = hi = None
    listing.price_min_minor = lo
    listing.price_max_minor = hi
