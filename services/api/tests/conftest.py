import os

os.environ.setdefault("DATABASE_URL", "sqlite+pysqlite:///:memory:")
os.environ.setdefault("JWT_SECRET", "test-secret-that-is-long-enough-for-hs256")
os.environ.setdefault("RATE_LIMITS_ENABLED", "false")
os.environ.setdefault("PAYMENT_PROVIDER", "test")
os.environ.setdefault("PUBLIC_BASE_URL", "https://tickets.example.tt")
os.environ.setdefault("SMTP_HOST", "")
os.environ.setdefault("SUPABASE_URL", "")

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402

import app.models  # noqa: E402,F401
from app.db.base import Base  # noqa: E402
from app.db.session import get_db  # noqa: E402
from app.main import app  # noqa: E402
from app.models import Country, ListingType  # noqa: E402


@pytest.fixture
def db_session():
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    session = sessionmaker(bind=engine, expire_on_commit=False)()
    # The one live market, as migration 0005 seeds it, so tests resolve fees
    # and currency the same way the deployed app does.
    session.add(
        Country(
            code="TT",
            name="Trinidad and Tobago",
            currency="TTD",
            timezone="America/Port_of_Spain",
            is_live=True,
            buyer_fee_bps=450,
            buyer_fee_fixed_minor=300,
            promoter_fee_bps=300,
            enabled_listing_types=[t.value for t in ListingType],
            delivery_enabled=False,
        )
    )
    session.commit()
    try:
        yield session
    finally:
        session.close()
        engine.dispose()


@pytest.fixture(autouse=True)
def _uploads(tmp_path, monkeypatch):
    from app.core.config import get_settings

    monkeypatch.setattr(get_settings(), "upload_dir", str(tmp_path / "uploads"))


@pytest.fixture
def client(db_session):
    app.dependency_overrides[get_db] = lambda: db_session
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
