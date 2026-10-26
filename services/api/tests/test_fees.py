import pytest

from app.services.fees import quote


def test_matches_business_model_table():
    # TT$500 face value, from docs/market-and-economics.md
    q = quote(50_000)
    assert q.buyer_fee_minor == 2_550  # 4.5% + TT$3
    assert q.total_minor == 52_550  # buyer pays TT$525.50
    assert q.promoter_payout_minor == 48_500  # promoter keeps TT$485 (97%)


def test_multiple_tickets_scale_fixed_fee():
    q = quote(30_000, quantity=4)
    assert q.subtotal_minor == 120_000
    assert q.buyer_fee_minor == 5_400 + 1_200


def test_free_rsvp_has_no_buyer_fee():
    q = quote(0, quantity=2)
    assert q.total_minor == 0


def test_rejects_bad_input():
    with pytest.raises(ValueError):
        quote(-1)


def test_quote_endpoint(client):
    r = client.get("/v1/fees/quote", params={"face_value_minor": 100_000})
    assert r.status_code == 200
    assert r.json()["total_minor"] == 104_800
