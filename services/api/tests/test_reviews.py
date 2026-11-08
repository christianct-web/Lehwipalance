"""Reviews, section ratings, and the verified-attendee badge."""

import uuid
from datetime import UTC, datetime, timedelta

import pytest
from sqlalchemy import select

from app.models import (
    Event,
    EventCategory,
    ListingStatus,
    Order,
    Organisation,
    Ticket,
    TicketStatus,
)

PAST = -3


def _auth(client, email):
    r = client.post(
        "/v1/auth/register",
        json={"email": email, "full_name": email.split("@")[0].title(), "password": "password123"},
    )
    assert r.status_code == 201
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _event(org, slug, *, days, status=ListingStatus.published):
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
    org = Organisation(name="Tribe", slug="tribe")
    db_session.add(org)
    db_session.flush()
    db_session.add_all(
        [
            _event(org, "finished-fete", days=PAST),
            _event(org, "upcoming-fete", days=30),
            _event(org, "draft-fete", days=PAST, status=ListingStatus.draft),
        ]
    )
    db_session.commit()
    return org


def _reviews(client, slug):
    return client.get(f"/v1/listings/{slug}/reviews").json()


# ---------- Writing ----------


def test_reading_is_public_writing_is_not(client, world):
    assert client.get("/v1/listings/finished-fete/reviews").status_code == 200
    r = client.post("/v1/listings/finished-fete/reviews", json={"rating": 5})
    assert r.status_code == 401


def test_write_and_read_a_review(client, world):
    h = _auth(client, "fan@example.com")
    r = client.post(
        "/v1/listings/finished-fete/reviews",
        json={
            "rating": 4,
            "comment": "Good vibes, long bar lines.",
            "sections": {"venue": 5, "value": 3, "music": 5},
        },
        headers=h,
    )
    assert r.status_code == 201
    body = r.json()
    assert body["rating"] == 4
    assert body["author_name"] == "Fan"
    assert body["is_verified_attendee"] is False, "no ticket, no badge"
    assert {s["section"]: s["rating"] for s in body["sections"]} == {
        "venue": 5,
        "value": 3,
        "music": 5,
    }

    page = _reviews(client, "finished-fete")
    assert page["summary"]["count"] == 1
    assert page["summary"]["average"] == 4.0
    assert page["summary"]["verified_count"] == 0
    assert {s["section"]: s["average"] for s in page["summary"]["sections"]} == {
        "venue": 5.0,
        "value": 3.0,
        "music": 5.0,
    }


def test_cannot_review_something_that_has_not_happened(client, world):
    h = _auth(client, "fan@example.com")
    r = client.post("/v1/listings/upcoming-fete/reviews", json={"rating": 5}, headers=h)
    assert r.status_code == 409
    assert "hasn't happened" in r.json()["detail"]


def test_draft_listings_have_no_public_reviews(client, world):
    h = _auth(client, "fan@example.com")
    assert client.get("/v1/listings/draft-fete/reviews").status_code == 404
    assert (
        client.post("/v1/listings/draft-fete/reviews", json={"rating": 5}, headers=h).status_code
        == 404
    )


def test_one_review_per_person_per_listing(client, world):
    h = _auth(client, "fan@example.com")
    assert (
        client.post("/v1/listings/finished-fete/reviews", json={"rating": 4}, headers=h).status_code
        == 201
    )
    r = client.post("/v1/listings/finished-fete/reviews", json={"rating": 2}, headers=h)
    assert r.status_code == 409
    assert "edit that review" in r.json()["detail"]


def test_ratings_are_bounded(client, world):
    h = _auth(client, "fan@example.com")
    for bad in ({"rating": 0}, {"rating": 6}, {"rating": 3, "sections": {"venue": 9}}):
        r = client.post("/v1/listings/finished-fete/reviews", json=bad, headers=h)
        assert r.status_code == 422, bad


def test_unknown_section_is_refused(client, world):
    h = _auth(client, "fan@example.com")
    r = client.post(
        "/v1/listings/finished-fete/reviews",
        json={"rating": 3, "sections": {"parking": 4}},
        headers=h,
    )
    assert r.status_code == 422


# ---------- Editing and deleting ----------


def test_edit_own_review_and_rollup_follows(client, world):
    h = _auth(client, "fan@example.com")
    review = client.post(
        "/v1/listings/finished-fete/reviews",
        json={"rating": 2, "sections": {"venue": 2}},
        headers=h,
    ).json()
    assert _reviews(client, "finished-fete")["summary"]["average"] == 2.0

    r = client.patch(
        f"/v1/reviews/{review['id']}",
        json={"rating": 5, "sections": {"venue": 5, "food": 4}},
        headers=h,
    )
    assert r.status_code == 200
    page = _reviews(client, "finished-fete")
    assert page["summary"]["average"] == 5.0
    assert {s["section"] for s in page["summary"]["sections"]} == {"venue", "food"}


def test_cannot_touch_someone_elses_review(client, world):
    mine = _auth(client, "one@example.com")
    theirs = _auth(client, "two@example.com")
    review = client.post(
        "/v1/listings/finished-fete/reviews", json={"rating": 4}, headers=mine
    ).json()
    patched = client.patch(f"/v1/reviews/{review['id']}", json={"rating": 1}, headers=theirs)
    assert patched.status_code == 404
    assert client.delete(f"/v1/reviews/{review['id']}", headers=theirs).status_code == 404


def test_delete_clears_the_rollup(client, world):
    h = _auth(client, "fan@example.com")
    review = client.post("/v1/listings/finished-fete/reviews", json={"rating": 4}, headers=h).json()
    assert client.delete(f"/v1/reviews/{review['id']}", headers=h).status_code == 204
    page = _reviews(client, "finished-fete")
    assert page["summary"]["count"] == 0
    assert page["summary"]["average"] is None, "no reviews is not a rating of zero"


def test_average_across_several_reviewers(client, world):
    for i, rating in enumerate((5, 4, 2)):
        h = _auth(client, f"fan{i}@example.com")
        client.post("/v1/listings/finished-fete/reviews", json={"rating": rating}, headers=h)
    summary = _reviews(client, "finished-fete")["summary"]
    assert summary["count"] == 3
    assert summary["average"] == round(11 / 3, 2)


# ---------- The verified-attendee badge ----------


def _sell_and_scan(db, client, owner_headers, *, is_test: bool, scan: bool, buyer_email: str):
    """Put a real (or simulated) ticket in someone's hands, optionally scanned."""
    org = client.post("/v1/orgs", json={"name": f"Org {buyer_email}"}, headers=owner_headers)
    org_id = org.json()["id"]
    future = (datetime.now(UTC) + timedelta(days=1)).isoformat()
    ev = client.post(
        f"/v1/orgs/{org_id}/events",
        json={"title": f"Fete {buyer_email}", "starts_at": future},
        headers=owner_headers,
    ).json()
    base = f"/v1/orgs/{org_id}/events/{ev['id']}"
    tiers = client.post(
        f"{base}/tiers",
        json={"name": "RSVP", "price_minor": 0, "quantity": 10},
        headers=owner_headers,
    ).json()["tiers"]
    client.post(f"{base}/publish", headers=owner_headers)

    buyer = _auth(client, buyer_email)
    order = client.post(
        "/v1/orders",
        json={
            "event_slug": ev["slug"],
            "items": [{"tier_id": tiers[0]["id"], "quantity": 1}],
            "buyer_name": "Buyer",
            "buyer_email": buyer_email,
        },
        headers=buyer,
    ).json()

    db_order = db.scalars(select(Order).where(Order.id == uuid.UUID(order["id"]))).one()
    db_order.is_test = is_test
    db.flush()

    if scan:
        ticket = db.scalars(select(Ticket).where(Ticket.order_id == db_order.id)).first()
        ticket.status = TicketStatus.checked_in
        ticket.checked_in_at = datetime.now(UTC)
    # Make the event reviewable: it is over.
    event = db.scalars(select(Event).where(Event.slug == ev["slug"])).one()
    event.starts_at = datetime.now(UTC) - timedelta(hours=6)
    db.commit()
    return ev["slug"], buyer


def test_scanned_in_earns_the_badge(client, db_session, world):
    owner = _auth(client, "owner@example.com")
    slug, buyer = _sell_and_scan(
        db_session, client, owner, is_test=False, scan=True, buyer_email="went@example.com"
    )
    r = client.post(f"/v1/listings/{slug}/reviews", json={"rating": 5}, headers=buyer)
    assert r.status_code == 201
    assert r.json()["is_verified_attendee"] is True
    assert _reviews(client, slug)["summary"]["verified_count"] == 1


def test_a_ticket_never_scanned_earns_nothing(client, db_session, world):
    owner = _auth(client, "owner@example.com")
    slug, buyer = _sell_and_scan(
        db_session, client, owner, is_test=False, scan=False, buyer_email="bought@example.com"
    )
    r = client.post(f"/v1/listings/{slug}/reviews", json={"rating": 5}, headers=buyer)
    assert r.json()["is_verified_attendee"] is False, "bought is not attended"


def test_a_simulated_ticket_never_earns_the_badge(client, db_session, world):
    """A demo ticket buys neither entry nor credibility."""
    owner = _auth(client, "owner@example.com")
    slug, buyer = _sell_and_scan(
        db_session, client, owner, is_test=True, scan=True, buyer_email="demo@example.com"
    )
    r = client.post(f"/v1/listings/{slug}/reviews", json={"rating": 5}, headers=buyer)
    assert r.json()["is_verified_attendee"] is False
    assert _reviews(client, slug)["summary"]["verified_count"] == 0


def test_badge_survives_an_edit(client, db_session, world):
    owner = _auth(client, "owner@example.com")
    slug, buyer = _sell_and_scan(
        db_session, client, owner, is_test=False, scan=True, buyer_email="went2@example.com"
    )
    review = client.post(f"/v1/listings/{slug}/reviews", json={"rating": 5}, headers=buyer).json()
    edited = client.patch(
        f"/v1/reviews/{review['id']}", json={"comment": "Second thoughts"}, headers=buyer
    ).json()
    assert edited["is_verified_attendee"] is True, "editing words doesn't un-attend you"


def test_attendance_is_per_listing(client, db_session, world):
    """Being scanned into one fete says nothing about another."""
    owner = _auth(client, "owner@example.com")
    slug, buyer = _sell_and_scan(
        db_session, client, owner, is_test=False, scan=True, buyer_email="went3@example.com"
    )
    r = client.post("/v1/listings/finished-fete/reviews", json={"rating": 4}, headers=buyer)
    assert r.json()["is_verified_attendee"] is False


# ---------- Discovery by rating ----------


def test_min_rating_filter(client, world):
    h = _auth(client, "fan@example.com")
    client.post("/v1/listings/finished-fete/reviews", json={"rating": 5}, headers=h)

    # finished-fete is in the past, so ask without the upcoming-only default.
    past = (datetime.now(UTC) - timedelta(days=30)).isoformat()

    def slugs(**extra):
        params = {"starts_after": past, **extra}
        return {r["slug"] for r in client.get("/v1/listings", params=params).json()["results"]}

    assert slugs(min_rating=4) == {"finished-fete"}
    assert slugs(min_rating=5) == {"finished-fete"}
    # An unrated listing is not a match for a rating filter, but shows without one.
    assert "upcoming-fete" not in slugs(min_rating=1)
    assert "upcoming-fete" in slugs()


def test_listing_summary_carries_the_rating(client, world):
    h = _auth(client, "fan@example.com")
    client.post("/v1/listings/finished-fete/reviews", json={"rating": 4}, headers=h)
    past = (datetime.now(UTC) - timedelta(days=30)).isoformat()
    rows = client.get("/v1/listings", params={"starts_after": past}).json()["results"]
    by_slug = {r["slug"]: r for r in rows}
    assert by_slug["finished-fete"]["rating_average"] == 4.0
    assert by_slug["finished-fete"]["rating_count"] == 1
    assert by_slug["upcoming-fete"]["rating_average"] is None
