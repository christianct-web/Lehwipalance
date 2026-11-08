"""Import every model here so Alembic autogenerate sees the full schema."""

from app.models.accommodation import AccommodationListing, PropertyType, RoomType
from app.models.booking import Booking, BookingStatus
from app.models.collaborator import ListingCollaborator
from app.models.country import Country
from app.models.event import Event, EventCategory, Seller, TicketTier
from app.models.filter_profile import DatePreference, FilterProfile, PriceBand
from app.models.inquiry import Inquiry, InquiryStatus
from app.models.listing import Listing, ListingStatus, ListingTag, ListingType
from app.models.offer import Offer, OfferType
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
from app.models.service import PriceModel, ServiceCategory, ServiceListing
from app.models.social import Favourite, Follow
from app.models.user import User

__all__ = [
    "AccommodationListing",
    "Booking",
    "BookingStatus",
    "Country",
    "DatePreference",
    "Event",
    "EventCategory",
    "Favourite",
    "FilterProfile",
    "Follow",
    "Inquiry",
    "InquiryStatus",
    "Listing",
    "ListingCollaborator",
    "ListingStatus",
    "ListingTag",
    "ListingType",
    "MemberRole",
    "Offer",
    "OfferType",
    "Order",
    "OrderItem",
    "OrderStatus",
    "OrgMember",
    "PriceBand",
    "PriceModel",
    "PropertyType",
    "Review",
    "ReviewSection",
    "ReviewSectionRating",
    "RoomType",
    "Organisation",
    "SalesChannel",
    "ServiceCategory",
    "ServiceListing",
    "Seller",
    "Ticket",
    "TicketStatus",
    "TicketTier",
    "User",
]
