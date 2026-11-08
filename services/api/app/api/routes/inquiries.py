"""The contact and booking flow for the vendor directory.

A service has no inventory to sell, so an inquiry is how it gets booked: the
organiser asks, the vendor replies, and either side can close it. Both sides
need a token — this is correspondence, not a public page.
"""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import AnyMember, CurrentUser, DbSession, OrgAdmin
from app.models import Inquiry, InquiryStatus, Listing, ListingStatus, ListingType, User
from app.schemas.inquiries import (
    InquiryIn,
    InquiryListingOut,
    InquiryOut,
    InquiryResponseIn,
    VendorInquiryOut,
)
from app.services import inquiries

# Categories you book by asking rather than by checking out. Events are not
# here: a fete has tickets, and an inquiry would be a worse way to buy one.
INQUIRABLE = (ListingType.service,)

customer = APIRouter(prefix="/v1", tags=["inquiries"])
vendor = APIRouter(prefix="/v1/orgs", tags=["inquiries"])


def _out(db: Session, inquiry: Inquiry) -> InquiryOut:
    listing = db.get(Listing, inquiry.listing_id)
    return InquiryOut(
        id=inquiry.id,
        listing=InquiryListingOut.model_validate(listing, from_attributes=True),
        status=inquiry.status.value,
        subject=inquiry.subject,
        message=inquiry.message,
        event_date=inquiry.event_date,
        contact_phone=inquiry.contact_phone,
        response=inquiry.response,
        created_at=inquiry.created_at,
        responded_at=inquiry.responded_at,
        resolved_at=inquiry.resolved_at,
    )


def _vendor_out(db: Session, inquiry: Inquiry) -> VendorInquiryOut:
    asker = db.get(User, inquiry.user_id)
    base = _out(db, inquiry)
    return VendorInquiryOut(
        **base.model_dump(),
        from_name=asker.full_name if asker else "Unknown",
        from_email=asker.email if asker else "",
    )


def _handle(error: inquiries.InquiryError) -> HTTPException:
    return HTTPException(error.status_code, error.detail)


# ---------- The organiser's side ----------


@customer.post(
    "/listings/{slug}/inquiries", response_model=InquiryOut, status_code=status.HTTP_201_CREATED
)
def create_inquiry(slug: str, body: InquiryIn, user: CurrentUser, db: DbSession) -> InquiryOut:
    """Ask a vendor about a listing."""
    listing = db.scalar(
        select(Listing).where(Listing.slug == slug, Listing.status == ListingStatus.published)
    )
    if listing is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Listing not found")
    if listing.type not in INQUIRABLE:
        raise HTTPException(409, f"A {listing.type.value} listing is not booked by inquiry")
    try:
        inquiry = inquiries.create(
            db,
            listing=listing,
            user=user,
            subject=body.subject,
            message=body.message,
            event_date=body.event_date,
            contact_phone=body.contact_phone,
        )
    except inquiries.InquiryError as e:
        raise _handle(e) from None
    db.commit()
    return _out(db, inquiry)


@customer.get("/me/inquiries", response_model=list[InquiryOut])
def my_inquiries(
    user: CurrentUser,
    db: DbSession,
    status_filter: Annotated[InquiryStatus | None, Query(alias="status")] = None,
) -> list[InquiryOut]:
    return [_out(db, i) for i in inquiries.for_user(db, user, status_filter)]


def _mine(db: Session, user: User, inquiry_id: UUID) -> Inquiry:
    inquiry = db.get(Inquiry, inquiry_id)
    if inquiry is None or inquiry.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Inquiry not found")
    return inquiry


@customer.get("/me/inquiries/{inquiry_id}", response_model=InquiryOut)
def my_inquiry(inquiry_id: UUID, user: CurrentUser, db: DbSession) -> InquiryOut:
    return _out(db, _mine(db, user, inquiry_id))


@customer.post("/me/inquiries/{inquiry_id}/cancel", response_model=InquiryOut)
def cancel_inquiry(inquiry_id: UUID, user: CurrentUser, db: DbSession) -> InquiryOut:
    """Withdraw an inquiry you sent."""
    inquiry = _mine(db, user, inquiry_id)
    try:
        inquiries.cancel(db, inquiry)
    except inquiries.InquiryError as e:
        raise _handle(e) from None
    db.commit()
    return _out(db, inquiry)


# ---------- The vendor's side ----------


def _theirs(db: Session, org_id: UUID, inquiry_id: UUID) -> Inquiry:
    inquiry = db.get(Inquiry, inquiry_id)
    if inquiry is None or inquiry.organisation_id != org_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Inquiry not found")
    return inquiry


@vendor.get("/{org_id}/inquiries", response_model=list[VendorInquiryOut])
def organisation_inbox(
    org_id: UUID,
    member: AnyMember,
    db: DbSession,
    status_filter: Annotated[InquiryStatus | None, Query(alias="status")] = None,
) -> list[VendorInquiryOut]:
    """The vendor's inbox, pending first — it is a work queue."""
    return [_vendor_out(db, i) for i in inquiries.for_organisation(db, org_id, status_filter)]


@vendor.get("/{org_id}/inquiries/{inquiry_id}", response_model=VendorInquiryOut)
def organisation_inquiry(
    org_id: UUID, inquiry_id: UUID, member: AnyMember, db: DbSession
) -> VendorInquiryOut:
    return _vendor_out(db, _theirs(db, org_id, inquiry_id))


@vendor.post("/{org_id}/inquiries/{inquiry_id}/respond", response_model=VendorInquiryOut)
def respond_to_inquiry(
    org_id: UUID,
    inquiry_id: UUID,
    body: InquiryResponseIn,
    member: OrgAdmin,
    db: DbSession,
) -> VendorInquiryOut:
    """Reply. Replying again updates the reply and keeps it open."""
    inquiry = _theirs(db, org_id, inquiry_id)
    try:
        inquiries.respond(db, inquiry, body.response)
    except inquiries.InquiryError as e:
        raise _handle(e) from None
    db.commit()
    return _vendor_out(db, inquiry)


@vendor.post("/{org_id}/inquiries/{inquiry_id}/resolve", response_model=VendorInquiryOut)
def resolve_inquiry(
    org_id: UUID, inquiry_id: UUID, member: OrgAdmin, db: DbSession
) -> VendorInquiryOut:
    """Close it off: booked, or answered and done."""
    inquiry = _theirs(db, org_id, inquiry_id)
    try:
        inquiries.resolve(db, inquiry)
    except inquiries.InquiryError as e:
        raise _handle(e) from None
    db.commit()
    return _vendor_out(db, inquiry)
