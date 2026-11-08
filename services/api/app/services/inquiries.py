"""Inquiries: an organiser asking a vendor, and the vendor replying.

The concept's "contact and booking flow directly in-app" for the venue and
vendor directory. A service has no inventory to sell, so this is how it gets
booked.
"""

from uuid import UUID

from sqlalchemy import Select, func, select
from sqlalchemy.orm import Session

from app.core.time import utcnow
from app.models import Inquiry, InquiryStatus, Listing, User

# What one organiser may have open with one vendor at a time, so a vendor's
# inbox cannot be flooded from a single account.
MAX_OPEN_PER_LISTING = 5

OPEN_STATUSES = (InquiryStatus.pending, InquiryStatus.responded)


class InquiryError(Exception):
    def __init__(self, status_code: int, detail: str):
        super().__init__(detail)
        self.status_code = status_code
        self.detail = detail


def open_count(db: Session, listing_id: UUID, user_id: UUID) -> int:
    return (
        db.scalar(
            select(func.count())
            .select_from(Inquiry)
            .where(
                Inquiry.listing_id == listing_id,
                Inquiry.user_id == user_id,
                Inquiry.status.in_(OPEN_STATUSES),
            )
        )
        or 0
    )


def create(
    db: Session,
    *,
    listing: Listing,
    user: User,
    subject: str,
    message: str,
    event_date=None,
    contact_phone: str | None = None,
) -> Inquiry:
    """Ask a vendor about a listing. The caller commits."""
    if open_count(db, listing.id, user.id) >= MAX_OPEN_PER_LISTING:
        raise InquiryError(409, "You already have several open inquiries with this vendor")
    inquiry = Inquiry(
        listing_id=listing.id,
        organisation_id=listing.organisation_id,
        user_id=user.id,
        subject=subject,
        message=message,
        event_date=event_date,
        contact_phone=contact_phone,
        status=InquiryStatus.pending,
    )
    db.add(inquiry)
    db.flush()
    return inquiry


def respond(db: Session, inquiry: Inquiry, response: str) -> Inquiry:
    """The vendor replies. Replying again updates the reply and keeps the
    inquiry open; a resolved or cancelled one is closed to further replies."""
    if inquiry.status in (InquiryStatus.resolved, InquiryStatus.cancelled):
        raise InquiryError(409, f"This inquiry is {inquiry.status.value}")
    inquiry.response = response
    inquiry.status = InquiryStatus.responded
    inquiry.responded_at = utcnow()
    return inquiry


def resolve(db: Session, inquiry: Inquiry) -> Inquiry:
    if inquiry.status == InquiryStatus.cancelled:
        raise InquiryError(409, "This inquiry was cancelled")
    inquiry.status = InquiryStatus.resolved
    inquiry.resolved_at = utcnow()
    return inquiry


def cancel(db: Session, inquiry: Inquiry) -> Inquiry:
    """The organiser withdraws it. Resolved inquiries stay resolved: the
    conversation already finished."""
    if inquiry.status == InquiryStatus.resolved:
        raise InquiryError(409, "This inquiry is already resolved")
    inquiry.status = InquiryStatus.cancelled
    return inquiry


def _ordered(stmt: Select) -> Select:
    # Pending first, because that is the vendor's work queue, then newest.
    return stmt.order_by(Inquiry.status != InquiryStatus.pending, Inquiry.created_at.desc())


def for_user(db: Session, user: User, status: InquiryStatus | None = None) -> list[Inquiry]:
    stmt = select(Inquiry).where(Inquiry.user_id == user.id)
    if status is not None:
        stmt = stmt.where(Inquiry.status == status)
    return list(db.scalars(_ordered(stmt)))


def for_organisation(
    db: Session, organisation_id: UUID, status: InquiryStatus | None = None
) -> list[Inquiry]:
    stmt = select(Inquiry).where(Inquiry.organisation_id == organisation_id)
    if status is not None:
        stmt = stmt.where(Inquiry.status == status)
    return list(db.scalars(_ordered(stmt)))
