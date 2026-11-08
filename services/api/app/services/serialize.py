"""Build order responses: shared by buyer, staff-sale and promoter routes."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Event, Order, Ticket, TicketTier
from app.schemas.orders import OrderEventOut, OrderItemOut, OrderOut, TicketOut
from app.services.notify import order_link
from app.services.orders import display_status


def order_out(db: Session, order: Order, event: Event | None = None) -> OrderOut:
    event = event or db.get(Event, order.listing_id)
    tier_names: dict[UUID, str] = dict(
        db.execute(
            select(TicketTier.id, TicketTier.name).where(TicketTier.listing_id == event.id)
        ).all()
    )
    tickets = db.scalars(
        select(Ticket).where(Ticket.order_id == order.id).order_by(Ticket.created_at, Ticket.code)
    ).all()
    return OrderOut(
        id=order.id,
        status=display_status(order),
        channel=order.channel,
        event=OrderEventOut(
            title=event.title,
            slug=event.slug,
            starts_at=event.starts_at,
            venue_name=event.venue_name,
            address=event.address,
            cover_image_url=event.cover_image_url,
        ),
        items=[
            OrderItemOut(
                tier_name=tier_names.get(i.offer_id, "Ticket"),
                quantity=i.quantity,
                unit_price_minor=i.unit_price_minor,
            )
            for i in order.items
        ],
        currency=order.currency,
        subtotal_minor=order.subtotal_minor,
        buyer_fee_minor=order.buyer_fee_minor,
        total_minor=order.total_minor,
        buyer_name=order.buyer_name,
        buyer_email=order.buyer_email,
        created_at=order.created_at,
        expires_at=order.expires_at,
        paid_at=order.paid_at,
        access_token=order.access_token or "",
        link=order_link(order),
        is_test=order.is_test,
        tickets=[
            TicketOut(
                code=t.code,
                tier_name=tier_names.get(t.offer_id, "Ticket"),
                status=t.status.value,
                checked_in_at=t.checked_in_at,
            )
            for t in tickets
        ],
    )
