"""Followings and favourites, and the feed of listings from followed orgs.

The concept's "stay connected to the people and brands you love": follow an
organisation, save a listing, and see what the organisations you follow have on.
All of it is the personal layer, so all of it needs a token.
"""

from datetime import UTC, datetime
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, Response, status
from sqlalchemy import select

from app.api.deps import CurrentUser, DbSession
from app.api.routes.listings import enabled_types
from app.models import Listing, ListingStatus, Organisation
from app.schemas.listings import ListingPageOut, ListingSummaryOut
from app.schemas.social import FavouritesOut, FollowedOrganisationOut, FollowerCountOut
from app.services import countries, listings, social

router = APIRouter(prefix="/v1/me", tags=["following"])


@router.get("/follows", response_model=list[FollowedOrganisationOut])
def list_follows(user: CurrentUser, db: DbSession) -> list[FollowedOrganisationOut]:
    orgs = social.followed_organisations(db, user)
    counts = social.follower_counts(db, [o.id for o in orgs])
    return [
        FollowedOrganisationOut(
            id=o.id,
            name=o.name,
            slug=o.slug,
            instagram=o.instagram,
            follower_count=counts.get(o.id, 0),
        )
        for o in orgs
    ]


@router.put("/follows/{organisation_id}", status_code=status.HTTP_204_NO_CONTENT)
def follow_organisation(organisation_id: UUID, user: CurrentUser, db: DbSession) -> Response:
    """Follow an organisation. Idempotent, so a double tap is harmless."""
    if db.get(Organisation, organisation_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Organisation not found")
    social.follow(db, user, organisation_id)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("/follows/{organisation_id}", status_code=status.HTTP_204_NO_CONTENT)
def unfollow_organisation(organisation_id: UUID, user: CurrentUser, db: DbSession) -> Response:
    """Unfollow. Also idempotent: unfollowing what you don't follow is fine."""
    social.unfollow(db, user, organisation_id)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/follows/listings", response_model=ListingPageOut)
def listings_from_followed(
    user: CurrentUser,
    db: DbSession,
    upcoming_only: bool = True,
    limit: int = Query(50, ge=1, le=listings.MAX_LIMIT),
    offset: int = Query(0, ge=0),
) -> ListingPageOut:
    """What the organisations you follow have on — the concept's feed of
    updates from followed orgs."""
    org_ids = social.followed_organisation_ids(db, user)
    if not org_ids:
        return ListingPageOut(total=0, limit=limit, offset=offset, results=[])
    f = listings.Filters(
        organisation_ids=org_ids,
        country_code=countries.default_code(),
        starts_after=datetime.now(UTC) if upcoming_only else None,
        limit=limit,
        offset=offset,
    )
    f.types = enabled_types(db, f)
    if not f.types:
        return ListingPageOut(total=0, limit=limit, offset=offset, results=[])
    return ListingPageOut(
        total=listings.count(db, f),
        limit=limit,
        offset=offset,
        results=[
            ListingSummaryOut.model_validate(r, from_attributes=True)
            for r in listings.discover(db, f)
        ],
    )


@router.get("/favourites", response_model=FavouritesOut)
def list_favourites(user: CurrentUser, db: DbSession) -> FavouritesOut:
    """Saved listings, most recently saved first.

    Unlike discovery this does not hide what is no longer published: something
    you saved that got cancelled is exactly what you want to be told about.
    """
    saved = social.favourites(db, user)
    return FavouritesOut(
        total=len(saved),
        results=[ListingSummaryOut.model_validate(r, from_attributes=True) for r in saved],
    )


@router.put("/favourites/{listing_id}", status_code=status.HTTP_204_NO_CONTENT)
def add_favourite(listing_id: UUID, user: CurrentUser, db: DbSession) -> Response:
    """Save a listing. Only something published can be saved."""
    listing = db.get(Listing, listing_id)
    if listing is None or listing.status != ListingStatus.published:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Listing not found")
    social.add_favourite(db, user, listing_id)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("/favourites/{listing_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_favourite(listing_id: UUID, user: CurrentUser, db: DbSession) -> Response:
    social.remove_favourite(db, user, listing_id)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


public = APIRouter(prefix="/v1", tags=["following"])


@public.get("/organisations/{slug}/followers", response_model=FollowerCountOut)
def organisation_followers(slug: str, db: DbSession) -> FollowerCountOut:
    """How many people follow this organisation. Public, like the count on a
    profile page."""
    org = db.scalar(select(Organisation).where(Organisation.slug == slug))
    if org is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Organisation not found")
    return FollowerCountOut(slug=org.slug, follower_count=social.follower_count(db, org.id))
