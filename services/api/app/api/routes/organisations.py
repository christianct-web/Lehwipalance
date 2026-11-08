"""Public organisation profiles, and crediting collaborators on a listing.

The concept makes a collaborator an organisation, discoverable and searchable
alongside every other organisation, whose profile shows everything it is linked
to. So an organisation page has two groups — what it runs, and what it is
credited on — and organisations are searchable here.
"""

from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import DbSession, OrgAdmin
from app.models import Listing, Organisation
from app.schemas.listings import ListingSummaryOut
from app.schemas.organisations import (
    CollaboratorIn,
    CollaboratorOut,
    OrganisationCardOut,
    OrganisationPageOut,
    OrganisationProfileOut,
)
from app.services import collaborators, social

public = APIRouter(prefix="/v1/organisations", tags=["organisations"])


def _summaries(listings) -> list[ListingSummaryOut]:
    return [ListingSummaryOut.model_validate(r, from_attributes=True) for r in listings]


@public.get("", response_model=OrganisationPageOut)
def search_organisations(
    db: DbSession,
    q: str | None = Query(None, max_length=200),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
) -> OrganisationPageOut:
    """Search organisations. Only ones with something published are listed: an
    empty profile is not a search result."""
    return OrganisationPageOut(
        limit=limit,
        offset=offset,
        results=[
            OrganisationCardOut.model_validate(o, from_attributes=True)
            for o in collaborators.search(db, q, limit, offset)
        ],
    )


@public.get("/{slug}", response_model=OrganisationProfileOut)
def organisation_profile(slug: str, db: DbSession) -> OrganisationProfileOut:
    org = db.scalar(select(Organisation).where(Organisation.slug == slug))
    if org is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Organisation not found")
    return OrganisationProfileOut(
        id=org.id,
        name=org.name,
        slug=org.slug,
        instagram=org.instagram,
        follower_count=social.follower_count(db, org.id),
        owned_listings=_summaries(collaborators.owned_listings(db, org.id)),
        collaborations=_summaries(collaborators.collaborations(db, org.id)),
    )


# On the listing's own path, not under /v1/organisations, where it would
# collide with a profile whose slug happened to be "listings".
listing_public = APIRouter(prefix="/v1/listings", tags=["organisations"])


@listing_public.get("/{listing_slug}/collaborators", response_model=list[CollaboratorOut])
def listing_collaborators(listing_slug: str, db: DbSession) -> list[CollaboratorOut]:
    listing = db.scalar(select(Listing).where(Listing.slug == listing_slug))
    if listing is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Listing not found")
    return [
        CollaboratorOut(
            id=org.id, name=org.name, slug=org.slug, instagram=org.instagram, credit=credit
        )
        for org, credit in collaborators.for_listing(db, listing.id)
    ]


# ---------- Managing them, from the owning organisation ----------

manage = APIRouter(prefix="/v1/orgs", tags=["organisations"])


def _owned_listing(db: Session, org_id: UUID, listing_id: UUID) -> Listing:
    listing = db.get(Listing, listing_id)
    if listing is None or listing.organisation_id != org_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Listing not found")
    return listing


@manage.get("/{org_id}/listings/{listing_id}/collaborators", response_model=list[CollaboratorOut])
def list_collaborators(
    org_id: UUID, listing_id: UUID, member: OrgAdmin, db: DbSession
) -> list[CollaboratorOut]:
    listing = _owned_listing(db, org_id, listing_id)
    return [
        CollaboratorOut(
            id=org.id, name=org.name, slug=org.slug, instagram=org.instagram, credit=credit
        )
        for org, credit in collaborators.for_listing(db, listing.id)
    ]


@manage.put("/{org_id}/listings/{listing_id}/collaborators", status_code=status.HTTP_204_NO_CONTENT)
def credit_collaborator(
    org_id: UUID, listing_id: UUID, body: CollaboratorIn, member: OrgAdmin, db: DbSession
) -> Response:
    """Credit another organisation on this listing. Idempotent, and re-sending
    it updates the credit.

    Note: this takes effect without the other organisation agreeing, which is
    how the concept describes it. Since a collaboration shows on their public
    profile, an invite-and-accept step is a decision worth taking before launch.
    """
    listing = _owned_listing(db, org_id, listing_id)
    if body.organisation_id == org_id:
        raise HTTPException(422, "A listing's owner is not one of its collaborators")
    if db.get(Organisation, body.organisation_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Organisation not found")
    collaborators.add(db, listing.id, body.organisation_id, body.credit)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@manage.delete(
    "/{org_id}/listings/{listing_id}/collaborators/{collaborator_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def remove_collaborator(
    org_id: UUID,
    listing_id: UUID,
    collaborator_id: UUID,
    member: OrgAdmin,
    db: DbSession,
) -> Response:
    listing = _owned_listing(db, org_id, listing_id)
    collaborators.remove(db, listing.id, collaborator_id)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
