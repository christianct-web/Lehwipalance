import enum
import uuid

from sqlalchemy import Enum, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, IdMixin, TimestampMixin
from app.models.listing import Listing, ListingType
from app.models.offer import Offer, OfferType


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

    # An offer's foreign key points at `listings`, which an event shares with
    # every other category, so the join is spelled out rather than inferred.
    tiers: Mapped[list["TicketTier"]] = relationship(
        "TicketTier",
        primaryjoin="TicketTier.listing_id == Event.id",
        foreign_keys="TicketTier.listing_id",
        order_by="TicketTier.sort_order",
        cascade="all, delete-orphan",
    )


class TicketTier(Offer):
    """Early bird, Tier 1, VIP: a pool of admissions at one price.

    Its inventory is a single counter, which is what makes it different from a
    room (counted per night) or a tour departure (counted per date). The shared
    part — price, currency, sales window — lives on `Offer`.
    """

    __tablename__ = "ticket_tiers"

    id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("offers.id", ondelete="CASCADE"), primary_key=True
    )
    quantity: Mapped[int] = mapped_column(Integer)
    quantity_sold: Mapped[int] = mapped_column(Integer, default=0)
    max_per_order: Mapped[int] = mapped_column(Integer, default=10)

    __mapper_args__ = {"polymorphic_identity": OfferType.ticket_tier}

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
