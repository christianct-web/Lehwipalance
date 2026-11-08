"""Demo content for Trinidad & Tobago, across every built category.

Why this exists: the placeholder listings were created ad hoc during the design
pass, and `switch-to-supabase.sh` does not copy rows — so the cutover would have
emptied the app. This makes the demo reproducible.

Everything here is **placeholder**. Names, prices and lineups are invented, no
real promoter or property has agreed to anything, and every description says so.
`PRODUCT.md` requires that any fete name, price or sales figure in the UI reads
as placeholder to anyone on the team.

Run it:
    docker compose -f docker-compose.prod.yml exec api python -m app.scripts.seed_demo
    docker compose -f docker-compose.prod.yml exec api python -m app.scripts.seed_demo --reset

Idempotent: listings and organisations are matched by slug, users by email, so
re-running updates rather than duplicating. `--reset` removes only what this
script owns, by that same slug and email list, and nothing else.
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass, field
from datetime import UTC, date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.db.session import SessionLocal
from app.models import (
    AccommodationListing,
    Booking,
    BookingStatus,
    Country,
    Event,
    EventCategory,
    Favourite,
    FilterProfile,
    Follow,
    Inquiry,
    InquiryStatus,
    Listing,
    ListingCollaborator,
    ListingStatus,
    ListingTag,
    MemberRole,
    Offer,
    Order,
    OrderItem,
    OrderStatus,
    Organisation,
    OrgMember,
    PriceModel,
    PropertyType,
    Review,
    ReviewSection,
    ReviewSectionRating,
    RoomType,
    SalesChannel,
    ServiceCategory,
    ServiceListing,
    Ticket,
    TicketStatus,
    TicketTier,
    User,
)
from app.services import listings as listing_service
from app.services import reviews as review_service
from app.services.orders import new_token

DEMO_PASSWORD = "demo-2027!"  # noqa: S105 - placeholder content, printed below
PLACEHOLDER = "PLACEHOLDER listing for design and demo only. Not a real offering.\n\n"

# Carnival 2027 is 8-9 February. The fetes sit in the days before it so the
# season planner has something shaped like a real week.
TT_TIMEZONE = "America/Port_of_Spain"
CARNIVAL = date(2027, 2, 8)


def _at(days_before: int, hour: int, minute: int = 0) -> datetime:
    """A local Trinidad wall-clock time before Carnival, converted to UTC.

    Converted properly rather than by adding four hours: a 22:00 fete would
    overflow the day, and a late-night start belongs to the evening it began on
    — the same thing the calendar's local-day grouping exists to get right.
    """
    day = CARNIVAL - timedelta(days=days_before)
    local = datetime(day.year, day.month, day.day, hour, minute, tzinfo=ZoneInfo(TT_TIMEZONE))
    return local.astimezone(UTC)


@dataclass
class Tier:
    name: str
    price_minor: int
    quantity: int
    sort_order: int = 0


@dataclass
class Fete:
    slug: str
    title: str
    category: EventCategory
    days_before: int
    hour: int
    venue: str
    city: str
    latitude: float
    longitude: float
    blurb: str
    tiers: list[Tier]
    tags: list[str] = field(default_factory=list)


FETES = [
    Fete(
        "sunrise-cooler-cruise",
        "Sunrise Cooler Cruise",
        EventCategory.fete,
        4,
        5,
        "Chaguaramas Boardwalk",
        "Chaguaramas",
        10.6792,
        -61.6381,
        "Boat leaves at five. Bring your cooler, no glass. Soca from the top deck.",
        [Tier("Cooler", 45000, 300), Tier("Cooler + Drinks", 65000, 120, 1)],
        ["soca", "cooler", "boat", "carnival-2027"],
    ),
    Fete(
        "bassline-breakfast",
        "Bassline Breakfast",
        EventCategory.fete,
        4,
        4,
        "Queen's Park Savannah",
        "Port of Spain",
        10.6700,
        -61.5150,
        "Breakfast party on the Savannah. Doubles and coffee from four.",
        [Tier("General", 32000, 400), Tier("VIP Deck", 58000, 80, 1)],
        ["soca", "breakfast", "carnival-2027"],
    ),
    Fete(
        "steel-brass-night",
        "Steel & Brass Night",
        EventCategory.concert,
        2,
        20,
        "Grand Stand, Queen's Park Savannah",
        "Port of Spain",
        10.6668,
        -61.5180,
        "Panorama warm-up. Full orchestras and a brass section.",
        [Tier("Entry", 25000, 600), Tier("Reserved Seat", 48000, 150, 1)],
        ["pan", "steelband", "carnival-2027"],
    ),
    Fete(
        "vale-lime",
        "Vale Lime",
        EventCategory.fete,
        2,
        22,
        "Santa Cruz",
        "Santa Cruz",
        10.6830,
        -61.4690,
        "Valley lime under the bamboo. Cooler rules apply.",
        [Tier("Cooler", 28000, 250)],
        ["cooler", "lime", "carnival-2027"],
    ),
    Fete(
        "the-all-inclusive",
        "The All-Inclusive",
        EventCategory.fete,
        2,
        16,
        "Hyatt Lawn",
        "Port of Spain",
        10.6471,
        -61.5133,
        "Premium all-inclusive. Food stations, open bar, no cooler.",
        [Tier("All-Inclusive", 155000, 220), Tier("Premium", 210000, 60, 1)],
        ["all inclusive", "premium", "carnival-2027"],
    ),
    Fete(
        "pan-yard-session",
        "Pan Yard Session",
        EventCategory.concert,
        2,
        19,
        "Woodbrook Panyard",
        "Port of Spain",
        10.6600,
        -61.5250,
        "Open yard rehearsal. Free to walk in, pay for the bar.",
        [Tier("Entry", 12000, 250)],
        ["pan", "steelband", "carnival-2027"],
    ),
    Fete(
        "carnival-monday-breakfast",
        "Carnival Monday Breakfast",
        EventCategory.fete,
        0,
        5,
        "Maracas Bay",
        "Maracas",
        10.7542,
        -61.4350,
        "Monday morning on the north coast before j'ouvert washes off.",
        [Tier("General", 38000, 300), Tier("Cabana", 95000, 24, 1)],
        ["soca", "breakfast", "beach", "carnival-2027"],
    ),
    Fete(
        "las-lap-cooldown",
        "Las Lap Cooldown",
        EventCategory.fete,
        -1,
        18,
        "Ariapita Avenue",
        "Port of Spain",
        10.6617,
        -61.5261,
        "Free cooldown on the Avenue when it is all over. RSVP so we can count heads.",
        [Tier("RSVP", 0, 500)],
        ["lime", "free", "carnival-2027"],
    ),
]


@dataclass
class Svc:
    slug: str
    title: str
    category: ServiceCategory
    price_model: PriceModel
    base_price_minor: int | None
    min_notice_days: int | None
    city: str
    latitude: float
    longitude: float
    blurb: str
    tags: list[str]


SERVICES = [
    Svc(
        "doubles-roti-catering",
        "Doubles & Roti Catering",
        ServiceCategory.catering,
        PriceModel.per_person,
        8500,
        7,
        "Port of Spain",
        10.6617,
        -61.5261,
        "Hot doubles, bake and shark, buss-up-shut. Fifty to five hundred guests.",
        ["doubles", "creole", "carnival-2027"],
    ),
    Svc(
        "northside-sound-crew",
        "Northside Sound Crew",
        ServiceCategory.av_production,
        PriceModel.from_,
        450000,
        14,
        "Port of Spain",
        10.6700,
        -61.5150,
        "Line array, monitors and a crew who have run Savannah shows.",
        ["sound", "stage", "carnival-2027"],
    ),
    Svc(
        "savannah-lens-photography",
        "Savannah Lens Photography",
        ServiceCategory.photography,
        PriceModel.hourly,
        35000,
        3,
        "Port of Spain",
        10.6668,
        -61.5180,
        "Two photographers, same-night edits for socials.",
        ["photography", "carnival-2027"],
    ),
    Svc(
        "leh-we-plan-events",
        "Leh We Plan Events",
        ServiceCategory.planning,
        PriceModel.quote_only,
        None,
        30,
        "Port of Spain",
        10.6549,
        -61.5019,
        "Full-service fete production: permits, vendors, staffing, the lot.",
        ["planning", "production"],
    ),
    Svc(
        "bamboo-decor-co",
        "Bamboo Decor Co",
        ServiceCategory.decor,
        PriceModel.from_,
        180000,
        10,
        "Santa Cruz",
        10.6830,
        -61.4690,
        "Bamboo structures, lighting and dressing for outdoor limes.",
        ["decor", "lighting"],
    ),
    Svc(
        "gate-crew-security",
        "Gate Crew Security",
        ServiceCategory.security,
        PriceModel.hourly,
        9000,
        7,
        "Port of Spain",
        10.6617,
        -61.5261,
        "SIA-trained door and perimeter staff, wristband and scanner experience.",
        ["security", "gate"],
    ),
    Svc(
        "island-shuttle-transport",
        "Island Shuttle Transport",
        ServiceCategory.transport,
        PriceModel.per_person,
        12000,
        5,
        "Port of Spain",
        10.6549,
        -61.5019,
        "Return shuttles from POS to north coast and Chaguaramas fetes.",
        ["transport", "shuttle", "carnival-2027"],
    ),
]


@dataclass
class Room:
    name: str
    price_minor: int
    units: int
    max_guests: int
    min_nights: int = 1
    sort_order: int = 0


@dataclass
class Place:
    slug: str
    title: str
    property_type: PropertyType
    city: str
    latitude: float
    longitude: float
    blurb: str
    rooms: list[Room]
    tags: list[str]


PLACES = [
    Place(
        "maracas-bay-guesthouse",
        "Maracas Bay Guesthouse",
        PropertyType.guesthouse,
        "Maracas",
        10.7542,
        -61.4350,
        "Five minutes from the beach, breakfast included, cold water shower outside.",
        [
            Room("Standard Double", 45000, 4, 2),
            Room("Sea View Suite", 90000, 2, 4, min_nights=2, sort_order=1),
        ],
        ["beach", "breakfast", "carnival-2027"],
    ),
    Place(
        "woodbrook-carnival-apartments",
        "Woodbrook Carnival Apartments",
        PropertyType.apartment,
        "Port of Spain",
        10.6617,
        -61.5261,
        "Walk to the Avenue and the Savannah. Three-night minimum over Carnival.",
        [
            Room("One Bedroom", 78000, 6, 2, min_nights=3),
            Room("Two Bedroom", 125000, 3, 4, min_nights=3, sort_order=1),
        ],
        ["carnival-2027", "walkable"],
    ),
    Place(
        "store-bay-villa",
        "Store Bay Villa",
        PropertyType.villa,
        "Scarborough",
        11.1811,
        -60.7394,
        "Tobago villa, pool, sleeps eight. Seven-night minimum in season.",
        [Room("Whole Villa", 320000, 1, 8, min_nights=7)],
        ["tobago", "pool", "villa"],
    ),
    Place(
        "pos-business-hotel",
        "POS Business Hotel",
        PropertyType.hotel,
        "Port of Spain",
        10.6500,
        -61.5180,
        "City hotel near the waterfront. Airport shuttle on request.",
        [
            Room("Queen", 68000, 20, 2),
            Room("Executive King", 98000, 8, 2, sort_order=1),
        ],
        ["city", "business"],
    ),
]

PROMOTER_ORG = ("Leh We Promotions", "leh-we-promotions")
VENDOR_ORG = ("Island Vendor Collective", "island-vendor-collective")
HOST_ORG = ("Coastline Stays", "coastline-stays")
COLLAB_ORG = ("Northside Sound", "northside-sound")

USERS = {
    "promoter": ("demo.promoter@lehwipalance.test", "Demo Promoter"),
    "vendor": ("demo.vendor@lehwipalance.test", "Demo Vendor"),
    "host": ("demo.host@lehwipalance.test", "Demo Host"),
    "collab": ("demo.sound@lehwipalance.test", "Demo Sound Crew"),
    "fan": ("demo.fan@lehwipalance.test", "Demo Fete Goer"),
}

# Everything this script owns, for --reset. Nothing outside these lists is touched.
OWNED_LISTING_SLUGS = (
    [f.slug for f in FETES]
    + [s.slug for s in SERVICES]
    + [p.slug for p in PLACES]
    + ["past-fete-for-reviews"]
)
OWNED_ORG_SLUGS = [PROMOTER_ORG[1], VENDOR_ORG[1], HOST_ORG[1], COLLAB_ORG[1]]
OWNED_EMAILS = [email for email, _ in USERS.values()]


# ---------- helpers ----------


def _user(db: Session, email: str, full_name: str) -> User:
    user = db.scalar(select(User).where(User.email == email))
    if user is None:
        user = User(email=email, full_name=full_name, password_hash=hash_password(DEMO_PASSWORD))
        db.add(user)
        db.flush()
    return user


def _org(db: Session, name: str, slug: str, owner: User) -> Organisation:
    org = db.scalar(select(Organisation).where(Organisation.slug == slug))
    if org is None:
        org = Organisation(name=name, slug=slug, contact_email=owner.email)
        db.add(org)
        db.flush()
    member = db.scalar(
        select(OrgMember).where(OrgMember.organisation_id == org.id, OrgMember.user_id == owner.id)
    )
    if member is None:
        db.add(OrgMember(organisation_id=org.id, user_id=owner.id, role=MemberRole.owner))
        db.flush()
    return org


def _tags(values: list[str]) -> list[str]:
    return sorted({t for t in (ListingTag.normalise(v) for v in values) if t})


def _find(db: Session, model, slug: str):
    return db.scalar(select(model).where(model.slug == slug))


# ---------- seeding ----------


def seed_fetes(db: Session, org: Organisation) -> list[Event]:
    out = []
    for f in FETES:
        event = _find(db, Event, f.slug)
        if event is None:
            event = Event(slug=f.slug, organisation_id=org.id)
            db.add(event)
        event.title = f.title
        event.category = f.category
        event.status = ListingStatus.published
        event.country_code = "TT"
        event.description = PLACEHOLDER + f.blurb
        event.venue_name = f.venue
        event.city = f.city
        event.address = "Trinidad"
        event.latitude = f.latitude
        event.longitude = f.longitude
        event.starts_at = _at(f.days_before, f.hour)
        event.tags = _tags(f.tags)
        db.flush()
        for t in f.tiers:
            tier = db.scalar(
                select(TicketTier).where(
                    TicketTier.listing_id == event.id, TicketTier.name == t.name
                )
            )
            if tier is None:
                tier = TicketTier(listing_id=event.id, name=t.name, currency="TTD")
                db.add(tier)
            tier.price_minor = t.price_minor
            tier.quantity = t.quantity
            tier.sort_order = t.sort_order
            tier.max_per_order = 10
        db.flush()
        listing_service.refresh_price_range(db, event.id)
        out.append(event)
    return out


def seed_services(db: Session, org: Organisation) -> list[ServiceListing]:
    out = []
    for s in SERVICES:
        svc = _find(db, ServiceListing, s.slug)
        if svc is None:
            svc = ServiceListing(slug=s.slug, organisation_id=org.id)
            db.add(svc)
        svc.title = s.title
        svc.status = ListingStatus.published
        svc.country_code = "TT"
        svc.description = PLACEHOLDER + s.blurb
        svc.city = s.city
        svc.latitude = s.latitude
        svc.longitude = s.longitude
        svc.category = s.category
        svc.price_model = s.price_model
        svc.base_price_minor = s.base_price_minor
        svc.min_notice_days = s.min_notice_days
        svc.tags = _tags(s.tags)
        db.flush()
        listing_service.refresh_price_range(db, svc.id)
        out.append(svc)
    return out


def seed_places(db: Session, org: Organisation) -> list[AccommodationListing]:
    out = []
    for p in PLACES:
        place = _find(db, AccommodationListing, p.slug)
        if place is None:
            place = AccommodationListing(slug=p.slug, organisation_id=org.id)
            db.add(place)
        place.title = p.title
        place.status = ListingStatus.published
        place.country_code = "TT"
        place.description = PLACEHOLDER + p.blurb
        place.city = p.city
        place.latitude = p.latitude
        place.longitude = p.longitude
        place.property_type = p.property_type
        place.check_in_after = time(14, 0)
        place.check_out_before = time(11, 0)
        place.tags = _tags(p.tags)
        db.flush()
        for r in p.rooms:
            room = db.scalar(
                select(RoomType).where(RoomType.listing_id == place.id, RoomType.name == r.name)
            )
            if room is None:
                room = RoomType(listing_id=place.id, name=r.name, currency="TTD")
                db.add(room)
            room.price_minor = r.price_minor
            room.units = r.units
            room.max_guests = r.max_guests
            room.min_nights = r.min_nights
            room.sort_order = r.sort_order
        db.flush()
        listing_service.refresh_price_range(db, place.id)
        out.append(place)
    return out


def seed_past_fete_with_reviews(db: Session, org: Organisation, fan: User) -> Event:
    """A finished fete with a real checked-in ticket, so the verified-attendee
    badge has something true to show. A review is only honest if someone
    actually went."""
    slug = "past-fete-for-reviews"
    event = _find(db, Event, slug)
    if event is None:
        event = Event(slug=slug, organisation_id=org.id)
        db.add(event)
    event.title = "Last Season Cooler Fete"
    event.category = EventCategory.fete
    event.status = ListingStatus.published
    event.country_code = "TT"
    event.description = PLACEHOLDER + "Finished fete, kept so reviews have a subject."
    event.venue_name = "Queen's Park Savannah"
    event.city = "Port of Spain"
    event.latitude = 10.6700
    event.longitude = -61.5150
    event.starts_at = datetime.now(UTC) - timedelta(days=270)
    event.tags = _tags(["cooler", "soca"])
    db.flush()

    tier = db.scalar(
        select(TicketTier).where(TicketTier.listing_id == event.id, TicketTier.name == "Cooler")
    )
    if tier is None:
        tier = TicketTier(
            listing_id=event.id, name="Cooler", currency="TTD", price_minor=40000, quantity=200
        )
        db.add(tier)
        db.flush()
    listing_service.refresh_price_range(db, event.id)

    order = db.scalar(select(Order).where(Order.listing_id == event.id, Order.buyer_id == fan.id))
    if order is None:
        order = Order(
            listing_id=event.id,
            buyer_id=fan.id,
            buyer_name=fan.full_name,
            buyer_email=fan.email,
            channel=SalesChannel.box_office,
            status=OrderStatus.paid,
            currency="TTD",
            subtotal_minor=40000,
            buyer_fee_minor=0,
            promoter_fee_minor=1200,
            total_minor=40000,
            paid_at=datetime.now(UTC) - timedelta(days=275),
            access_token=new_token(),
            # A real sale, not a simulated one: the badge depends on that.
            is_test=False,
            items=[OrderItem(offer_id=tier.id, quantity=1, unit_price_minor=40000)],
        )
        db.add(order)
        db.flush()
        tier.quantity_sold += 1
        db.add(
            Ticket(
                order_id=order.id,
                offer_id=tier.id,
                holder_id=fan.id,
                code=new_token(),
                status=TicketStatus.checked_in,
                checked_in_at=datetime.now(UTC) - timedelta(days=270),
            )
        )
        db.flush()

    review = db.scalar(
        select(Review).where(Review.listing_id == event.id, Review.user_id == fan.id)
    )
    if review is None:
        review = Review(
            listing_id=event.id,
            user_id=fan.id,
            rating=5,
            comment="Bar lines were short and the sound was clean. Would go again.",
            is_verified_attendee=review_service.attended(db, fan, event.id),
        )
        for section, score in (
            (ReviewSection.venue, 5),
            (ReviewSection.music, 5),
            (ReviewSection.value, 4),
            (ReviewSection.organisation, 5),
        ):
            review.sections.append(ReviewSectionRating(section=section, rating=score))
        db.add(review)
        db.flush()
    review_service.refresh_rating(db, event.id)
    return event


def seed_social(db: Session, fan: User, promoter_org: Organisation, fetes: list[Event]) -> None:
    if db.get(Follow, {"user_id": fan.id, "organisation_id": promoter_org.id}) is None:
        db.add(Follow(user_id=fan.id, organisation_id=promoter_org.id))
    for event in fetes[:3]:
        if db.get(Favourite, {"user_id": fan.id, "listing_id": event.id}) is None:
            db.add(Favourite(user_id=fan.id, listing_id=event.id))

    profiles = [
        ("Carnival in Trinidad", "Port of Spain", ["event"], ["soca", "pan"], "this_month"),
        ("Somewhere to stay", None, ["accommodation"], [], "upcoming"),
        ("Vendors for my fete", "Port of Spain", ["service"], [], "upcoming"),
    ]
    for i, (name, city, types, tags, dates) in enumerate(profiles):
        profile = db.scalar(
            select(FilterProfile).where(FilterProfile.user_id == fan.id, FilterProfile.name == name)
        )
        if profile is None:
            profile = FilterProfile(user_id=fan.id, name=name)
            db.add(profile)
        profile.country_code = "TT"
        profile.city = city
        profile.listing_types = types
        profile.tags = _tags(tags)
        profile.date_preference = dates
        profile.is_active = i == 0
    db.flush()


def seed_collaborator(db: Session, collab: Organisation, fetes: list[Event]) -> None:
    """A sound crew credited on a fete it does not own: the concept's
    collaborator, and what makes it discoverable at all."""
    target = next((f for f in fetes if f.slug == "steel-brass-night"), None)
    if target is None:
        return
    existing = db.get(ListingCollaborator, {"listing_id": target.id, "organisation_id": collab.id})
    if existing is None:
        db.add(
            ListingCollaborator(listing_id=target.id, organisation_id=collab.id, credit="sound by")
        )


def seed_inquiry(db: Session, fan: User, services: list[ServiceListing]) -> None:
    caterer = next((s for s in services if s.slug == "doubles-roti-catering"), None)
    if caterer is None:
        return
    existing = db.scalar(
        select(Inquiry).where(Inquiry.listing_id == caterer.id, Inquiry.user_id == fan.id)
    )
    if existing is not None:
        return
    db.add(
        Inquiry(
            listing_id=caterer.id,
            organisation_id=caterer.organisation_id,
            user_id=fan.id,
            subject="Catering for 200 on Carnival Friday",
            message="Woodbrook, 200 covers, six o'clock start. Can you do it?",
            event_date=CARNIVAL - timedelta(days=3),
            contact_phone="+18681234567",
            response="Yes - TT$85 a head for 200. Deposit by 20 January to hold the date.",
            status=InquiryStatus.responded,
            responded_at=datetime.now(UTC) - timedelta(days=1),
        )
    )


def seed_booking(db: Session, fan: User, places: list[AccommodationListing]) -> None:
    """One confirmed stay, so per-night availability has something to show."""
    place = next((p for p in places if p.slug == "woodbrook-carnival-apartments"), None)
    if place is None:
        return
    room = db.scalar(
        select(RoomType).where(RoomType.listing_id == place.id, RoomType.name == "One Bedroom")
    )
    if room is None:
        return
    if db.scalar(select(Booking).where(Booking.offer_id == room.id)) is not None:
        return
    nights = 3
    start = CARNIVAL - timedelta(days=3)
    subtotal = room.price_minor * nights
    order = Order(
        listing_id=place.id,
        buyer_id=fan.id,
        buyer_name=fan.full_name,
        buyer_email=fan.email,
        channel=SalesChannel.online,
        status=OrderStatus.paid,
        currency="TTD",
        subtotal_minor=subtotal,
        buyer_fee_minor=0,
        promoter_fee_minor=0,
        total_minor=subtotal,
        paid_at=datetime.now(UTC),
        access_token=new_token(),
        is_test=False,
        items=[OrderItem(offer_id=room.id, quantity=1, unit_price_minor=room.price_minor)],
    )
    db.add(order)
    db.flush()
    db.add(
        Booking(
            order_id=order.id,
            offer_id=room.id,
            guest_id=fan.id,
            stay_start=start,
            stay_end=start + timedelta(days=nights),
            rooms=1,
            guests=2,
            code=new_token(),
            status=BookingStatus.confirmed,
        )
    )


# ---------- reset ----------


def reset(db: Session) -> None:
    """Remove only what this script owns, by slug and email."""
    listing_ids = list(db.scalars(select(Listing.id).where(Listing.slug.in_(OWNED_LISTING_SLUGS))))
    if listing_ids:
        offer_ids = list(db.scalars(select(Offer.id).where(Offer.listing_id.in_(listing_ids))))
        order_ids = list(db.scalars(select(Order.id).where(Order.listing_id.in_(listing_ids))))
        if order_ids:
            db.execute(delete(Booking).where(Booking.order_id.in_(order_ids)))
            db.execute(delete(Ticket).where(Ticket.order_id.in_(order_ids)))
            db.execute(delete(OrderItem).where(OrderItem.order_id.in_(order_ids)))
        db.execute(delete(Inquiry).where(Inquiry.listing_id.in_(listing_ids)))
        db.execute(
            delete(ReviewSectionRating).where(
                ReviewSectionRating.review_id.in_(
                    select(Review.id).where(Review.listing_id.in_(listing_ids))
                )
            )
        )
        db.execute(delete(Review).where(Review.listing_id.in_(listing_ids)))
        db.execute(delete(Favourite).where(Favourite.listing_id.in_(listing_ids)))
        db.execute(
            delete(ListingCollaborator).where(ListingCollaborator.listing_id.in_(listing_ids))
        )
        if order_ids:
            db.execute(delete(Order).where(Order.id.in_(order_ids)))
        if offer_ids:
            db.execute(delete(TicketTier).where(TicketTier.id.in_(offer_ids)))
            db.execute(delete(RoomType).where(RoomType.id.in_(offer_ids)))
            db.execute(delete(Offer).where(Offer.id.in_(offer_ids)))
        db.execute(delete(ListingTag).where(ListingTag.listing_id.in_(listing_ids)))
        # The per-category detail tables, by their own table objects: a
        # subclass delete would try to go through the base.
        db.execute(
            ServiceListing.__table__.delete().where(ServiceListing.__table__.c.id.in_(listing_ids))
        )
        db.execute(
            AccommodationListing.__table__.delete().where(
                AccommodationListing.__table__.c.id.in_(listing_ids)
            )
        )
        db.execute(Event.__table__.delete().where(Event.__table__.c.id.in_(listing_ids)))
        db.execute(delete(Listing).where(Listing.id.in_(listing_ids)))

    user_ids = list(db.scalars(select(User.id).where(User.email.in_(OWNED_EMAILS))))
    org_ids = list(
        db.scalars(select(Organisation.id).where(Organisation.slug.in_(OWNED_ORG_SLUGS)))
    )
    if user_ids:
        db.execute(delete(FilterProfile).where(FilterProfile.user_id.in_(user_ids)))
        db.execute(delete(Follow).where(Follow.user_id.in_(user_ids)))
        db.execute(delete(Favourite).where(Favourite.user_id.in_(user_ids)))
    if org_ids:
        db.execute(delete(OrgMember).where(OrgMember.organisation_id.in_(org_ids)))
        db.execute(delete(Follow).where(Follow.organisation_id.in_(org_ids)))
        db.execute(delete(Organisation).where(Organisation.id.in_(org_ids)))
    if user_ids:
        db.execute(delete(User).where(User.id.in_(user_ids)))
    db.commit()


# ---------- entry point ----------


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--reset",
        action="store_true",
        help="remove the demo content this script owns, then stop",
    )
    args = parser.parse_args(argv)

    db = SessionLocal()
    try:
        if db.get(Country, "TT") is None:
            print("No TT market: run the migrations first (alembic upgrade head).")
            return 1

        if args.reset:
            reset(db)
            print("Demo content removed.")
            return 0

        promoter = _user(db, *USERS["promoter"])
        vendor = _user(db, *USERS["vendor"])
        host = _user(db, *USERS["host"])
        collab_owner = _user(db, *USERS["collab"])
        fan = _user(db, *USERS["fan"])

        promoter_org = _org(db, *PROMOTER_ORG, promoter)
        vendor_org = _org(db, *VENDOR_ORG, vendor)
        host_org = _org(db, *HOST_ORG, host)
        collab_org = _org(db, *COLLAB_ORG, collab_owner)

        fetes = seed_fetes(db, promoter_org)
        services = seed_services(db, vendor_org)
        places = seed_places(db, host_org)
        seed_past_fete_with_reviews(db, promoter_org, fan)
        seed_collaborator(db, collab_org, fetes)
        seed_social(db, fan, promoter_org, fetes)
        seed_inquiry(db, fan, services)
        seed_booking(db, fan, places)
        db.commit()

        print(f"Seeded {len(fetes)} fetes, {len(services)} services, {len(places)} places.")
        print("Sign in with any of these; the password is the same for all:")
        for role, (email, name) in USERS.items():
            print(f"  {role:9} {email:36} {name}")
        print(f"  password  {DEMO_PASSWORD}")
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    sys.exit(main())
