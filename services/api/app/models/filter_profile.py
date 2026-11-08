import enum
import uuid
from datetime import datetime

from sqlalchemy import (
    JSON,
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
    false,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, IdMixin, TimestampMixin


class PriceBand(enum.StrEnum):
    """The concept's price preference: "free, paid, or custom bracket"."""

    any = "any"
    free = "free"
    paid = "paid"
    custom = "custom"


class DatePreference(enum.StrEnum):
    """The concept's date preference: "upcoming, this weekend, this month, or
    custom". The relative ones resolve against the market's local clock at read
    time, so a saved profile keeps meaning what it says as time passes."""

    upcoming = "upcoming"
    this_weekend = "this_weekend"
    this_month = "this_month"
    custom = "custom"


class FilterProfile(IdMixin, TimestampMixin, Base):
    """A saved set of discovery preferences, scoped to a country or a city.

    From docs/original-concept.md: a customer keeps several of these — a
    Trinidad profile tuned to events, a Tobago one tuned to places to stay —
    and switches between them to change the feed.

    The fields mirror `app.services.listings.Filters`, which is what the feed
    actually runs, so the stored shape and the query shape cannot drift.

    `listing_types` and `tags` are JSON here, unlike `listing_tags` on a
    listing: these are read back whole to build a query, never themselves
    queried, so there is nothing for an index to do.
    """

    __tablename__ = "filter_profiles"
    __table_args__ = (UniqueConstraint("user_id", "name", name="uq_filter_profiles_user_name"),)

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(80))
    # The profile driving the feed. Exactly one per user is active; the service
    # enforces it when activating, rather than a partial unique index, which
    # would have to be spelled differently for each backend.
    is_active: Mapped[bool] = mapped_column(Boolean, default=False, server_default=false())

    # Location scope: a market, optionally narrowed to one city.
    country_code: Mapped[str] = mapped_column(String(2), ForeignKey("countries.code"), default="TT")
    city: Mapped[str | None] = mapped_column(String(120), nullable=True)

    # Category interests. Empty means every category the market shows.
    listing_types: Mapped[list[str]] = mapped_column(JSON, default=list)
    # Keyword interests, matched against a listing's tags.
    tags: Mapped[list[str]] = mapped_column(JSON, default=list)

    price_band: Mapped[PriceBand] = mapped_column(
        Enum(PriceBand, native_enum=False), default=PriceBand.any
    )
    # Only meaningful when price_band is `custom`.
    price_min_minor: Mapped[int | None] = mapped_column(Integer, nullable=True)
    price_max_minor: Mapped[int | None] = mapped_column(Integer, nullable=True)

    date_preference: Mapped[DatePreference] = mapped_column(
        Enum(DatePreference, native_enum=False), default=DatePreference.upcoming
    )
    # Only meaningful when date_preference is `custom`.
    starts_after: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    starts_before: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    sort: Mapped[str] = mapped_column(String(20), default="date")
