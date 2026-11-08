"""Collaborators: organisations credited on a listing they do not own.

A listing has one owner — the organisation that created it and gets paid — and
any number of collaborators. An organisation page therefore shows two groups,
which is exactly the split the concept asks for: owned listings, and shared
listings or collabs.
"""

from uuid import UUID

from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session

from app.models import Listing, ListingCollaborator, ListingStatus, Organisation


def for_listing(db: Session, listing_id: UUID) -> list[tuple[Organisation, str | None]]:
    rows = db.execute(
        select(Organisation, ListingCollaborator.credit)
        .join(ListingCollaborator, ListingCollaborator.organisation_id == Organisation.id)
        .where(ListingCollaborator.listing_id == listing_id)
        .order_by(Organisation.name)
    ).all()
    return [(org, credit) for org, credit in rows]


def for_listings(db: Session, listing_ids: list[UUID]) -> dict[UUID, list[Organisation]]:
    """Collaborators for several listings at once, so a list page is one query."""
    if not listing_ids:
        return {}
    rows = db.execute(
        select(ListingCollaborator.listing_id, Organisation)
        .join(Organisation, Organisation.id == ListingCollaborator.organisation_id)
        .where(ListingCollaborator.listing_id.in_(listing_ids))
        .order_by(Organisation.name)
    ).all()
    out: dict[UUID, list[Organisation]] = {}
    for listing_id, org in rows:
        out.setdefault(listing_id, []).append(org)
    return out


def add(db: Session, listing_id: UUID, organisation_id: UUID, credit: str | None) -> None:
    """Credit an organisation on a listing. Idempotent; updates the credit if
    it is already there. The caller commits."""
    existing = db.get(
        ListingCollaborator, {"listing_id": listing_id, "organisation_id": organisation_id}
    )
    if existing is None:
        db.add(
            ListingCollaborator(
                listing_id=listing_id, organisation_id=organisation_id, credit=credit
            )
        )
    else:
        existing.credit = credit


def remove(db: Session, listing_id: UUID, organisation_id: UUID) -> None:
    db.execute(
        delete(ListingCollaborator).where(
            ListingCollaborator.listing_id == listing_id,
            ListingCollaborator.organisation_id == organisation_id,
        )
    )


def _public(stmt):
    return stmt.where(Listing.status == ListingStatus.published)


def owned_listings(db: Session, organisation_id: UUID) -> list[Listing]:
    return list(
        db.scalars(
            _public(select(Listing).where(Listing.organisation_id == organisation_id)).order_by(
                Listing.starts_at.asc().nulls_last(), Listing.title
            )
        ).unique()
    )


def collaborations(db: Session, organisation_id: UUID) -> list[Listing]:
    """Listings this organisation is credited on but does not own."""
    return list(
        db.scalars(
            _public(
                select(Listing).join(
                    ListingCollaborator, ListingCollaborator.listing_id == Listing.id
                )
            )
            .where(
                ListingCollaborator.organisation_id == organisation_id,
                # An organisation crediting itself would appear in both groups.
                Listing.organisation_id != organisation_id,
            )
            .order_by(Listing.starts_at.asc().nulls_last(), Listing.title)
        ).unique()
    )


def search(db: Session, query: str | None, limit: int, offset: int) -> list[Organisation]:
    """Organisations, searchable as the concept requires of collaborators.

    Only organisations with something published are listed: an empty profile is
    not a search result.
    """
    has_public = (
        select(Listing.id)
        .where(
            Listing.organisation_id == Organisation.id,
            Listing.status == ListingStatus.published,
        )
        .exists()
    )
    credited = (
        select(ListingCollaborator.listing_id)
        .join(Listing, Listing.id == ListingCollaborator.listing_id)
        .where(
            ListingCollaborator.organisation_id == Organisation.id,
            Listing.status == ListingStatus.published,
        )
        .exists()
    )
    stmt = select(Organisation).where(has_public | credited)
    if query:
        stmt = stmt.where(func.lower(Organisation.name).like(f"%{query.strip().lower()}%"))
    return list(db.scalars(stmt.order_by(Organisation.name).limit(limit).offset(offset)))
