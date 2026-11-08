import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Index, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin


class OfferType(enum.StrEnum):
    """What shape of thing is being sold.

    Each listing category sells something differently: a fete sells tiers of
    admission, accommodation sells nights in a room, a tour sells seats on a
    departure, a store sells stock. They share a price, a currency and a sales
    window; they do not share how inventory is counted, which is why this is a
    hierarchy and not one table with nullable columns.
    """

    ticket_tier = "ticket_tier"
    room_type = "room_type"


class Offer(IdMixin, TimestampMixin, Base):
    """Something sellable on a listing.

    The base of a joined-table inheritance hierarchy, the same pattern
    `listings` uses. Everything an order line needs in order to be priced and
    sold lives here, so `order_items` points at one table whatever is being
    bought. How many are left is the subclass's business, because a ticket tier
    counts a single pool while a room counts per night.
    """

    __tablename__ = "offers"
    __table_args__ = (Index("ix_offers_listing_type", "listing_id", "type"),)

    listing_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("listings.id", ondelete="CASCADE"), index=True
    )
    type: Mapped[OfferType] = mapped_column(Enum(OfferType, native_enum=False), index=True)
    name: Mapped[str] = mapped_column(String(120))
    # Money is integer minor units with an explicit currency, from the
    # listing's market.
    price_minor: Mapped[int] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), default="TTD")
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    # When this can be bought, which is not the same as when it is used: early
    # bird tickets stop selling long before the fete.
    sales_start_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sales_end_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __mapper_args__ = {"polymorphic_on": type}
