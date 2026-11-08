"""Follows and favourites: the people and listings someone keeps up with."""

from uuid import UUID

from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session

from app.models import Favourite, Follow, Listing, Organisation, User


def followed_organisations(db: Session, user: User) -> list[Organisation]:
    return list(
        db.scalars(
            select(Organisation)
            .join(Follow, Follow.organisation_id == Organisation.id)
            .where(Follow.user_id == user.id)
            .order_by(Organisation.name)
        )
    )


def followed_organisation_ids(db: Session, user: User) -> list[UUID]:
    return list(db.scalars(select(Follow.organisation_id).where(Follow.user_id == user.id)))


def follower_count(db: Session, organisation_id: UUID) -> int:
    return db.scalar(select(func.count()).where(Follow.organisation_id == organisation_id)) or 0


def follower_counts(db: Session, organisation_ids: list[UUID]) -> dict[UUID, int]:
    """Counts for several organisations at once, so a list page is one query."""
    if not organisation_ids:
        return {}
    rows = db.execute(
        select(Follow.organisation_id, func.count())
        .where(Follow.organisation_id.in_(organisation_ids))
        .group_by(Follow.organisation_id)
    ).all()
    return {org_id: int(n) for org_id, n in rows}


def follow(db: Session, user: User, organisation_id: UUID) -> None:
    """Idempotent: following twice is following once. The caller commits."""
    exists = db.get(Follow, {"user_id": user.id, "organisation_id": organisation_id})
    if exists is None:
        db.add(Follow(user_id=user.id, organisation_id=organisation_id))


def unfollow(db: Session, user: User, organisation_id: UUID) -> None:
    db.execute(
        delete(Follow).where(Follow.user_id == user.id, Follow.organisation_id == organisation_id)
    )


def favourites(db: Session, user: User) -> list[Listing]:
    return list(
        db.scalars(
            select(Listing)
            .join(Favourite, Favourite.listing_id == Listing.id)
            .where(Favourite.user_id == user.id)
            .order_by(Favourite.created_at.desc())
        ).unique()
    )


def add_favourite(db: Session, user: User, listing_id: UUID) -> None:
    exists = db.get(Favourite, {"user_id": user.id, "listing_id": listing_id})
    if exists is None:
        db.add(Favourite(user_id=user.id, listing_id=listing_id))


def remove_favourite(db: Session, user: User, listing_id: UUID) -> None:
    db.execute(
        delete(Favourite).where(Favourite.user_id == user.id, Favourite.listing_id == listing_id)
    )
