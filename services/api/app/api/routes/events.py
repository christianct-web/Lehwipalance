from datetime import UTC, datetime

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.api.deps import DbSession
from app.models import Event, ListingStatus
from app.schemas.events import EventDetailOut, EventSummaryOut, FeeQuoteOut, TierOut
from app.services import countries, fees, orders

router = APIRouter(prefix="/v1", tags=["events"])


@router.get("/events", response_model=list[EventSummaryOut])
def list_events(
    db: DbSession,
    upcoming_only: bool = True,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
) -> list[Event]:
    stmt = select(Event).where(Event.status == ListingStatus.published)
    if upcoming_only:
        stmt = stmt.where(Event.starts_at >= datetime.now(UTC))
    stmt = stmt.order_by(Event.starts_at).limit(limit).offset(offset)
    return list(db.scalars(stmt))


@router.get("/events/{slug}", response_model=EventDetailOut)
def get_event(slug: str, db: DbSession) -> EventDetailOut:
    event = db.scalar(
        select(Event)
        .where(Event.slug == slug, Event.status == ListingStatus.published)
        .options(selectinload(Event.tiers))
    )
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Event not found")
    # Same availability rule as checkout: tickets in someone's checkout aren't free.
    held = orders.held_quantities(db, [t.id for t in event.tiers])
    out = EventDetailOut.model_validate(event, from_attributes=True)
    out.tiers = [
        TierOut(
            id=t.id,
            name=t.name,
            price_minor=t.price_minor,
            currency=t.currency,
            remaining=orders.available(t, held),
            max_per_order=t.max_per_order,
        )
        for t in event.tiers
    ]
    return out


@router.get("/fees/quote", response_model=FeeQuoteOut)
def fee_quote(
    db: DbSession,
    face_value_minor: int = Query(ge=0),
    quantity: int = Query(1, ge=1, le=50),
    country: str | None = Query(None, min_length=2, max_length=2),
) -> fees.FeeQuote:
    """What a ticket at this face value costs the buyer and pays the promoter.
    Rates come from the market; `country` defaults to the configured one."""
    return fees.quote(face_value_minor, quantity, countries.fee_config(db, country))
