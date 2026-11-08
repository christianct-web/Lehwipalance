"""Request and response bodies for filter profiles and the feed they drive."""

from datetime import datetime
from typing import Self
from uuid import UUID

from pydantic import AwareDatetime, BaseModel, ConfigDict, Field, model_validator

from app.models import DatePreference, ListingType, PriceBand
from app.schemas.listings import ListingSummaryOut


class _ProfileFields(BaseModel):
    city: str | None = Field(None, max_length=120)
    listing_types: list[ListingType] = Field(default_factory=list)
    tags: list[str] = Field(default_factory=list, max_length=30)
    price_band: PriceBand = PriceBand.any
    price_min_minor: int | None = Field(None, ge=0)
    price_max_minor: int | None = Field(None, ge=0)
    date_preference: DatePreference = DatePreference.upcoming
    starts_after: AwareDatetime | None = None
    starts_before: AwareDatetime | None = None
    sort: str = "date"

    @model_validator(mode="after")
    def _coherent(self) -> Self:
        if self.price_band == PriceBand.custom:
            if self.price_min_minor is None and self.price_max_minor is None:
                raise ValueError("a custom price band needs a minimum or a maximum")
            lo, hi = self.price_min_minor, self.price_max_minor
            if lo is not None and hi is not None and lo > hi:
                raise ValueError("price_min_minor is above price_max_minor")
        if self.date_preference == DatePreference.custom:
            if self.starts_after is None and self.starts_before is None:
                raise ValueError("a custom date preference needs a start or an end")
            a, b = self.starts_after, self.starts_before
            if a is not None and b is not None and a > b:
                raise ValueError("starts_after is later than starts_before")
        return self


class FilterProfileIn(_ProfileFields):
    name: str = Field(min_length=1, max_length=80)
    # Only Trinidad & Tobago is live; the route checks it against the markets.
    country_code: str = Field("TT", min_length=2, max_length=2)
    # Make this the profile driving the feed as soon as it exists.
    activate: bool = False


class FilterProfilePatch(_ProfileFields):
    name: str | None = Field(None, min_length=1, max_length=80)
    country_code: str | None = Field(None, min_length=2, max_length=2)


class FilterProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    is_active: bool
    country_code: str
    city: str | None
    listing_types: list[str]
    tags: list[str]
    price_band: str
    price_min_minor: int | None
    price_max_minor: int | None
    date_preference: str
    starts_after: datetime | None
    starts_before: datetime | None
    sort: str


class FeedOut(BaseModel):
    """The "For You" view: what the active profile is asking for, and the
    window it resolved to, so a client can label the results honestly."""

    profile: FilterProfileOut
    resolved_starts_after: datetime | None
    resolved_starts_before: datetime | None
    total: int
    limit: int
    offset: int
    results: list[ListingSummaryOut]
