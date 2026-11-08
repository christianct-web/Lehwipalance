"""Filter profiles: managing them, switching between them, and the feed."""

from datetime import UTC, datetime, timedelta

import pytest

from app.models import (
    Country,
    Event,
    EventCategory,
    ListingStatus,
    ListingType,
    Organisation,
)
from app.services import filter_profiles

POS = (10.6549, -61.5019)
PROFILES = "/v1/me/filter-profiles"


def _auth(client, email="fan@example.com"):
    client.post(
        "/v1/auth/register",
        json={"email": email, "full_name": "Fete Fan", "password": "soca-2027!"},
    )
    token = client.post("/v1/auth/login", json={"email": email, "password": "soca-2027!"}).json()[
        "access_token"
    ]
    return {"Authorization": f"Bearer {token}"}


def _event(org, title, slug, *, days, city="Port of Spain", lo=30_000, hi=30_000, tags=()):
    e = Event(
        organisation_id=org.id,
        title=title,
        slug=slug,
        category=EventCategory.fete,
        status=ListingStatus.published,
        country_code="TT",
        city=city,
        starts_at=datetime.now(UTC) + timedelta(days=days),
        latitude=POS[0],
        longitude=POS[1],
        tags=list(tags),
    )
    e.price_min_minor, e.price_max_minor = lo, hi
    return e


@pytest.fixture
def catalogue(db_session):
    org = Organisation(name="Promo", slug="promo")
    db_session.add(org)
    db_session.flush()
    db_session.add_all(
        [
            _event(org, "Soon Soca", "soon-soca", days=2, tags=["soca"]),
            _event(org, "Later Pan", "later-pan", days=45, tags=["pan"]),
            _event(org, "Free Lime", "free-lime", days=3, lo=0, hi=0, tags=["soca"]),
            _event(org, "Tobago Stay", "tobago-stay", days=4, city="Scarborough"),
        ]
    )
    db_session.commit()
    return org


def _slugs(body):
    return {r["slug"] for r in body["results"]}


def _create(client, headers, **body):
    return client.post(PROFILES, json=body, headers=headers)


def _active_flags(client, headers):
    return {p["name"]: p["is_active"] for p in client.get(PROFILES, headers=headers).json()}


# ---------- Managing profiles ----------


def test_needs_a_token(client):
    assert client.get(PROFILES).status_code == 401
    assert client.post(PROFILES, json={"name": "x"}).status_code == 401
    assert client.get("/v1/me/feed").status_code == 401


def test_first_profile_is_active_automatically(client, catalogue):
    h = _auth(client)
    r = client.post(PROFILES, json={"name": "Trinidad"}, headers=h)
    assert r.status_code == 201
    assert r.json()["is_active"] is True, "nothing else could be driving the feed"

    r = client.post(PROFILES, json={"name": "Tobago"}, headers=h)
    assert r.json()["is_active"] is False


def test_switching_profiles_deactivates_the_other(client, catalogue):
    h = _auth(client)
    first = client.post(PROFILES, json={"name": "A"}, headers=h).json()
    second = client.post(PROFILES, json={"name": "B"}, headers=h).json()

    r = client.post(f"{PROFILES}/{second['id']}/activate", headers=h)
    assert r.status_code == 200
    states = {p["name"]: p["is_active"] for p in client.get(PROFILES, headers=h).json()}
    assert states == {"A": False, "B": True}
    # And back again.
    client.post(f"{PROFILES}/{first['id']}/activate", headers=h)
    states = {p["name"]: p["is_active"] for p in client.get(PROFILES, headers=h).json()}
    assert states == {"A": True, "B": False}


def test_names_are_unique_per_user_not_globally(client, catalogue):
    h1 = _auth(client, "one@example.com")
    h2 = _auth(client, "two@example.com")
    assert client.post(PROFILES, json={"name": "Trinidad"}, headers=h1).status_code == 201
    assert client.post(PROFILES, json={"name": "Trinidad"}, headers=h1).status_code == 409
    # Someone else may use the same name.
    assert client.post(PROFILES, json={"name": "Trinidad"}, headers=h2).status_code == 201


def test_cannot_see_or_touch_another_users_profile(client, catalogue):
    h1 = _auth(client, "one@example.com")
    h2 = _auth(client, "two@example.com")
    mine = client.post(PROFILES, json={"name": "Mine"}, headers=h1).json()
    for call in (
        lambda: client.get(f"{PROFILES}/{mine['id']}", headers=h2),
        lambda: client.patch(f"{PROFILES}/{mine['id']}", json={"city": "x"}, headers=h2),
        lambda: client.post(f"{PROFILES}/{mine['id']}/activate", headers=h2),
        lambda: client.delete(f"{PROFILES}/{mine['id']}", headers=h2),
        lambda: client.get(f"{PROFILES}/{mine['id']}/feed", headers=h2),
    ):
        assert call().status_code == 404, "another user's id must not be probeable"


def test_deleting_the_active_profile_promotes_another(client, catalogue):
    h = _auth(client)
    active = client.post(PROFILES, json={"name": "A"}, headers=h).json()
    client.post(PROFILES, json={"name": "B"}, headers=h)
    assert client.delete(f"{PROFILES}/{active['id']}", headers=h).status_code == 204

    left = client.get(PROFILES, headers=h).json()
    assert [p["name"] for p in left] == ["B"]
    assert left[0]["is_active"] is True, "never leave profiles with none active"
    # And the feed still runs.
    assert client.get("/v1/me/feed", headers=h).status_code == 200


def test_deleting_the_last_profile_leaves_no_feed(client, catalogue):
    h = _auth(client)
    only = client.post(PROFILES, json={"name": "Only"}, headers=h).json()
    client.delete(f"{PROFILES}/{only['id']}", headers=h)
    r = client.get("/v1/me/feed", headers=h)
    assert r.status_code == 404
    assert "/v1/listings" in r.json()["detail"], "point the client at unfiltered browsing"


def test_rejects_a_market_we_do_not_serve(client, catalogue):
    h = _auth(client)
    r = client.post(
        "/v1/me/filter-profiles", json={"name": "Barbados", "country_code": "BB"}, headers=h
    )
    assert r.status_code == 422


def test_profiles_are_capped(client, catalogue, monkeypatch):
    monkeypatch.setattr(filter_profiles, "MAX_PER_USER", 2)
    h = _auth(client)
    for name in ("A", "B"):
        assert client.post(PROFILES, json={"name": name}, headers=h).status_code == 201
    assert client.post(PROFILES, json={"name": "C"}, headers=h).status_code == 409


def test_tags_are_normalised_to_match_listing_tags(client, catalogue):
    h = _auth(client)
    r = client.post(
        "/v1/me/filter-profiles",
        json={"name": "Soca", "tags": ["  SOCA ", "Soca", "Steel  Pan", ""]},
        headers=h,
    )
    assert r.json()["tags"] == ["soca", "steel pan"]


def test_incoherent_bands_and_windows_are_refused(client, catalogue):
    h = _auth(client)
    bad = [
        {"name": "a", "price_band": "custom"},
        {"name": "b", "price_band": "custom", "price_min_minor": 900, "price_max_minor": 100},
        {"name": "c", "date_preference": "custom"},
        {
            "name": "d",
            "date_preference": "custom",
            "starts_after": "2027-03-01T00:00:00Z",
            "starts_before": "2027-02-01T00:00:00Z",
        },
        {"name": "e", "sort": "sideways"},
    ]
    for body in bad:
        assert client.post(PROFILES, json=body, headers=h).status_code == 422, body


# ---------- The feed ----------


def test_feed_applies_the_profile(client, catalogue):
    h = _auth(client)
    client.post(
        "/v1/me/filter-profiles",
        json={"name": "Soca only", "tags": ["soca"]},
        headers=h,
    )
    body = client.get("/v1/me/feed", headers=h).json()
    assert _slugs(body) == {"soon-soca", "free-lime"}
    assert body["profile"]["name"] == "Soca only"


def test_feed_price_bands(client, catalogue):
    h = _auth(client)
    p = client.post(
        "/v1/me/filter-profiles", json={"name": "P", "price_band": "free"}, headers=h
    ).json()
    assert _slugs(client.get("/v1/me/feed", headers=h).json()) == {"free-lime"}

    client.patch(f"{PROFILES}/{p['id']}", json={"price_band": "paid"}, headers=h)
    assert "free-lime" not in _slugs(client.get("/v1/me/feed", headers=h).json())

    client.patch(
        f"{PROFILES}/{p['id']}",
        json={"price_band": "custom", "price_min_minor": 0, "price_max_minor": 100},
        headers=h,
    )
    assert _slugs(client.get("/v1/me/feed", headers=h).json()) == {"free-lime"}


def test_feed_city_scope(client, catalogue):
    h = _auth(client)
    client.post(PROFILES, json={"name": "Tobago", "city": "Scarborough"}, headers=h)
    assert _slugs(client.get("/v1/me/feed", headers=h).json()) == {"tobago-stay"}


def test_feed_resolves_relative_dates_and_reports_the_window(client, catalogue):
    h = _auth(client)
    client.post(
        "/v1/me/filter-profiles",
        json={"name": "This month", "date_preference": "this_month"},
        headers=h,
    )
    body = client.get("/v1/me/feed", headers=h).json()
    assert body["resolved_starts_after"] is not None
    assert body["resolved_starts_before"] is not None
    # A 45-day-out event cannot be in this month.
    assert "later-pan" not in _slugs(body)


def test_feed_upcoming_excludes_nothing_upcoming(client, catalogue):
    h = _auth(client)
    client.post(PROFILES, json={"name": "All"}, headers=h)
    body = client.get("/v1/me/feed", headers=h).json()
    assert body["total"] == 4
    assert body["resolved_starts_before"] is None


def test_feed_respects_category_gating(client, db_session, catalogue):
    h = _auth(client)
    client.post(PROFILES, json={"name": "All"}, headers=h)
    tt = db_session.get(Country, "TT")
    tt.enabled_listing_types = [t.value for t in ListingType if t is not ListingType.event]
    db_session.commit()
    body = client.get("/v1/me/feed", headers=h).json()
    assert body["total"] == 0 and body["results"] == []


def test_feed_pagination(client, catalogue):
    h = _auth(client)
    client.post(PROFILES, json={"name": "All"}, headers=h)
    first = client.get("/v1/me/feed", params={"limit": 2}, headers=h).json()
    assert len(first["results"]) == 2 and first["total"] == 4
    second = client.get("/v1/me/feed", params={"limit": 2, "offset": 2}, headers=h).json()
    assert not _slugs(first) & _slugs(second)


def test_named_profile_feed_does_not_need_activating(client, catalogue):
    h = _auth(client)
    client.post(PROFILES, json={"name": "Active"}, headers=h)
    other = client.post(
        "/v1/me/filter-profiles", json={"name": "Pan", "tags": ["pan"]}, headers=h
    ).json()
    assert other["is_active"] is False
    body = client.get(f"{PROFILES}/{other['id']}/feed", headers=h).json()
    assert _slugs(body) == {"later-pan"}
