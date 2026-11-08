"""Service listings: the vendor directory's own fields, and listing detail."""

from datetime import datetime
from typing import Self
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.models import PriceModel, ServiceCategory
from app.schemas.listings import ListingSummaryOut
from app.schemas.organisations import CollaboratorOut, OrganisationCardOut


class ServiceFieldsOut(BaseModel):
    """What a service listing adds to the shared listing fields."""

    model_config = ConfigDict(from_attributes=True)

    category: str
    price_model: str
    base_price_minor: int | None
    min_notice_days: int | None


class EventFieldsOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    category: str


class ListingDetailOut(ListingSummaryOut):
    """One listing of any category, with whatever its category adds.

    Exactly one of `event` or `service` is set, chosen by `type`. A client that
    only knows about events keeps working; a new category adds a field rather
    than changing the shape of this response.
    """

    description: str | None
    address: str | None
    organisation: OrganisationCardOut
    collaborators: list[CollaboratorOut]
    event: EventFieldsOut | None = None
    service: ServiceFieldsOut | None = None


class _ServiceFields(BaseModel):
    description: str | None = Field(None, max_length=10_000)
    city: str | None = Field(None, max_length=120)
    venue_name: str | None = Field(None, max_length=200)
    address: str | None = Field(None, max_length=300)
    latitude: float | None = Field(None, ge=-90, le=90)
    longitude: float | None = Field(None, ge=-180, le=180)
    cover_image_url: str | None = Field(None, max_length=500)
    tags: list[str] = Field(default_factory=list, max_length=30)
    category: ServiceCategory = ServiceCategory.other
    price_model: PriceModel = PriceModel.quote_only
    base_price_minor: int | None = Field(None, ge=0)
    min_notice_days: int | None = Field(None, ge=0, le=365)

    @model_validator(mode="after")
    def _price_is_coherent(self) -> Self:
        if self.price_model == PriceModel.quote_only:
            if self.base_price_minor is not None:
                raise ValueError("a quote-only service cannot publish a price")
        elif self.base_price_minor is None:
            raise ValueError(f"a {self.price_model.value} price needs base_price_minor")
        return self


class ServiceIn(_ServiceFields):
    title: str = Field(min_length=1, max_length=200)


class ServicePatch(_ServiceFields):
    title: str | None = Field(None, min_length=1, max_length=200)


class ServiceOut(BaseModel):
    """A service as its own organisation sees it, including while a draft."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    slug: str
    title: str
    status: str
    description: str | None
    country_code: str
    city: str | None
    venue_name: str | None
    address: str | None
    latitude: float | None
    longitude: float | None
    cover_image_url: str | None
    tags: list[str]
    category: str
    price_model: str
    base_price_minor: int | None
    min_notice_days: int | None
    rating_count: int
    rating_average: float | None
    created_at: datetime
