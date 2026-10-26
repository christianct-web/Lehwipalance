"""Promoter endpoints: organisations, their members, events, ticket tiers and sellers.

Everything here is scoped to an organisation the caller belongs to. Roles:
- owner: everything, including granting owner/manager
- manager: events, tiers and sellers; can add or remove sellers and scanners
- seller, scanner: read the organisation's events
"""

from datetime import UTC, datetime
from typing import Annotated, Any
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, Response, status
from pydantic import BaseModel
from sqlalchemy import exists, func, select
from sqlalchemy.orm import Session, selectinload

from app.api.deps import AnyMember, CurrentUser, DbSession, OrgAdmin
from app.models import (
    Event,
    EventStatus,
    MemberRole,
    Order,
    OrderItem,
    OrderStatus,
    Organisation,
    OrgMember,
    Seller,
    TicketTier,
    User,
)
from app.schemas.promoter import (
    EventIn,
    EventPatch,
    MemberIn,
    MemberOut,
    MyOrganisationOut,
    OrganisationIn,
    OrganisationOut,
    OrganisationPatch,
    PromoterEventOut,
    PromoterEventSummaryOut,
    SellerIn,
    SellerOut,
    TierIn,
    TierPatch,
)
from app.services.codes import seller_code, slugify, with_suffix

router = APIRouter(prefix="/v1/orgs", tags=["promoter"])

_ADMIN_ROLES = {MemberRole.owner, MemberRole.manager}


def _aware(dt: datetime | None) -> datetime | None:
    # SQLite hands back naive datetimes; everything is stored as UTC.
    if dt is not None and dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt


def _changes(body: BaseModel, not_null: set[str]) -> dict[str, Any]:
    """Fields the client sent, rejecting an explicit null on required columns."""
    data = body.model_dump(exclude_unset=True)
    nulled = sorted(k for k in not_null if k in data and data[k] is None)
    if nulled:
        raise _invalid(f"Cannot be null: {nulled}")
    return data


def _unique_slug(db: Session, column, text: str, max_length: int) -> str:
    slug = slugify(text, max_length)
    while db.scalar(select(exists().where(column == slug))):
        slug = with_suffix(slug[: max_length - 7])
    return slug


def _conflict(detail: str) -> HTTPException:
    return HTTPException(status.HTTP_409_CONFLICT, detail)


def _invalid(detail: str) -> HTTPException:
    return HTTPException(422, detail)


# ==================== Organisations ====================


@router.post("", response_model=OrganisationOut, status_code=status.HTTP_201_CREATED)
def create_organisation(body: OrganisationIn, user: CurrentUser, db: DbSession) -> Organisation:
    org = Organisation(
        **body.model_dump(), slug=_unique_slug(db, Organisation.slug, body.name, 120)
    )
    db.add(org)
    db.flush()
    db.add(OrgMember(organisation_id=org.id, user_id=user.id, role=MemberRole.owner))
    db.commit()
    return org


@router.get("", response_model=list[MyOrganisationOut])
def list_my_organisations(user: CurrentUser, db: DbSession) -> list[MyOrganisationOut]:
    rows = db.execute(
        select(Organisation, OrgMember.role)
        .join(OrgMember, OrgMember.organisation_id == Organisation.id)
        .where(OrgMember.user_id == user.id)
        .order_by(Organisation.name)
    )
    return [
        MyOrganisationOut(**OrganisationOut.model_validate(org).model_dump(), role=role)
        for org, role in rows
    ]


@router.get("/{org_id}", response_model=OrganisationOut)
def get_organisation(org_id: UUID, member: AnyMember, db: DbSession) -> Organisation:
    return db.get(Organisation, org_id)


@router.patch("/{org_id}", response_model=OrganisationOut)
def update_organisation(
    org_id: UUID, body: OrganisationPatch, member: OrgAdmin, db: DbSession
) -> Organisation:
    org = db.get(Organisation, org_id)
    for key, value in _changes(body, {"name"}).items():
        setattr(org, key, value)
    db.commit()
    return org


# ==================== Members ====================


def _member_out(m: OrgMember, u: User) -> MemberOut:
    return MemberOut(user_id=u.id, email=u.email, full_name=u.full_name, role=m.role)


@router.get("/{org_id}/members", response_model=list[MemberOut])
def list_members(org_id: UUID, member: OrgAdmin, db: DbSession) -> list[MemberOut]:
    rows = db.execute(
        select(OrgMember, User)
        .join(User, User.id == OrgMember.user_id)
        .where(OrgMember.organisation_id == org_id)
        .order_by(User.full_name)
    )
    return [_member_out(m, u) for m, u in rows]


@router.post("/{org_id}/members", response_model=MemberOut, status_code=status.HTTP_201_CREATED)
def add_member(org_id: UUID, body: MemberIn, member: OrgAdmin, db: DbSession) -> MemberOut:
    if body.role in _ADMIN_ROLES and member.role != MemberRole.owner:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Only an owner can add owners or managers")
    user = db.scalar(select(User).where(User.email == body.email.lower()))
    if user is None or not user.is_active:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No account with that email")
    taken = db.scalar(
        select(exists().where(OrgMember.organisation_id == org_id, OrgMember.user_id == user.id))
    )
    if taken:
        raise _conflict("Already a member")
    new = OrgMember(organisation_id=org_id, user_id=user.id, role=body.role)
    db.add(new)
    db.commit()
    return _member_out(new, user)


@router.delete("/{org_id}/members/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_member(org_id: UUID, user_id: UUID, member: AnyMember, db: DbSession) -> Response:
    target = db.scalar(
        select(OrgMember).where(OrgMember.organisation_id == org_id, OrgMember.user_id == user_id)
    )
    if target is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Member not found")
    leaving = target.user_id == member.user_id
    allowed = (
        leaving
        or member.role == MemberRole.owner
        or (member.role == MemberRole.manager and target.role not in _ADMIN_ROLES)
    )
    if not allowed:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Your role can't remove this member")
    if target.role == MemberRole.owner:
        owners = db.scalar(
            select(func.count())
            .select_from(OrgMember)
            .where(OrgMember.organisation_id == org_id, OrgMember.role == MemberRole.owner)
        )
        if owners <= 1:
            raise _conflict("An organisation needs at least one owner")
    db.delete(target)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ==================== Events ====================


def _get_event(db: Session, org_id: UUID, event_id: UUID) -> Event:
    event = db.scalar(
        select(Event)
        .where(Event.id == event_id, Event.organisation_id == org_id)
        .options(selectinload(Event.tiers))
    )
    if event is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Event not found")
    return event


def _editable_event(db: Session, org_id: UUID, event_id: UUID) -> Event:
    event = _get_event(db, org_id, event_id)
    if event.status == EventStatus.cancelled:
        raise _conflict("This event is cancelled")
    return event


@router.get("/{org_id}/events", response_model=list[PromoterEventSummaryOut])
def list_org_events(
    org_id: UUID,
    member: AnyMember,
    db: DbSession,
    status_: Annotated[EventStatus | None, Query(alias="status")] = None,
) -> list[Event]:
    stmt = select(Event).where(Event.organisation_id == org_id)
    if status_ is not None:
        stmt = stmt.where(Event.status == status_)
    return list(db.scalars(stmt.order_by(Event.starts_at)))


@router.post(
    "/{org_id}/events", response_model=PromoterEventOut, status_code=status.HTTP_201_CREATED
)
def create_event(org_id: UUID, body: EventIn, member: OrgAdmin, db: DbSession) -> Event:
    if body.ends_at and body.ends_at <= body.starts_at:
        raise _invalid("ends_at must be after starts_at")
    event = Event(
        **body.model_dump(),
        organisation_id=org_id,
        status=EventStatus.draft,
        slug=_unique_slug(db, Event.slug, body.title, 160),
    )
    db.add(event)
    db.commit()
    return _get_event(db, org_id, event.id)


@router.get("/{org_id}/events/{event_id}", response_model=PromoterEventOut)
def get_org_event(org_id: UUID, event_id: UUID, member: AnyMember, db: DbSession) -> Event:
    return _get_event(db, org_id, event_id)


@router.patch("/{org_id}/events/{event_id}", response_model=PromoterEventOut)
def update_event(
    org_id: UUID, event_id: UUID, body: EventPatch, member: OrgAdmin, db: DbSession
) -> Event:
    event = _editable_event(db, org_id, event_id)
    changes = _changes(body, {"title", "starts_at", "category"})
    starts_at = changes.get("starts_at", _aware(event.starts_at))
    ends_at = changes.get("ends_at", _aware(event.ends_at))
    if ends_at and ends_at <= starts_at:
        raise _invalid("ends_at must be after starts_at")
    for key, value in changes.items():
        setattr(event, key, value)
    db.commit()
    return event


@router.post("/{org_id}/events/{event_id}/publish", response_model=PromoterEventOut)
def publish_event(org_id: UUID, event_id: UUID, member: OrgAdmin, db: DbSession) -> Event:
    event = _editable_event(db, org_id, event_id)
    if event.status == EventStatus.published:
        return event
    if not event.tiers:
        raise _conflict("Add at least one ticket tier before publishing")
    if _aware(event.starts_at) <= datetime.now(UTC):
        raise _conflict("The event has already started")
    event.status = EventStatus.published
    db.commit()
    return event


@router.post("/{org_id}/events/{event_id}/cancel", response_model=PromoterEventOut)
def cancel_event(org_id: UUID, event_id: UUID, member: OrgAdmin, db: DbSession) -> Event:
    event = _get_event(db, org_id, event_id)
    if event.status == EventStatus.cancelled:
        return event
    paid = db.scalar(
        select(exists().where(Order.event_id == event.id, Order.status == OrderStatus.paid))
    )
    if paid:
        # Cancelling with paid orders means refunding them; that flow isn't built yet.
        raise _conflict("This event has paid orders; refunds must be handled first")
    event.status = EventStatus.cancelled
    db.commit()
    return event


# ==================== Ticket tiers ====================


def _get_tier(event: Event, tier_id: UUID) -> TicketTier:
    tier = next((t for t in event.tiers if t.id == tier_id), None)
    if tier is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Tier not found")
    return tier


@router.post(
    "/{org_id}/events/{event_id}/tiers",
    response_model=PromoterEventOut,
    status_code=status.HTTP_201_CREATED,
)
def create_tier(
    org_id: UUID, event_id: UUID, body: TierIn, member: OrgAdmin, db: DbSession
) -> Event:
    event = _editable_event(db, org_id, event_id)
    db.add(TicketTier(**body.model_dump(), event_id=event.id))
    db.commit()
    db.refresh(event, ["tiers"])
    return event


@router.patch("/{org_id}/events/{event_id}/tiers/{tier_id}", response_model=PromoterEventOut)
def update_tier(
    org_id: UUID, event_id: UUID, tier_id: UUID, body: TierPatch, member: OrgAdmin, db: DbSession
) -> Event:
    event = _editable_event(db, org_id, event_id)
    tier = _get_tier(event, tier_id)
    changes = _changes(body, {"name", "price_minor", "quantity", "max_per_order", "sort_order"})
    if tier.quantity_sold:
        if "price_minor" in changes and changes["price_minor"] != tier.price_minor:
            raise _conflict("Tickets in this tier are sold; add a new tier for a new price")
        if changes.get("quantity", tier.quantity) < tier.quantity_sold:
            raise _conflict(f"{tier.quantity_sold} tickets are already sold in this tier")
    start = changes.get("sales_start_at", _aware(tier.sales_start_at))
    end = changes.get("sales_end_at", _aware(tier.sales_end_at))
    if start and end and end <= start:
        raise _invalid("sales_end_at must be after sales_start_at")
    for key, value in changes.items():
        setattr(tier, key, value)
    db.commit()
    db.refresh(event, ["tiers"])
    return event


@router.delete(
    "/{org_id}/events/{event_id}/tiers/{tier_id}", status_code=status.HTTP_204_NO_CONTENT
)
def delete_tier(
    org_id: UUID, event_id: UUID, tier_id: UUID, member: OrgAdmin, db: DbSession
) -> Response:
    event = _editable_event(db, org_id, event_id)
    tier = _get_tier(event, tier_id)
    ordered = db.scalar(select(exists().where(OrderItem.tier_id == tier.id)))
    if tier.quantity_sold or ordered:
        raise _conflict("This tier has orders; set its quantity or sales window instead")
    event.tiers.remove(tier)
    db.delete(tier)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ==================== Sellers ====================


@router.get("/{org_id}/events/{event_id}/sellers", response_model=list[SellerOut])
def list_sellers(org_id: UUID, event_id: UUID, member: OrgAdmin, db: DbSession) -> list[Seller]:
    event = _get_event(db, org_id, event_id)
    return list(
        db.scalars(select(Seller).where(Seller.event_id == event.id).order_by(Seller.display_name))
    )


@router.post(
    "/{org_id}/events/{event_id}/sellers",
    response_model=SellerOut,
    status_code=status.HTTP_201_CREATED,
)
def create_seller(
    org_id: UUID, event_id: UUID, body: SellerIn, member: OrgAdmin, db: DbSession
) -> Seller:
    event = _editable_event(db, org_id, event_id)
    user_id = None
    if body.email:
        user = db.scalar(select(User).where(User.email == body.email.lower()))
        if user is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "No account with that email")
        user_id = user.id
    code = seller_code()
    while db.scalar(select(exists().where(Seller.code == code))):
        code = seller_code()
    seller = Seller(event_id=event.id, display_name=body.display_name, user_id=user_id, code=code)
    db.add(seller)
    db.commit()
    return seller


@router.delete(
    "/{org_id}/events/{event_id}/sellers/{seller_id}", status_code=status.HTTP_204_NO_CONTENT
)
def delete_seller(
    org_id: UUID, event_id: UUID, seller_id: UUID, member: OrgAdmin, db: DbSession
) -> Response:
    event = _get_event(db, org_id, event_id)
    seller = db.scalar(select(Seller).where(Seller.id == seller_id, Seller.event_id == event.id))
    if seller is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Seller not found")
    if db.scalar(select(exists().where(Order.seller_id == seller.id))):
        raise _conflict("This seller has orders and is kept for the sales report")
    db.delete(seller)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
