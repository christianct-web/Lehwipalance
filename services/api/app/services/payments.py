"""Payment provider boundary.

Rules (see docs/codebase-audit.md, PCI section):
- Card numbers and CVVs are entered ONLY on the provider's hosted page.
- This service stores the provider's reference, never card data.
- No stored-value wallet in v1 (T&T E-Money Issuer Order).

Providers:
- "test": a stand-in hosted checkout served by the web app at /pay/test/...,
  where the buyer presses "Pay" or "Decline". No money moves. Use it until the
  WiPay business account is approved. The site shows a test-mode banner.
- "wipay": not wired yet. Implement `WipayProvider` with Mana Labs 8's
  wipay-connect SDK and add a callback route that verifies the payload and
  calls `orders.mark_paid` / `orders.mark_failed`, as the test route does.
"""

from typing import Protocol
from urllib.parse import quote

from app.core.config import get_settings
from app.models import Order

PROVIDERS = {"test"}


class PaymentProvider(Protocol):
    def create_checkout(self, order: Order) -> str:
        """Return the hosted checkout URL for this order."""
        ...


class TestPaymentProvider:
    def create_checkout(self, order: Order) -> str:
        base = get_settings().public_base_url.rstrip("/")
        return f"{base}/pay/test/{order.id}?token={quote(order.access_token or '')}"


def get_provider() -> PaymentProvider:
    name = get_settings().payment_provider
    if name == "test":
        return TestPaymentProvider()
    raise RuntimeError(f"Payment provider {name!r} isn't available yet")


def check_configured() -> None:
    name = get_settings().payment_provider
    if name not in PROVIDERS:
        raise RuntimeError(
            f"PAYMENT_PROVIDER={name!r} isn't implemented yet. Use 'test' until the "
            "WiPay integration (wipay-connect) is added."
        )
