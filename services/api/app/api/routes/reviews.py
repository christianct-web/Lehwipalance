"""Reviews on a listing, with the verified-attendee badge.

Reading them is public — reviews are part of deciding whether to go. Writing
one needs a token, and carries the badge if this platform scanned the person in
at the gate.
"""

from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import CurrentUser, DbSession
from app.core.time import aware, utcnow
from app.models import Listing, ListingStatus, Review, User
from app.schemas.reviews import (
    ReviewIn,
    ReviewOut,
    ReviewPageOut,
    ReviewPatch,
    ReviewSummaryOut,
    SectionRatingOut,
    SectionSummaryOut,
)
from app.services import reviews

router = APIRouter(prefix="/v1", tags=["reviews"])


def _listing(db: Session, slug: str) -> Listing:
    listing = db.scalar(select(Listing).where(Listing.slug == slug))
    # Draft listings are not public, so neither are their reviews. A cancelled
    # one keeps them: it may have happened before it was cancelled.
    if listing is None or listing.status == ListingStatus.draft:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Listing not found")
    return listing


def _out(review: Review, author: User) -> ReviewOut:
    return ReviewOut(
        id=review.id,
        rating=review.rating,
        comment=review.comment,
        is_verified_attendee=review.is_verified_attendee,
        author_name=author.full_name,
        created_at=review.created_at,
        updated_at=review.updated_at,
        sections=[
            SectionRatingOut(section=str(s.section), rating=s.rating)
            for s in sorted(review.sections, key=lambda s: str(s.section))
        ],
    )


def _summary_out(summary: reviews.Summary) -> ReviewSummaryOut:
    return ReviewSummaryOut(
        count=summary.count,
        average=summary.average,
        verified_count=summary.verified_count,
        sections=[
            SectionSummaryOut(section=s.section, count=s.count, average=s.average)
            for s in summary.sections
        ],
    )


@router.get("/listings/{slug}/reviews", response_model=ReviewPageOut)
def list_reviews(
    slug: str,
    db: DbSession,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
) -> ReviewPageOut:
    listing = _listing(db, slug)
    return ReviewPageOut(
        listing_slug=listing.slug,
        summary=_summary_out(reviews.summary(db, listing.id)),
        limit=limit,
        offset=offset,
        results=[_out(r, a) for r, a in reviews.page(db, listing.id, limit, offset)],
    )


@router.post(
    "/listings/{slug}/reviews", response_model=ReviewOut, status_code=status.HTTP_201_CREATED
)
def create_review(slug: str, body: ReviewIn, user: CurrentUser, db: DbSession) -> ReviewOut:
    """Review a listing you have been to.

    Refused before it happens: a verdict on a fete that has not started yet is
    not a review of anything.
    """
    listing = _listing(db, slug)
    starts_at = aware(listing.starts_at)
    if starts_at is not None and starts_at > utcnow():
        raise HTTPException(409, "This hasn't happened yet")

    existing = db.scalar(
        select(Review).where(Review.listing_id == listing.id, Review.user_id == user.id)
    )
    if existing is not None:
        raise HTTPException(409, "You have already reviewed this; edit that review instead")

    review = Review(
        listing_id=listing.id,
        user_id=user.id,
        rating=body.rating,
        comment=body.comment,
        is_verified_attendee=reviews.attended(db, user, listing.id),
    )
    reviews.set_sections(review, body.section_scores())
    db.add(review)
    db.flush()
    reviews.refresh_rating(db, listing.id)
    db.commit()
    return _out(review, user)


def _own(db: Session, user: User, review_id: UUID) -> Review:
    review = db.get(Review, review_id)
    # 404 rather than 403 for someone else's review: ids aren't for probing.
    if review is None or review.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Review not found")
    return review


@router.patch("/reviews/{review_id}", response_model=ReviewOut)
def update_review(
    review_id: UUID, body: ReviewPatch, user: CurrentUser, db: DbSession
) -> ReviewOut:
    """Change your own review. The badge is not re-evaluated: it recorded that
    you were scanned in, which editing your words does not change."""
    review = _own(db, user, review_id)
    changes = body.model_dump(exclude_unset=True)
    if "rating" in changes:
        if changes["rating"] is None:
            raise HTTPException(422, "rating cannot be null")
        review.rating = changes["rating"]
    if "comment" in changes:
        review.comment = changes["comment"]
    if "sections" in changes and changes["sections"] is not None:
        reviews.set_sections(review, {str(k): v for k, v in changes["sections"].items()})
    db.flush()
    reviews.refresh_rating(db, review.listing_id)
    db.commit()
    return _out(review, user)


@router.delete("/reviews/{review_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_review(review_id: UUID, user: CurrentUser, db: DbSession) -> Response:
    review = _own(db, user, review_id)
    listing_id = review.listing_id
    db.delete(review)
    db.flush()
    reviews.refresh_rating(db, listing_id)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
