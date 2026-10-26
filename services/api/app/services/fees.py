"""Fee model from the market & economics analysis (docs/market-and-economics.md).

All amounts are integer minor units (cents). Rates are basis points so the
arithmetic stays exact. Change the defaults here once the client signs off
on pricing.
"""

from dataclasses import dataclass

BUYER_FEE_BPS = 450  # 4.5% charged to the buyer
BUYER_FEE_FIXED_MINOR = 300  # + TT$3.00 per ticket
PROMOTER_FEE_BPS = 300  # 3% deducted from the promoter's payout


def _bps(amount_minor: int, bps: int) -> int:
    # Round half up to the nearest cent.
    return (amount_minor * bps + 5_000) // 10_000


@dataclass(frozen=True)
class FeeQuote:
    face_value_minor: int
    quantity: int
    subtotal_minor: int
    buyer_fee_minor: int
    total_minor: int
    promoter_fee_minor: int
    promoter_payout_minor: int


def quote(face_value_minor: int, quantity: int = 1) -> FeeQuote:
    if face_value_minor < 0 or quantity < 1:
        raise ValueError("face value must be >= 0 and quantity >= 1")
    subtotal = face_value_minor * quantity
    if face_value_minor == 0:
        buyer_fee = 0  # free RSVPs carry no fee
    else:
        buyer_fee = _bps(subtotal, BUYER_FEE_BPS) + BUYER_FEE_FIXED_MINOR * quantity
    promoter_fee = _bps(subtotal, PROMOTER_FEE_BPS)
    return FeeQuote(
        face_value_minor=face_value_minor,
        quantity=quantity,
        subtotal_minor=subtotal,
        buyer_fee_minor=buyer_fee,
        total_minor=subtotal + buyer_fee,
        promoter_fee_minor=promoter_fee,
        promoter_payout_minor=subtotal - promoter_fee,
    )
