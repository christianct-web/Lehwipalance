"""give back inventory taken by simulated sales before 0003

Before 0003, test-provider payments added to ticket_tiers.quantity_sold. 0003
flagged those orders is_test but left the counts, so tiers could look sold out.

The app increments quantity_sold only for paid, non-test orders (free tickets,
cash and box-office sales, settled live payments), so the right value is always
the sum of those orders' items. Recompute it from that: exact, safe to re-run,
and correct whether 0003 ran in an earlier release or together with this one.

Revision ID: 0004
Revises: 0003
Create Date: 2026-11-08 18:00:00
"""

from collections.abc import Sequence

from alembic import op

revision: str = "0004"
down_revision: str | None = "0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _paid_items(test: bool) -> str:
    return f"""
        SELECT COALESCE(SUM(oi.quantity), 0)
        FROM order_items oi
        JOIN orders o ON o.id = oi.order_id
        WHERE oi.tier_id = ticket_tiers.id
          AND o.status = 'paid'
          AND o.is_test = {"true" if test else "false"}
    """


def upgrade() -> None:
    op.execute(f"UPDATE ticket_tiers SET quantity_sold = ({_paid_items(test=False)})")


def downgrade() -> None:
    # Code before this revision counted paid test orders as sold; put them back.
    op.execute(
        f"UPDATE ticket_tiers SET quantity_sold = ({_paid_items(test=False)}) "
        f"+ ({_paid_items(test=True)})"
    )
