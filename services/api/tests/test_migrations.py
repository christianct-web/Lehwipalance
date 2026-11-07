"""Upgrade tests against real Postgres (the production database).

Run when TEST_POSTGRES_URL points at a disposable database, e.g.
  TEST_POSTGRES_URL=postgresql+psycopg://lehwi:lehwi@localhost:5432/lehwi_test pytest
CI provides one. The database's public schema is dropped and recreated.
"""

import os
import uuid
from datetime import UTC, datetime, timedelta
from pathlib import Path

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, text

from app.core.config import get_settings

PG_URL = os.environ.get("TEST_POSTGRES_URL")
pytestmark = pytest.mark.skipif(not PG_URL, reason="TEST_POSTGRES_URL not set")

API_ROOT = Path(__file__).resolve().parents[1]


@pytest.fixture
def pg(monkeypatch):
    engine = create_engine(PG_URL)
    with engine.begin() as conn:
        conn.execute(text("DROP SCHEMA public CASCADE"))
        conn.execute(text("CREATE SCHEMA public"))
    # alembic/env.py takes the URL from the app settings.
    monkeypatch.setattr(get_settings(), "database_url", PG_URL)
    cfg = Config(str(API_ROOT / "alembic.ini"))
    cfg.set_main_option("script_location", str(API_ROOT / "alembic"))
    yield engine, cfg
    engine.dispose()


def _insert(conn, table, **values):
    values.setdefault("id", uuid.uuid4())
    cols = ", ".join(values)
    params = ", ".join(f":{k}" for k in values)
    conn.execute(text(f"INSERT INTO {table} ({cols}) VALUES ({params})"), values)
    return values["id"]


def _seed_0002(conn):
    """Data as the 0002 code left it: simulated payments consumed inventory."""
    now = datetime.now(UTC)
    stamp = {"created_at": now, "updated_at": now}
    org = _insert(conn, "organisations", name="Tribe", slug="tribe", **stamp)
    event = _insert(
        conn,
        "events",
        organisation_id=org,
        title="Fete",
        slug="fete",
        category="fete",
        status="published",
        starts_at=now + timedelta(days=30),
        **stamp,
    )

    def tier(name, price, quantity, sold):
        return _insert(
            conn,
            "ticket_tiers",
            event_id=event,
            name=name,
            price_minor=price,
            currency="TTD",
            quantity=quantity,
            quantity_sold=sold,
            max_per_order=10,
            sort_order=0,
            **stamp,
        )

    # Paid tier: 2 simulated + 1 real cash = 3 sold. Free tier: 1 real RSVP.
    vip = tier("VIP", 10000, 5, 3)
    rsvp = tier("RSVP", 0, 10, 1)

    def order(tier_id, qty, channel, status, total, reference):
        oid = _insert(
            conn,
            "orders",
            event_id=event,
            status=status,
            channel=channel,
            currency="TTD",
            subtotal_minor=total,
            buyer_fee_minor=0,
            promoter_fee_minor=0,
            total_minor=total,
            payment_reference=reference,
            buyer_name="B",
            access_token=uuid.uuid4().hex,
            **stamp,
        )
        _insert(
            conn, "order_items", order_id=oid, tier_id=tier_id, quantity=qty, unit_price_minor=0
        )
        if status == "paid":
            for _ in range(qty):
                _insert(
                    conn,
                    "tickets",
                    order_id=oid,
                    tier_id=tier_id,
                    code=uuid.uuid4().hex,
                    status="valid",
                    **stamp,
                )
        return oid

    return {
        "vip": vip,
        "rsvp": rsvp,
        "sim_paid": order(vip, 2, "online", "paid", 20000, "TEST-ABC123"),
        "sim_pending": order(vip, 1, "online", "pending", 10000, None),
        "cash": order(vip, 1, "seller_cash", "paid", 10000, None),
        "free": order(rsvp, 1, "online", "paid", 0, None),
    }


def _sold(conn, tier_id):
    return conn.scalar(text("SELECT quantity_sold FROM ticket_tiers WHERE id = :i"), {"i": tier_id})


def _is_test(conn, order_id):
    return conn.scalar(text("SELECT is_test FROM orders WHERE id = :i"), {"i": order_id})


def test_upgrade_releases_inventory_of_backfilled_test_orders(pg):
    engine, cfg = pg
    command.upgrade(cfg, "0002")
    with engine.begin() as conn:
        ids = _seed_0002(conn)

    command.upgrade(cfg, "head")
    with engine.begin() as conn:
        # Simulated orders are flagged; real cash and free orders are not.
        assert _is_test(conn, ids["sim_paid"]) is True
        assert _is_test(conn, ids["sim_pending"]) is True
        assert _is_test(conn, ids["cash"]) is False
        assert _is_test(conn, ids["free"]) is False
        # Only the real cash sale still counts against the paid tier.
        assert _sold(conn, ids["vip"]) == 1
        assert _sold(conn, ids["rsvp"]) == 1

    # Downgrading puts the old accounting back (0002 counted test sales as sold).
    command.downgrade(cfg, "0002")
    with engine.begin() as conn:
        assert _sold(conn, ids["vip"]) == 3
        assert _sold(conn, ids["rsvp"]) == 1


def test_upgrade_after_0003_already_deployed(pg):
    """The previous release ran 0003 (flag only); then the current code took more
    orders before 0004 arrived. 0004 must fix the old count without touching the new."""
    engine, cfg = pg
    command.upgrade(cfg, "0002")
    with engine.begin() as conn:
        ids = _seed_0002(conn)
    command.upgrade(cfg, "0003")
    now = datetime.now(UTC)
    with engine.begin() as conn:
        assert _sold(conn, ids["vip"]) == 3  # the bug: simulated sales still counted
        event = conn.scalar(
            text("SELECT event_id FROM ticket_tiers WHERE id = :i"), {"i": ids["vip"]}
        )
        # Under the current code: a simulated sale (no inventory) and a real cash sale (+1).
        for is_test, channel, ref in ((True, "online", "TEST-NEW"), (False, "box_office", None)):
            oid = _insert(
                conn,
                "orders",
                event_id=event,
                status="paid",
                channel=channel,
                currency="TTD",
                subtotal_minor=10000,
                buyer_fee_minor=0,
                promoter_fee_minor=0,
                total_minor=10000,
                payment_reference=ref,
                access_token=uuid.uuid4().hex,
                is_test=is_test,
                created_at=now,
                updated_at=now,
            )
            _insert(
                conn,
                "order_items",
                order_id=oid,
                tier_id=ids["vip"],
                quantity=1,
                unit_price_minor=0,
            )
        conn.execute(
            text("UPDATE ticket_tiers SET quantity_sold = quantity_sold + 1 WHERE id = :i"),
            {"i": ids["vip"]},
        )

    command.upgrade(cfg, "head")
    with engine.begin() as conn:
        assert _sold(conn, ids["vip"]) == 2  # the old cash sale + the new box-office sale
        assert _sold(conn, ids["rsvp"]) == 1

    # Re-running the recount is harmless.
    command.downgrade(cfg, "0003")
    command.upgrade(cfg, "head")
    with engine.begin() as conn:
        assert _sold(conn, ids["vip"]) == 2


def test_upgrade_matches_the_app(pg):
    """After upgrade, the app's report and public availability agree with the data."""
    from sqlalchemy.orm import sessionmaker

    from app.models import Event, TicketTier
    from app.services import orders

    engine, cfg = pg
    command.upgrade(cfg, "0002")
    with engine.begin() as conn:
        ids = _seed_0002(conn)
    command.upgrade(cfg, "head")

    db = sessionmaker(bind=engine)()
    try:
        vip = db.get(TicketTier, ids["vip"])
        held = orders.held_quantities(db, [vip.id])
        assert orders.available(vip, held) == 4  # 5 - 1 real sale; test orders hold nothing
        event = db.get(Event, vip.event_id)
        assert orders.check_in(db, event, _first_code(db, ids["sim_paid"]), None).result == (
            "test_ticket"
        )
    finally:
        db.close()


def _first_code(db, order_id):
    return db.scalar(text("SELECT code FROM tickets WHERE order_id = :o LIMIT 1"), {"o": order_id})
