"""Filter profiles: saved discovery preferences, and the feed they drive.

A profile stores what someone is interested in; `to_filters` turns it into the
same `listings.Filters` the open search endpoint uses, so the "For You" feed is
the ordinary discovery query with the profile's arguments rather than a second
implementation that can drift from it.

The relative date preferences — upcoming, this weekend, this month — are
resolved here, against the market's local clock, every time the feed is read.
A profile saved in January still means "this weekend" in March.
"""

from datetime import UTC, datetime, time, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.models import DatePreference, FilterProfile, ListingType, PriceBand, User
from app.services import countries, listings

# Enough for a profile per island plus a few moods; a bound stops one account
# filling the table.
MAX_PER_USER = 20

# A fete weekend starts on Friday: Friday night is the Carnival season's
# busiest slot, so "this weekend" that excluded it would be wrong for the
# product even though it is right for a calendar.
_WEEKEND_START_WEEKDAY = 4  # Monday is 0


def for_user(db: Session, user: User) -> list[FilterProfile]:
    return list(
        db.scalars(
            select(FilterProfile)
            .where(FilterProfile.user_id == user.id)
            .order_by(FilterProfile.name)
        )
    )


def active(db: Session, user: User) -> FilterProfile | None:
    return db.scalar(
        select(FilterProfile).where(
            FilterProfile.user_id == user.id, FilterProfile.is_active.is_(True)
        )
    )


def activate(db: Session, profile: FilterProfile) -> None:
    """Make this the profile driving the feed. The caller commits."""
    db.execute(
        update(FilterProfile)
        .where(
            FilterProfile.user_id == profile.user_id,
            FilterProfile.id != profile.id,
            FilterProfile.is_active.is_(True),
        )
        .values(is_active=False)
    )
    profile.is_active = True


def weekend_window(now: datetime) -> tuple[datetime, datetime]:
    """The current weekend if one is under way, otherwise the coming one.

    Friday 00:00 through Sunday 23:59:59.999999, in whatever timezone `now`
    carries.
    """
    # Negative on Friday, Saturday or Sunday, which lands on the weekend
    # already under way; positive earlier in the week, which lands on the
    # coming one.
    friday = (now + timedelta(days=_WEEKEND_START_WEEKDAY - now.weekday())).date()
    start = datetime.combine(friday, time.min, tzinfo=now.tzinfo)
    end = datetime.combine(friday + timedelta(days=2), time.max, tzinfo=now.tzinfo)
    return start, end


def month_window(now: datetime) -> tuple[datetime, datetime]:
    first = now.date().replace(day=1)
    next_first = (first + timedelta(days=31)).replace(day=1)
    return (
        datetime.combine(first, time.min, tzinfo=now.tzinfo),
        datetime.combine(next_first - timedelta(days=1), time.max, tzinfo=now.tzinfo),
    )


def _date_window(
    profile: FilterProfile, now_local: datetime
) -> tuple[datetime | None, datetime | None]:
    if profile.date_preference == DatePreference.this_weekend:
        return weekend_window(now_local)
    if profile.date_preference == DatePreference.this_month:
        return month_window(now_local)
    if profile.date_preference == DatePreference.custom:
        return profile.starts_after, profile.starts_before
    # upcoming
    return now_local.astimezone(UTC), None


def to_filters(
    db: Session, profile: FilterProfile, *, limit: int = 50, offset: int = 0
) -> listings.Filters:
    """The discovery query this profile asks for, resolved as of now."""
    country = countries.get(db, profile.country_code)
    tz = ZoneInfo(country.timezone) if country else UTC
    starts_after, starts_before = _date_window(profile, datetime.now(tz))

    band = profile.price_band
    return listings.Filters(
        types=[ListingType(t) for t in (profile.listing_types or [])],
        country_code=profile.country_code,
        city=profile.city,
        tags=list(profile.tags or []),
        starts_after=starts_after,
        starts_before=starts_before,
        free_only=band == PriceBand.free,
        paid_only=band == PriceBand.paid,
        price_min_minor=profile.price_min_minor if band == PriceBand.custom else None,
        price_max_minor=profile.price_max_minor if band == PriceBand.custom else None,
        sort=profile.sort,
        limit=limit,
        offset=offset,
    )
