"""Promoter sales desk: cash sales, sales report, order lookup, gate check-in and
flyer upload. Scoped to an organisation like the rest of /v1/orgs.

Who can do what:
- record a sale: owners and managers (for any seller), sellers (credited to themselves)
- sales report, orders, flyer upload: owners and managers
- check in tickets: owners, managers and scanners
"""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, BackgroundTasks, File, HTTPException, Query, UploadFile, status
from sqlalchemy import case, func, or_, select
from sqlalchemy.orm import Session

from app.api.deps import AnyMember, DbSession, OrgAdmin, OrgScanner
from app.core.config import get_settings
from app.models import (
    Event,
    ListingStatus,
    MemberRole,
    Order,
    OrderItem,
    OrderStatus,
    Seller,
    Ticket,
    TicketStatus,
    TicketTier,
)
from app.schemas.orders import (
    ChannelReport,
    CheckinIn,
    CheckinOut,
    CheckinStatsOut,
    MySellerOut,
    OrderOut,
    PromoterOrderOut,
    SalesReportOut,
    SellerReport,
    StaffSaleIn,
    TierReport,
)
from app.schemas.promoter import PromoterEventOut
from app.services import notify, orders, storage
from app.services.serialize import order_out

router = APIRouter(prefix="/v1/orgs", tags=["promoter sales"])

_ADMIN_ROLES = {MemberRole.owner, MemberRole.manager}


def _event(db: Session, org_id: UUID, event_id: UUID) -> Event:
    event = db.scalar(select(Event).where(Event.id == event_id, Event.organisation_id == org_id))
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Event not found")
    return event


def _my_seller(db: Session, event: Event, user_id: UUID) -> Seller | None:
    return db.scalar(select(Seller).where(Seller.event_id == event.id, Seller.user_id == user_id))


# ==================== Staff sales ====================


@router.get("/{org_id}/events/{event_id}/sellers/me", response_model=MySellerOut)
def my_seller_record(org_id: UUID, event_id: UUID, member: AnyMember, db: DbSession) -> Seller:
    seller = _my_seller(db, _event(db, org_id, event_id), member.user_id)
    if seller is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "You aren't a seller for this event")
    return seller


@router.post(
    "/{org_id}/events/{event_id}/sales",
    response_model=OrderOut,
    status_code=status.HTTP_201_CREATED,
)
def record_sale(
    org_id: UUID,
    event_id: UUID,
    body: StaffSaleIn,
    member: AnyMember,
    db: DbSession,
    background: BackgroundTasks,
) -> OrderOut:
    """A ticket sold for cash by a committee seller or at the box office."""
    event = _event(db, org_id, event_id)
    if member.role in _ADMIN_ROLES:
        seller = None
        if body.seller_id:
            seller = db.scalar(
                select(Seller).where(Seller.id == body.seller_id, Seller.event_id == event.id)
            )
            if seller is None:
                raise HTTPException(status.HTTP_404_NOT_FOUND, "Seller not found")
    elif member.role == MemberRole.seller:
        seller = _my_seller(db, event, member.user_id)
        if seller is None:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "You aren't a seller for this event")
        if body.seller_id and body.seller_id != seller.id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Sellers record their own sales")
    else:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Your role can't record sales")

    try:
        order = orders.place_order(
            db,
            event=event,
            lines=[(body.tier_id, body.quantity)],
            channel=body.channel,
            buyer=orders.Buyer(
                name=body.buyer_name, email=body.buyer_email, phone=body.buyer_phone
            ),
            seller=seller,
            recorded_by=member.user_id,
        )
    except orders.SaleError as e:
        db.rollback()
        raise HTTPException(e.status_code, e.detail) from None
    db.commit()
    msg = notify.ticket_email(order, event)
    if msg is not None:
        background.add_task(notify.send, msg)
    return order_out(db, order, event)


# ==================== Reports ====================


@router.get("/{org_id}/events/{event_id}/report", response_model=SalesReportOut)
def sales_report(org_id: UUID, event_id: UUID, member: OrgAdmin, db: DbSession) -> SalesReportOut:
    event = _event(db, org_id, event_id)
    tiers = db.scalars(
        select(TicketTier).where(TicketTier.event_id == event.id).order_by(TicketTier.sort_order)
    ).all()
    held = orders.held_quantities(db, [t.id for t in tiers])
    # Real sales only: simulated (test-provider) orders never count.
    paid = (Order.event_id == event.id, Order.status == OrderStatus.paid, Order.is_test.is_(False))

    # Gross per tier from paid order lines (not price * sold, in case a price changed).
    tier_gross = dict(
        db.execute(
            select(OrderItem.tier_id, func.sum(OrderItem.quantity * OrderItem.unit_price_minor))
            .join(Order, Order.id == OrderItem.order_id)
            .where(*paid)
            .group_by(OrderItem.tier_id)
        ).all()
    )
    tickets_per_order = (
        select(OrderItem.order_id, func.sum(OrderItem.quantity).label("n"))
        .group_by(OrderItem.order_id)
        .subquery()
    )
    channel_rows = db.execute(
        select(
            Order.channel,
            func.count(Order.id),
            func.coalesce(func.sum(tickets_per_order.c.n), 0),
            func.coalesce(func.sum(Order.subtotal_minor), 0),
        )
        .join(tickets_per_order, tickets_per_order.c.order_id == Order.id)
        .where(*paid)
        .group_by(Order.channel)
    ).all()
    seller_rows = db.execute(
        select(
            Seller,
            func.count(Order.id),
            func.coalesce(func.sum(tickets_per_order.c.n), 0),
            func.coalesce(func.sum(Order.subtotal_minor), 0),
        )
        .outerjoin(
            Order,
            (Order.seller_id == Seller.id)
            & (Order.status == OrderStatus.paid)
            & Order.is_test.is_(False),
        )
        .outerjoin(tickets_per_order, tickets_per_order.c.order_id == Order.id)
        .where(Seller.event_id == event.id)
        .group_by(Seller.id)
        .order_by(Seller.display_name)
    ).all()
    totals = db.execute(
        select(
            func.coalesce(func.sum(Order.subtotal_minor), 0),
            func.coalesce(func.sum(Order.buyer_fee_minor), 0),
            func.coalesce(func.sum(Order.promoter_fee_minor), 0),
        ).where(*paid)
    ).one()
    checked_in = _count_tickets(db, event, TicketStatus.checked_in)

    channels = [
        ChannelReport(channel=c, orders=n, tickets=int(t), gross_minor=int(g))
        for c, n, t, g in channel_rows
    ]
    gross, buyer_fees, promoter_fees = (int(x) for x in totals)
    return SalesReportOut(
        currency="TTD",
        tickets_sold=sum(t.quantity_sold for t in tiers),
        checked_in=checked_in,
        gross_minor=gross,
        buyer_fees_minor=buyer_fees,
        promoter_fees_minor=promoter_fees,
        payout_minor=gross - promoter_fees,
        cash_collected_minor=sum(c.gross_minor for c in channels if c.channel != "online"),
        tiers=[
            TierReport(
                tier_id=t.id,
                name=t.name,
                price_minor=t.price_minor,
                quantity=t.quantity,
                sold=t.quantity_sold,
                held=held.get(t.id, 0),
                remaining=orders.available(t, held),
                gross_minor=int(tier_gross.get(t.id, 0)),
            )
            for t in tiers
        ],
        channels=channels,
        sellers=[
            SellerReport(
                seller_id=s.id,
                display_name=s.display_name,
                code=s.code,
                orders=n,
                tickets=int(t),
                gross_minor=int(g),
            )
            for s, n, t, g in seller_rows
        ],
    )


@router.get("/{org_id}/events/{event_id}/orders", response_model=list[PromoterOrderOut])
def list_orders(
    org_id: UUID,
    event_id: UUID,
    member: OrgAdmin,
    db: DbSession,
    q: Annotated[str | None, Query(max_length=200)] = None,
    include_unpaid: bool = False,
    limit: int = Query(100, ge=1, le=500),
) -> list[PromoterOrderOut]:
    event = _event(db, org_id, event_id)
    stmt = (
        select(Order, Seller.display_name)
        .outerjoin(Seller, Seller.id == Order.seller_id)
        .where(Order.event_id == event.id)
    )
    if not include_unpaid:
        stmt = stmt.where(Order.status == OrderStatus.paid, Order.is_test.is_(False))
    if q:
        like = f"%{q.strip().lower()}%"
        stmt = stmt.where(
            or_(
                func.lower(Order.buyer_name).like(like),
                func.lower(Order.buyer_email).like(like),
                Order.buyer_phone.like(like),
            )
        )
    rows = db.execute(stmt.order_by(Order.created_at.desc()).limit(limit)).all()
    ids = [o.id for o, _ in rows]
    counts: dict[UUID, tuple[int, int]] = {}
    if ids:
        for order_id, total, done in db.execute(
            select(
                Ticket.order_id,
                func.count(Ticket.id),
                func.sum(case((Ticket.status == TicketStatus.checked_in, 1), else_=0)),
            )
            .where(Ticket.order_id.in_(ids))
            .group_by(Ticket.order_id)
        ):
            counts[order_id] = (int(total), int(done or 0))
    return [
        PromoterOrderOut(
            id=o.id,
            created_at=o.created_at,
            status=orders.display_status(o),
            channel=o.channel,
            buyer_name=o.buyer_name,
            buyer_email=o.buyer_email,
            buyer_phone=o.buyer_phone,
            seller_name=seller_name,
            is_test=o.is_test,
            tickets=counts.get(o.id, (0, 0))[0],
            checked_in=counts.get(o.id, (0, 0))[1],
            total_minor=o.total_minor,
            link=notify.order_link(o),
        )
        for o, seller_name in rows
    ]


# ==================== Check-in ====================


def _count_tickets(db: Session, event: Event, only: TicketStatus | None = None) -> int:
    stmt = (
        select(func.count(Ticket.id))
        .join(TicketTier, TicketTier.id == Ticket.tier_id)
        .join(Order, Order.id == Ticket.order_id)
        .where(
            TicketTier.event_id == event.id,
            Ticket.status != TicketStatus.void,
            Order.is_test.is_(False),
        )
    )
    if only is not None:
        stmt = stmt.where(Ticket.status == only)
    return db.scalar(stmt) or 0


@router.get("/{org_id}/events/{event_id}/checkin", response_model=CheckinStatsOut)
def checkin_stats(
    org_id: UUID, event_id: UUID, member: OrgScanner, db: DbSession
) -> CheckinStatsOut:
    event = _event(db, org_id, event_id)
    return CheckinStatsOut(
        checked_in=_count_tickets(db, event, TicketStatus.checked_in),
        total=_count_tickets(db, event),
    )


@router.post("/{org_id}/events/{event_id}/checkin", response_model=CheckinOut)
def check_in(
    org_id: UUID, event_id: UUID, body: CheckinIn, member: OrgScanner, db: DbSession
) -> CheckinOut:
    event = _event(db, org_id, event_id)
    res = orders.check_in(db, event, body.code, member.user_id)
    db.commit()
    show = res.result != "wrong_event"  # don't reveal another event's buyer
    return CheckinOut(
        result=res.result,
        tier_name=res.tier.name if res.tier and show else None,
        buyer_name=res.order.buyer_name if res.order and show else None,
        checked_in_at=res.ticket.checked_in_at if res.ticket and show else None,
        checked_in=_count_tickets(db, event, TicketStatus.checked_in),
        total=_count_tickets(db, event),
    )


# ==================== Flyer ====================


@router.post("/{org_id}/events/{event_id}/cover", response_model=PromoterEventOut)
def upload_cover(
    org_id: UUID,
    event_id: UUID,
    member: OrgAdmin,
    db: DbSession,
    file: Annotated[UploadFile, File()],
) -> Event:
    event = _event(db, org_id, event_id)
    if event.status == ListingStatus.cancelled:
        raise HTTPException(status.HTTP_409_CONFLICT, "This event is cancelled")
    limit = get_settings().max_upload_bytes
    data = file.file.read(limit + 1)
    if len(data) > limit:
        raise HTTPException(413, f"Images can be at most {limit // (1024 * 1024)} MB")
    try:
        event.cover_image_url = storage.save_image(data, f"events/{event.id}")
    except storage.StorageError as e:
        raise HTTPException(422, str(e)) from None
    db.commit()
    db.refresh(event, ["tiers"])
    return event
