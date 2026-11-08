import enum
import uuid
from datetime import date, datetime

from sqlalchemy import Date, DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin


class InquiryStatus(enum.StrEnum):
    """The states the Flutter customer app already models
    (`lib/core/models/inquiries_model.dart`), kept identical so
    `RealApiService` needs no translation layer.
    """

    pending = "pending"
    responded = "responded"
    resolved = "resolved"
    cancelled = "cancelled"


class Inquiry(IdMixin, TimestampMixin, Base):
    """Someone asking a vendor about a service: the concept's "contact and
    booking flow directly in-app".

    One message and one reply, which is what the Flutter app's contract
    already expects (`respondToInquiry`, `updateInquiryStatus`). A full
    back-and-forth thread is a later decision, not a silent one: the app's
    `ChatApiService` is prototype surface area nobody has asked for.
    """

    __tablename__ = "inquiries"

    listing_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("listings.id", ondelete="CASCADE"), index=True
    )
    # The vendor's organisation, copied from the listing when the inquiry is
    # made so their whole inbox is one indexed read rather than a join per
    # listing.
    organisation_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("organisations.id", ondelete="CASCADE"), index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))

    subject: Mapped[str] = mapped_column(String(200))
    message: Mapped[str] = mapped_column(Text)
    # When the organiser needs it. Often the first thing that decides whether a
    # vendor can help at all.
    event_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    # So a vendor can reply without the organiser being a registered user with
    # notifications set up.
    contact_phone: Mapped[str | None] = mapped_column(String(32), nullable=True)

    response: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[InquiryStatus] = mapped_column(
        Enum(InquiryStatus, native_enum=False), default=InquiryStatus.pending, index=True
    )
    responded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
