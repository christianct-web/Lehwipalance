"""Discovery: filters, the map viewport, the calendar and the price rollup."""

from datetime import UTC, date, datetime, timedelta

import pytest

from app.models import (
    Country,
    Event,
    EventCategory,
    ListingStatus,
    ListingType,
    Organisation,
    TicketTier,
)

# Port of Spain, near enough.
POS = (10.6549, -61.5019)
# Scarborough, Tobago: about 100 km away, so outside a 25 km radius.
SCARBOROUGH = (11.1811, -60.7394)


def _event(org, title, slug, *, days=30, city="Port of Spain", at=POS, status=None, tags=()):
    return Event(
        organisation_id=org.id,
        title=title,
        slug=slug,
        description=f"{title} description",
        category=EventCategory.fete,
        status=status or ListingStatus.published,
        country_code="TT",
        city=city,
        venue_name=f"{title} venue",
        latitude=at[0],
        longitude=at[1],
        starts_at=datetime.now(UTC) + timedelta(days=days),
        tags=list(tags),
    )


@pytest.fixture
def seeded(db_session):
    org = Organisation(name="Test Promotions", slug="test-promotions")
    db_session.add(org)
    db_session.flush()

    cheap = _event(org, "Cooler Cruise", "cooler-cruise", days=10, tags=["soca", "cooler"])
    pricey = _event(org, "All Inclusive", "all-inclusive", days=20, tags=["all-inclusive"])
    free = _event(org, "Pan Yard Lime", "pan-yard-lime", days=15, tags=["pan"])
    tobago = _event(
        org,
        "Tobago Beach Lime",
        "tobago-beach-lime",
        days=12,
        city="Scarborough",
        at=SCARBOROUGH,
    )
    draft = _event(org, "Secret Draft", "secret-draft", days=25, status=ListingStatus.draft)
    past = _event(org, "Last Year Fete", "last-year-fete", days=-200)
    db_session.add_all([cheap, pricey, free, tobago, draft, past])
    db_session.flush()

    # Price ranges, as the rollup would set them.
    for listing, lo, hi in (
        (cheap, 25_000, 40_000),
        (pricey, 150_000, 220_000),
        (free, 0, 0),
        (tobago, 30_000, 30_000),
        (past, 20_000, 20_000),
    ):
        listing.price_min_minor, listing.price_max_minor = lo, hi
    db_session.commit()
    return org


def _slugs(payload):
    return [r["slug"] for r in payload["results"]]


def test_lists_published_upcoming_only(client, seeded):
    r = client.get("/v1/listings")
    assert r.status_code == 200
    body = r.json()
    # The draft and the past event are both out; four remain.
    assert set(_slugs(body)) == {
        "cooler-cruise",
        "tobago-beach-lime",
        "pan-yard-lime",
        "all-inclusive",
    }
    assert body["total"] == 4


def test_sorts_by_date_then_price(client, seeded):
    assert _slugs(client.get("/v1/listings").json()) == [
        "cooler-cruise",
        "tobago-beach-lime",
        "pan-yard-lime",
        "all-inclusive",
    ]
    assert _slugs(client.get("/v1/listings", params={"sort": "price_low"}).json())[0] == (
        "pan-yard-lime"
    )
    assert _slugs(client.get("/v1/listings", params={"sort": "price_high"}).json())[0] == (
        "all-inclusive"
    )


def test_rejects_unknown_sort(client, seeded):
    assert client.get("/v1/listings", params={"sort": "sideways"}).status_code == 422


def test_filters_by_city_case_insensitively(client, seeded):
    body = client.get("/v1/listings", params={"city": "scarborough"}).json()
    assert _slugs(body) == ["tobago-beach-lime"]


def test_free_text_search_covers_title_and_venue(client, seeded):
    assert _slugs(client.get("/v1/listings", params={"q": "cooler"}).json()) == ["cooler-cruise"]
    assert _slugs(client.get("/v1/listings", params={"q": "PAN YARD"}).json()) == ["pan-yard-lime"]


def test_filters_by_price_window(client, seeded):
    # A listing matches when its range overlaps the window.
    body = client.get("/v1/listings", params={"price_max_minor": 50_000}).json()
    assert set(_slugs(body)) == {"cooler-cruise", "tobago-beach-lime", "pan-yard-lime"}
    body = client.get("/v1/listings", params={"price_min_minor": 200_000}).json()
    assert _slugs(body) == ["all-inclusive"]


def test_free_only(client, seeded):
    assert _slugs(client.get("/v1/listings", params={"free": "true"}).json()) == ["pan-yard-lime"]


def test_rejects_inverted_price_window(client, seeded):
    r = client.get("/v1/listings", params={"price_min_minor": 90_000, "price_max_minor": 10_000})
    assert r.status_code == 422


def test_filters_by_tag_matching_any(client, seeded):
    assert _slugs(client.get("/v1/listings", params={"tag": "pan"}).json()) == ["pan-yard-lime"]
    body = client.get("/v1/listings", params={"tag": ["pan", "cooler"]}).json()
    assert set(_slugs(body)) == {"pan-yard-lime", "cooler-cruise"}
    # Tags are normalised on the way in and on the way out.
    assert _slugs(client.get("/v1/listings", params={"tag": "  SOCA "}).json()) == ["cooler-cruise"]


def test_map_viewport_and_radius(client, seeded):
    # A box over Trinidad only.
    body = client.get("/v1/listings", params={"bbox": "10.0,-62.0,11.0,-61.0"}).json()
    assert "tobago-beach-lime" not in _slugs(body)
    # Around Port of Spain, Tobago is ~100 km away.
    near = {"near": f"{POS[0]},{POS[1]}", "radius_km": 25}
    assert "tobago-beach-lime" not in _slugs(client.get("/v1/listings", params=near).json())
    wide = {"near": f"{POS[0]},{POS[1]}", "radius_km": 200}
    assert "tobago-beach-lime" in _slugs(client.get("/v1/listings", params=wide).json())


def test_rejects_bad_geography(client, seeded):
    assert client.get("/v1/listings", params={"bbox": "nonsense"}).status_code == 422
    assert client.get("/v1/listings", params={"near": "10.6"}).status_code == 422
    assert client.get("/v1/listings", params={"near": "999,999"}).status_code == 422
    r = client.get("/v1/listings", params={"bbox": "10,-62,11,-61", "near": "10.6,-61.5"})
    assert r.status_code == 422


def test_explicit_window_overrides_upcoming_default(client, seeded):
    past = (datetime.now(UTC) - timedelta(days=365)).isoformat()
    body = client.get("/v1/listings", params={"starts_after": past}).json()
    assert "last-year-fete" in _slugs(body)


def test_pagination_reports_the_full_total(client, seeded):
    body = client.get("/v1/listings", params={"limit": 2}).json()
    assert len(body["results"]) == 2
    assert body["total"] == 4
    second = client.get("/v1/listings", params={"limit": 2, "offset": 2}).json()
    assert not set(_slugs(body)) & set(_slugs(second))


def test_a_market_that_hides_a_category_returns_nothing(client, db_session, seeded):
    tt = db_session.get(Country, "TT")
    tt.enabled_listing_types = [t.value for t in ListingType if t is not ListingType.event]
    db_session.commit()
    body = client.get("/v1/listings").json()
    assert body["total"] == 0
    assert body["results"] == []


def test_a_market_that_is_not_live_returns_nothing(client, db_session, seeded):
    tt = db_session.get(Country, "TT")
    tt.is_live = False
    db_session.commit()
    assert client.get("/v1/listings").json()["total"] == 0


def test_unknown_market_is_empty_not_an_error(client, seeded):
    assert client.get("/v1/listings", params={"country": "BB"}).json()["total"] == 0


# ---------- Calendar ----------


def test_calendar_counts_days_in_the_market_timezone(client, seeded):
    start = date.today()
    r = client.get(
        "/v1/listings/calendar",
        params={"start": start.isoformat(), "end": (start + timedelta(days=40)).isoformat()},
    )
    assert r.status_code == 200
    body = r.json()
    assert body["timezone"] == "America/Port_of_Spain"
    assert body["country_code"] == "TT"
    # Four upcoming events inside 40 days, each on its own day.
    assert sum(d["count"] for d in body["days"]) == 4
    assert all(d["count"] >= 1 for d in body["days"])
    assert [d["day"] for d in body["days"]] == sorted(d["day"] for d in body["days"])


def test_calendar_window_is_bounded(client, seeded):
    start = date.today()
    r = client.get(
        "/v1/listings/calendar",
        params={"start": start.isoformat(), "end": (start + timedelta(days=400)).isoformat()},
    )
    assert r.status_code == 422


def test_calendar_rejects_a_backwards_window(client, seeded):
    start = date.today()
    r = client.get(
        "/v1/listings/calendar",
        params={"start": start.isoformat(), "end": (start - timedelta(days=5)).isoformat()},
    )
    assert r.status_code == 422


def test_calendar_honours_filters(client, seeded):
    start = date.today()
    body = client.get(
        "/v1/listings/calendar",
        params={
            "start": start.isoformat(),
            "end": (start + timedelta(days=40)).isoformat(),
            "free": "true",
        },
    ).json()
    assert sum(d["count"] for d in body["days"]) == 1


def test_calendar_unknown_market_is_404(client, seeded):
    assert client.get("/v1/listings/calendar", params={"country": "BB"}).status_code == 404


# ---------- Price rollup ----------


def test_price_rollup_follows_the_tiers(client, db_session, seeded):
    from app.services import listings as svc

    org = seeded
    event = _event(org, "Rollup Fete", "rollup-fete", days=5)
    db_session.add(event)
    db_session.flush()

    svc.refresh_price_range(db_session, event.id)
    db_session.commit()
    assert event.price_min_minor is None, "no tiers means no price"

    db_session.add_all(
        [
            TicketTier(event_id=event.id, name="Early", price_minor=30_000, quantity=10),
            TicketTier(event_id=event.id, name="VIP", price_minor=90_000, quantity=5),
        ]
    )
    db_session.flush()
    svc.refresh_price_range(db_session, event.id)
    db_session.commit()
    assert (event.price_min_minor, event.price_max_minor) == (30_000, 90_000)
