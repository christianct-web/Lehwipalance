from datetime import UTC, datetime, timedelta
from uuid import UUID

import pytest

from app.models import Order, OrderStatus

FUTURE = (datetime.now(UTC) + timedelta(days=60)).isoformat()


def _auth(client, email):
    r = client.post(
        "/v1/auth/register", json={"email": email, "full_name": email, "password": "password123"}
    )
    assert r.status_code == 201
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


@pytest.fixture
def owner(client):
    return _auth(client, "owner@example.com")


@pytest.fixture
def org_id(client, owner):
    r = client.post("/v1/orgs", json={"name": "Tribe Promotions"}, headers=owner)
    assert r.status_code == 201
    return r.json()["id"]


def _add_member(client, org_id, headers, email, role):
    member = _auth(client, email)
    r = client.post(
        f"/v1/orgs/{org_id}/members", json={"email": email, "role": role}, headers=headers
    )
    assert r.status_code == 201
    return member


def _event(client, org_id, headers, **extra):
    body = {"title": "Sunrise Cooler Fete", "starts_at": FUTURE, **extra}
    r = client.post(f"/v1/orgs/{org_id}/events", json=body, headers=headers)
    assert r.status_code == 201, r.text
    return r.json()


def _tier(client, org_id, event_id, headers, **extra):
    body = {"name": "Early bird", "price_minor": 45000, "quantity": 200, **extra}
    r = client.post(f"/v1/orgs/{org_id}/events/{event_id}/tiers", json=body, headers=headers)
    assert r.status_code == 201, r.text
    return r.json()["tiers"][-1]


# ---------- Organisations and members ----------


def test_creator_becomes_owner_and_slug_is_unique(client, owner, org_id):
    r = client.get("/v1/orgs", headers=owner)
    assert [(o["slug"], o["role"]) for o in r.json()] == [("tribe-promotions", "owner")]

    other = _auth(client, "other@example.com")
    r = client.post("/v1/orgs", json={"name": "Tribe Promotions"}, headers=other)
    assert r.json()["slug"].startswith("tribe-promotions-")


def test_non_member_sees_404_not_403(client, org_id):
    stranger = _auth(client, "stranger@example.com")
    assert client.get(f"/v1/orgs/{org_id}", headers=stranger).status_code == 404
    assert client.get(f"/v1/orgs/{org_id}/events", headers=stranger).status_code == 404


def test_requires_login(client, org_id):
    assert client.get(f"/v1/orgs/{org_id}").status_code == 401


def test_manager_can_add_sellers_but_not_managers(client, owner, org_id):
    manager = _add_member(client, org_id, owner, "manager@example.com", "manager")
    _add_member(client, org_id, manager, "scanner@example.com", "scanner")
    _auth(client, "m2@example.com")
    r = client.post(
        f"/v1/orgs/{org_id}/members",
        json={"email": "m2@example.com", "role": "manager"},
        headers=manager,
    )
    assert r.status_code == 403


def test_add_member_errors(client, owner, org_id):
    url = f"/v1/orgs/{org_id}/members"
    r = client.post(url, json={"email": "nobody@example.com", "role": "seller"}, headers=owner)
    assert r.status_code == 404
    r = client.post(url, json={"email": "owner@example.com", "role": "seller"}, headers=owner)
    assert r.status_code == 409


def test_last_owner_cannot_leave(client, owner, org_id):
    me = client.get("/v1/auth/me", headers=owner).json()["id"]
    assert client.delete(f"/v1/orgs/{org_id}/members/{me}", headers=owner).status_code == 409


def test_member_removal_rules(client, owner, org_id):
    manager = _add_member(client, org_id, owner, "manager@example.com", "manager")
    seller = _add_member(client, org_id, owner, "seller@example.com", "seller")
    members = {
        m["email"]: m["user_id"]
        for m in client.get(f"/v1/orgs/{org_id}/members", headers=owner).json()
    }

    # A seller can't remove anyone else, but can leave.
    r = client.delete(f"/v1/orgs/{org_id}/members/{members['manager@example.com']}", headers=seller)
    assert r.status_code == 403
    # A manager can remove a seller but not the owner.
    r = client.delete(f"/v1/orgs/{org_id}/members/{members['owner@example.com']}", headers=manager)
    assert r.status_code == 403
    r = client.delete(f"/v1/orgs/{org_id}/members/{members['seller@example.com']}", headers=manager)
    assert r.status_code == 204


def test_seller_role_cannot_edit(client, owner, org_id):
    seller = _add_member(client, org_id, owner, "seller@example.com", "seller")
    assert client.patch(f"/v1/orgs/{org_id}", json={"name": "X"}, headers=seller).status_code == 403
    r = client.post(
        f"/v1/orgs/{org_id}/events", json={"title": "Nope", "starts_at": FUTURE}, headers=seller
    )
    assert r.status_code == 403
    # ...but can read events.
    assert client.get(f"/v1/orgs/{org_id}/events", headers=seller).status_code == 200


def test_patch_rejects_null_on_required_field(client, owner, org_id):
    r = client.patch(f"/v1/orgs/{org_id}", json={"name": None}, headers=owner)
    assert r.status_code == 422
    r = client.patch(f"/v1/orgs/{org_id}", json={"instagram": "@tribe"}, headers=owner)
    assert r.json()["instagram"] == "@tribe"


# ---------- Events ----------


def test_event_lifecycle(client, owner, org_id):
    event = _event(client, org_id, owner)
    assert event["status"] == "draft"
    url = f"/v1/orgs/{org_id}/events/{event['id']}"

    # Drafts are hidden from the public listing.
    assert client.get(f"/v1/events/{event['slug']}").status_code == 404

    # Publishing needs a tier.
    assert client.post(f"{url}/publish", headers=owner).status_code == 409
    _tier(client, org_id, event["id"], owner)
    r = client.post(f"{url}/publish", headers=owner)
    assert r.status_code == 200 and r.json()["status"] == "published"
    assert client.get(f"/v1/events/{event['slug']}").status_code == 200

    r = client.get(f"/v1/orgs/{org_id}/events", params={"status": "published"}, headers=owner)
    assert [e["id"] for e in r.json()] == [event["id"]]

    r = client.post(f"{url}/cancel", headers=owner)
    assert r.json()["status"] == "cancelled"
    assert client.patch(url, json={"title": "Back on"}, headers=owner).status_code == 409


def test_cannot_cancel_with_paid_orders(client, owner, org_id, db_session):
    event = _event(client, org_id, owner)
    db_session.add(
        Order(
            event_id=UUID(event["id"]),
            status=OrderStatus.paid,
            subtotal_minor=45000,
            total_minor=47325,
        )
    )
    db_session.commit()
    r = client.post(f"/v1/orgs/{org_id}/events/{event['id']}/cancel", headers=owner)
    assert r.status_code == 409


def test_event_dates_validated(client, owner, org_id):
    r = client.post(
        f"/v1/orgs/{org_id}/events",
        json={"title": "Backwards", "starts_at": FUTURE, "ends_at": FUTURE},
        headers=owner,
    )
    assert r.status_code == 422
    r = client.post(
        f"/v1/orgs/{org_id}/events",
        json={"title": "No timezone", "starts_at": "2027-02-10T20:00:00"},
        headers=owner,
    )
    assert r.status_code == 422

    event = _event(client, org_id, owner)
    earlier = (datetime.now(UTC) + timedelta(days=1)).isoformat()
    r = client.patch(
        f"/v1/orgs/{org_id}/events/{event['id']}", json={"ends_at": earlier}, headers=owner
    )
    assert r.status_code == 422


def test_cannot_publish_past_event(client, owner, org_id):
    past = (datetime.now(UTC) - timedelta(days=1)).isoformat()
    event = _event(client, org_id, owner, starts_at=past)
    _tier(client, org_id, event["id"], owner)
    r = client.post(f"/v1/orgs/{org_id}/events/{event['id']}/publish", headers=owner)
    assert r.status_code == 409


def test_event_of_another_org_is_404(client, owner, org_id):
    event = _event(client, org_id, owner)
    other_org = client.post("/v1/orgs", json={"name": "Other"}, headers=owner).json()["id"]
    r = client.get(f"/v1/orgs/{other_org}/events/{event['id']}", headers=owner)
    assert r.status_code == 404


# ---------- Tiers ----------


def test_tier_rules_once_tickets_are_sold(client, owner, org_id, db_session):
    from app.models import TicketTier

    event = _event(client, org_id, owner)
    tier = _tier(client, org_id, event["id"], owner)
    url = f"/v1/orgs/{org_id}/events/{event['id']}/tiers/{tier['id']}"

    row = db_session.get(TicketTier, UUID(tier["id"]))
    row.quantity_sold = 50
    db_session.commit()

    assert client.patch(url, json={"price_minor": 50000}, headers=owner).status_code == 409
    assert client.patch(url, json={"quantity": 40}, headers=owner).status_code == 409
    assert client.delete(url, headers=owner).status_code == 409

    r = client.patch(url, json={"quantity": 300, "name": "Early bird (extended)"}, headers=owner)
    assert r.status_code == 200
    assert r.json()["tiers"][0]["remaining"] == 250


def test_tier_validation_and_delete(client, owner, org_id):
    event = _event(client, org_id, owner)
    base = f"/v1/orgs/{org_id}/events/{event['id']}/tiers"
    start = datetime.now(UTC) + timedelta(days=5)
    r = client.post(
        base,
        json={
            "name": "Bad window",
            "price_minor": 100,
            "quantity": 1,
            "sales_start_at": start.isoformat(),
            "sales_end_at": (start - timedelta(hours=1)).isoformat(),
        },
        headers=owner,
    )
    assert r.status_code == 422
    r = client.post(
        base, json={"name": "Negative", "price_minor": -1, "quantity": 1}, headers=owner
    )
    assert r.status_code == 422

    tier = _tier(client, org_id, event["id"], owner, sales_start_at=start.isoformat())
    early = (start - timedelta(hours=1)).isoformat()
    r = client.patch(f"{base}/{tier['id']}", json={"sales_end_at": early}, headers=owner)
    assert r.status_code == 422

    assert client.delete(f"{base}/{tier['id']}", headers=owner).status_code == 204
    detail = client.get(f"/v1/orgs/{org_id}/events/{event['id']}", headers=owner).json()
    assert detail["tiers"] == []


# ---------- Sellers ----------


def test_sellers(client, owner, org_id):
    event = _event(client, org_id, owner)
    base = f"/v1/orgs/{org_id}/events/{event['id']}/sellers"
    _auth(client, "committee@example.com")

    r = client.post(
        base, json={"display_name": "Keisha", "email": "committee@example.com"}, headers=owner
    )
    assert r.status_code == 201
    seller = r.json()
    assert len(seller["code"]) == 6 and seller["user_id"]

    r = client.post(base, json={"display_name": "Ghost", "email": "x@example.com"}, headers=owner)
    assert r.status_code == 404

    unlinked = client.post(base, json={"display_name": "Marcus"}, headers=owner).json()
    assert unlinked["user_id"] is None and unlinked["code"] != seller["code"]

    names = [s["display_name"] for s in client.get(base, headers=owner).json()]
    assert names == ["Keisha", "Marcus"]

    assert client.delete(f"{base}/{unlinked['id']}", headers=owner).status_code == 204
    assert client.delete(f"{base}/{unlinked['id']}", headers=owner).status_code == 404


def test_seller_with_orders_is_kept(client, owner, org_id, db_session):
    event = _event(client, org_id, owner)
    base = f"/v1/orgs/{org_id}/events/{event['id']}/sellers"
    seller = client.post(base, json={"display_name": "Keisha"}, headers=owner).json()
    db_session.add(
        Order(
            event_id=UUID(event["id"]),
            seller_id=UUID(seller["id"]),
            subtotal_minor=0,
            total_minor=0,
        )
    )
    db_session.commit()
    assert client.delete(f"{base}/{seller['id']}", headers=owner).status_code == 409
