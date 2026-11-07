from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict

_DEV_SECRET = "dev-only-secret-change-me"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    environment: str = "development"
    database_url: str = "postgresql+psycopg://lehwi:lehwi@localhost:5432/lehwi"
    jwt_secret: str = _DEV_SECRET
    jwt_algorithm: str = "HS256"
    jwt_expires_minutes: int = 60
    cors_origins: str = "http://localhost:5173"

    # Where the web app lives, e.g. https://lehwipalance.com. Used to build the
    # links in ticket emails and the test checkout page.
    public_base_url: str = "http://localhost:5173"

    # Payments. "test" simulates a hosted checkout (no real money) until the
    # WiPay account is approved; "wipay" plugs in wipay-connect.
    payment_provider: str = "test"
    order_hold_minutes: int = 15
    wipay_account_number: str = ""
    wipay_api_key: str = ""
    wipay_environment: str = "sandbox"
    wipay_callback_url: str = ""

    # Flyer uploads. With Supabase set, images go to Supabase Storage; without
    # it they are written to `upload_dir` and served by the API at /uploads.
    supabase_url: str = ""
    supabase_service_key: str = ""
    supabase_bucket: str = "event-media"
    upload_dir: str = "/srv/uploads"
    max_upload_bytes: int = 5 * 1024 * 1024

    # Ticket emails. Leave smtp_host empty to skip sending.
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    smtp_from: str = "Lehwi Palance <tickets@example.com>"
    smtp_starttls: bool = True

    rate_limits_enabled: bool = True

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def is_production(self) -> bool:
        return self.environment == "production"

    @property
    def test_payments(self) -> bool:
        return self.payment_provider == "test"

    def check_production(self) -> None:
        """Refuse to boot a production server with development defaults."""
        if not self.is_production:
            return
        if self.jwt_secret == _DEV_SECRET or len(self.jwt_secret) < 32:
            raise RuntimeError("JWT_SECRET must be set to a random string of 32+ characters")
        if self.public_base_url.startswith("http://localhost"):
            raise RuntimeError("PUBLIC_BASE_URL must be set to the site's public address")


@lru_cache
def get_settings() -> Settings:
    return Settings()
