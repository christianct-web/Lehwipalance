"""Request and response bodies for the promoter (organisation-scoped) endpoints."""

from datetime import datetime
from typing import Self
from uuid import UUID

from pydantic import AwareDatetime, BaseModel, ConfigDict, EmailStr, Field, model_validator

from app.models import EventCategory, EventStatus, MemberRole

# ---------- Organisations ----------


class OrganisationIn(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    contact_email: EmailStr | None = None
    contact_phone: str | None = Field(None, max_length=32)
    instagram: str | None = Field(None, max_length=120)


class OrganisationPatch(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=200)
    contact_email: EmailStr | None = None
    contact_phone: str | None = Field(None, max_length=32)
    instagram: str | None = Field(None, max_length=120)


class OrganisationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    slug: str
    contact_email: str | None
    contact_phone: str | None
    instagram: str | None


class MyOrganisationOut(OrganisationOut):
    role: MemberRole


# ---------- Members ----------


class MemberIn(BaseModel):
    email: EmailStr
    role: MemberRole


class MemberOut(BaseModel):
    user_id: UUID
    email: str
    full_name: str
    role: MemberRole


# ---------- Events ----------


class _EventFields(BaseModel):
    description: str | None = Field(None, max_length=10_000)
    category: EventCategory | None = None
    venue_name: str | None = Field(None, max_length=200)
    address: str | None = Field(None, max_length=300)
    latitude: float | None = Field(None, ge=-90, le=90)
    longitude: float | None = Field(None, ge=-180, le=180)
    ends_at: AwareDatetime | None = None
    cover_image_url: str | None = Field(None, max_length=500)


class EventIn(_EventFields):
    title: str = Field(min_length=1, max_length=200)
    category: EventCategory = EventCategory.fete
    starts_at: AwareDatetime


class EventPatch(_EventFields):
    title: str | None = Field(None, min_length=1, max_length=200)
    starts_at: AwareDatetime | None = None


class PromoterTierOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    price_minor: int
    currency: str
    quantity: int
    quantity_sold: int
    remaining: int
    max_per_order: int
    sort_order: int
    sales_start_at: datetime | None
    sales_end_at: datetime | None


class PromoterEventSummaryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    slug: str
    title: str
    category: EventCategory
    status: EventStatus
    venue_name: str | None
    starts_at: datetime


class PromoterEventOut(PromoterEventSummaryOut):
    description: str | None
    address: str | None
    latitude: float | None
    longitude: float | None
    ends_at: datetime | None
    cover_image_url: str | None
    tiers: list[PromoterTierOut]


# ---------- Ticket tiers ----------


class _TierFields(BaseModel):
    sales_start_at: AwareDatetime | None = None
    sales_end_at: AwareDatetime | None = None

    @model_validator(mode="after")
    def _window_in_order(self) -> Self:
        if self.sales_start_at and self.sales_end_at and self.sales_end_at <= self.sales_start_at:
            raise ValueError("sales_end_at must be after sales_start_at")
        return self


class TierIn(_TierFields):
    name: str = Field(min_length=1, max_length=120)
    price_minor: int = Field(ge=0, le=100_000_000)
    quantity: int = Field(ge=1, le=1_000_000)
    max_per_order: int = Field(10, ge=1, le=50)
    sort_order: int = 0


class TierPatch(_TierFields):
    name: str | None = Field(None, min_length=1, max_length=120)
    price_minor: int | None = Field(None, ge=0, le=100_000_000)
    quantity: int | None = Field(None, ge=1, le=1_000_000)
    max_per_order: int | None = Field(None, ge=1, le=50)
    sort_order: int | None = None


# ---------- Sellers ----------


class SellerIn(BaseModel):
    display_name: str = Field(min_length=1, max_length=120)
    # Optional: link the seller to an existing account so they can see their own sales.
    email: EmailStr | None = None


class SellerOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    display_name: str
    code: str
    user_id: UUID | None
