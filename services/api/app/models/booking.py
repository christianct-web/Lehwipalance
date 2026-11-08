import enum
import uuid
from datetime import date, datetime

from sqlalchemy import (
    CheckConstraint,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    Integer,
    String,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin


class BookingStatus(enum.StrEnum):
    # Waiting for payment, holding its nights until the order's hold lapses.
    held = "held"
    confirmed = "confirmed"
    checked_in = "checked_in"
    checked_out = "checked_out"
    cancelled = "cancelled"
    no_show = "no_show"


class Booking(IdMixin, TimestampMixin, Base):
    """A stay: rooms of one kind, over a range of nights.

    What a ticket is to an event, this is to accommodation — the thing the
    buyer now holds, with a code to present on arrival. The difference is the
    shape of what it consumes: a ticket takes one from a pool, a booking takes
    one room on each of several nights.

    `stay_end` is the departure date and is **exclusive**: a Friday-to-Sunday
    stay is nights of Friday and Saturday, and two such bookings can share a
    Sunday without colliding. Every overlap test in
    `app.services.bookings` depends on that.
    """

    __tablename__ = "bookings"
    __table_args__ = (
        CheckConstraint("stay_end > stay_start", name="ck_bookings_dates_ordered"),
        CheckConstraint("rooms > 0", name="ck_bookings_rooms_positive"),
        # The shape of the availability query: this room type, these nights.
        Index("ix_bookings_offer_dates", "offer_id", "stay_start", "stay_end"),
    )

    order_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("orders.id"), index=True)
    # The room type booked.
    offer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("offers.id"), index=True)
    guest_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), nullable=True)

    stay_start: Mapped[date] = mapped_column(Date)
    stay_end: Mapped[date] = mapped_column(Date)
    rooms: Mapped[int] = mapped_column(Integer, default=1)
    guests: Mapped[int] = mapped_column(Integer, default=1)

    # What the guest presents on arrival. Random, not guessable, like a ticket's.
    code: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    status: Mapped[BookingStatus] = mapped_column(
        Enum(BookingStatus, native_enum=False), default=BookingStatus.held, index=True
    )
    checked_in_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    checked_out_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    @property
    def nights(self) -> int:
        return (self.stay_end - self.stay_start).days
