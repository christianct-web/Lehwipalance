"""Payment provider boundary.

Rules (see docs/codebase-audit.md, PCI section):
- Card numbers and CVVs are entered ONLY on the provider's hosted page.
- This service stores the provider's reference, never card data.
- No stored-value wallet in v1 (T&T E-Money Issuer Order).

The WiPay integration should reuse Mana Labs 8's wipay-connect SDK and
callback server rather than a fresh client.
"""

from typing import Protocol
from uuid import UUID


class PaymentProvider(Protocol):
    def create_checkout(self, order_id: UUID, amount_minor: int, currency: str) -> str:
        """Return the hosted checkout URL for this order."""
        ...

    def verify_callback(self, payload: dict) -> tuple[UUID, bool, str]:
        """Validate a provider callback; return (order_id, paid, provider_reference)."""
        ...
