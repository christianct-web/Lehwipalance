from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class TierOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    price_minor: int
    currency: str
    remaining: int
    max_per_order: int


class EventSummaryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    slug: str
    title: str
    category: str
    venue_name: str | None
    starts_at: datetime
    cover_image_url: str | None


class EventDetailOut(EventSummaryOut):
    description: str | None
    address: str | None
    latitude: float | None
    longitude: float | None
    ends_at: datetime | None
    tiers: list[TierOut]


class FeeQuoteOut(BaseModel):
    face_value_minor: int
    quantity: int
    subtotal_minor: int
    buyer_fee_minor: int
    total_minor: int
    promoter_fee_minor: int
    promoter_payout_minor: int
