"""Request and response bodies for discovery."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class ListingSummaryOut(BaseModel):
    """One card in a feed, a search result or a map popup, of any category."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    type: str
    slug: str
    title: str
    status: str
    country_code: str
    city: str | None
    venue_name: str | None
    latitude: float | None
    longitude: float | None
    starts_at: datetime | None
    ends_at: datetime | None
    cover_image_url: str | None
    price_min_minor: int | None
    price_max_minor: int | None
    rating_count: int
    rating_average: float | None
    tags: list[str]


class ListingPageOut(BaseModel):
    """A page of results, with the total so a client can show "123 found"."""

    total: int
    limit: int
    offset: int
    results: list[ListingSummaryOut]


class CalendarDayOut(BaseModel):
    day: date
    count: int


class CalendarOut(BaseModel):
    """Counts per day for the central calendar, in the market's own timezone."""

    country_code: str
    timezone: str
    start: date
    end: date
    days: list[CalendarDayOut]
