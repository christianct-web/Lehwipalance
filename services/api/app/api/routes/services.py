"""Service listings: the vendor directory's own management endpoints.

Events have a rich, event-shaped API (tiers, sellers, the gate). A service has
none of that — no inventory, no date, no checkout — so it gets its own
endpoints rather than being bent into the event ones. Each category added in
Phase C does the same, because the details genuinely differ; what they share
already lives on `listings`.
"""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import exists, select
from sqlalchemy.orm import Session

from app.api.deps import AnyMember, DbSession, OrgAdmin
from app.models import (
    Listing,
    ListingStatus,
    ListingTag,
    ListingType,
    ServiceListing,
)
from app.schemas.services import ServiceIn, ServiceOut, ServicePatch
from app.services import countries, listings
from app.services.codes import slugify, with_suffix

router = APIRouter(prefix="/v1/orgs", tags=["services"])


def _unique_slug(db: Session, text: str) -> str:
    """Slugs are unique across every category, so the check is on Listing."""
    slug = slugify(text, 160)
    while db.scalar(select(exists().where(Listing.slug == slug))):
        slug = with_suffix(slug[:153])
    return slug


def _get(db: Session, org_id: UUID, listing_id: UUID) -> ServiceListing:
    service = db.get(ServiceListing, listing_id)
    if service is None or service.organisation_id != org_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Service not found")
    return service


def _apply(service: ServiceListing, values: dict) -> None:
    tags = values.pop("tags", None)
    for key, value in values.items():
        setattr(service, key, value)
    if tags is not None:
        service.tags = sorted({t for t in (ListingTag.normalise(t) for t in tags) if t})


@router.get("/{org_id}/services", response_model=list[ServiceOut])
def list_services(
    org_id: UUID,
    member: AnyMember,
    db: DbSession,
    status_filter: Annotated[ListingStatus | None, Query(alias="status")] = None,
) -> list[ServiceListing]:
    """Everything this organisation offers, drafts included."""
    stmt = select(ServiceListing).where(ServiceListing.organisation_id == org_id)
    if status_filter is not None:
        stmt = stmt.where(ServiceListing.status == status_filter)
    return list(db.scalars(stmt.order_by(ServiceListing.title)).unique())


@router.post("/{org_id}/services", response_model=ServiceOut, status_code=status.HTTP_201_CREATED)
def create_service(
    org_id: UUID, body: ServiceIn, member: OrgAdmin, db: DbSession
) -> ServiceListing:
    code = countries.default_code()
    if not countries.allows(db, code, ListingType.service):
        raise HTTPException(409, f"Services are not available in {code} yet")
    values = body.model_dump()
    tags = values.pop("tags", [])
    service = ServiceListing(
        **values,
        organisation_id=org_id,
        status=ListingStatus.draft,
        country_code=code,
        slug=_unique_slug(db, body.title),
    )
    service.tags = sorted({t for t in (ListingTag.normalise(t) for t in tags) if t})
    db.add(service)
    db.flush()
    listings.refresh_price_range(db, service.id)
    db.commit()
    return service


@router.get("/{org_id}/services/{listing_id}", response_model=ServiceOut)
def get_service(org_id: UUID, listing_id: UUID, member: AnyMember, db: DbSession) -> ServiceListing:
    return _get(db, org_id, listing_id)


@router.patch("/{org_id}/services/{listing_id}", response_model=ServiceOut)
def update_service(
    org_id: UUID, listing_id: UUID, body: ServicePatch, member: OrgAdmin, db: DbSession
) -> ServiceListing:
    service = _get(db, org_id, listing_id)
    values = body.model_dump(exclude_unset=True)
    if "title" in values and values["title"] is None:
        raise HTTPException(422, "title cannot be null")
    # The price model and its figure have to stay coherent after a partial
    # edit, not only when they arrive together.
    model = values.get("price_model", service.price_model)
    base = values.get("base_price_minor", service.base_price_minor)
    if model == "quote_only" or str(model) == "quote_only":
        if base is not None:
            raise HTTPException(422, "a quote-only service cannot publish a price")
    elif base is None:
        raise HTTPException(422, f"a {model} price needs base_price_minor")
    _apply(service, values)
    db.flush()
    listings.refresh_price_range(db, service.id)
    db.commit()
    return service


@router.post("/{org_id}/services/{listing_id}/publish", response_model=ServiceOut)
def publish_service(
    org_id: UUID, listing_id: UUID, member: OrgAdmin, db: DbSession
) -> ServiceListing:
    """List it in the directory.

    A service has no tiers to require and no start time to be in the future, so
    the bar is that an organiser can tell what is on offer: a description.
    """
    service = _get(db, org_id, listing_id)
    if service.status == ListingStatus.published:
        return service
    if not (service.description or "").strip():
        raise HTTPException(409, "Add a description before listing this service")
    service.status = ListingStatus.published
    db.commit()
    return service


@router.post("/{org_id}/services/{listing_id}/unpublish", response_model=ServiceOut)
def unpublish_service(
    org_id: UUID, listing_id: UUID, member: OrgAdmin, db: DbSession
) -> ServiceListing:
    """Take it out of the directory, back to a draft.

    Not "cancel": a service is an ongoing offering, not an occasion. Inquiries
    already sent are left alone — withdrawing the listing does not withdraw the
    conversations.
    """
    service = _get(db, org_id, listing_id)
    service.status = ListingStatus.draft
    db.commit()
    return service
