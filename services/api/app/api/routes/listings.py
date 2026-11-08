"""Discovery across every category: search, the map, and the central calendar.

One endpoint answers the whole filter set in docs/original-concept.md, so a
filter profile's "For You" feed is this call with the profile's stored
arguments rather than a separate code path.
"""

from datetime import UTC, date, datetime, timedelta
from typing import Annotated

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select

from app.api.deps import DbSession
from app.models import (
    AccommodationListing,
    Listing,
    ListingStatus,
    ListingType,
    Organisation,
    ServiceListing,
)
from app.schemas.listings import (
    CalendarDayOut,
    CalendarOut,
    ListingPageOut,
    ListingSummaryOut,
)
from app.schemas.organisations import CollaboratorOut, OrganisationCardOut
from app.schemas.services import (
    AccommodationFieldsOut,
    EventFieldsOut,
    ListingDetailOut,
    ServiceFieldsOut,
)
from app.services import collaborators, countries, listings

router = APIRouter(prefix="/v1", tags=["discovery"])

# A calendar request is capped so one call can't scan the whole catalogue.
MAX_CALENDAR_DAYS = 120


def _bounds(bbox: str | None, near: str | None, radius_km: float) -> listings.Bounds | None:
    if bbox and near:
        raise HTTPException(422, "Use bbox or near, not both")
    if bbox:
        try:
            south, west, north, east = (float(p) for p in bbox.split(","))
        except ValueError:
            raise HTTPException(422, "bbox must be south,west,north,east") from None
        if south > north:
            raise HTTPException(422, "bbox south must not be north of north")
        return listings.Bounds(south=south, west=west, north=north, east=east)
    if near:
        try:
            latitude, longitude = (float(p) for p in near.split(","))
        except ValueError:
            raise HTTPException(422, "near must be latitude,longitude") from None
        if not -90 <= latitude <= 90 or not -180 <= longitude <= 180:
            raise HTTPException(422, "near is outside the world")
        return listings.bounds_around(latitude, longitude, radius_km)
    return None


def _filters(
    *,
    type_: list[ListingType] | None,
    country: str | None,
    city: str | None,
    q: str | None,
    tag: list[str] | None,
    starts_after: datetime | None,
    starts_before: datetime | None,
    upcoming_only: bool,
    price_min_minor: int | None,
    price_max_minor: int | None,
    free: bool,
    min_rating: float | None,
    bbox: str | None,
    near: str | None,
    radius_km: float,
    sort: str,
    limit: int,
    offset: int,
) -> listings.Filters:
    if sort not in listings.Sort.all:
        raise HTTPException(422, f"sort must be one of {', '.join(listings.Sort.all)}")
    if price_min_minor is not None and price_max_minor is not None:
        if price_min_minor > price_max_minor:
            raise HTTPException(422, "price_min_minor is above price_max_minor")
    code = (country or countries.default_code()).upper()
    # Upcoming is the default, but an explicit window always wins: a client
    # asking for last weekend means it.
    if starts_after is None and upcoming_only:
        starts_after = datetime.now(UTC)
    return listings.Filters(
        types=list(type_ or []),
        country_code=code,
        city=city,
        query=q,
        tags=list(tag or []),
        starts_after=starts_after,
        starts_before=starts_before,
        price_min_minor=price_min_minor,
        price_max_minor=price_max_minor,
        free_only=free,
        min_rating=min_rating,
        bounds=_bounds(bbox, near, radius_km),
        sort=sort,
        limit=limit,
        offset=offset,
    )


@router.get("/listings", response_model=ListingPageOut)
def list_listings(
    db: DbSession,
    type_: Annotated[list[ListingType] | None, Query(alias="type")] = None,
    country: str | None = Query(None, min_length=2, max_length=2),
    city: str | None = Query(None, max_length=120),
    q: str | None = Query(None, max_length=200),
    tag: Annotated[list[str] | None, Query()] = None,
    starts_after: datetime | None = None,
    starts_before: datetime | None = None,
    upcoming_only: bool = True,
    price_min_minor: int | None = Query(None, ge=0),
    price_max_minor: int | None = Query(None, ge=0),
    free: bool = False,
    min_rating: float | None = Query(None, ge=1, le=5),
    bbox: str | None = Query(None, description="south,west,north,east"),
    near: str | None = Query(None, description="latitude,longitude"),
    radius_km: float = Query(10, gt=0, le=500),
    sort: str = "date",
    limit: int = Query(50, ge=1, le=listings.MAX_LIMIT),
    offset: int = Query(0, ge=0),
) -> ListingPageOut:
    """Published listings in a live market, filtered every way a filter profile
    can be configured. Categories a market has switched off return nothing."""
    f = _filters(
        type_=type_,
        country=country,
        city=city,
        q=q,
        tag=tag,
        starts_after=starts_after,
        starts_before=starts_before,
        upcoming_only=upcoming_only,
        price_min_minor=price_min_minor,
        price_max_minor=price_max_minor,
        free=free,
        min_rating=min_rating,
        bbox=bbox,
        near=near,
        radius_km=radius_km,
        sort=sort,
        limit=limit,
        offset=offset,
    )
    f.types = enabled_types(db, f)
    if not f.types:
        return ListingPageOut(total=0, limit=limit, offset=offset, results=[])
    return ListingPageOut(
        total=listings.count(db, f),
        limit=limit,
        offset=offset,
        results=[
            ListingSummaryOut.model_validate(row, from_attributes=True)
            for row in listings.discover(db, f)
        ],
    )


def enabled_types(db, f: listings.Filters) -> list[ListingType]:
    """Narrow the requested categories to the ones this market actually shows.

    A market with stores switched off must not leak store listings, and asking
    only for a category it has switched off is an empty result, not an error.
    """
    country = countries.get(db, f.country_code)
    if country is None or not country.is_live:
        return []
    available = [t for t in ListingType if country.allows(t)]
    if not f.types:
        return available
    return [t for t in f.types if t in available]


@router.get("/listings/calendar", response_model=CalendarOut)
def listings_calendar(
    db: DbSession,
    start: date | None = None,
    end: date | None = None,
    type_: Annotated[list[ListingType] | None, Query(alias="type")] = None,
    country: str | None = Query(None, min_length=2, max_length=2),
    city: str | None = Query(None, max_length=120),
    q: str | None = Query(None, max_length=200),
    tag: Annotated[list[str] | None, Query()] = None,
    price_min_minor: int | None = Query(None, ge=0),
    price_max_minor: int | None = Query(None, ge=0),
    free: bool = False,
) -> CalendarOut:
    """How much is on each day, for the concept's central calendar.

    Days are the market's own local days, because "what's on Saturday" is a
    local question. Days with nothing on are left out.
    """
    code = (country or countries.default_code()).upper()
    country_row = countries.get(db, code)
    if country_row is None or not country_row.is_live:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No such market")

    start = start or date.today()
    end = end or start + timedelta(days=30)
    if end < start:
        raise HTTPException(422, "end is before start")
    if (end - start).days + 1 > MAX_CALENDAR_DAYS:
        raise HTTPException(422, f"at most {MAX_CALENDAR_DAYS} days per request")

    f = _filters(
        type_=type_,
        country=code,
        city=city,
        q=q,
        tag=tag,
        starts_after=None,
        starts_before=None,
        # The window is the calendar's own range, not "from now".
        upcoming_only=False,
        price_min_minor=price_min_minor,
        price_max_minor=price_max_minor,
        free=free,
        min_rating=None,
        bbox=None,
        near=None,
        radius_km=10,
        sort=listings.Sort.date,
        limit=listings.MAX_LIMIT,
        offset=0,
    )
    f.types = enabled_types(db, f)
    tally = listings.calendar(db, f, start, end) if f.types else {}
    return CalendarOut(
        country_code=code,
        timezone=country_row.timezone,
        start=start,
        end=end,
        days=[CalendarDayOut(day=d, count=n) for d, n in tally.items()],
    )


# Declared after /v1/listings/calendar on purpose: Starlette matches in order,
# and a single-segment path parameter would otherwise swallow it.
@router.get("/listings/{slug}", response_model=ListingDetailOut)
def listing_detail(slug: str, db: DbSession) -> ListingDetailOut:
    """One listing of any category, with whatever its category adds.

    The event-specific page (`/v1/events/{slug}`) stays as it is: it carries
    tiers and live availability, which no other category has.
    """
    listing = db.scalar(
        select(Listing).where(Listing.slug == slug, Listing.status != ListingStatus.draft)
    )
    if listing is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Listing not found")

    detail = ListingDetailOut(
        **ListingSummaryOut.model_validate(listing, from_attributes=True).model_dump(),
        description=listing.description,
        address=listing.address,
        organisation=OrganisationCardOut.model_validate(
            db.get(Organisation, listing.organisation_id), from_attributes=True
        ),
        collaborators=[
            CollaboratorOut(
                id=org.id, name=org.name, slug=org.slug, instagram=org.instagram, credit=credit
            )
            for org, credit in collaborators.for_listing(db, listing.id)
        ],
    )
    if listing.type == ListingType.event:
        detail.event = EventFieldsOut.model_validate(listing, from_attributes=True)
    elif listing.type == ListingType.service:
        service = db.get(ServiceListing, listing.id)
        if service is not None:
            detail.service = ServiceFieldsOut.model_validate(service, from_attributes=True)
    elif listing.type == ListingType.accommodation:
        place = db.get(AccommodationListing, listing.id)
        if place is not None:
            detail.accommodation = AccommodationFieldsOut.model_validate(
                place, from_attributes=True
            )
    return detail
