"""Orders: inventory holds, settlement and ticket issue.

Inventory rule: a tier's available count is
    quantity - quantity_sold - (tickets in pending online orders whose hold hasn't expired)
Every write that can change it locks the tier rows first, so two buyers racing
for the last ticket are served one at a time.

A pending order that is paid after its hold expired is honoured if the tickets
are still there; otherwise it is marked failed with the payment reference kept,
so the promoter can refund it.
"""

import logging
import secrets
from collections.abc import Iterable
from dataclasses import dataclass
from datetime import timedelta
from uuid import UUID

from sqlalchemy import func, select, update
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.time import aware, utcnow
from app.models import (
    Event,
    EventStatus,
    Order,
    OrderItem,
    OrderStatus,
    SalesChannel,
    Seller,
    Ticket,
    TicketStatus,
    TicketTier,
)
from app.services import fees

log = logging.getLogger(__name__)

# How long after the start an event keeps selling when it has no end time.
DEFAULT_EVENT_LENGTH = timedelta(hours=12)


class SaleError(Exception):
    def __init__(self, status_code: int, detail: str):
        super().__init__(detail)
        self.status_code = status_code
        self.detail = detail


@dataclass
class Buyer:
    name: str
    email: str | None = None
    phone: str | None = None
    user_id: UUID | None = None


def new_token() -> str:
    return secrets.token_urlsafe(24)


def is_expired(order: Order) -> bool:
    expires = aware(order.expires_at)
    return order.status == OrderStatus.pending and expires is not None and expires <= utcnow()


def display_status(order: Order) -> str:
    return "expired" if is_expired(order) else order.status.value


def held_quantities(db: Session, tier_ids: Iterable[UUID]) -> dict[UUID, int]:
    rows = db.execute(
        select(OrderItem.tier_id, func.sum(OrderItem.quantity))
        .join(Order, Order.id == OrderItem.order_id)
        .where(
            OrderItem.tier_id.in_(list(tier_ids)),
            Order.status == OrderStatus.pending,
            Order.expires_at > utcnow(),
        )
        .group_by(OrderItem.tier_id)
    )
    return {tier_id: int(total) for tier_id, total in rows}


def available(tier: TicketTier, held: dict[UUID, int]) -> int:
    return max(tier.quantity - tier.quantity_sold - held.get(tier.id, 0), 0)


def sales_close_at(event: Event, tier: TicketTier):
    if tier.sales_end_at:
        return aware(tier.sales_end_at)
    return aware(event.ends_at) or aware(event.starts_at) + DEFAULT_EVENT_LENGTH


def _lock_tiers(db: Session, event_id: UUID, tier_ids: list[UUID]) -> dict[UUID, TicketTier]:
    tiers = db.scalars(
        select(TicketTier)
        .where(TicketTier.id.in_(tier_ids), TicketTier.event_id == event_id)
        .order_by(TicketTier.id)  # fixed lock order, so two orders can't deadlock
        .with_for_update()
        .execution_options(populate_existing=True)
    ).all()
    return {t.id: t for t in tiers}


def _issue_tickets(db: Session, order: Order) -> None:
    for item in order.items:
        for _ in range(item.quantity):
            db.add(
                Ticket(
                    order_id=order.id,
                    tier_id=item.tier_id,
                    holder_id=order.buyer_id,
                    code=new_token(),
                    status=TicketStatus.valid,
                )
            )


def _commit_inventory(tiers: dict[UUID, TicketTier], order: Order) -> None:
    for item in order.items:
        tiers[item.tier_id].quantity_sold += item.quantity


def place_order(
    db: Session,
    *,
    event: Event,
    lines: list[tuple[UUID, int]],
    channel: SalesChannel,
    buyer: Buyer,
    seller: Seller | None = None,
    recorded_by: UUID | None = None,
) -> Order:
    """Create an order. Online paid orders come back `pending` with a hold;
    free orders and staff-recorded sales come back `paid` with tickets issued.
    The caller commits."""
    if event.status != EventStatus.published:
        raise SaleError(409, "This event isn't on sale")

    wanted: dict[UUID, int] = {}
    for tier_id, quantity in lines:
        wanted[tier_id] = wanted.get(tier_id, 0) + quantity
    tiers = _lock_tiers(db, event.id, sorted(wanted))
    if len(tiers) != len(wanted):
        raise SaleError(404, "Ticket tier not found")
    held = held_quantities(db, wanted)

    now = utcnow()
    online = channel == SalesChannel.online
    subtotal = buyer_fee = promoter_fee = 0
    items = []
    for tier_id, quantity in wanted.items():
        tier = tiers[tier_id]
        if tier.sales_start_at and aware(tier.sales_start_at) > now:
            raise SaleError(409, f"{tier.name} isn't on sale yet")
        if sales_close_at(event, tier) <= now:
            raise SaleError(409, f"Sales for {tier.name} have closed")
        if online and quantity > tier.max_per_order:
            raise SaleError(422, f"{tier.name}: at most {tier.max_per_order} per order")
        left = available(tier, held)
        if quantity > left:
            msg = f"{tier.name} is sold out" if left == 0 else f"Only {left} {tier.name} left"
            raise SaleError(409, msg)
        q = fees.quote(tier.price_minor, quantity)
        subtotal += q.subtotal_minor
        # Cash buyers pay face value; the buyer fee is an online-checkout charge.
        buyer_fee += q.buyer_fee_minor if online else 0
        promoter_fee += q.promoter_fee_minor
        items.append(
            OrderItem(tier_id=tier_id, quantity=quantity, unit_price_minor=tier.price_minor)
        )

    order = Order(
        event_id=event.id,
        buyer_id=buyer.user_id,
        buyer_name=buyer.name,
        buyer_email=buyer.email.lower() if buyer.email else None,
        buyer_phone=buyer.phone,
        seller_id=seller.id if seller else None,
        channel=channel,
        currency="TTD",
        subtotal_minor=subtotal,
        buyer_fee_minor=buyer_fee,
        promoter_fee_minor=promoter_fee,
        total_minor=subtotal + buyer_fee,
        access_token=new_token(),
        recorded_by=recorded_by,
        items=items,
    )
    db.add(order)
    if online and order.total_minor > 0:
        order.status = OrderStatus.pending
        order.expires_at = now + timedelta(minutes=get_settings().order_hold_minutes)
    else:
        order.status = OrderStatus.paid
        order.paid_at = now
        _commit_inventory(tiers, order)
        db.flush()
        _issue_tickets(db, order)
    db.flush()
    return order


def _lock_order(db: Session, order_id: UUID) -> Order | None:
    return db.scalar(
        select(Order)
        .where(Order.id == order_id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )


def mark_paid(db: Session, order_id: UUID, reference: str) -> Order:
    """Settle a verified payment. Idempotent: a repeated callback is a no-op.
    The caller commits."""
    order = _lock_order(db, order_id)
    if order is None:
        raise SaleError(404, "Order not found")
    if order.status == OrderStatus.paid:
        return order
    if order.status != OrderStatus.pending:
        log.warning("payment %s for order %s in status %s", reference, order.id, order.status)
        order.payment_reference = reference
        return order

    tiers = _lock_tiers(db, order.event_id, sorted({i.tier_id for i in order.items}))
    if is_expired(order):
        # The hold lapsed, so its tickets may have gone to someone else.
        held = held_quantities(db, tiers)
        if any(item.quantity > available(tiers[item.tier_id], held) for item in order.items):
            log.error("order %s paid (%s) after its hold expired and sold out", order.id, reference)
            order.status = OrderStatus.failed
            order.payment_reference = reference
            return order

    order.status = OrderStatus.paid
    order.paid_at = utcnow()
    order.payment_reference = reference
    _commit_inventory(tiers, order)
    _issue_tickets(db, order)
    db.flush()
    return order


def mark_failed(db: Session, order_id: UUID, reference: str | None) -> Order:
    order = _lock_order(db, order_id)
    if order is None:
        raise SaleError(404, "Order not found")
    if order.status == OrderStatus.pending:
        order.status = OrderStatus.failed
        order.payment_reference = reference
    return order


# ---------- Check-in ----------


@dataclass
class CheckinResult:
    result: str  # ok | already_checked_in | void | wrong_event | not_found
    ticket: Ticket | None = None
    tier: TicketTier | None = None
    order: Order | None = None


def check_in(db: Session, event: Event, code: str, user_id: UUID) -> CheckinResult:
    row = db.execute(
        select(Ticket, TicketTier, Order)
        .join(TicketTier, TicketTier.id == Ticket.tier_id)
        .join(Order, Order.id == Ticket.order_id)
        .where(Ticket.code == code.strip())
    ).first()
    if row is None:
        return CheckinResult("not_found")
    ticket, tier, order = row
    if tier.event_id != event.id:
        return CheckinResult("wrong_event", ticket, tier, order)
    # One conditional UPDATE, so two gates scanning the same ticket can't both admit it.
    done = db.execute(
        update(Ticket)
        .where(Ticket.id == ticket.id, Ticket.status == TicketStatus.valid)
        .values(status=TicketStatus.checked_in, checked_in_at=utcnow(), checked_in_by=user_id)
    )
    db.refresh(ticket)
    if done.rowcount == 1:
        return CheckinResult("ok", ticket, tier, order)
    if ticket.status == TicketStatus.checked_in:
        return CheckinResult("already_checked_in", ticket, tier, order)
    return CheckinResult("void", ticket, tier, order)
