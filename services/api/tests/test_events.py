from datetime import UTC, datetime, timedelta

from app.models import Event, EventStatus, Organisation, TicketTier


def _seed(db):
    org = Organisation(name="Test Promotions", slug="test-promotions")
    db.add(org)
    db.flush()
    upcoming = Event(
        organisation_id=org.id,
        title="Sunrise Cooler Fete",
        slug="sunrise-cooler-fete",
        status=EventStatus.published,
        starts_at=datetime.now(UTC) + timedelta(days=30),
        venue_name="Queen's Park Savannah",
    )
    draft = Event(
        organisation_id=org.id,
        title="Secret Draft",
        slug="secret-draft",
        status=EventStatus.draft,
        starts_at=datetime.now(UTC) + timedelta(days=40),
    )
    db.add_all([upcoming, draft])
    db.flush()
    db.add_all(
        [
            TicketTier(
                event_id=upcoming.id,
                name="Early bird",
                price_minor=45000,
                quantity=200,
                quantity_sold=200,
                sort_order=0,
            ),
            TicketTier(
                event_id=upcoming.id,
                name="Tier 1",
                price_minor=50000,
                quantity=500,
                quantity_sold=120,
                sort_order=1,
            ),
        ]
    )
    db.commit()


def test_lists_only_published_upcoming(client, db_session):
    _seed(db_session)
    r = client.get("/v1/events")
    assert r.status_code == 200
    assert [e["slug"] for e in r.json()] == ["sunrise-cooler-fete"]


def test_event_detail_with_tiers(client, db_session):
    _seed(db_session)
    r = client.get("/v1/events/sunrise-cooler-fete")
    assert r.status_code == 200
    tiers = r.json()["tiers"]
    assert [t["name"] for t in tiers] == ["Early bird", "Tier 1"]
    assert [t["remaining"] for t in tiers] == [0, 380]


def test_draft_is_not_public(client, db_session):
    _seed(db_session)
    assert client.get("/v1/events/secret-draft").status_code == 404
