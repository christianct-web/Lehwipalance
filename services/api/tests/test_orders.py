import uuid
from datetime import UTC, datetime, timedelta

import pytest

from app.core import ratelimit
from app.core.config import get_settings
from app.models import Order

FUTURE = (datetime.now(UTC) + timedelta(days=30)).isoformat()
PNG = b"\x89PNG\r\n\x1a\n" + b"\x00" * 64


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
def setup(client, owner):
    """A published event with a paid tier (5 tickets) and a free tier."""
    org = client.post("/v1/orgs", json={"name": "Tribe"}, headers=owner).json()["id"]
    ev = client.post(
        f"/v1/orgs/{org}/events", json={"title": "Sunrise Fete", "starts_at": FUTURE}, headers=owner
    ).json()
    base = f"/v1/orgs/{org}/events/{ev['id']}"
    tiers = client.post(
        f"{base}/tiers",
        json={"name": "Early bird", "price_minor": 40000, "quantity": 5, "max_per_order": 4},
        headers=owner,
    ).json()["tiers"]
    tiers = client.post(
        f"{base}/tiers", json={"name": "RSVP", "price_minor": 0, "quantity": 100}, headers=owner
    ).json()["tiers"]
    assert client.post(f"{base}/publish", headers=owner).status_code == 200
    by_name = {t["name"]: t["id"] for t in tiers}
    return {
        "org": org,
        "event": ev,
        "base": base,
        "paid": by_name["Early bird"],
        "free": by_name["RSVP"],
    }


def _order(client, setup, tier, qty=1, **extra):
    body = {
        "event_slug": setup["event"]["slug"],
        "items": [{"tier_id": tier, "quantity": qty}],
        "buyer_name": "Ana",
        "buyer_email": "Ana@Example.com",
        **extra,
    }
    return client.post("/v1/orders", json=body)


def _pay(client, order, outcome="paid"):
    return client.post(
        f"/v1/payments/test/{order['id']}",
        json={"token": order["access_token"], "outcome": outcome},
    )


def _expire(db_session, order):
    db_session.get(Order, uuid.UUID(order["id"])).expires_at = datetime.now(UTC) - timedelta(
        minutes=1
    )
    db_session.commit()


# ---------- Online checkout ----------


def test_paid_checkout_flow(client, setup):
    r = _order(client, setup, setup["paid"], 2)
    assert r.status_code == 201, r.text
    order = r.json()
    assert order["status"] == "pending"
    assert order["subtotal_minor"] == 80000
    # 4.5% + TT$3 per ticket
    assert order["buyer_fee_minor"] == 3600 + 600
    assert order["total_minor"] == 84200
    assert order["checkout_url"].startswith("https://tickets.example.tt/pay/test/")
    assert order["tickets"] == []
    assert order["buyer_email"] == "ana@example.com"

    r = _pay(client, order)
    assert r.status_code == 200
    paid = r.json()
    assert paid["status"] == "paid"
    assert len(paid["tickets"]) == 2
    assert len({t["code"] for t in paid["tickets"]}) == 2

    # Paying twice is a no-op.
    assert len(_pay(client, order).json()["tickets"]) == 2

    r = client.get(f"/v1/orders/{order['id']}", params={"token": order["access_token"]})
    assert r.json()["status"] == "paid"
    assert client.get(f"/v1/orders/{order['id']}", params={"token": "nope"}).status_code == 404

    ev = client.get(f"/v1/events/{setup['event']['slug']}").json()
    assert next(t for t in ev["tiers"] if t["id"] == setup["paid"])["remaining"] == 3


def test_declined_payment_releases_hold(client, setup):
    order = _order(client, setup, setup["paid"], 4).json()
    assert _order(client, setup, setup["paid"], 2).json()["detail"] == "Only 1 Early bird left"
    assert _pay(client, order, "declined").json()["status"] == "failed"
    assert _order(client, setup, setup["paid"], 4).status_code == 201


def test_holds_prevent_overselling_and_expire(client, setup, db_session):
    a = _order(client, setup, setup["paid"], 4).json()
    b = _order(client, setup, setup["paid"], 1).json()
    r = _order(client, setup, setup["paid"], 1)
    assert r.status_code == 409
    assert r.json()["detail"] == "Early bird is sold out"

    # Let a's hold lapse: its tickets go back on sale.
    _expire(db_session, a)
    got = client.get(f"/v1/orders/{a['id']}", params={"token": a["access_token"]}).json()
    assert got["status"] == "expired"
    c = _order(client, setup, setup["paid"], 4).json()
    assert _pay(client, c).json()["status"] == "paid"
    assert _pay(client, b).json()["status"] == "paid"

    # a pays late, but its tickets are gone: failed, reference kept for a refund.
    late = _pay(client, a).json()
    assert late["status"] == "failed"
    assert late["tickets"] == []


def test_late_payment_honoured_when_tickets_remain(client, setup, db_session):
    a = _order(client, setup, setup["paid"], 2).json()
    _expire(db_session, a)
    assert _pay(client, a).json()["status"] == "paid"


def test_free_tickets_issue_immediately(client, setup):
    r = _order(client, setup, setup["free"], 3)
    order = r.json()
    assert order["status"] == "paid"
    assert order["checkout_url"] is None
    assert order["total_minor"] == 0
    assert len(order["tickets"]) == 3


def test_order_validation(client, setup, owner):
    assert (
        _order(client, setup, setup["paid"], 5).json()["detail"]
        == "Early bird: at most 4 per order"
    )
    assert _order(client, setup, str(uuid.uuid4())).status_code == 404
    r = client.post(
        "/v1/orders",
        json={
            "event_slug": "nope",
            "items": [{"tier_id": setup["paid"], "quantity": 1}],
            "buyer_name": "A",
            "buyer_email": "a@example.com",
        },
    )
    assert r.status_code == 404

    # Draft events aren't on sale.
    ev = client.post(
        f"/v1/orgs/{setup['org']}/events",
        json={"title": "Draft", "starts_at": FUTURE},
        headers=owner,
    ).json()
    r = client.post(
        "/v1/orders",
        json={
            "event_slug": ev["slug"],
            "items": [{"tier_id": setup["paid"], "quantity": 1}],
            "buyer_name": "A",
            "buyer_email": "a@example.com",
        },
    )
    assert r.status_code == 409


def test_tier_sales_window(client, setup, owner):
    later = (datetime.now(UTC) + timedelta(days=2)).isoformat()
    r = client.patch(
        f"{setup['base']}/tiers/{setup['paid']}", json={"sales_start_at": later}, headers=owner
    )
    assert r.status_code == 200
    assert _order(client, setup, setup["paid"]).json()["detail"] == "Early bird isn't on sale yet"


def test_seller_code_credits_seller(client, setup, owner):
    seller = client.post(
        f"{setup['base']}/sellers", json={"display_name": "Kez"}, headers=owner
    ).json()
    order = _order(client, setup, setup["paid"], 1, seller_code=seller["code"].lower()).json()
    _pay(client, order)
    report = client.get(f"{setup['base']}/report", headers=owner).json()
    kez = report["sellers"][0]
    assert (kez["display_name"], kez["tickets"], kez["gross_minor"]) == ("Kez", 1, 40000)


def test_signed_in_buyer_sees_their_orders(client, setup):
    me = _auth(client, "buyer@example.com")
    body = {
        "event_slug": setup["event"]["slug"],
        "items": [{"tier_id": setup["free"], "quantity": 1}],
        "buyer_name": "B",
        "buyer_email": "buyer@example.com",
    }
    assert client.post("/v1/orders", json=body, headers=me).status_code == 201
    assert client.post("/v1/orders", json=body).status_code == 201  # guest, not linked
    assert len(client.get("/v1/me/orders", headers=me).json()) == 1


def test_test_payments_hidden_outside_test_mode(client, setup, monkeypatch):
    order = _order(client, setup, setup["paid"]).json()
    monkeypatch.setattr(get_settings(), "payment_provider", "wipay")
    assert _pay(client, order).status_code == 404
    assert client.get("/v1/config").json() == {"payment_provider": "wipay", "test_payments": False}


# ---------- Staff sales ----------


def _member(client, setup, owner, email, role):
    h = _auth(client, email)
    r = client.post(
        f"/v1/orgs/{setup['org']}/members", json={"email": email, "role": role}, headers=owner
    )
    assert r.status_code == 201
    return h


def test_cash_sales_by_admin_and_seller(client, setup, owner):
    seller_h = _member(client, setup, owner, "kez@example.com", "seller")
    scanner_h = _member(client, setup, owner, "gate@example.com", "scanner")
    sale = {"tier_id": setup["paid"], "quantity": 2, "buyer_name": "Cash buyer"}

    # Not yet linked to a seller record.
    assert client.post(f"{setup['base']}/sales", json=sale, headers=seller_h).status_code == 403
    assert client.get(f"{setup['base']}/sellers/me", headers=seller_h).status_code == 404
    seller = client.post(
        f"{setup['base']}/sellers",
        json={"display_name": "Kez", "email": "kez@example.com"},
        headers=owner,
    ).json()
    assert client.get(f"{setup['base']}/sellers/me", headers=seller_h).json()["id"] == seller["id"]

    r = client.post(f"{setup['base']}/sales", json=sale, headers=seller_h)
    assert r.status_code == 201, r.text
    order = r.json()
    assert order["status"] == "paid"
    assert order["channel"] == "seller_cash"
    assert order["buyer_fee_minor"] == 0
    assert len(order["tickets"]) == 2

    # Max-per-order is an online limit; staff can sell the remaining 3 at once.
    box = {**sale, "quantity": 3, "channel": "box_office"}
    assert client.post(f"{setup['base']}/sales", json=box, headers=owner).status_code == 201
    assert client.post(f"{setup['base']}/sales", json=sale, headers=owner).status_code == 409
    assert client.post(f"{setup['base']}/sales", json=sale, headers=scanner_h).status_code == 403

    report = client.get(f"{setup['base']}/report", headers=owner).json()
    assert report["tickets_sold"] == 5
    assert report["gross_minor"] == 200000
    assert report["cash_collected_minor"] == 200000
    assert report["promoter_fees_minor"] == 6000
    assert report["payout_minor"] == 194000
    assert {c["channel"]: c["tickets"] for c in report["channels"]} == {
        "seller_cash": 2,
        "box_office": 3,
    }
    assert report["tiers"][0]["remaining"] == 0
    assert client.get(f"{setup['base']}/report", headers=seller_h).status_code == 403


def test_seller_cannot_credit_someone_else(client, setup, owner):
    seller_h = _member(client, setup, owner, "kez@example.com", "seller")
    client.post(
        f"{setup['base']}/sellers",
        json={"display_name": "Kez", "email": "kez@example.com"},
        headers=owner,
    )
    other = client.post(
        f"{setup['base']}/sellers", json={"display_name": "Other"}, headers=owner
    ).json()
    sale = {"tier_id": setup["paid"], "quantity": 1, "buyer_name": "X", "seller_id": other["id"]}
    assert client.post(f"{setup['base']}/sales", json=sale, headers=seller_h).status_code == 403


def test_orders_list_and_search(client, setup, owner):
    _order(client, setup, setup["free"], 1)
    pending = _order(client, setup, setup["paid"], 1, buyer_name="Zed").json()
    rows = client.get(f"{setup['base']}/orders", headers=owner).json()
    assert [r["buyer_name"] for r in rows] == ["Ana"]
    rows = client.get(
        f"{setup['base']}/orders", params={"include_unpaid": True, "q": "zed"}, headers=owner
    ).json()
    assert [(r["id"], r["status"]) for r in rows] == [(pending["id"], "pending")]
    assert rows[0]["link"].startswith("https://tickets.example.tt/orders/")


# ---------- Check-in ----------


def test_check_in(client, setup, owner):
    scanner_h = _member(client, setup, owner, "gate@example.com", "scanner")
    seller_h = _member(client, setup, owner, "kez@example.com", "seller")
    code = _order(client, setup, setup["free"], 1).json()["tickets"][0]["code"]
    url = f"{setup['base']}/checkin"

    assert client.get(url, headers=scanner_h).json() == {"checked_in": 0, "total": 1}
    r = client.post(url, json={"code": f"  {code} "}, headers=scanner_h).json()
    assert (r["result"], r["tier_name"], r["buyer_name"]) == ("ok", "RSVP", "Ana")
    assert (r["checked_in"], r["total"]) == (1, 1)
    again = client.post(url, json={"code": code}, headers=owner).json()
    assert again["result"] == "already_checked_in"
    assert again["checked_in_at"] is not None
    assert (
        client.post(url, json={"code": "bogus"}, headers=scanner_h).json()["result"] == "not_found"
    )
    assert client.post(url, json={"code": code}, headers=seller_h).status_code == 403

    order = client.get(f"/v1/orders/{_order(client, setup, setup['free'], 1).json()['id']}")
    assert order.status_code == 422  # token required


def test_check_in_wrong_event(client, setup, owner):
    ev = client.post(
        f"/v1/orgs/{setup['org']}/events",
        json={"title": "Other", "starts_at": FUTURE},
        headers=owner,
    ).json()
    code = _order(client, setup, setup["free"], 1).json()["tickets"][0]["code"]
    r = client.post(
        f"/v1/orgs/{setup['org']}/events/{ev['id']}/checkin", json={"code": code}, headers=owner
    ).json()
    assert r["result"] == "wrong_event"
    assert r["buyer_name"] is None


# ---------- Flyer upload ----------


def test_cover_upload(client, setup, owner):
    r = client.post(
        f"{setup['base']}/cover", files={"file": ("f.png", PNG, "image/png")}, headers=owner
    )
    assert r.status_code == 200, r.text
    url = r.json()["cover_image_url"]
    assert url.startswith("https://tickets.example.tt/api/uploads/events/")
    assert client.get(url.split("/api", 1)[1]).content == PNG

    r = client.post(
        f"{setup['base']}/cover",
        files={"file": ("x.png", b"not an image", "image/png")},
        headers=owner,
    )
    assert r.status_code == 422


# ---------- Rate limits ----------


def test_login_is_rate_limited(client, monkeypatch):
    monkeypatch.setattr(get_settings(), "rate_limits_enabled", True)
    ratelimit.reset()
    body = {"email": "x@example.com", "password": "wrong-password"}
    codes = [client.post("/v1/auth/login", json=body).status_code for _ in range(11)]
    assert codes[:10] == [401] * 10
    assert codes[10] == 429
    ratelimit.reset()
