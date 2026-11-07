"""flag orders paid through the simulated test provider

Revision ID: 0003
Revises: 0002
Create Date: 2026-11-08 12:00:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0003"
down_revision: str | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "orders",
        sa.Column("is_test", sa.Boolean(), server_default=sa.false(), nullable=False),
    )
    # Online orders created before this flag existed were all simulated (no
    # live provider has ever been configured), so mark them as test orders.
    op.execute(
        "UPDATE orders SET is_test = true "
        "WHERE channel = 'online' AND total_minor > 0 "
        "AND (payment_reference IS NULL OR payment_reference LIKE 'TEST-%')"
    )


def downgrade() -> None:
    op.drop_column("orders", "is_test")
