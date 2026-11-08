"""Reviews, the verified-attendee badge, and the rating rollup.

The badge is the point. Anyone can run a directory and collect opinions; this
platform sold the ticket and scanned it at the gate, so it can say which
reviewers actually turned up. That is proof a competitor cannot fabricate, and
it is only worth anything if it is strict — so a simulated order never earns it,
and it is settled once, when the review is written.
"""

from dataclasses import dataclass
from uuid import UUID

from sqlalchemy import case, exists, func, or_, select
from sqlalchemy.orm import Session

from app.models import (
    Listing,
    Order,
    Review,
    ReviewSection,
    ReviewSectionRating,
    Ticket,
    TicketStatus,
    User,
)


@dataclass(frozen=True)
class SectionSummary:
    section: str
    count: int
    average: float


@dataclass(frozen=True)
class Summary:
    count: int
    average: float | None
    verified_count: int
    sections: list[SectionSummary]


def attended(db: Session, user: User, listing_id: UUID) -> bool:
    """Whether this person has a real, checked-in ticket for this listing.

    Guest checkout means a ticket may have no holder, so the buyer on the order
    counts too. Simulated orders are excluded: a demo ticket buys neither entry
    nor credibility.

    Only events can be attended today. When accommodation and tours land, a
    completed booking becomes the other way to earn this.
    """
    scanned = (
        select(Ticket.id)
        .join(Order, Order.id == Ticket.order_id)
        .where(
            Order.listing_id == listing_id,
            Order.is_test.is_(False),
            Ticket.status == TicketStatus.checked_in,
            or_(Ticket.holder_id == user.id, Order.buyer_id == user.id),
        )
    )
    return bool(db.scalar(select(exists(scanned))))


def refresh_rating(db: Session, listing_id: UUID) -> None:
    """Recompute a listing's rating rollup. The caller commits.

    Stored as a count and a sum rather than an average so the numbers stay
    exact integers and discovery can filter on the average without recomputing
    it over every review.
    """
    listing = db.get(Listing, listing_id)
    if listing is None:
        return
    count, total = db.execute(
        select(func.count(), func.coalesce(func.sum(Review.rating), 0)).where(
            Review.listing_id == listing_id
        )
    ).one()
    listing.rating_count = int(count)
    listing.rating_sum = int(total)


def summary(db: Session, listing_id: UUID) -> Summary:
    count, total, verified = db.execute(
        select(
            func.count(),
            func.coalesce(func.sum(Review.rating), 0),
            # A CASE sum rather than an aggregate FILTER clause, which is
            # spelled inconsistently across backends.
            func.coalesce(func.sum(case((Review.is_verified_attendee.is_(True), 1), else_=0)), 0),
        ).where(Review.listing_id == listing_id)
    ).one()
    rows = db.execute(
        select(ReviewSectionRating.section, func.count(), func.avg(ReviewSectionRating.rating))
        .join(Review, Review.id == ReviewSectionRating.review_id)
        .where(Review.listing_id == listing_id)
        .group_by(ReviewSectionRating.section)
    ).all()
    order = {s: i for i, s in enumerate(ReviewSection)}
    sections = sorted(
        (
            SectionSummary(section=str(section), count=int(n), average=round(float(avg), 2))
            for section, n, avg in rows
        ),
        key=lambda s: order.get(ReviewSection(s.section), 99),
    )
    return Summary(
        count=int(count),
        average=round(int(total) / int(count), 2) if count else None,
        verified_count=int(verified),
        sections=sections,
    )


def page(db: Session, listing_id: UUID, limit: int, offset: int) -> list[tuple[Review, User]]:
    """Reviews newest first, with their author. Verified attendees first would
    bias the page; the badge is shown per review instead."""
    return list(
        db.execute(
            select(Review, User)
            .join(User, User.id == Review.user_id)
            .where(Review.listing_id == listing_id)
            .order_by(Review.created_at.desc())
            .limit(limit)
            .offset(offset)
        ).all()
    )


def set_sections(review: Review, scores: dict[str, int]) -> None:
    """Replace a review's section scores with exactly what was sent."""
    review.sections.clear()
    for section, rating in sorted(scores.items()):
        review.sections.append(ReviewSectionRating(section=ReviewSection(section), rating=rating))
