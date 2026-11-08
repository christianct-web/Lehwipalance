"""Accommodation: listing a property, its rooms, availability and stays.

Rooms are the second shape of `Offer`, and the reason it exists: a room sold
for Friday is free again on Saturday, so availability is per night rather than
a pool that depletes. The arithmetic lives in `app.services.bookings`.
"""

import secrets
from datetime import date, timedelta
from typing import Annotated
from uuid import UUID

from fastapi import (
    APIRouter,
    BackgroundTasks,
    Depends,
    HTTPException,
    Query,
    Response,
    status,
)
from sqlalchemy import exists, select
from sqlalchemy.orm import Session

from app.api.deps import AnyMember, DbSession, OptionalUser, OrgAdmin
from app.core.config import get_settings
from app.core.ratelimit import rate_limit
from app.models import (
    AccommodationListing,
    Booking,
    Listing,
    ListingStatus,
    ListingTag,
    ListingType,
    Offer,
    Order,
    RoomType,
)
from app.schemas.accommodation import (
    AvailabilityOut,
    BookingOut,
    PlaceIn,
    PlaceOut,
    PlacePatch,
    RoomAvailabilityOut,
    RoomIn,
    RoomOut,
    RoomPatch,
    StayIn,
    StayOut,
    StayPlaceOut,
)
from app.services import bookings, countries, listings, payments
from app.services.codes import slugify, with_suffix
from app.services.orders import Buyer, SaleError

# How far ahead availability can be asked for in one call.
MAX_WINDOW_NIGHTS = 90

manage = APIRouter(prefix="/v1/orgs", tags=["accommodation"])
public = APIRouter(prefix="/v1", tags=["accommodation"])


def _sale_error(e: SaleError) -> HTTPException:
    return HTTPException(e.status_code, e.detail)


# ---------- The property's own endpoints ----------


def _unique_slug(db: Session, text: str) -> str:
    slug = slugify(text, 160)
    while db.scalar(select(exists().where(Listing.slug == slug))):
        slug = with_suffix(slug[:153])
    return slug


def _rooms(db: Session, listing_id: UUID) -> list[RoomType]:
    return list(
        db.scalars(
            select(RoomType)
            .where(RoomType.listing_id == listing_id)
            .order_by(RoomType.sort_order, RoomType.name)
        ).unique()
    )


def _place_out(db: Session, place: AccommodationListing) -> PlaceOut:
    return PlaceOut(
        **{
            k: getattr(place, k)
            for k in (
                "id",
                "slug",
                "title",
                "description",
                "country_code",
                "city",
                "venue_name",
                "address",
                "latitude",
                "longitude",
                "cover_image_url",
                "check_in_after",
                "check_out_before",
                "price_min_minor",
                "price_max_minor",
                "rating_count",
            )
        },
        status=place.status.value,
        property_type=place.property_type.value,
        tags=list(place.tags),
        rating_average=place.rating_average,
        rooms=[RoomOut.model_validate(r, from_attributes=True) for r in _rooms(db, place.id)],
    )


def _get(db: Session, org_id: UUID, listing_id: UUID) -> AccommodationListing:
    place = db.get(AccommodationListing, listing_id)
    if place is None or place.organisation_id != org_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Place not found")
    return place


@manage.get("/{org_id}/places", response_model=list[PlaceOut])
def list_places(org_id: UUID, member: AnyMember, db: DbSession) -> list[PlaceOut]:
    places = db.scalars(
        select(AccommodationListing)
        .where(AccommodationListing.organisation_id == org_id)
        .order_by(AccommodationListing.title)
    ).unique()
    return [_place_out(db, p) for p in places]


@manage.post("/{org_id}/places", response_model=PlaceOut, status_code=status.HTTP_201_CREATED)
def create_place(org_id: UUID, body: PlaceIn, member: OrgAdmin, db: DbSession) -> PlaceOut:
    code = countries.default_code()
    if not countries.allows(db, code, ListingType.accommodation):
        raise HTTPException(409, f"Accommodation is not available in {code} yet")
    values = body.model_dump()
    tags = values.pop("tags", [])
    place = AccommodationListing(
        **values,
        organisation_id=org_id,
        status=ListingStatus.draft,
        country_code=code,
        slug=_unique_slug(db, body.title),
    )
    place.tags = sorted({t for t in (ListingTag.normalise(t) for t in tags) if t})
    db.add(place)
    db.commit()
    return _place_out(db, place)


@manage.get("/{org_id}/places/{listing_id}", response_model=PlaceOut)
def get_place(org_id: UUID, listing_id: UUID, member: AnyMember, db: DbSession) -> PlaceOut:
    return _place_out(db, _get(db, org_id, listing_id))


@manage.patch("/{org_id}/places/{listing_id}", response_model=PlaceOut)
def update_place(
    org_id: UUID, listing_id: UUID, body: PlacePatch, member: OrgAdmin, db: DbSession
) -> PlaceOut:
    place = _get(db, org_id, listing_id)
    values = body.model_dump(exclude_unset=True)
    if "title" in values and values["title"] is None:
        raise HTTPException(422, "title cannot be null")
    tags = values.pop("tags", None)
    for key, value in values.items():
        setattr(place, key, value)
    if tags is not None:
        place.tags = sorted({t for t in (ListingTag.normalise(t) for t in tags) if t})
    db.commit()
    return _place_out(db, place)


@manage.post("/{org_id}/places/{listing_id}/publish", response_model=PlaceOut)
def publish_place(org_id: UUID, listing_id: UUID, member: OrgAdmin, db: DbSession) -> PlaceOut:
    """List it. There must be somewhere to actually stay."""
    place = _get(db, org_id, listing_id)
    if place.status == ListingStatus.published:
        return _place_out(db, place)
    if not _rooms(db, place.id):
        raise HTTPException(409, "Add at least one room before listing this place")
    if not (place.description or "").strip():
        raise HTTPException(409, "Add a description before listing this place")
    place.status = ListingStatus.published
    db.commit()
    return _place_out(db, place)


@manage.post("/{org_id}/places/{listing_id}/unpublish", response_model=PlaceOut)
def unpublish_place(org_id: UUID, listing_id: UUID, member: OrgAdmin, db: DbSession) -> PlaceOut:
    """Take it off the market, back to a draft. Bookings already taken stand —
    a property going unlisted does not cancel someone's stay."""
    place = _get(db, org_id, listing_id)
    place.status = ListingStatus.draft
    db.commit()
    return _place_out(db, place)


# ---------- Rooms ----------


@manage.post(
    "/{org_id}/places/{listing_id}/rooms",
    response_model=PlaceOut,
    status_code=status.HTTP_201_CREATED,
)
def create_room(
    org_id: UUID, listing_id: UUID, body: RoomIn, member: OrgAdmin, db: DbSession
) -> PlaceOut:
    place = _get(db, org_id, listing_id)
    currency = countries.fee_config(db, place.country_code).currency
    db.add(RoomType(**body.model_dump(), listing_id=place.id, currency=currency))
    db.flush()
    listings.refresh_price_range(db, place.id)
    db.commit()
    return _place_out(db, place)


def _room_of(db: Session, place: AccommodationListing, room_id: UUID) -> RoomType:
    room = db.get(RoomType, room_id)
    if room is None or room.listing_id != place.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Room not found")
    return room


@manage.patch("/{org_id}/places/{listing_id}/rooms/{room_id}", response_model=PlaceOut)
def update_room(
    org_id: UUID,
    listing_id: UUID,
    room_id: UUID,
    body: RoomPatch,
    member: OrgAdmin,
    db: DbSession,
) -> PlaceOut:
    place = _get(db, org_id, listing_id)
    room = _room_of(db, place, room_id)
    values = {k: v for k, v in body.model_dump(exclude_unset=True).items() if v is not None}
    if "units" in values:
        # Cutting rooms below what is already booked would oversell a night.
        taken = bookings.nightly_taken(
            db, room.id, date.today(), date.today() + timedelta(days=MAX_WINDOW_NIGHTS)
        )
        worst = max(taken.values(), default=0)
        if values["units"] < worst:
            raise HTTPException(
                409, f"{worst} of these are booked on at least one night; units can't go below that"
            )
    for key, value in values.items():
        setattr(room, key, value)
    db.flush()
    listings.refresh_price_range(db, place.id)
    db.commit()
    return _place_out(db, place)


@manage.delete(
    "/{org_id}/places/{listing_id}/rooms/{room_id}", status_code=status.HTTP_204_NO_CONTENT
)
def delete_room(
    org_id: UUID, listing_id: UUID, room_id: UUID, member: OrgAdmin, db: DbSession
) -> Response:
    place = _get(db, org_id, listing_id)
    room = _room_of(db, place, room_id)
    if db.scalar(select(exists().where(Booking.offer_id == room.id))):
        raise HTTPException(409, "This room has bookings; set its units or price instead")
    db.delete(room)
    db.flush()
    listings.refresh_price_range(db, place.id)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# ---------- Availability ----------


@public.get("/listings/{slug}/availability", response_model=AvailabilityOut)
def availability(
    slug: str,
    db: DbSession,
    stay_start: date,
    stay_end: date,
    guests: Annotated[int, Query(ge=1, le=100)] = 1,
    rooms: Annotated[int, Query(ge=1, le=20)] = 1,
) -> AvailabilityOut:
    """What is free for these nights, and what it would cost."""
    place = db.scalar(
        select(AccommodationListing).where(
            AccommodationListing.slug == slug,
            AccommodationListing.status == ListingStatus.published,
        )
    )
    if place is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Place not found")
    if stay_end <= stay_start:
        raise HTTPException(422, "stay_end must be after stay_start")
    nights = (stay_end - stay_start).days
    if nights > MAX_WINDOW_NIGHTS:
        raise HTTPException(422, f"At most {MAX_WINDOW_NIGHTS} nights per request")

    out = []
    for room in _rooms(db, place.id):
        free = bookings.available(db, room, stay_start, stay_end)
        priced = bookings.quote(db, room, stay_start, stay_end, rooms)
        reason = None
        if nights < room.min_nights:
            reason = f"{room.min_nights}-night minimum"
        elif guests > room.max_guests * rooms:
            reason = f"sleeps {room.max_guests} per room"
        elif free < rooms:
            reason = "fully booked" if free == 0 else f"only {free} left"
        out.append(
            RoomAvailabilityOut(
                room=RoomOut.model_validate(room, from_attributes=True),
                available=free,
                nights=nights,
                subtotal_minor=priced.subtotal_minor,
                buyer_fee_minor=priced.buyer_fee_minor,
                total_minor=priced.total_minor,
                currency=priced.currency,
                unavailable_reason=reason,
            )
        )
    return AvailabilityOut(
        listing_slug=place.slug,
        stay_start=stay_start,
        stay_end=stay_end,
        nights=nights,
        rooms=out,
    )


# ---------- Taking a stay ----------


def _stay_out(
    db: Session, order: Order, booking: Booking, checkout_url: str | None = None
) -> StayOut:
    place = db.get(AccommodationListing, order.listing_id)
    room = db.get(Offer, booking.offer_id)
    return StayOut(
        id=order.id,
        status=order.status.value,
        place=StayPlaceOut(
            title=place.title,
            slug=place.slug,
            city=place.city,
            address=place.address,
            check_in_after=place.check_in_after,
            check_out_before=place.check_out_before,
        ),
        booking=BookingOut(
            id=booking.id,
            code=booking.code,
            status=booking.status.value,
            stay_start=booking.stay_start,
            stay_end=booking.stay_end,
            nights=booking.nights,
            rooms=booking.rooms,
            guests=booking.guests,
            checked_in_at=booking.checked_in_at,
            checked_out_at=booking.checked_out_at,
        ),
        room_name=room.name if room else "Room",
        currency=order.currency,
        subtotal_minor=order.subtotal_minor,
        buyer_fee_minor=order.buyer_fee_minor,
        total_minor=order.total_minor,
        buyer_name=order.buyer_name,
        buyer_email=order.buyer_email,
        created_at=order.created_at,
        expires_at=order.expires_at,
        paid_at=order.paid_at,
        access_token=order.access_token or "",
        is_test=order.is_test,
        checkout_url=checkout_url,
    )


@public.post(
    "/stays",
    response_model=StayOut,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(rate_limit("stays", 20, 60))],
)
def book_stay(body: StayIn, db: DbSession, user: OptionalUser) -> StayOut:
    """Book a stay. Guest checkout, like a ticket: no account needed."""
    place = db.scalar(
        select(AccommodationListing).where(
            AccommodationListing.slug == body.listing_slug,
            AccommodationListing.status == ListingStatus.published,
        )
    )
    if place is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Place not found")
    room = db.get(RoomType, body.room_type_id)
    if room is None or room.listing_id != place.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Room not found")
    try:
        order, booking = bookings.place(
            db,
            listing=place,
            room=room,
            start=body.stay_start,
            end=body.stay_end,
            rooms=body.rooms,
            guests=body.guests,
            buyer=Buyer(
                name=body.buyer_name,
                email=body.buyer_email,
                phone=body.buyer_phone,
                user_id=user.id if user else None,
            ),
        )
    except SaleError as e:
        db.rollback()
        raise _sale_error(e) from None
    url = (
        payments.get_provider().create_checkout(order) if order.status.value == "pending" else None
    )
    db.commit()
    return _stay_out(db, order, booking, url)


@public.get("/stays/{order_id}", response_model=StayOut)
def get_stay(order_id: UUID, db: DbSession, token: Annotated[str, Query()]) -> StayOut:
    order = db.get(Order, order_id)
    if order is None or not order.access_token or order.access_token != token:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Stay not found")
    booking = bookings.booking_of(db, order_id)
    if booking is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Stay not found")
    return _stay_out(db, order, booking)


@public.post("/payments/test/stays/{order_id}", response_model=StayOut)
def complete_test_stay_payment(
    order_id: UUID,
    token: Annotated[str, Query()],
    db: DbSession,
    background: BackgroundTasks,
    outcome: Annotated[str, Query(pattern="^(paid|failed)$")] = "paid",
) -> StayOut:
    """The test provider settling a stay.

    Separate from the ticket endpoint on purpose: that one is the
    revenue-critical path and emails tickets. When WiPay is wired there will be
    one real callback URL, and it will have to dispatch on the listing's type —
    noted in docs/roadmap.md so it is designed rather than discovered.
    """
    if not get_settings().test_payments:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not found")
    order = db.get(Order, order_id)
    if order is None or not order.access_token or order.access_token != token:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Stay not found")
    reference = f"TEST-{secrets.token_hex(6).upper()}"
    try:
        if outcome == "paid":
            order = bookings.confirm(db, order_id, reference)
        else:
            order = bookings.fail(db, order_id, reference)
    except SaleError as e:
        db.rollback()
        raise _sale_error(e) from None
    db.commit()
    return _stay_out(db, order, bookings.booking_of(db, order_id))
