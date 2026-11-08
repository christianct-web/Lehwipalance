"""Accommodation: rooms, per-night availability, and booking a stay."""

import uuid
from datetime import UTC, date, datetime, timedelta

import pytest

from app.core.config import get_settings
from app.models import Booking, BookingStatus, Country, ListingType, Order, OrderStatus
from app.services import payments


class FakeLiveProvider:
    """A real provider: orders are real money, not simulated."""

    def create_checkout(self, order):
        return f"https://pay.example/{order.id}"


@pytest.fixture(autouse=True)
def live_payments(monkeypatch):
    # Availability is about real inventory, so default to a live provider.
    monkeypatch.setattr(get_settings(), "payment_provider", "fake-live")
    monkeypatch.setattr(payments, "get_provider", FakeLiveProvider)


def _auth(client, email):
    r = client.post(
        "/v1/auth/register",
        json={"email": email, "full_name": email.split("@")[0].title(), "password": "password123"},
    )
    assert r.status_code == 201
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def _d(offset: int) -> str:
    return (date.today() + timedelta(days=offset)).isoformat()


@pytest.fixture
def hotel(client):
    """A guesthouse with 2 Standard rooms (TT$450/night) and 1 Suite."""
    headers = _auth(client, "host@example.com")
    org = client.post("/v1/orgs", json={"name": "Maracas Guesthouse"}, headers=headers).json()["id"]
    place = client.post(
        f"/v1/orgs/{org}/places",
        json={
            "title": "Maracas Bay Guesthouse",
            "description": "Five minutes from the beach, breakfast included.",
            "city": "Maracas",
            "property_type": "guesthouse",
            "check_in_after": "14:00:00",
            "check_out_before": "11:00:00",
            "tags": ["Beach", "  BREAKFAST  "],
        },
        headers=headers,
    ).json()
    base = f"/v1/orgs/{org}/places/{place['id']}"
    client.post(
        f"{base}/rooms",
        json={"name": "Standard Double", "price_minor": 45000, "units": 2, "max_guests": 2},
        headers=headers,
    )
    place = client.post(
        f"{base}/rooms",
        json={
            "name": "Suite",
            "price_minor": 90000,
            "units": 1,
            "max_guests": 4,
            "min_nights": 2,
        },
        headers=headers,
    ).json()
    client.post(f"{base}/publish", headers=headers)
    rooms = {r["name"]: r["id"] for r in place["rooms"]}
    return {"headers": headers, "org": org, "place": place, "rooms": rooms, "base": base}


def _book(
    client, hotel, room="Standard Double", *, start=10, end=12, rooms=1, guests=2, email=None
):
    return client.post(
        "/v1/stays",
        json={
            "listing_slug": hotel["place"]["slug"],
            "room_type_id": hotel["rooms"][room],
            "stay_start": _d(start),
            "stay_end": _d(end),
            "rooms": rooms,
            "guests": guests,
            "buyer_name": "Guest",
            "buyer_email": email or "guest@example.com",
        },
    )


def _free(client, hotel, *, start=10, end=12, guests=1, rooms=1):
    body = client.get(
        f"/v1/listings/{hotel['place']['slug']}/availability",
        params={"stay_start": _d(start), "stay_end": _d(end), "guests": guests, "rooms": rooms},
    ).json()
    return {r["room"]["name"]: r for r in body["rooms"]}, body


# ---------- Listing a property ----------


def test_publish_needs_rooms_and_a_description(client):
    headers = _auth(client, "host@example.com")
    org = client.post("/v1/orgs", json={"name": "Bare Inn"}, headers=headers).json()["id"]
    place = client.post(
        f"/v1/orgs/{org}/places", json={"title": "Bare Inn"}, headers=headers
    ).json()
    base = f"/v1/orgs/{org}/places/{place['id']}"
    # Somewhere to stay is the more fundamental requirement, so it is reported
    # first.
    r = client.post(f"{base}/publish", headers=headers)
    assert r.status_code == 409 and "room" in r.json()["detail"]

    client.post(
        f"{base}/rooms",
        json={"name": "Double", "price_minor": 30000, "units": 1},
        headers=headers,
    )
    r = client.post(f"{base}/publish", headers=headers)
    assert r.status_code == 409 and "description" in r.json()["detail"]

    client.patch(base, json={"description": "A place to stay."}, headers=headers)
    assert client.post(f"{base}/publish", headers=headers).json()["status"] == "published"


def test_price_rollup_spans_the_room_rates(client, hotel):
    body = client.get(
        "/v1/listings", params={"type": "accommodation", "upcoming_only": "false"}
    ).json()
    row = next(r for r in body["results"] if r["slug"] == hotel["place"]["slug"])
    assert (row["price_min_minor"], row["price_max_minor"]) == (45000, 90000)
    assert row["tags"] == ["beach", "breakfast"]


def test_generic_detail_carries_accommodation_fields(client, hotel):
    body = client.get(f"/v1/listings/{hotel['place']['slug']}").json()
    assert body["type"] == "accommodation"
    assert body["accommodation"]["property_type"] == "guesthouse"
    assert body["accommodation"]["check_in_after"] == "14:00:00"
    assert body["event"] is None and body["service"] is None


def test_accommodation_must_be_enabled_in_the_market(client, db_session, hotel):
    tt = db_session.get(Country, "TT")
    tt.enabled_listing_types = [t.value for t in ListingType if t is not ListingType.accommodation]
    db_session.commit()
    r = client.post(
        f"/v1/orgs/{hotel['org']}/places", json={"title": "Too Late"}, headers=hotel["headers"]
    )
    assert r.status_code == 409


# ---------- Availability, the per-night part ----------


def test_availability_prices_the_whole_stay(client, hotel):
    rooms, body = _free(client, hotel, start=10, end=13)
    assert body["nights"] == 3
    std = rooms["Standard Double"]
    assert std["available"] == 2
    # Three nights at TT$450, and the fixed fee charged once, not per night.
    assert std["subtotal_minor"] == 135000
    assert std["buyer_fee_minor"] == 6075 + 300
    assert std["total_minor"] == 135000 + 6375


def test_a_booking_takes_only_the_nights_it_uses(client, hotel):
    """The point of the Offer split: a room sold for one night is free the next."""
    assert _book(client, hotel, start=10, end=11).status_code == 201

    rooms, _ = _free(client, hotel, start=10, end=11)
    assert rooms["Standard Double"]["available"] == 1, "that night is one down"
    rooms, _ = _free(client, hotel, start=11, end=12)
    assert rooms["Standard Double"]["available"] == 2, "the next night is untouched"


def test_departure_and_arrival_can_share_a_day(client, hotel):
    """stay_end is exclusive: checking out Wednesday frees Wednesday night."""
    assert _book(client, hotel, start=10, end=12, rooms=2).status_code == 201
    rooms, _ = _free(client, hotel, start=12, end=13)
    assert rooms["Standard Double"]["available"] == 2


def test_the_worst_night_decides_a_longer_stay(client, hotel):
    """Both rooms are taken on one night only; a stay spanning it cannot use
    either, even though the other nights are free."""
    assert _book(client, hotel, start=11, end=12, rooms=2).status_code == 201
    rooms, _ = _free(client, hotel, start=10, end=14)
    assert rooms["Standard Double"]["available"] == 0
    assert rooms["Standard Double"]["unavailable_reason"] == "fully booked"
    # A stay avoiding that night is fine.
    rooms, _ = _free(client, hotel, start=12, end=14)
    assert rooms["Standard Double"]["available"] == 2


def test_cannot_oversell_a_night(client, hotel):
    assert _book(client, hotel, start=10, end=12, rooms=2).status_code == 201
    r = _book(client, hotel, start=11, end=13, rooms=1, email="other@example.com")
    assert r.status_code == 409
    assert "fully booked" in r.json()["detail"]


def test_minimum_nights_and_occupancy(client, hotel):
    # The suite needs two nights.
    r = _book(client, hotel, room="Suite", start=10, end=11, guests=2)
    assert r.status_code == 409 and "2-night minimum" in r.json()["detail"]
    # And sleeps four.
    r = _book(client, hotel, room="Suite", start=10, end=12, guests=5)
    assert r.status_code == 409 and "sleeps 4" in r.json()["detail"]
    assert _book(client, hotel, room="Suite", start=10, end=12, guests=4).status_code == 201

    rooms, _ = _free(client, hotel, start=10, end=11, guests=2)
    assert rooms["Suite"]["unavailable_reason"] == "2-night minimum"


def test_rejects_backwards_and_past_dates(client, hotel):
    assert _book(client, hotel, start=12, end=12).status_code == 422
    assert _book(client, hotel, start=12, end=10).status_code == 422
    assert _book(client, hotel, start=-2, end=3).status_code == 422
    assert _book(client, hotel, start=10, end=200).status_code == 422


def test_availability_window_is_bounded(client, hotel):
    r = client.get(
        f"/v1/listings/{hotel['place']['slug']}/availability",
        params={"stay_start": _d(1), "stay_end": _d(200)},
    )
    assert r.status_code == 422
    r = client.get(
        f"/v1/listings/{hotel['place']['slug']}/availability",
        params={"stay_start": _d(5), "stay_end": _d(5)},
    )
    assert r.status_code == 422


def test_draft_places_are_not_bookable(client, hotel):
    client.post(f"{hotel['base']}/unpublish", headers=hotel["headers"])
    assert _book(client, hotel).status_code == 404
    assert (
        client.get(
            f"/v1/listings/{hotel['place']['slug']}/availability",
            params={"stay_start": _d(10), "stay_end": _d(12)},
        ).status_code
        == 404
    )


# ---------- Holds and settlement ----------


def test_a_pending_booking_holds_its_nights_then_releases_them(client, db_session, hotel):
    r = _book(client, hotel, start=10, end=12, rooms=2)
    assert r.status_code == 201
    stay = r.json()
    assert stay["status"] == "pending"
    assert stay["booking"]["status"] == "held"
    assert stay["checkout_url"].startswith("https://pay.example/")

    rooms, _ = _free(client, hotel, start=10, end=12)
    assert rooms["Standard Double"]["available"] == 0, "a hold is not availability"

    # Let the hold lapse.
    order = db_session.get(Order, uuid.UUID(stay["id"]))
    order.expires_at = datetime.now(UTC) - timedelta(minutes=1)
    db_session.commit()
    rooms, _ = _free(client, hotel, start=10, end=12)
    assert rooms["Standard Double"]["available"] == 2, "a lapsed hold frees the nights"


def test_settlement_confirms_the_booking(client, hotel, monkeypatch):
    monkeypatch.setattr(get_settings(), "payment_provider", "test")
    monkeypatch.setattr(get_settings(), "test_checkout", True)
    monkeypatch.setattr(payments, "get_provider", payments.TestPaymentProvider)

    stay = _book(client, hotel, start=10, end=12).json()
    r = client.post(
        f"/v1/payments/test/stays/{stay['id']}",
        params={"token": stay["access_token"], "outcome": "paid"},
    )
    assert r.status_code == 200
    assert r.json()["status"] == "paid"
    assert r.json()["booking"]["status"] == "confirmed"
    # Settling twice is a no-op.
    again = client.post(
        f"/v1/payments/test/stays/{stay['id']}",
        params={"token": stay["access_token"], "outcome": "paid"},
    )
    assert again.json()["status"] == "paid"


def test_a_declined_payment_releases_the_nights(client, hotel, monkeypatch):
    monkeypatch.setattr(get_settings(), "payment_provider", "test")
    monkeypatch.setattr(get_settings(), "test_checkout", True)
    monkeypatch.setattr(payments, "get_provider", payments.TestPaymentProvider)

    stay = _book(client, hotel, start=10, end=12, rooms=2).json()
    r = client.post(
        f"/v1/payments/test/stays/{stay['id']}",
        params={"token": stay["access_token"], "outcome": "failed"},
    )
    assert r.json()["status"] == "failed"
    assert r.json()["booking"]["status"] == "cancelled"
    rooms, _ = _free(client, hotel, start=10, end=12)
    assert rooms["Standard Double"]["available"] == 2


def test_simulated_bookings_never_hold_a_room(client, hotel, monkeypatch):
    """The same rule as a simulated ticket: it demonstrates, it does not consume."""
    monkeypatch.setattr(get_settings(), "payment_provider", "test")
    monkeypatch.setattr(get_settings(), "test_checkout", True)
    monkeypatch.setattr(payments, "get_provider", payments.TestPaymentProvider)

    stay = _book(client, hotel, start=10, end=12, rooms=2).json()
    assert stay["is_test"] is True
    client.post(
        f"/v1/payments/test/stays/{stay['id']}",
        params={"token": stay["access_token"], "outcome": "paid"},
    )
    rooms, _ = _free(client, hotel, start=10, end=12)
    assert rooms["Standard Double"]["available"] == 2, "a demo booking takes nothing"


def test_a_stay_is_private_to_its_token(client, hotel):
    stay = _book(client, hotel).json()
    assert (
        client.get(f"/v1/stays/{stay['id']}", params={"token": stay["access_token"]}).status_code
        == 200
    )
    assert client.get(f"/v1/stays/{stay['id']}", params={"token": "wrong"}).status_code == 404


def test_free_stays_confirm_immediately(client, db_session, hotel):
    client.patch(
        f"{hotel['base']}/rooms/{hotel['rooms']['Standard Double']}",
        json={"price_minor": 0},
        headers=hotel["headers"],
    )
    stay = _book(client, hotel, start=10, end=12).json()
    assert stay["status"] == "paid"
    assert stay["booking"]["status"] == "confirmed"
    assert stay["checkout_url"] is None


# ---------- Managing rooms against live bookings ----------


def test_units_cannot_drop_below_what_is_booked(client, hotel):
    assert _book(client, hotel, start=10, end=12, rooms=2).status_code == 201
    r = client.patch(
        f"{hotel['base']}/rooms/{hotel['rooms']['Standard Double']}",
        json={"units": 1},
        headers=hotel["headers"],
    )
    assert r.status_code == 409
    assert "booked" in r.json()["detail"]


def test_a_room_with_bookings_cannot_be_deleted(client, hotel):
    _book(client, hotel, start=10, end=12)
    r = client.delete(
        f"{hotel['base']}/rooms/{hotel['rooms']['Standard Double']}", headers=hotel["headers"]
    )
    assert r.status_code == 409
    # An unbooked room can go.
    r = client.delete(f"{hotel['base']}/rooms/{hotel['rooms']['Suite']}", headers=hotel["headers"])
    assert r.status_code == 204


def test_another_organisation_cannot_touch_the_property(client, hotel):
    other = _auth(client, "other@example.com")
    other_org = client.post("/v1/orgs", json={"name": "Outsiders"}, headers=other).json()["id"]
    assert (
        client.get(f"/v1/orgs/{other_org}/places/{hotel['place']['id']}", headers=other).status_code
        == 404
    )
    assert (
        client.patch(
            f"/v1/orgs/{hotel['org']}/places/{hotel['place']['id']}",
            json={"title": "Hijacked"},
            headers=other,
        ).status_code
        == 404
    )


def test_ticketing_is_untouched_by_bookings(client, db_session, hotel):
    """A booking order and a ticket order live side by side in `orders`."""
    _book(client, hotel, start=10, end=12)
    orders = db_session.query(Order).all()
    bookings_count = db_session.query(Booking).count()
    assert len(orders) == 1 and bookings_count == 1
    assert orders[0].status == OrderStatus.pending
    assert db_session.query(Booking).one().status == BookingStatus.held
