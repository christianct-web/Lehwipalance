import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, IdMixin, TimestampMixin
from app.models.listing import Listing, ListingType


class EventCategory(enum.StrEnum):
    fete = "fete"
    concert = "concert"
    festival = "festival"
    sport = "sport"
    community = "community"
    other = "other"


class Event(Listing):
    """An event listing: a fete, concert, festival or sporting fixture.

    Everything shared with the other categories — title, slug, status, venue,
    location, cover, tags, and the date in `starts_at`/`ends_at` — lives on
    `Listing`. Only what is specific to an event lives here.
    """

    __tablename__ = "event_details"

    id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("listings.id", ondelete="CASCADE"), primary_key=True
    )
    category: Mapped[EventCategory] = mapped_column(
        Enum(EventCategory, native_enum=False), default=EventCategory.fete
    )

    __mapper_args__ = {"polymorphic_identity": ListingType.event}

    tiers: Mapped[list["TicketTier"]] = relationship(
        back_populates="event", order_by="TicketTier.sort_order"
    )


class TicketTier(IdMixin, TimestampMixin, Base):
    """Early bird, Tier 1, VIP... Money is stored in minor units (cents).

    Tiers are an event's sellable inventory. When accommodation arrives this
    grows into a shared `Offer` base alongside rate plans and tour departures;
    until there is a second real shape to generalise against, it stays as it is.
    """

    __tablename__ = "ticket_tiers"

    # To event_details rather than listings, so a tier can only ever hang off
    # an event.
    event_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("event_details.id"), index=True)
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
        """Unsold capacity, ignoring checkout holds. What a buyer can actually
        get is `services.orders.available`, which subtracts holds."""
        return max(self.quantity - self.quantity_sold, 0)


class Seller(IdMixin, TimestampMixin, Base):
    """A committee member selling for a promoter, tracked by a personal code."""

    __tablename__ = "sellers"

    event_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("event_details.id"), index=True)
    user_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    display_name: Mapped[str] = mapped_column(String(120))
    code: Mapped[str] = mapped_column(String(32), unique=True, index=True)
