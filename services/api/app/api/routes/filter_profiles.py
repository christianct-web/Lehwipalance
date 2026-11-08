"""Filter profiles and the "For You" feed.

From docs/original-concept.md: a logged-in customer keeps several saved sets of
discovery preferences, one per country or city, and switches between them to
change what the feed shows. Browsing without an account is still open — that is
`/v1/listings`; this is the personal layer, so everything here needs a token.
"""

from typing import Any
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, Response, status
from sqlalchemy import exists, select
from sqlalchemy.orm import Session

from app.api.deps import CurrentUser, DbSession
from app.api.routes.listings import enabled_types
from app.models import FilterProfile, ListingTag
from app.schemas.filter_profiles import (
    FeedOut,
    FilterProfileIn,
    FilterProfileOut,
    FilterProfilePatch,
)
from app.schemas.listings import ListingSummaryOut
from app.services import countries, filter_profiles, listings

router = APIRouter(prefix="/v1/me/filter-profiles", tags=["filter profiles"])


def _live_market_or_422(db: Session, code: str) -> str:
    code = code.upper()
    country = countries.get(db, code)
    if country is None or not country.is_live:
        raise HTTPException(422, f"{code} is not a market we serve yet")
    return code


def _mine(db: Session, user: CurrentUser, profile_id: UUID) -> FilterProfile:
    profile = db.get(FilterProfile, profile_id)
    # 404 rather than 403 for someone else's profile: ids shouldn't be probeable.
    if profile is None or profile.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Filter profile not found")
    return profile


def _name_is_free(db: Session, user_id: UUID, name: str, exclude: UUID | None = None) -> bool:
    stmt = select(FilterProfile.id).where(
        FilterProfile.user_id == user_id, FilterProfile.name == name
    )
    if exclude is not None:
        stmt = stmt.where(FilterProfile.id != exclude)
    return not db.scalar(select(exists(stmt)))


def _clean(values: dict[str, Any]) -> dict[str, Any]:
    """Normalise what goes into the row: enum values for JSON columns, tags the
    same way a listing's tags are normalised so the two actually match."""
    if "listing_types" in values:
        values["listing_types"] = sorted({str(t) for t in values["listing_types"]})
    if "tags" in values:
        seen = {ListingTag.normalise(t) for t in values["tags"]}
        values["tags"] = sorted(t for t in seen if t)
    if values.get("sort") is not None and values["sort"] not in listings.Sort.all:
        raise HTTPException(422, f"sort must be one of {', '.join(listings.Sort.all)}")
    return values


@router.get("", response_model=list[FilterProfileOut])
def list_profiles(user: CurrentUser, db: DbSession) -> list[FilterProfile]:
    return filter_profiles.for_user(db, user)


@router.post("", response_model=FilterProfileOut, status_code=status.HTTP_201_CREATED)
def create_profile(body: FilterProfileIn, user: CurrentUser, db: DbSession) -> FilterProfile:
    existing = filter_profiles.for_user(db, user)
    if len(existing) >= filter_profiles.MAX_PER_USER:
        raise HTTPException(409, f"At most {filter_profiles.MAX_PER_USER} filter profiles")
    if not _name_is_free(db, user.id, body.name):
        raise HTTPException(409, f"You already have a profile called {body.name!r}")

    values = _clean(body.model_dump(exclude={"activate"}))
    values["country_code"] = _live_market_or_422(db, values["country_code"])
    profile = FilterProfile(**values, user_id=user.id)
    db.add(profile)
    db.flush()
    # The first profile someone makes is the one driving their feed; there is
    # nothing else it could be.
    if body.activate or not existing:
        filter_profiles.activate(db, profile)
    db.commit()
    return profile


@router.get("/{profile_id}", response_model=FilterProfileOut)
def get_profile(profile_id: UUID, user: CurrentUser, db: DbSession) -> FilterProfile:
    return _mine(db, user, profile_id)


@router.patch("/{profile_id}", response_model=FilterProfileOut)
def update_profile(
    profile_id: UUID, body: FilterProfilePatch, user: CurrentUser, db: DbSession
) -> FilterProfile:
    profile = _mine(db, user, profile_id)
    values = _clean(body.model_dump(exclude_unset=True))
    if "name" in values:
        if values["name"] is None:
            raise HTTPException(422, "name cannot be null")
        if not _name_is_free(db, user.id, values["name"], exclude=profile.id):
            raise HTTPException(409, f"You already have a profile called {values['name']!r}")
    if values.get("country_code") is not None:
        values["country_code"] = _live_market_or_422(db, values["country_code"])
    elif "country_code" in values:
        del values["country_code"]
    for key, value in values.items():
        setattr(profile, key, value)
    db.commit()
    return profile


@router.post("/{profile_id}/activate", response_model=FilterProfileOut)
def activate_profile(profile_id: UUID, user: CurrentUser, db: DbSession) -> FilterProfile:
    """Switch the feed to this profile."""
    profile = _mine(db, user, profile_id)
    filter_profiles.activate(db, profile)
    db.commit()
    return profile


@router.delete("/{profile_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_profile(profile_id: UUID, user: CurrentUser, db: DbSession) -> Response:
    profile = _mine(db, user, profile_id)
    was_active = profile.is_active
    db.delete(profile)
    db.flush()
    # Never leave someone with profiles but no active one, or the feed has
    # nothing to run.
    if was_active:
        remaining = filter_profiles.for_user(db, user)
        if remaining:
            filter_profiles.activate(db, remaining[0])
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/{profile_id}/feed", response_model=FeedOut)
def profile_feed(
    profile_id: UUID,
    user: CurrentUser,
    db: DbSession,
    limit: int = Query(50, ge=1, le=listings.MAX_LIMIT),
    offset: int = Query(0, ge=0),
) -> FeedOut:
    """What this profile is asking for right now."""
    return _feed(db, _mine(db, user, profile_id), limit, offset)


def _feed(db: Session, profile: FilterProfile, limit: int, offset: int) -> FeedOut:
    f = filter_profiles.to_filters(db, profile, limit=limit, offset=offset)
    f.types = enabled_types(db, f)
    results = listings.discover(db, f) if f.types else []
    return FeedOut(
        profile=FilterProfileOut.model_validate(profile, from_attributes=True),
        resolved_starts_after=f.starts_after,
        resolved_starts_before=f.starts_before,
        total=listings.count(db, f) if f.types else 0,
        limit=limit,
        offset=offset,
        results=[ListingSummaryOut.model_validate(r, from_attributes=True) for r in results],
    )


feed_router = APIRouter(prefix="/v1/me", tags=["filter profiles"])


@feed_router.get("/feed", response_model=FeedOut)
def my_feed(
    user: CurrentUser,
    db: DbSession,
    limit: int = Query(50, ge=1, le=listings.MAX_LIMIT),
    offset: int = Query(0, ge=0),
) -> FeedOut:
    """The "For You" feed: the active profile's query, resolved as of now.

    With no profiles saved there is nothing to resolve, so this is a 404 and the
    client shows the unfiltered listings instead — the concept's toggle between
    all listings and filtered ones.
    """
    profile = filter_profiles.active(db, user)
    if profile is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, "No active filter profile. Browse /v1/listings instead."
        )
    return _feed(db, profile, limit, offset)
