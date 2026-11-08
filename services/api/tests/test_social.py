"""Follows and favourites, and the feed of listings from followed orgs."""

from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import select

from app.models import Event, EventCategory, ListingStatus, Organisation

FOLLOWS = "/v1/me/follows"
FAVS = "/v1/me/favourites"
MISSING_ID = "00000000-0000-0000-0000-000000000000"


def _listing(db, slug) -> Event:
    return db.scalars(select(Event).where(Event.slug == slug)).one()


def _auth(client, email="fan@example.com"):
    client.post(
        "/v1/auth/register",
        json={"email": email, "full_name": "Fan", "password": "soca-2027!"},
    )
    token = client.post("/v1/auth/login", json={"email": email, "password": "soca-2027!"}).json()[
        "access_token"
    ]
    return {"Authorization": f"Bearer {token}"}


def _event(org, slug, *, days=10, status=ListingStatus.published):
    return Event(
        organisation_id=org.id,
        title=slug.replace("-", " ").title(),
        slug=slug,
        category=EventCategory.fete,
        status=status,
        country_code="TT",
        starts_at=datetime.now(UTC) + timedelta(days=days),
    )


@pytest.fixture
def world(db_session):
    tribe = Organisation(name="Tribe", slug="tribe")
    caesars = Organisation(name="Caesars Army", slug="caesars-army")
    db_session.add_all([tribe, caesars])
    db_session.flush()
    db_session.add_all(
        [
            _event(tribe, "tribe-ignite", days=5),
            _event(tribe, "tribe-past", days=-5),
            _event(caesars, "ajs-soca-brainwash", days=8),
            _event(caesars, "caesars-draft", status=ListingStatus.draft),
        ]
    )
    db_session.commit()
    return tribe, caesars


def test_everything_needs_a_token(client, world):
    tribe, _ = world
    assert client.get(FOLLOWS).status_code == 401
    assert client.put(f"{FOLLOWS}/{tribe.id}").status_code == 401
    assert client.get(FAVS).status_code == 401
    assert client.get(f"{FOLLOWS}/listings").status_code == 401


# ---------- Follows ----------


def test_follow_is_idempotent(client, world):
    tribe, _ = world
    h = _auth(client)
    assert client.put(f"{FOLLOWS}/{tribe.id}", headers=h).status_code == 204
    assert client.put(f"{FOLLOWS}/{tribe.id}", headers=h).status_code == 204
    body = client.get(FOLLOWS, headers=h).json()
    assert [o["slug"] for o in body] == ["tribe"]
    assert body[0]["follower_count"] == 1


def test_unfollow_is_idempotent(client, world):
    tribe, _ = world
    h = _auth(client)
    # Unfollowing something never followed is not an error.
    assert client.delete(f"{FOLLOWS}/{tribe.id}", headers=h).status_code == 204
    client.put(f"{FOLLOWS}/{tribe.id}", headers=h)
    assert client.delete(f"{FOLLOWS}/{tribe.id}", headers=h).status_code == 204
    assert client.get(FOLLOWS, headers=h).json() == []


def test_following_an_unknown_organisation_is_404(client, world):
    h = _auth(client)
    assert (
        client.put(f"{FOLLOWS}/{'0' * 8}-0000-0000-0000-000000000000", headers=h).status_code == 404
    )


def test_follower_count_is_public_and_counts_everyone(client, world):
    tribe, _ = world
    h1 = _auth(client, "one@example.com")
    h2 = _auth(client, "two@example.com")
    client.put(f"{FOLLOWS}/{tribe.id}", headers=h1)
    client.put(f"{FOLLOWS}/{tribe.id}", headers=h2)
    # No token needed.
    r = client.get("/v1/organisations/tribe/followers")
    assert r.status_code == 200
    assert r.json() == {"slug": "tribe", "follower_count": 2}


def test_follower_count_unknown_org(client, world):
    assert client.get("/v1/organisations/nobody/followers").status_code == 404


def test_feed_from_followed_organisations(client, world):
    tribe, caesars = world
    h = _auth(client)
    assert client.get(f"{FOLLOWS}/listings", headers=h).json()["total"] == 0

    client.put(f"{FOLLOWS}/{tribe.id}", headers=h)
    body = client.get(f"{FOLLOWS}/listings", headers=h).json()
    # Only Tribe, only published, only upcoming.
    assert [r["slug"] for r in body["results"]] == ["tribe-ignite"]

    client.put(f"{FOLLOWS}/{caesars.id}", headers=h)
    body = client.get(f"{FOLLOWS}/listings", headers=h).json()
    assert {r["slug"] for r in body["results"]} == {"tribe-ignite", "ajs-soca-brainwash"}
    assert "caesars-draft" not in {r["slug"] for r in body["results"]}


def test_feed_can_include_past_listings(client, world):
    tribe, _ = world
    h = _auth(client)
    client.put(f"{FOLLOWS}/{tribe.id}", headers=h)
    body = client.get(f"{FOLLOWS}/listings", params={"upcoming_only": "false"}, headers=h).json()
    assert {r["slug"] for r in body["results"]} == {"tribe-ignite", "tribe-past"}


def test_follows_are_per_user(client, world):
    tribe, _ = world
    h1 = _auth(client, "one@example.com")
    h2 = _auth(client, "two@example.com")
    client.put(f"{FOLLOWS}/{tribe.id}", headers=h1)
    assert client.get(FOLLOWS, headers=h2).json() == []
    assert client.get(f"{FOLLOWS}/listings", headers=h2).json()["total"] == 0


# ---------- Favourites ----------


def test_save_and_unsave_a_listing(client, db_session, world):
    h = _auth(client)
    listing_id = _listing(db_session, "tribe-ignite").id
    assert client.put(f"{FAVS}/{listing_id}", headers=h).status_code == 204
    assert client.put(f"{FAVS}/{listing_id}", headers=h).status_code == 204, "idempotent"
    body = client.get(FAVS, headers=h).json()
    assert body["total"] == 1
    assert body["results"][0]["slug"] == "tribe-ignite"

    assert client.delete(f"{FAVS}/{listing_id}", headers=h).status_code == 204
    assert client.get(FAVS, headers=h).json()["total"] == 0


def test_cannot_save_a_draft_listing(client, db_session, world):
    h = _auth(client)
    draft_id = _listing(db_session, "caesars-draft").id
    assert client.put(f"{FAVS}/{draft_id}", headers=h).status_code == 404


def test_favourites_keep_showing_a_cancelled_listing(client, db_session, world):
    """What you saved getting cancelled is exactly what you want to be told."""
    h = _auth(client)
    event = _listing(db_session, "tribe-ignite")
    client.put(f"{FAVS}/{event.id}", headers=h)

    event.status = ListingStatus.cancelled
    db_session.commit()

    body = client.get(FAVS, headers=h).json()
    assert body["total"] == 1
    assert body["results"][0]["status"] == "cancelled"
    # Discovery, by contrast, hides it.
    assert "tribe-ignite" not in {r["slug"] for r in client.get("/v1/listings").json()["results"]}


def test_favourites_are_per_user(client, db_session, world):
    h1 = _auth(client, "one@example.com")
    h2 = _auth(client, "two@example.com")
    listing_id = _listing(db_session, "tribe-ignite").id
    client.put(f"{FAVS}/{listing_id}", headers=h1)
    assert client.get(FAVS, headers=h2).json()["total"] == 0
