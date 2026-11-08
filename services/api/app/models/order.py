import enum
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Integer, String, false
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, IdMixin, TimestampMixin


class OrderStatus(enum.StrEnum):
    pending = "pending"
    paid = "paid"
    failed = "failed"
    cancelled = "cancelled"
    refunded = "refunded"


class SalesChannel(enum.StrEnum):
    online = "online"
    seller_cash = "seller_cash"
    box_office = "box_office"


class TicketStatus(enum.StrEnum):
    valid = "valid"
    checked_in = "checked_in"
    void = "void"


class Order(IdMixin, TimestampMixin, Base):
    __tablename__ = "orders"

    buyer_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    # To `listings`, not `event_details`: an accommodation order is not for
    # an event. Which categories are purchasable is an application rule.
    listing_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("listings.id"), index=True)
    seller_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("sellers.id"), nullable=True)
    status: Mapped[OrderStatus] = mapped_column(
        Enum(OrderStatus, native_enum=False), default=OrderStatus.pending, index=True
    )
    channel: Mapped[SalesChannel] = mapped_column(
        Enum(SalesChannel, native_enum=False), default=SalesChannel.online
    )
    currency: Mapped[str] = mapped_column(String(3), default="TTD")
    subtotal_minor: Mapped[int] = mapped_column(Integer)
    buyer_fee_minor: Mapped[int] = mapped_column(Integer, default=0)
    promoter_fee_minor: Mapped[int] = mapped_column(Integer, default=0)
    total_minor: Mapped[int] = mapped_column(Integer)
    # Reference from the payment provider. Card data never touches this system.
    payment_reference: Mapped[str | None] = mapped_column(String(120), nullable=True)
    paid_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Guest checkout: buyers don't need an account. The access token is the
    # secret in the order link that shows their tickets.
    buyer_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    buyer_email: Mapped[str | None] = mapped_column(String(320), nullable=True, index=True)
    buyer_phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    access_token: Mapped[str | None] = mapped_column(
        String(64), unique=True, index=True, nullable=True
    )
    # A pending online order holds its tickets until this time.
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # Paid through the simulated test provider: never admitted at the gate, and
    # kept out of inventory, holds and sales figures.
    is_test: Mapped[bool] = mapped_column(Boolean, default=False, server_default=false())
    # Staff member who recorded a cash or box-office sale.
    recorded_by: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), nullable=True)

    items: Mapped[list["OrderItem"]] = relationship(back_populates="order")
    tickets: Mapped[list["Ticket"]] = relationship(back_populates="order")


class OrderItem(IdMixin, Base):
    __tablename__ = "order_items"

    order_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("orders.id"), index=True)
    offer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("offers.id"), index=True)
    quantity: Mapped[int] = mapped_column(Integer)
    unit_price_minor: Mapped[int] = mapped_column(Integer)

    order: Mapped[Order] = relationship(back_populates="items")


class Ticket(IdMixin, TimestampMixin, Base):
    """One admission. `code` is what the QR encodes; it is random, not guessable."""

    __tablename__ = "tickets"

    order_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("orders.id"), index=True)
    offer_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("offers.id"), index=True)
    holder_id: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    code: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    status: Mapped[TicketStatus] = mapped_column(
        Enum(TicketStatus, native_enum=False), default=TicketStatus.valid
    )
    checked_in_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    checked_in_by: Mapped[uuid.UUID | None] = mapped_column(ForeignKey("users.id"), nullable=True)

    order: Mapped[Order] = relationship(back_populates="tickets")
