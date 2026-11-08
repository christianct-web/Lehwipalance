"""Stays: per-night availability, taking a booking, and settling it.

Why this is not `orders.place_order` with a different argument: a ticket tier
holds one pool that depletes, so availability is a single subtraction. A room
holds `units` on *each* night, so a room sold for Friday is free again on
Saturday and availability is the worst night in the range. The two cannot share
an inventory check without one of them lying.

What they do share — idempotent settlement, keeping the payment reference for a
refund, re-checking availability at settle time because a hold can lapse while
a payment is in flight — is implemented here in parallel rather than threaded
through the ticket engine. That engine is the revenue-critical path and was
left untouched on purpose. Once vacation departures and store stock land there
will be three examples of the pattern and a shared shape worth extracting; two
is not enough to extract from.

Concurrency: every operation takes the listing row lock first, exactly as
ticketing does, so bookings for one property are serialised and the per-night
arithmetic below cannot race.
"""

import logging
from collections import Counter
from dataclasses import dataclass
from datetime import date, timedelta
from uuid import UUID

from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.time import utcnow
from app.models import (
    Booking,
    BookingStatus,
    Listing,
    ListingStatus,
    ListingType,
    Order,
    OrderItem,
    OrderStatus,
    RoomType,
    SalesChannel,
)
from app.services import countries, fees
from app.services.orders import Buyer, SaleError, new_token

log = logging.getLogger(__name__)

# A booking longer than this is almost certainly a mistake, and it bounds the
# per-night arithmetic below.
MAX_NIGHTS = 90

# Bookings that hold a room regardless of the order's state.
_HOLDING = (BookingStatus.confirmed, BookingStatus.checked_in)


def lock_listing(db: Session, listing_id: UUID) -> Listing | None:
    """Take the listing's row lock, the one every category shares."""
    locked = db.scalar(
        select(Listing.id)
        .where(Listing.id == listing_id, Listing.type == ListingType.accommodation)
        .with_for_update()
    )
    if locked is None:
        return None
    return db.scalar(
        select(Listing).where(Listing.id == listing_id).execution_options(populate_existing=True)
    )


def nights_of(start: date, end: date) -> list[date]:
    """The nights a stay occupies. `end` is the departure date, so it is not one."""
    return [start + timedelta(days=n) for n in range((end - start).days)]


def nightly_taken(db: Session, offer_id: UUID, start: date, end: date) -> Counter:
    """How many rooms of this kind are taken on each night of the range.

    Counted in Python over the overlapping bookings rather than in SQL: the set
    is small, and `generate_series` has no portable equivalent on the SQLite
    test database. If a property ever carries enough bookings for this to hurt,
    a materialised per-night table is the next step — not a different answer.
    """
    rows = db.execute(
        select(Booking.stay_start, Booking.stay_end, Booking.rooms)
        .join(Order, Order.id == Booking.order_id)
        .where(
            Booking.offer_id == offer_id,
            # Overlap, with `stay_end` exclusive: a departure does not collide
            # with an arrival on the same day.
            Booking.stay_start < end,
            Booking.stay_end > start,
            # Simulated orders never hold a room, exactly as they never hold a
            # ticket.
            Order.is_test.is_(False),
            or_(
                Booking.status.in_(_HOLDING),
                and_(
                    Booking.status == BookingStatus.held,
                    Order.status == OrderStatus.pending,
                    Order.expires_at > utcnow(),
                ),
            ),
        )
    ).all()
    taken: Counter = Counter()
    for stay_start, stay_end, rooms in rows:
        for night in nights_of(max(stay_start, start), min(stay_end, end)):
            taken[night] += rooms
    return taken


def available(db: Session, room: RoomType, start: date, end: date) -> int:
    """Rooms of this kind bookable for the whole range.

    The worst night decides it: a room free on three nights of four cannot be
    sold as a four-night stay.
    """
    taken = nightly_taken(db, room.id, start, end)
    worst = max((taken[night] for night in nights_of(start, end)), default=0)
    return max(room.units - worst, 0)


@dataclass(frozen=True)
class Quote:
    nights: int
    rooms: int
    rate_minor: int
    subtotal_minor: int
    buyer_fee_minor: int
    total_minor: int
    promoter_fee_minor: int
    currency: str


def quote(db: Session, room: RoomType, start: date, end: date, rooms: int) -> Quote:
    """What a stay costs.

    The fixed part of the buyer fee is charged **once per booking**, not per
    night: the fee model was written per ticket, and charging TT$3 a night would
    be a different product decision than the one that was signed off. Flagged
    in docs/roadmap.md as needing the client's confirmation.
    """
    nights = (end - start).days
    # Rates come from the property's own market, as they do for a fete.
    country_code = db.scalar(select(Listing.country_code).where(Listing.id == room.listing_id))
    config = countries.fee_config(db, country_code)
    subtotal = room.price_minor * rooms * nights
    priced = fees.quote(subtotal, 1, config)
    return Quote(
        nights=nights,
        rooms=rooms,
        rate_minor=room.price_minor,
        subtotal_minor=subtotal,
        buyer_fee_minor=priced.buyer_fee_minor,
        total_minor=priced.total_minor,
        promoter_fee_minor=priced.promoter_fee_minor,
        currency=config.currency,
    )


def validate(room: RoomType, start: date, end: date, rooms: int, guests: int) -> None:
    today = utcnow().date()
    if end <= start:
        raise SaleError(422, "The departure date must be after the arrival date")
    nights = (end - start).days
    if start < today:
        raise SaleError(422, "That arrival date has passed")
    if nights > MAX_NIGHTS:
        raise SaleError(422, f"At most {MAX_NIGHTS} nights per booking")
    if nights < room.min_nights:
        raise SaleError(409, f"{room.name} has a {room.min_nights}-night minimum")
    if rooms < 1:
        raise SaleError(422, "Book at least one room")
    if guests < 1:
        raise SaleError(422, "A booking needs at least one guest")
    if guests > room.max_guests * rooms:
        raise SaleError(
            409, f"{room.name} sleeps {room.max_guests}; {rooms} room(s) is not enough for {guests}"
        )


def place(
    db: Session,
    *,
    listing: Listing,
    room: RoomType,
    start: date,
    end: date,
    rooms: int,
    guests: int,
    buyer: Buyer,
) -> tuple[Order, Booking]:
    """Take a booking. Comes back `pending`/`held` awaiting payment, or already
    `paid`/`confirmed` when there is nothing to pay. The caller commits."""
    listing = lock_listing(db, listing.id)
    if listing is None or listing.status != ListingStatus.published:
        raise SaleError(409, "This place isn't taking bookings")

    validate(room, start, end, rooms, guests)
    free = available(db, room, start, end)
    if rooms > free:
        detail = (
            f"{room.name} is fully booked for those nights"
            if free == 0
            else f"Only {free} {room.name} left for those nights"
        )
        raise SaleError(409, detail)

    priced = quote(db, room, start, end, rooms)
    needs_payment = priced.total_minor > 0
    payments = get_settings().online_payments
    if needs_payment and payments == "off":
        raise SaleError(409, "Online payments aren't open yet.")

    now = utcnow()
    order = Order(
        listing_id=listing.id,
        buyer_id=buyer.user_id,
        buyer_name=buyer.name,
        buyer_email=buyer.email.lower() if buyer.email else None,
        buyer_phone=buyer.phone,
        channel=SalesChannel.online,
        currency=priced.currency,
        subtotal_minor=priced.subtotal_minor,
        buyer_fee_minor=priced.buyer_fee_minor,
        promoter_fee_minor=priced.promoter_fee_minor,
        total_minor=priced.total_minor,
        access_token=new_token(),
        is_test=needs_payment and payments == "test",
        items=[
            # One line per booking: the quantity is rooms, and the nights live
            # on the booking itself.
            OrderItem(offer_id=room.id, quantity=rooms, unit_price_minor=room.price_minor)
        ],
    )
    booking = Booking(
        offer_id=room.id,
        guest_id=buyer.user_id,
        stay_start=start,
        stay_end=end,
        rooms=rooms,
        guests=guests,
        code=new_token(),
        status=BookingStatus.held,
    )
    db.add(order)
    db.flush()
    booking.order_id = order.id

    if needs_payment:
        order.status = OrderStatus.pending
        order.expires_at = now + timedelta(minutes=get_settings().order_hold_minutes)
    else:
        order.status = OrderStatus.paid
        order.paid_at = now
        booking.status = BookingStatus.confirmed
    db.add(booking)
    db.flush()
    return order, booking


def booking_of(db: Session, order_id: UUID) -> Booking | None:
    return db.scalar(select(Booking).where(Booking.order_id == order_id))


def confirm(db: Session, order_id: UUID, reference: str) -> Order:
    """Settle a verified payment for a stay. Idempotent. The caller commits.

    Mirrors `orders.mark_paid`: the nights are re-checked, because a hold can
    lapse while a payment is in flight and someone else can take the room. If
    they are gone the order is marked failed and the reference kept, so the
    property can refund it.
    """
    listing_id = db.scalar(select(Order.listing_id).where(Order.id == order_id))
    if listing_id is None:
        raise SaleError(404, "Order not found")
    lock_listing(db, listing_id)
    order = db.scalar(
        select(Order)
        .where(Order.id == order_id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    booking = booking_of(db, order_id)
    if booking is None:
        raise SaleError(409, "That order is not a booking")

    if order.status == OrderStatus.paid:
        return order
    if order.status != OrderStatus.pending:
        log.warning(
            "payment %s for booking order %s in status %s: refund due",
            reference,
            order.id,
            order.status,
        )
        order.payment_reference = reference
        return order

    order.payment_reference = reference
    if not order.is_test:
        room = db.get(RoomType, booking.offer_id)
        # This booking's own hold must not count against it.
        taken = nightly_taken(db, room.id, booking.stay_start, booking.stay_end)
        mine = Counter()
        for night in nights_of(booking.stay_start, booking.stay_end):
            mine[night] = booking.rooms
        worst = max(
            (taken[n] - mine[n] for n in nights_of(booking.stay_start, booking.stay_end)),
            default=0,
        )
        if booking.rooms > max(room.units - worst, 0):
            log.error("order %s paid (%s) but its nights are gone: refund due", order.id, reference)
            order.status = OrderStatus.failed
            booking.status = BookingStatus.cancelled
            return order

    order.status = OrderStatus.paid
    order.paid_at = utcnow()
    booking.status = BookingStatus.confirmed
    db.flush()
    return order


def fail(db: Session, order_id: UUID, reference: str | None) -> Order:
    order = db.scalar(
        select(Order)
        .where(Order.id == order_id)
        .with_for_update()
        .execution_options(populate_existing=True)
    )
    if order is None:
        raise SaleError(404, "Order not found")
    if order.status == OrderStatus.pending:
        order.status = OrderStatus.failed
        order.payment_reference = reference
        booking = booking_of(db, order_id)
        if booking is not None:
            booking.status = BookingStatus.cancelled
    return order
