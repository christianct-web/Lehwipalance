"""Collaborators, public organisation profiles and organisation search."""

import uuid
from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import select

from app.models import Event, EventCategory, ListingStatus, Organisation


def _auth(client, email):
    r = client.post(
        "/v1/auth/register",
        json={"email": email, "full_name": email.split("@")[0].title(), "password": "password123"},
    )
    assert r.status_code == 201
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _event(org, slug, *, days=20, status=ListingStatus.published):
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
def owner(client):
    return _auth(client, "owner@example.com")


@pytest.fixture
def world(client, db_session, owner):
    """Tribe, created through the API so `owner` really owns it, plus a sound
    crew with nothing of its own and an organisation with nothing at all."""
    tribe_id = client.post("/v1/orgs", json={"name": "Tribe"}, headers=owner).json()["id"]
    tribe = db_session.get(Organisation, uuid.UUID(tribe_id))
    sound = Organisation(name="Dubplate Sound", slug="dubplate-sound")
    quiet = Organisation(name="Quiet Co", slug="quiet-co")
    db_session.add_all([sound, quiet])
    db_session.flush()
    db_session.add_all(
        [
            _event(tribe, "tribe-ignite"),
            _event(tribe, "tribe-draft", status=ListingStatus.draft),
        ]
    )
    db_session.commit()
    return tribe, sound, quiet


def _listing(db, slug) -> Event:
    return db.scalars(select(Event).where(Event.slug == slug)).one()


# ---------- Crediting ----------


def test_credit_and_remove_a_collaborator(client, db_session, world, owner):
    tribe, sound, _ = world
    listing = _listing(db_session, "tribe-ignite")
    base = f"/v1/orgs/{tribe.id}/listings/{listing.id}/collaborators"

    r = client.put(
        base,
        json={"organisation_id": str(sound.id), "credit": "sound by"},
        headers=owner,
    )
    assert r.status_code == 204

    public = client.get("/v1/listings/tribe-ignite/collaborators").json()
    assert [(c["slug"], c["credit"]) for c in public] == [("dubplate-sound", "sound by")]

    # Idempotent, and re-sending updates the credit.
    client.put(
        base,
        json={"organisation_id": str(sound.id), "credit": "co-promoter"},
        headers=owner,
    )
    public = client.get("/v1/listings/tribe-ignite/collaborators").json()
    assert len(public) == 1 and public[0]["credit"] == "co-promoter"

    assert client.delete(f"{base}/{sound.id}", headers=owner).status_code == 204
    assert client.get("/v1/listings/tribe-ignite/collaborators").json() == []


def test_a_listing_owner_is_not_its_own_collaborator(client, db_session, world, owner):
    tribe, _, _ = world
    listing = _listing(db_session, "tribe-ignite")
    r = client.put(
        f"/v1/orgs/{tribe.id}/listings/{listing.id}/collaborators",
        json={"organisation_id": str(tribe.id)},
        headers=owner,
    )
    assert r.status_code == 422


def test_cannot_credit_on_a_listing_you_do_not_own(client, db_session, world):
    tribe, sound, _ = world
    listing = _listing(db_session, "tribe-ignite")
    # Someone running their own organisation, with no rights over Tribe.
    other = _auth(client, "other@example.com")
    other_org = client.post("/v1/orgs", json={"name": "Outsiders"}, headers=other).json()["id"]

    # Their own organisation, but someone else's listing.
    r = client.put(
        f"/v1/orgs/{other_org}/listings/{listing.id}/collaborators",
        json={"organisation_id": str(sound.id)},
        headers=other,
    )
    assert r.status_code == 404
    # And Tribe is not an organisation they belong to at all.
    r = client.put(
        f"/v1/orgs/{tribe.id}/listings/{listing.id}/collaborators",
        json={"organisation_id": str(sound.id)},
        headers=other,
    )
    assert r.status_code == 404


def test_crediting_an_unknown_organisation_is_404(client, db_session, world, owner):
    tribe, _, _ = world
    listing = _listing(db_session, "tribe-ignite")
    r = client.put(
        f"/v1/orgs/{tribe.id}/listings/{listing.id}/collaborators",
        json={"organisation_id": "00000000-0000-0000-0000-000000000000"},
        headers=owner,
    )
    assert r.status_code == 404


# ---------- Public profiles ----------


def test_profile_splits_owned_from_collaborations(client, db_session, world, owner):
    tribe, sound, _ = world
    listing = _listing(db_session, "tribe-ignite")
    client.put(
        f"/v1/orgs/{tribe.id}/listings/{listing.id}/collaborators",
        json={"organisation_id": str(sound.id), "credit": "sound by"},
        headers=owner,
    )

    tribe_page = client.get("/v1/organisations/tribe").json()
    assert [r["slug"] for r in tribe_page["owned_listings"]] == ["tribe-ignite"]
    assert tribe_page["collaborations"] == []

    sound_page = client.get("/v1/organisations/dubplate-sound").json()
    assert sound_page["owned_listings"] == []
    assert [r["slug"] for r in sound_page["collaborations"]] == ["tribe-ignite"]


def test_profile_hides_drafts_and_contact_details(client, world):
    body = client.get("/v1/organisations/tribe").json()
    assert "tribe-draft" not in {r["slug"] for r in body["owned_listings"]}
    # Promoter contact details are collected for payouts, not for publishing.
    assert "contact_email" not in body
    assert "contact_phone" not in body
    assert "payout_reference" not in body


def test_profile_carries_the_follower_count(client, world):
    tribe, _, _ = world
    h = _auth(client, "fan@example.com")
    client.put(f"/v1/me/follows/{tribe.id}", headers=h)
    assert client.get("/v1/organisations/tribe").json()["follower_count"] == 1


def test_unknown_profile_is_404(client, world):
    assert client.get("/v1/organisations/nobody").status_code == 404


def test_unknown_listing_collaborators_is_404(client, world):
    assert client.get("/v1/listings/nothing/collaborators").status_code == 404


# ---------- Search ----------


def test_search_lists_only_organisations_with_something_published(client, world):
    body = client.get("/v1/organisations").json()
    slugs = {o["slug"] for o in body["results"]}
    assert "tribe" in slugs
    # Quiet Co has nothing at all; Dubplate Sound is not credited yet.
    assert "quiet-co" not in slugs
    assert "dubplate-sound" not in slugs


def test_being_credited_makes_an_organisation_discoverable(client, db_session, world, owner):
    """The concept's "collaborators are discoverable and searchable alongside
    other organizations" — a sound crew with no listings of its own included."""
    tribe, sound, _ = world
    listing = _listing(db_session, "tribe-ignite")
    client.put(
        f"/v1/orgs/{tribe.id}/listings/{listing.id}/collaborators",
        json={"organisation_id": str(sound.id)},
        headers=owner,
    )
    slugs = {o["slug"] for o in client.get("/v1/organisations").json()["results"]}
    assert "dubplate-sound" in slugs


def test_search_by_name(client, world):
    body = client.get("/v1/organisations", params={"q": "TRIB"}).json()
    assert [o["slug"] for o in body["results"]] == ["tribe"]
    assert client.get("/v1/organisations", params={"q": "zzz"}).json()["results"] == []
