"""Import every model here so Alembic autogenerate sees the full schema."""

from app.models.event import Event, EventCategory, EventStatus, Seller, TicketTier
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
    "Event",
    "EventCategory",
    "EventStatus",
    "MemberRole",
    "Order",
    "OrderItem",
    "OrderStatus",
    "OrgMember",
    "Organisation",
    "SalesChannel",
    "Seller",
    "Ticket",
    "TicketStatus",
    "TicketTier",
    "User",
]
