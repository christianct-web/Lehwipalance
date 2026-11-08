"""Buyer-facing checkout: place an order, pay, see tickets."""

import secrets
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, status
from sqlalchemy import select

from app.api.deps import CurrentUser, DbSession, OptionalUser
from app.core.config import get_settings
from app.core.ratelimit import rate_limit
from app.models import Event, Order, SalesChannel, Seller
from app.schemas.orders import (
    OrderCreatedOut,
    OrderIn,
    OrderOut,
    PublicConfigOut,
    TestPaymentIn,
)
from app.services import notify, orders, payments
from app.services.serialize import order_out

router = APIRouter(prefix="/v1", tags=["checkout"])


def _sale_error(e: orders.SaleError) -> HTTPException:
    return HTTPException(e.status_code, e.detail)


def _order_by_token(db: DbSession, order_id: UUID, token: str) -> Order:
    order = db.get(Order, order_id)
    if order is None or not secrets.compare_digest(order.access_token or "", token):
        # Same answer for "no such order" and "wrong token", so links can't be probed.
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Order not found")
    return order


def _email_tickets(background: BackgroundTasks, order: Order, event: Event) -> None:
    msg = notify.ticket_email(order, event)
    if msg is not None:
        background.add_task(notify.send, msg)


@router.get("/config", response_model=PublicConfigOut)
def public_config() -> PublicConfigOut:
    settings = get_settings()
    return PublicConfigOut(
        payment_provider=settings.payment_provider,
        test_payments=settings.test_payments,
        online_payments=settings.online_payments,
    )


@router.post(
    "/orders",
    response_model=OrderCreatedOut,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(rate_limit("orders", 20, 60))],
)
def create_order(
    body: OrderIn, db: DbSession, user: OptionalUser, background: BackgroundTasks
) -> OrderCreatedOut:
    event = db.scalar(select(Event).where(Event.slug == body.event_slug))
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Event not found")
    seller = None
    if body.seller_code:
        seller = db.scalar(
            select(Seller).where(
                Seller.code == body.seller_code.strip().upper(), Seller.event_id == event.id
            )
        )
        # An unknown seller code doesn't block the sale; it just isn't credited.
    try:
        order = orders.place_order(
            db,
            event=event,
            lines=[(i.tier_id, i.quantity) for i in body.items],
            channel=SalesChannel.online,
            buyer=orders.Buyer(
                name=body.buyer_name,
                email=body.buyer_email,
                phone=body.buyer_phone,
                user_id=user.id if user else None,
            ),
            seller=seller,
        )
    except orders.SaleError as e:
        db.rollback()
        raise _sale_error(e) from None
    db.commit()

    checkout_url = None
    if order.status.value == "pending":
        checkout_url = payments.get_provider().create_checkout(order)
    else:
        _email_tickets(background, order, event)
    out = order_out(db, order, event)
    return OrderCreatedOut(**out.model_dump(), checkout_url=checkout_url)


@router.get("/orders/{order_id}", response_model=OrderOut)
def get_order(order_id: UUID, db: DbSession, token: Annotated[str, Query()]) -> OrderOut:
    return order_out(db, _order_by_token(db, order_id, token))


@router.post("/payments/test/{order_id}", response_model=OrderOut)
def complete_test_payment(
    order_id: UUID, body: TestPaymentIn, db: DbSession, background: BackgroundTasks
) -> OrderOut:
    """The test provider's "hosted page" calls this. Absent outside test mode."""
    if not get_settings().test_payments:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not found")
    _order_by_token(db, order_id, body.token)
    reference = f"TEST-{secrets.token_hex(6).upper()}"
    try:
        if body.outcome == "paid":
            order = orders.mark_paid(db, order_id, reference)
        else:
            order = orders.mark_failed(db, order_id, reference)
    except orders.SaleError as e:
        db.rollback()
        raise _sale_error(e) from None
    db.commit()
    event = db.get(Event, order.listing_id)
    if order.status.value == "paid" and order.payment_reference == reference:
        _email_tickets(background, order, event)
    return order_out(db, order, event)


@router.get("/me/orders", response_model=list[OrderOut])
def my_orders(user: CurrentUser, db: DbSession) -> list[OrderOut]:
    rows = db.scalars(
        select(Order).where(Order.buyer_id == user.id).order_by(Order.created_at.desc()).limit(100)
    )
    return [order_out(db, o) for o in rows]
