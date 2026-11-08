"""Accommodation listings, room types, availability and stays."""

from datetime import date, datetime, time
from typing import Self
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, model_validator

from app.models import PropertyType


class _PlaceFields(BaseModel):
    description: str | None = Field(None, max_length=10_000)
    city: str | None = Field(None, max_length=120)
    venue_name: str | None = Field(None, max_length=200)
    address: str | None = Field(None, max_length=300)
    latitude: float | None = Field(None, ge=-90, le=90)
    longitude: float | None = Field(None, ge=-180, le=180)
    cover_image_url: str | None = Field(None, max_length=500)
    tags: list[str] = Field(default_factory=list, max_length=30)
    property_type: PropertyType = PropertyType.hotel
    check_in_after: time | None = None
    check_out_before: time | None = None


class PlaceIn(_PlaceFields):
    title: str = Field(min_length=1, max_length=200)


class PlacePatch(_PlaceFields):
    title: str | None = Field(None, min_length=1, max_length=200)


class RoomIn(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    # Per night.
    price_minor: int = Field(ge=0)
    units: int = Field(ge=1, le=10_000)
    max_guests: int = Field(2, ge=1, le=50)
    min_nights: int = Field(1, ge=1, le=90)
    sort_order: int = 0


class RoomPatch(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=120)
    price_minor: int | None = Field(None, ge=0)
    units: int | None = Field(None, ge=1, le=10_000)
    max_guests: int | None = Field(None, ge=1, le=50)
    min_nights: int | None = Field(None, ge=1, le=90)
    sort_order: int | None = None


class RoomOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    price_minor: int
    currency: str
    units: int
    max_guests: int
    min_nights: int
    sort_order: int


class PlaceOut(BaseModel):
    """A property as its own organisation sees it, drafts included."""

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
    property_type: str
    check_in_after: time | None
    check_out_before: time | None
    price_min_minor: int | None
    price_max_minor: int | None
    rating_count: int
    rating_average: float | None
    rooms: list[RoomOut]


class RoomAvailabilityOut(BaseModel):
    room: RoomOut
    available: int
    nights: int
    subtotal_minor: int
    buyer_fee_minor: int
    total_minor: int
    currency: str
    # Why it cannot be booked, when it cannot: a minimum-nights rule or
    # occupancy, rather than a bare zero.
    unavailable_reason: str | None = None


class AvailabilityOut(BaseModel):
    listing_slug: str
    stay_start: date
    stay_end: date
    nights: int
    rooms: list[RoomAvailabilityOut]


class StayIn(BaseModel):
    listing_slug: str
    room_type_id: UUID
    stay_start: date
    stay_end: date
    rooms: int = Field(1, ge=1, le=20)
    guests: int = Field(1, ge=1, le=100)
    buyer_name: str = Field(min_length=1, max_length=200)
    buyer_email: EmailStr
    buyer_phone: str | None = Field(None, max_length=32)

    @model_validator(mode="after")
    def _ordered(self) -> Self:
        if self.stay_end <= self.stay_start:
            raise ValueError("stay_end must be after stay_start")
        return self


class BookingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    status: str
    stay_start: date
    stay_end: date
    nights: int
    rooms: int
    guests: int
    checked_in_at: datetime | None
    checked_out_at: datetime | None


class StayPlaceOut(BaseModel):
    title: str
    slug: str
    city: str | None
    address: str | None
    check_in_after: time | None
    check_out_before: time | None


class StayOut(BaseModel):
    """An order for a stay: the money, the place and the booking."""

    id: UUID
    status: str
    place: StayPlaceOut
    booking: BookingOut
    room_name: str
    currency: str
    subtotal_minor: int
    buyer_fee_minor: int
    total_minor: int
    buyer_name: str | None
    buyer_email: str | None
    created_at: datetime
    expires_at: datetime | None
    paid_at: datetime | None
    access_token: str
    is_test: bool
    checkout_url: str | None = None
