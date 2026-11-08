"""Service listings (the vendor directory) and the inquiry flow that books them."""

import pytest

from app.models import Country, ListingType
from app.services import inquiries as inquiry_service


def _auth(client, email):
    r = client.post(
        "/v1/auth/register",
        json={"email": email, "full_name": email.split("@")[0].title(), "password": "password123"},
    )
    assert r.status_code == 201
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


@pytest.fixture
def vendor(client):
    """A caterer with one published service and one draft."""
    headers = _auth(client, "caterer@example.com")
    org = client.post("/v1/orgs", json={"name": "Doubles Dynasty"}, headers=headers).json()["id"]
    live = client.post(
        f"/v1/orgs/{org}/services",
        json={
            "title": "Doubles & Roti Catering",
            "description": "Hot doubles, bake and shark, buss-up-shut for 50 to 500 guests.",
            "city": "Port of Spain",
            "category": "catering",
            "price_model": "per_person",
            "base_price_minor": 8500,
            "min_notice_days": 7,
            "tags": ["Doubles", "  CREOLE  "],
        },
        headers=headers,
    ).json()
    client.post(f"/v1/orgs/{org}/services/{live['id']}/publish", headers=headers)
    draft = client.post(
        f"/v1/orgs/{org}/services",
        json={"title": "Secret Menu", "description": "Not ready.", "category": "catering"},
        headers=headers,
    ).json()
    return {"headers": headers, "org": org, "live": live, "draft": draft}


# ---------- Creating and listing ----------


def test_create_normalises_tags_and_rolls_up_price(client, vendor):
    live = client.get(
        f"/v1/orgs/{vendor['org']}/services/{vendor['live']['id']}", headers=vendor["headers"]
    ).json()
    assert live["tags"] == ["creole", "doubles"]
    assert live["price_model"] == "per_person"
    assert live["base_price_minor"] == 8500
    assert live["status"] == "published"


def test_quote_only_publishes_no_price(client, vendor):
    r = client.post(
        f"/v1/orgs/{vendor['org']}/services",
        json={"title": "Bespoke Planning", "category": "planning", "price_model": "quote_only"},
        headers=vendor["headers"],
    )
    assert r.status_code == 201
    assert r.json()["base_price_minor"] is None


def test_price_model_and_figure_must_agree(client, vendor):
    base = f"/v1/orgs/{vendor['org']}/services"
    # A quote-only service cannot carry a figure.
    r = client.post(
        base,
        json={
            "title": "Contradiction",
            "category": "other",
            "price_model": "quote_only",
            "base_price_minor": 100,
        },
        headers=vendor["headers"],
    )
    assert r.status_code == 422
    # A priced model needs one.
    r = client.post(
        base,
        json={"title": "No Figure", "category": "other", "price_model": "hourly"},
        headers=vendor["headers"],
    )
    assert r.status_code == 422


def test_partial_edit_cannot_break_the_price_pairing(client, vendor):
    """Switching to quote-only without clearing the figure must be refused, not
    silently stored."""
    url = f"/v1/orgs/{vendor['org']}/services/{vendor['live']['id']}"
    r = client.patch(url, json={"price_model": "quote_only"}, headers=vendor["headers"])
    assert r.status_code == 422
    # Clearing both together is fine.
    r = client.patch(
        url,
        json={"price_model": "quote_only", "base_price_minor": None},
        headers=vendor["headers"],
    )
    assert r.status_code == 200
    assert r.json()["base_price_minor"] is None


def test_publish_needs_a_description(client, vendor):
    bare = client.post(
        f"/v1/orgs/{vendor['org']}/services",
        json={"title": "Mystery", "category": "other"},
        headers=vendor["headers"],
    ).json()
    r = client.post(
        f"/v1/orgs/{vendor['org']}/services/{bare['id']}/publish", headers=vendor["headers"]
    )
    assert r.status_code == 409
    assert "description" in r.json()["detail"]


def test_unpublish_returns_it_to_draft(client, vendor):
    url = f"/v1/orgs/{vendor['org']}/services/{vendor['live']['id']}"
    assert client.post(f"{url}/unpublish", headers=vendor["headers"]).json()["status"] == "draft"
    assert client.post(f"{url}/publish", headers=vendor["headers"]).json()["status"] == "published"


def test_another_organisation_cannot_touch_it(client, vendor):
    other = _auth(client, "other@example.com")
    other_org = client.post("/v1/orgs", json={"name": "Outsiders"}, headers=other).json()["id"]
    assert (
        client.get(
            f"/v1/orgs/{other_org}/services/{vendor['live']['id']}", headers=other
        ).status_code
        == 404
    )
    assert (
        client.get(
            f"/v1/orgs/{vendor['org']}/services/{vendor['live']['id']}", headers=other
        ).status_code
        == 404
    )


def test_services_must_be_enabled_in_the_market(client, db_session, vendor):
    tt = db_session.get(Country, "TT")
    tt.enabled_listing_types = [t.value for t in ListingType if t is not ListingType.service]
    db_session.commit()
    r = client.post(
        f"/v1/orgs/{vendor['org']}/services",
        json={"title": "Too Late", "category": "other"},
        headers=vendor["headers"],
    )
    assert r.status_code == 409


# ---------- Discovery ----------


def test_services_appear_in_discovery_with_their_price(client, vendor):
    body = client.get("/v1/listings", params={"type": "service", "upcoming_only": "false"}).json()
    rows = {r["slug"]: r for r in body["results"]}
    assert "doubles-roti-catering" in rows
    assert rows["doubles-roti-catering"]["price_min_minor"] == 8500
    # The draft is not public.
    assert "secret-menu" not in rows


def test_services_have_no_date_so_upcoming_only_hides_them(client, vendor):
    """A service is an ongoing offering, not an occasion: it sorts after dated
    listings and is filtered out when a date window is asked for."""
    body = client.get("/v1/listings", params={"type": "service"}).json()
    assert body["total"] == 0


def test_quote_only_services_match_no_price_filter(client, vendor):
    client.post(
        f"/v1/orgs/{vendor['org']}/services",
        json={
            "title": "Ask Us Planning",
            "description": "Full-service planning.",
            "category": "planning",
            "price_model": "quote_only",
        },
        headers=vendor["headers"],
    )
    svc = client.get(f"/v1/orgs/{vendor['org']}/services", headers=vendor["headers"]).json()
    ask = next(s for s in svc if s["slug"] == "ask-us-planning")
    client.post(f"/v1/orgs/{vendor['org']}/services/{ask['id']}/publish", headers=vendor["headers"])

    params = {"type": "service", "upcoming_only": "false"}
    assert "ask-us-planning" in {
        r["slug"] for r in client.get("/v1/listings", params=params).json()["results"]
    }
    priced = {**params, "price_max_minor": 1_000_000}
    assert "ask-us-planning" not in {
        r["slug"] for r in client.get("/v1/listings", params=priced).json()["results"]
    }
    assert "ask-us-planning" not in {
        r["slug"]
        for r in client.get("/v1/listings", params={**params, "free": "true"}).json()["results"]
    }


def test_generic_listing_detail_carries_the_category_fields(client, vendor):
    body = client.get("/v1/listings/doubles-roti-catering").json()
    assert body["type"] == "service"
    assert body["service"]["category"] == "catering"
    assert body["service"]["min_notice_days"] == 7
    assert body["event"] is None
    assert body["organisation"]["name"] == "Doubles Dynasty"


def test_generic_listing_detail_hides_drafts(client, vendor):
    assert client.get("/v1/listings/secret-menu").status_code == 404
    assert client.get("/v1/listings/nothing-here").status_code == 404


def test_listing_detail_does_not_shadow_the_calendar(client, vendor):
    """/v1/listings/calendar must not be read as a listing slug."""
    r = client.get("/v1/listings/calendar")
    assert r.status_code == 200
    assert "timezone" in r.json()


# ---------- Inquiries ----------


def test_inquiry_round_trip(client, vendor):
    organiser = _auth(client, "organiser@example.com")
    r = client.post(
        "/v1/listings/doubles-roti-catering/inquiries",
        json={
            "subject": "Catering for 200",
            "message": "Carnival Friday, Woodbrook. Can you do 200 covers?",
            "event_date": "2027-02-05",
            "contact_phone": "+18681234567",
        },
        headers=organiser,
    )
    assert r.status_code == 201
    inquiry = r.json()
    assert inquiry["status"] == "pending"
    assert inquiry["listing"]["slug"] == "doubles-roti-catering"

    # It lands in the vendor's inbox, with who is asking.
    inbox = client.get(f"/v1/orgs/{vendor['org']}/inquiries", headers=vendor["headers"]).json()
    assert len(inbox) == 1
    assert inbox[0]["from_name"] == "Organiser"
    assert inbox[0]["from_email"] == "organiser@example.com"
    assert inbox[0]["event_date"] == "2027-02-05"

    # The vendor replies.
    r = client.post(
        f"/v1/orgs/{vendor['org']}/inquiries/{inquiry['id']}/respond",
        json={"response": "Yes - TT$85 a head, deposit by 20 Jan."},
        headers=vendor["headers"],
    )
    assert r.status_code == 200
    assert r.json()["status"] == "responded"
    assert r.json()["responded_at"] is not None

    # The organiser sees the reply.
    mine = client.get("/v1/me/inquiries", headers=organiser).json()
    assert mine[0]["response"].startswith("Yes")

    # And the vendor closes it off.
    r = client.post(
        f"/v1/orgs/{vendor['org']}/inquiries/{inquiry['id']}/resolve", headers=vendor["headers"]
    )
    assert r.json()["status"] == "resolved"
    assert r.json()["resolved_at"] is not None


def test_inquiry_needs_a_token_and_a_published_listing(client, vendor):
    assert (
        client.post(
            "/v1/listings/doubles-roti-catering/inquiries",
            json={"subject": "s", "message": "m"},
        ).status_code
        == 401
    )
    organiser = _auth(client, "organiser@example.com")
    # A draft is not inquirable.
    assert (
        client.post(
            "/v1/listings/secret-menu/inquiries",
            json={"subject": "s", "message": "m"},
            headers=organiser,
        ).status_code
        == 404
    )


def test_an_event_is_not_booked_by_inquiry(client, db_session, vendor):
    """A fete has tickets; an inquiry would be a worse way to buy one."""
    from datetime import UTC, datetime, timedelta

    from app.models import Event, EventCategory, ListingStatus, Organisation

    org = Organisation(name="Tribe", slug="tribe")
    db_session.add(org)
    db_session.flush()
    db_session.add(
        Event(
            organisation_id=org.id,
            title="A Fete",
            slug="a-fete",
            category=EventCategory.fete,
            status=ListingStatus.published,
            country_code="TT",
            starts_at=datetime.now(UTC) + timedelta(days=10),
        )
    )
    db_session.commit()

    organiser = _auth(client, "organiser@example.com")
    r = client.post(
        "/v1/listings/a-fete/inquiries",
        json={"subject": "s", "message": "m"},
        headers=organiser,
    )
    assert r.status_code == 409
    assert "not booked by inquiry" in r.json()["detail"]


def test_organiser_can_withdraw_and_vendor_cannot_reopen(client, vendor):
    organiser = _auth(client, "organiser@example.com")
    inquiry = client.post(
        "/v1/listings/doubles-roti-catering/inquiries",
        json={"subject": "Maybe", "message": "Still deciding."},
        headers=organiser,
    ).json()
    r = client.post(f"/v1/me/inquiries/{inquiry['id']}/cancel", headers=organiser)
    assert r.json()["status"] == "cancelled"
    # A cancelled inquiry is closed to replies.
    r = client.post(
        f"/v1/orgs/{vendor['org']}/inquiries/{inquiry['id']}/respond",
        json={"response": "Too late"},
        headers=vendor["headers"],
    )
    assert r.status_code == 409


def test_resolved_inquiries_cannot_be_withdrawn(client, vendor):
    organiser = _auth(client, "organiser@example.com")
    inquiry = client.post(
        "/v1/listings/doubles-roti-catering/inquiries",
        json={"subject": "Done", "message": "Booked."},
        headers=organiser,
    ).json()
    client.post(
        f"/v1/orgs/{vendor['org']}/inquiries/{inquiry['id']}/resolve", headers=vendor["headers"]
    )
    r = client.post(f"/v1/me/inquiries/{inquiry['id']}/cancel", headers=organiser)
    assert r.status_code == 409


def test_inquiries_are_private_to_both_sides(client, vendor):
    organiser = _auth(client, "organiser@example.com")
    nosy = _auth(client, "nosy@example.com")
    nosy_org = client.post("/v1/orgs", json={"name": "Nosy Co"}, headers=nosy).json()["id"]
    inquiry = client.post(
        "/v1/listings/doubles-roti-catering/inquiries",
        json={"subject": "Private", "message": "Confidential."},
        headers=organiser,
    ).json()

    assert client.get(f"/v1/me/inquiries/{inquiry['id']}", headers=nosy).status_code == 404
    assert client.get(f"/v1/orgs/{nosy_org}/inquiries", headers=nosy).json() == []
    assert (
        client.get(f"/v1/orgs/{nosy_org}/inquiries/{inquiry['id']}", headers=nosy).status_code
        == 404
    )


def test_open_inquiries_per_vendor_are_capped(client, vendor, monkeypatch):
    monkeypatch.setattr(inquiry_service, "MAX_OPEN_PER_LISTING", 2)
    organiser = _auth(client, "organiser@example.com")
    for i in range(2):
        r = client.post(
            "/v1/listings/doubles-roti-catering/inquiries",
            json={"subject": f"Ask {i}", "message": "..."},
            headers=organiser,
        )
        assert r.status_code == 201
    r = client.post(
        "/v1/listings/doubles-roti-catering/inquiries",
        json={"subject": "Spam", "message": "..."},
        headers=organiser,
    )
    assert r.status_code == 409


def test_resolving_frees_the_cap(client, vendor, monkeypatch):
    monkeypatch.setattr(inquiry_service, "MAX_OPEN_PER_LISTING", 1)
    organiser = _auth(client, "organiser@example.com")
    first = client.post(
        "/v1/listings/doubles-roti-catering/inquiries",
        json={"subject": "One", "message": "..."},
        headers=organiser,
    ).json()
    assert (
        client.post(
            "/v1/listings/doubles-roti-catering/inquiries",
            json={"subject": "Two", "message": "..."},
            headers=organiser,
        ).status_code
        == 409
    )
    client.post(
        f"/v1/orgs/{vendor['org']}/inquiries/{first['id']}/resolve", headers=vendor["headers"]
    )
    assert (
        client.post(
            "/v1/listings/doubles-roti-catering/inquiries",
            json={"subject": "Two", "message": "..."},
            headers=organiser,
        ).status_code
        == 201
    )


def test_inbox_filters_by_status_and_puts_pending_first(client, vendor):
    organiser = _auth(client, "organiser@example.com")
    ids = []
    for i in range(3):
        ids.append(
            client.post(
                "/v1/listings/doubles-roti-catering/inquiries",
                json={"subject": f"Ask {i}", "message": "..."},
                headers=organiser,
            ).json()["id"]
        )
    client.post(
        f"/v1/orgs/{vendor['org']}/inquiries/{ids[0]}/respond",
        json={"response": "Replied"},
        headers=vendor["headers"],
    )
    inbox = client.get(f"/v1/orgs/{vendor['org']}/inquiries", headers=vendor["headers"]).json()
    assert inbox[0]["status"] == "pending", "the work queue comes first"
    pending = client.get(
        f"/v1/orgs/{vendor['org']}/inquiries",
        params={"status": "pending"},
        headers=vendor["headers"],
    ).json()
    assert len(pending) == 2
    assert all(i["status"] == "pending" for i in pending)
