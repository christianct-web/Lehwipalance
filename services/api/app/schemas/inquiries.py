"""Request and response bodies for inquiries."""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class InquiryIn(BaseModel):
    subject: str = Field(min_length=1, max_length=200)
    message: str = Field(min_length=1, max_length=4_000)
    # When the organiser needs it; often what decides whether a vendor can help.
    event_date: date | None = None
    contact_phone: str | None = Field(None, max_length=32)


class InquiryResponseIn(BaseModel):
    response: str = Field(min_length=1, max_length=4_000)


class InquiryListingOut(BaseModel):
    """Enough of the listing to show the inquiry in a list."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    slug: str
    title: str
    type: str


class InquiryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    listing: InquiryListingOut
    status: str
    subject: str
    message: str
    event_date: date | None
    contact_phone: str | None
    response: str | None
    created_at: datetime
    responded_at: datetime | None
    resolved_at: datetime | None


class VendorInquiryOut(InquiryOut):
    """The vendor's view, which also names who is asking so they can reply."""

    from_name: str
    from_email: str
