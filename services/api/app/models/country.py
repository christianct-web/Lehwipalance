from sqlalchemy import JSON, Boolean, Float, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin


class Country(TimestampMixin, Base):
    """A market. The concept gates features and sets fee rates per country, so
    this table — not a constant in the code — decides what is available where.

    Keyed by its ISO 3166-1 alpha-2 code rather than a surrogate id: there is
    one row per country, the code is stable, and it reads better in a listing's
    foreign key than an opaque uuid.

    Only Trinidad & Tobago is seeded and live. Another market is one row away,
    but each needs a payment rail that works there plus its own consumer
    protection, refund and tax position, so none is enabled by default.
    """

    __tablename__ = "countries"

    code: Mapped[str] = mapped_column(String(2), primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    currency: Mapped[str] = mapped_column(String(3))
    # IANA zone: "this weekend" and "this month" are local questions, not UTC ones.
    timezone: Mapped[str] = mapped_column(String(64))

    # Open to the public. A country can sit here half-configured while off.
    is_live: Mapped[bool] = mapped_column(Boolean, default=False)

    # Fee rates, admin-configurable per country as the concept requires.
    # Basis points, so the arithmetic stays exact; see services/fees.py.
    buyer_fee_bps: Mapped[int] = mapped_column(Integer)
    buyer_fee_fixed_minor: Mapped[int] = mapped_column(Integer)
    promoter_fee_bps: Mapped[int] = mapped_column(Integer)

    # Which of the five categories this market shows, as ListingType values.
    # The concept's "availability varies by country".
    enabled_listing_types: Mapped[list[str]] = mapped_column(JSON, default=list)
    # Food delivery needs couriers on the ground, not just a flag, so it stays
    # off until there is an operating partner in the market.
    delivery_enabled: Mapped[bool] = mapped_column(Boolean, default=False)

    # Where to centre the map before the device reports a location.
    default_latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    default_longitude: Mapped[float | None] = mapped_column(Float, nullable=True)

    def allows(self, listing_type: str) -> bool:
        """Whether this market shows a category. Takes a ListingType or its value."""
        return str(listing_type) in (self.enabled_listing_types or [])
