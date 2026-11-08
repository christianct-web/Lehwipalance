"""Import every model here so Alembic autogenerate sees the full schema."""

from app.models.country import Country
from app.models.event import Event, EventCategory, Seller, TicketTier
from app.models.filter_profile import DatePreference, FilterProfile, PriceBand
from app.models.listing import Listing, ListingStatus, ListingTag, ListingType
from app.models.order import (
    Order,
    OrderItem,
    OrderStatus,
    SalesChannel,
    Ticket,
    TicketStatus,
)
from app.models.organisation import MemberRole, Organisation, OrgMember
from app.models.review import Review, ReviewSection, ReviewSectionRating
from app.models.social import Favourite, Follow
from app.models.user import User

__all__ = [
    "Country",
    "DatePreference",
    "Event",
    "EventCategory",
    "Favourite",
    "FilterProfile",
    "Follow",
    "Listing",
    "ListingStatus",
    "ListingTag",
    "ListingType",
    "MemberRole",
    "Order",
    "OrderItem",
    "OrderStatus",
    "OrgMember",
    "PriceBand",
    "Review",
    "ReviewSection",
    "ReviewSectionRating",
    "Organisation",
    "SalesChannel",
    "Seller",
    "Ticket",
    "TicketStatus",
    "TicketTier",
    "User",
]
