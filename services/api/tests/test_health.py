def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_production_refuses_dev_defaults():
    import pytest

    from app.core.config import Settings

    base = {"environment": "production", "public_base_url": "https://tickets.example.tt"}
    with pytest.raises(RuntimeError, match="JWT_SECRET"):
        Settings(**base, jwt_secret="short").check_production()
    with pytest.raises(RuntimeError, match="PUBLIC_BASE_URL"):
        Settings(
            environment="production", jwt_secret="x" * 40, public_base_url="http://localhost:5173"
        ).check_production()
    Settings(**base, jwt_secret="x" * 40).check_production()


def test_unknown_payment_provider_refused(monkeypatch):
    import pytest

    from app.core.config import get_settings
    from app.services import payments

    monkeypatch.setattr(get_settings(), "payment_provider", "wipay")
    with pytest.raises(RuntimeError, match="isn't implemented yet"):
        payments.check_configured()
