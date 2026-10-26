from datetime import UTC, datetime

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.api.deps import DbSession
from app.models import Event, EventStatus
from app.schemas.events import EventDetailOut, EventSummaryOut, FeeQuoteOut
from app.services import fees

router = APIRouter(prefix="/v1", tags=["events"])


@router.get("/events", response_model=list[EventSummaryOut])
def list_events(
    db: DbSession,
    upcoming_only: bool = True,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
) -> list[Event]:
    stmt = select(Event).where(Event.status == EventStatus.published)
    if upcoming_only:
        stmt = stmt.where(Event.starts_at >= datetime.now(UTC))
    stmt = stmt.order_by(Event.starts_at).limit(limit).offset(offset)
    return list(db.scalars(stmt))


@router.get("/events/{slug}", response_model=EventDetailOut)
def get_event(slug: str, db: DbSession) -> Event:
    event = db.scalar(
        select(Event)
        .where(Event.slug == slug, Event.status == EventStatus.published)
        .options(selectinload(Event.tiers))
    )
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Event not found")
    return event


@router.get("/fees/quote", response_model=FeeQuoteOut)
def fee_quote(
    face_value_minor: int = Query(ge=0), quantity: int = Query(1, ge=1, le=50)
) -> fees.FeeQuote:
    return fees.quote(face_value_minor, quantity)
