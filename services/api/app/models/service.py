import enum
import uuid

from sqlalchemy import CheckConstraint, Enum, ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column

from app.models.listing import Listing, ListingType


class ServiceCategory(enum.StrEnum):
    """What a vendor does.

    Taken from the concept's "caterers, AV teams, speakers, photographers,
    planners, and more". The Flutter app's own `ServiceCategory` has only
    `entertainer` and `transport`, which is scaffold, not a taxonomy; this
    supersedes it.
    """

    catering = "catering"
    bar = "bar"
    av_production = "av_production"
    photography = "photography"
    entertainment = "entertainment"
    planning = "planning"
    decor = "decor"
    security = "security"
    transport = "transport"
    staffing = "staffing"
    other = "other"


class PriceModel(enum.StrEnum):
    """How a service is priced.

    Services mostly do not have a shelf price, so this says what the number on
    the listing means — or that there is no number and you have to ask.
    """

    fixed = "fixed"
    from_ = "from"
    hourly = "hourly"
    per_person = "per_person"
    quote_only = "quote_only"


class ServiceListing(Listing):
    """A vendor's offering: a caterer, AV crew, photographer, planner.

    The concept's venue and vendor directory — "the bridge between organizers
    and the services they need". Unlike an event it has no inventory and no
    date: it is an ongoing offering, and booking it happens through an inquiry
    rather than a checkout. That is why Phase C starts here: no inventory engine
    to generalise, and the buyers are promoters who already use the product.
    """

    __tablename__ = "service_details"
    __table_args__ = (
        # A quote-only service has no figure, and a priced one must have one.
        # Enforced here as well as in the migration, because the test database
        # is built from the models and would otherwise enforce nothing.
        CheckConstraint(
            "(price_model = 'quote_only') = (base_price_minor IS NULL)",
            name="ck_service_details_price_matches_model",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("listings.id", ondelete="CASCADE"), primary_key=True
    )
    category: Mapped[ServiceCategory] = mapped_column(
        Enum(ServiceCategory, native_enum=False), default=ServiceCategory.other
    )
    price_model: Mapped[PriceModel] = mapped_column(
        Enum(PriceModel, native_enum=False), default=PriceModel.quote_only
    )
    # What the price model refers to. Null when there is no published figure,
    # which is the honest state for quote_only and keeps the listing out of
    # price filters rather than pretending it is free.
    base_price_minor: Mapped[int | None] = mapped_column(Integer, nullable=True)
    # How far ahead a vendor needs to be asked. Practical information an
    # organiser wants before enquiring, not an afterthought.
    min_notice_days: Mapped[int | None] = mapped_column(Integer, nullable=True)

    __mapper_args__ = {"polymorphic_identity": ListingType.service}
