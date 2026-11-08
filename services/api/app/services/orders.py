"""Orders: inventory holds, settlement and ticket issue.

Concurrency: every operation that reads or changes an event's inventory or
status takes the event row lock first, then (if needed) the order, then the
tiers: checkout, staff sales, payment settlement, tier edits and cancellation.
So they run one at a time per event, always in the same lock order.

Inventory: a tier's available count is
    quantity - quantity_sold - (tickets in pending, unexpired, non-test orders)
Tier capacity can't be cut below sold + held, and settlement re-checks
capacity, so a sale never takes a tier past its quantity.

Payment after the fact: if a payment arrives for an order whose tickets are
gone (hold lapsed and sold out) it's marked failed; for an event that was
cancelled, the order stays cancelled. Either way the payment reference is kept
so the promoter can refund it.

Simulated payments (test provider) create `is_test` orders: they get tickets for
demonstration, but never hold or consume inventory, never count in reports, and
are refused at the gate.
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
    Listing,
    ListingStatus,
    ListingType,
    Order,
    OrderItem,
    OrderStatus,
    SalesChannel,
    Seller,
    Ticket,
    TicketStatus,
    TicketTier,
)
from app.services import countries, fees

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


def lock_event(db: Session, event_id: UUID) -> Event | None:
    """Take the event's row lock (see module docstring) and re-read it.

    The lock is taken on the `listings` row, which is the one every category
    shares and so the one all callers can agree on. An event spans two tables,
    and `FOR UPDATE` over that join would have to name a table anyway.
    """
    locked = db.scalar(
        select(Listing.id)
        .where(Listing.id == event_id, Listing.type == ListingType.event)
        .with_for_update()
    )
    if locked is None:
        return None
    return db.scalar(
        select(Event).where(Event.id == event_id).execution_options(populate_existing=True)
    )


def held_quantities(
    db: Session, tier_ids: Iterable[UUID], exclude_order: UUID | None = None
) -> dict[UUID, int]:
    stmt = (
        select(OrderItem.tier_id, func.sum(OrderItem.quantity))
        .join(Order, Order.id == OrderItem.order_id)
        .where(
            OrderItem.tier_id.in_(list(tier_ids)),
            Order.status == OrderStatus.pending,
            Order.expires_at > utcnow(),
            Order.is_test.is_(False),
        )
        .group_by(OrderItem.tier_id)
    )
    if exclude_order is not None:
        stmt = stmt.where(Order.id != exclude_order)
    return {tier_id: int(total) for tier_id, total in db.execute(stmt)}


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
        .order_by(TicketTier.id)  # fixed lock order
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
    """Create an order. Online paid orders come back `pending` with a hold (or a
    simulated `is_test` order in test mode); free orders and staff-recorded sales
    come back `paid` with tickets issued. The caller commits."""
    event = lock_event(db, event.id)
    if event is None or event.status != ListingStatus.published:
        raise SaleError(409, "This event isn't on sale")

    wanted: dict[UUID, int] = {}
    for tier_id, quantity in lines:
        wanted[tier_id] = wanted.get(tier_id, 0) + quantity
    tiers = _lock_tiers(db, event.id, sorted(wanted))
    if len(tiers) != len(wanted):
        raise SaleError(404, "Ticket tier not found")
    held = held_quantities(db, wanted)

    now = utcnow()
    fee_config = countries.fee_config(db, event.country_code)
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
        q = fees.quote(tier.price_minor, quantity, fee_config)
        subtotal += q.subtotal_minor
        # Cash buyers pay face value; the buyer fee is an online-checkout charge.
        buyer_fee += q.buyer_fee_minor if online else 0
        promoter_fee += q.promoter_fee_minor
        items.append(
            OrderItem(tier_id=tier_id, quantity=quantity, unit_price_minor=tier.price_minor)
        )

    needs_payment = online and subtotal + buyer_fee > 0
    payments = get_settings().online_payments
    if needs_payment and payments == "off":
        raise SaleError(409, "Online payments aren't open yet. Buy from a seller or at the gate.")

    order = Order(
        event_id=event.id,
        buyer_id=buyer.user_id,
        buyer_name=buyer.name,
        buyer_email=buyer.email.lower() if buyer.email else None,
        buyer_phone=buyer.phone,
        seller_id=seller.id if seller else None,
        channel=channel,
        currency=fee_config.currency,
        subtotal_minor=subtotal,
        buyer_fee_minor=buyer_fee,
        promoter_fee_minor=promoter_fee,
        total_minor=subtotal + buyer_fee,
        access_token=new_token(),
        recorded_by=recorded_by,
        is_test=needs_payment and payments == "test",
        items=items,
    )
    db.add(order)
    if needs_payment:
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


def _lock_order_and_event(db: Session, order_id: UUID) -> tuple[Order, Event]:
    event_id = db.scalar(select(Order.event_id).where(Order.id == order_id))
    if event_id is None:
        raise SaleError(404, "Order not found")
    event = lock_event(db, event_id)
    order = db.scalar(
        select(Order)
        .where(Order.id == order_id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    return order, event


def mark_paid(db: Session, order_id: UUID, reference: str) -> Order:
    """Settle a verified payment. Idempotent: a repeated callback is a no-op.
    The caller commits."""
    order, event = _lock_order_and_event(db, order_id)
    if order.status == OrderStatus.paid:
        return order
    if order.status != OrderStatus.pending:
        log.warning(
            "payment %s for order %s in status %s: refund due",
            reference,
            order.id,
            order.status,
        )
        order.payment_reference = reference
        return order
    if event.status != ListingStatus.published:
        log.error("payment %s for order %s of a cancelled event: refund due", reference, order.id)
        order.status = OrderStatus.cancelled
        order.payment_reference = reference
        return order

    order.payment_reference = reference
    if not order.is_test:
        tiers = _lock_tiers(db, order.event_id, sorted({i.tier_id for i in order.items}))
        # This order's own hold doesn't count against it; everyone else's does.
        held = held_quantities(db, tiers, exclude_order=order.id)
        if any(item.quantity > available(tiers[item.tier_id], held) for item in order.items):
            log.error(
                "order %s paid (%s) but its tickets are gone: refund due", order.id, reference
            )
            order.status = OrderStatus.failed
            return order
        _commit_inventory(tiers, order)

    order.status = OrderStatus.paid
    order.paid_at = utcnow()
    _issue_tickets(db, order)
    db.flush()
    return order


def mark_failed(db: Session, order_id: UUID, reference: str | None) -> Order:
    order, _ = _lock_order_and_event(db, order_id)
    if order.status == OrderStatus.pending:
        order.status = OrderStatus.failed
        order.payment_reference = reference
    return order


def cancel_open_orders(db: Session, event_id: UUID) -> int:
    """On event cancellation (caller holds the event lock): close every checkout
    still waiting for payment, so a late payment can't issue tickets."""
    result = db.execute(
        update(Order)
        .where(Order.event_id == event_id, Order.status == OrderStatus.pending)
        .values(status=OrderStatus.cancelled)
    )
    return result.rowcount


# ---------- Check-in ----------


@dataclass
class CheckinResult:
    result: str  # ok | already_checked_in | void | test_ticket | wrong_event | not_found
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
    if order.is_test:
        return CheckinResult("test_ticket", ticket, tier, order)
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
