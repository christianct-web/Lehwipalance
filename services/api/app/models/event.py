import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, IdMixin, TimestampMixin


class EventStatus(enum.StrEnum):
    draft = "draft"
    published = "published"
    cancelled = "cancelled"


class EventCategory(enum.StrEnum):
    fete = "fete"
    concert = "concert"
    festival = "festival"
    sport = "sport"
    community = "community"
    other = "other"


class Event(IdMixin, TimestampMixin, Base):
    __tablename__ = "events"

    organisation_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("organisations.id"), index=True)
    title: Mapped[str] = mapped_column(String(200))
    slug: Mapped[str] = mapped_column(String(160), unique=True, index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    category: Mapped[EventCategory] = mapped_column(
        Enum(EventCategory, native_enum=False), default=EventCategory.fete
    )
    status: Mapped[EventStatus] = mapped_column(
        Enum(EventStatus, native_enum=False), default=EventStatus.draft, index=True
    )
    venue_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    address: Mapped[str | None] = mapped_column(String(300), nullable=True)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    cover_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    tiers: Mapped[list["TicketTier"]] = relationship(
        back_populates="event", order_by="TicketTier.sort_order"
    )


class TicketTier(IdMixin, TimestampMixin, Base):
    """Early bird, Tier 1, VIP... Money is stored in minor units (cents)."""

    __tablename__ = "ticket_tiers"

    event_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("events.id"), index=True)
    name: Mapped[str] = mapped_column(String(120))
    price_minor: Mapped[int] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), default="TTD")
    quantity: Mapped[int] = mapped_column(Integer)
    quantity_sold: Mapped[int] = mapped_column(Integer, default=0)
    max_per_order: Mapped[int] = mapped_column(Integer, default=10)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    sales_start_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    sales_end_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    event: Mapped[Event] = relationship(back_populates="tiers")

    @property
    def remaining(self) -> int:
        return max(self.quantity - self.quantity_sold, 0)


class Seller(IdMixin, TimestampMixin, Base):
    """A committee member selling for a promoter, tracked by a personal code."""

    __tablename__ = "sellers"

    event_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("events.id"), index=True)
    user_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    display_name: Mapped[str] = mapped_column(String(120))
    code: Mapped[str] = mapped_column(String(32), unique=True, index=True)
