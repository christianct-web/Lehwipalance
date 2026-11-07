"""Checkout, tickets, staff sales, reports and check-in."""

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field

from app.models import SalesChannel


class OrderLineIn(BaseModel):
    tier_id: UUID
    quantity: int = Field(ge=1, le=50)


class _BuyerFields(BaseModel):
    buyer_name: str = Field(min_length=1, max_length=200)
    buyer_phone: str | None = Field(None, max_length=32)


class OrderIn(_BuyerFields):
    event_slug: str = Field(min_length=1, max_length=160)
    items: list[OrderLineIn] = Field(min_length=1, max_length=10)
    buyer_email: EmailStr
    seller_code: str | None = Field(None, max_length=32)


class StaffSaleIn(_BuyerFields):
    tier_id: UUID
    quantity: int = Field(ge=1, le=100)
    buyer_email: EmailStr | None = None
    channel: Literal[SalesChannel.seller_cash, SalesChannel.box_office] = SalesChannel.seller_cash
    seller_id: UUID | None = None


class TestPaymentIn(BaseModel):
    token: str
    outcome: Literal["paid", "declined"]


class OrderEventOut(BaseModel):
    title: str
    slug: str
    starts_at: datetime
    venue_name: str | None
    address: str | None
    cover_image_url: str | None


class OrderItemOut(BaseModel):
    tier_name: str
    quantity: int
    unit_price_minor: int


class TicketOut(BaseModel):
    code: str
    tier_name: str
    status: str
    checked_in_at: datetime | None


class OrderOut(BaseModel):
    id: UUID
    status: str  # pending | paid | failed | cancelled | refunded | expired
    channel: SalesChannel
    event: OrderEventOut
    items: list[OrderItemOut]
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
    link: str
    tickets: list[TicketOut]


class OrderCreatedOut(OrderOut):
    # Where to send the buyer to pay; None when the order is already paid (free tickets).
    checkout_url: str | None


class PublicConfigOut(BaseModel):
    payment_provider: str
    test_payments: bool


# ---------- Promoter reports ----------


class TierReport(BaseModel):
    tier_id: UUID
    name: str
    price_minor: int
    quantity: int
    sold: int
    held: int
    remaining: int
    gross_minor: int


class ChannelReport(BaseModel):
    channel: SalesChannel
    orders: int
    tickets: int
    gross_minor: int


class SellerReport(BaseModel):
    seller_id: UUID
    display_name: str
    code: str
    orders: int
    tickets: int
    gross_minor: int


class SalesReportOut(BaseModel):
    currency: str
    tickets_sold: int
    checked_in: int
    gross_minor: int  # face value of paid tickets
    buyer_fees_minor: int
    promoter_fees_minor: int
    payout_minor: int  # what the promoter is owed: face value less the promoter fee
    cash_collected_minor: int  # face value taken in cash by sellers and the box office
    tiers: list[TierReport]
    channels: list[ChannelReport]
    sellers: list[SellerReport]


class PromoterOrderOut(BaseModel):
    id: UUID
    created_at: datetime
    status: str
    channel: SalesChannel
    buyer_name: str | None
    buyer_email: str | None
    buyer_phone: str | None
    seller_name: str | None
    tickets: int
    checked_in: int
    total_minor: int
    link: str


class MySellerOut(BaseModel):
    id: UUID
    display_name: str
    code: str


# ---------- Check-in ----------


class CheckinIn(BaseModel):
    code: str = Field(min_length=1, max_length=200)


class CheckinStatsOut(BaseModel):
    checked_in: int
    total: int


class CheckinOut(CheckinStatsOut):
    result: Literal["ok", "already_checked_in", "void", "wrong_event", "not_found"]
    tier_name: str | None = None
    buyer_name: str | None = None
    checked_in_at: datetime | None = None
