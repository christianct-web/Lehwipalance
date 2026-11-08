import enum
import uuid
from datetime import datetime

from sqlalchemy import (
    JSON,
    CheckConstraint,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Index,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin


class ListingType(enum.StrEnum):
    """The five listing categories from docs/original-concept.md.

    The Flutter customer app's own enum (apps/customer/lib/enum.dart) names two
    of these differently: its `hotel` is `accommodation` here and its `place` is
    `vacation`. That mapping belongs in RealApiService, not in the schema.
    """

    event = "event"
    accommodation = "accommodation"
    vacation = "vacation"
    service = "service"
    store = "store"


class ListingStatus(enum.StrEnum):
    draft = "draft"
    published = "published"
    cancelled = "cancelled"


class Listing(IdMixin, TimestampMixin, Base):
    """Anything an organisation publishes, of any category.

    This is the base of a joined-table inheritance hierarchy: everything
    discovery touches lives here, in one indexed table, so the central calendar,
    the map, search, filter profiles, follows, favourites, reviews, the media
    feed and collaborators can all work across categories without a union over
    five tables. Category-specific columns live in a detail table per type
    (`event_details` and so on), keyed by the same id.

    The base is never instantiated directly and so has no polymorphic identity;
    each subclass declares its own. Adding a category means adding a subclass
    and its detail table, not touching this one.
    """

    __tablename__ = "listings"
    __table_args__ = (
        # An event without a start time is meaningless, but accommodation has
        # no single start (availability lives in its rate plans), so the column
        # is nullable and the invariant is enforced per type instead.
        CheckConstraint(
            "type <> 'event' OR starts_at IS NOT NULL",
            name="ck_listings_event_has_start",
        ),
        # The shape of nearly every discovery query: this category, published,
        # in date order.
        Index("ix_listings_discovery", "type", "status", "starts_at"),
        Index("ix_listings_country_city", "country_code", "city"),
    )

    organisation_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("organisations.id"), index=True)
    type: Mapped[ListingType] = mapped_column(Enum(ListingType, native_enum=False), index=True)
    title: Mapped[str] = mapped_column(String(200))
    # Unique across every category, so one URL space serves all of them.
    slug: Mapped[str] = mapped_column(String(160), unique=True, index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[ListingStatus] = mapped_column(
        Enum(ListingStatus, native_enum=False), default=ListingStatus.draft, index=True
    )

    # Market. Decides currency, fee rates and which categories are on offer.
    country_code: Mapped[str] = mapped_column(
        String(2), ForeignKey("countries.code"), default="TT", index=True
    )
    city: Mapped[str | None] = mapped_column(String(120), nullable=True)

    venue_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    address: Mapped[str | None] = mapped_column(String(300), nullable=True)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    cover_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # When this listing happens. An event's date and door time; a tour's season.
    # Null for a category with no single date, such as a service or a store.
    starts_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True
    )
    ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # The concept's "keyword interests": free tags a filter profile can match.
    tags: Mapped[list[str]] = mapped_column(JSON, default=list)

    __mapper_args__ = {"polymorphic_on": type}
