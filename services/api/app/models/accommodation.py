import enum
import uuid
from datetime import time

from sqlalchemy import Enum, ForeignKey, Integer, Time
from sqlalchemy.orm import Mapped, mapped_column

from app.models.listing import Listing, ListingType
from app.models.offer import Offer, OfferType


class PropertyType(enum.StrEnum):
    """From the concept's "hotels, guesthouses, villas, and rentals"."""

    hotel = "hotel"
    guesthouse = "guesthouse"
    villa = "villa"
    apartment = "apartment"
    hostel = "hostel"
    other = "other"


class AccommodationListing(Listing):
    """Somewhere to stay.

    Has no single `starts_at` — it is available on an ongoing basis, and what a
    guest can actually get is decided per night by its rooms. That is why
    `listings.starts_at` is nullable and the check constraint only requires it
    of events.
    """

    __tablename__ = "accommodation_details"

    id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("listings.id", ondelete="CASCADE"), primary_key=True
    )
    property_type: Mapped[PropertyType] = mapped_column(
        Enum(PropertyType, native_enum=False), default=PropertyType.hotel
    )
    # Local times at the property. A guest needs them before booking, not on
    # arrival.
    check_in_after: Mapped[time | None] = mapped_column(Time, nullable=True)
    check_out_before: Mapped[time | None] = mapped_column(Time, nullable=True)

    __mapper_args__ = {"polymorphic_identity": ListingType.accommodation}


class RoomType(Offer):
    """A kind of room, of which the property has some number.

    `Offer.price_minor` is the rate **per night**. `units` is how many rooms of
    this kind exist, which is the ceiling on any single night — not a pool that
    depletes as a ticket tier does. A room sold for Friday is available again on
    Saturday, which is the whole reason `Offer` had to exist.
    """

    __tablename__ = "room_types"

    id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("offers.id", ondelete="CASCADE"), primary_key=True
    )
    units: Mapped[int] = mapped_column(Integer)
    max_guests: Mapped[int] = mapped_column(Integer, default=2)
    min_nights: Mapped[int] = mapped_column(Integer, default=1)

    __mapper_args__ = {"polymorphic_identity": OfferType.room_type}
