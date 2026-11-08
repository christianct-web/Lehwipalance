"""Fee model from the market & economics analysis (docs/market-and-economics.md).

All amounts are integer minor units (cents). Rates are basis points so the
arithmetic stays exact.

Rates are per country, held on the `countries` row and resolved by
`app.services.countries.fee_config`, because the concept calls for
admin-configurable base rates per market. The constant below is Trinidad &
Tobago, the only live market, and is the fallback where no database row is
available.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class FeeConfig:
    """What one market charges. Mirrors the fee columns on `countries`."""

    currency: str
    buyer_fee_bps: int
    buyer_fee_fixed_minor: int
    promoter_fee_bps: int


# Trinidad & Tobago: buyer pays 4.5% + TT$3 per ticket, promoter pays 3%.
# Seeded into `countries` by migration 0005; mirrored here so the arithmetic
# can be tested, and used when no country row is in reach.
TTD = FeeConfig(
    currency="TTD",
    buyer_fee_bps=450,
    buyer_fee_fixed_minor=300,
    promoter_fee_bps=300,
)


def _bps(amount_minor: int, bps: int) -> int:
    # Round half up to the nearest cent.
    return (amount_minor * bps + 5_000) // 10_000


@dataclass(frozen=True)
class FeeQuote:
    currency: str
    face_value_minor: int
    quantity: int
    subtotal_minor: int
    buyer_fee_minor: int
    total_minor: int
    promoter_fee_minor: int
    promoter_payout_minor: int


def quote(face_value_minor: int, quantity: int = 1, config: FeeConfig = TTD) -> FeeQuote:
    if face_value_minor < 0 or quantity < 1:
        raise ValueError("face value must be >= 0 and quantity >= 1")
    subtotal = face_value_minor * quantity
    if face_value_minor == 0:
        buyer_fee = 0  # free RSVPs carry no fee
    else:
        buyer_fee = _bps(subtotal, config.buyer_fee_bps) + config.buyer_fee_fixed_minor * quantity
    promoter_fee = _bps(subtotal, config.promoter_fee_bps)
    return FeeQuote(
        currency=config.currency,
        face_value_minor=face_value_minor,
        quantity=quantity,
        subtotal_minor=subtotal,
        buyer_fee_minor=buyer_fee,
        total_minor=subtotal + buyer_fee,
        promoter_fee_minor=promoter_fee,
        promoter_payout_minor=subtotal - promoter_fee,
    )
