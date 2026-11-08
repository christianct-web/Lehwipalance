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
from app.models.user import User

__all__ = [
    "Country",
    "DatePreference",
    "Event",
    "EventCategory",
    "FilterProfile",
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
    "Organisation",
    "SalesChannel",
    "Seller",
    "Ticket",
    "TicketStatus",
    "TicketTier",
    "User",
]
