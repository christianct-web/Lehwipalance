"""Resolving a market: its currency, fee rates and which categories it shows.

Every listing names a country, and that row — not a constant — decides the
currency a sale is priced in, the fee rates charged on it, and whether the
category is on offer there at all.
"""

import logging

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import Country, ListingType
from app.services.fees import TTD, FeeConfig

log = logging.getLogger(__name__)


def default_code() -> str:
    return get_settings().default_country


def get(db: Session, code: str | None = None) -> Country | None:
    return db.get(Country, (code or default_code()).upper())


def live_countries(db: Session) -> list[Country]:
    return list(db.scalars(select(Country).where(Country.is_live.is_(True)).order_by(Country.name)))


def fee_config(db: Session, code: str | None = None) -> FeeConfig:
    """The market's fee rates, falling back to Trinidad & Tobago's.

    A listing's `country_code` is a non-null foreign key, so in Postgres the row
    is always there. The fallback covers unit tests on SQLite, which does not
    enforce foreign keys, and is logged so a genuinely missing row is visible.
    """
    country = get(db, code)
    if country is None:
        log.warning("no countries row for %r; using the %s defaults", code, TTD.currency)
        return TTD
    return FeeConfig(
        currency=country.currency,
        buyer_fee_bps=country.buyer_fee_bps,
        buyer_fee_fixed_minor=country.buyer_fee_fixed_minor,
        promoter_fee_bps=country.promoter_fee_bps,
    )


def allows(db: Session, code: str | None, listing_type: ListingType) -> bool:
    """Whether a market shows a category. An unknown market shows nothing."""
    country = get(db, code)
    return country is not None and country.is_live and country.allows(listing_type)
