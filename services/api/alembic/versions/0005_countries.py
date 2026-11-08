"""markets: per-country currency, fee rates and category gating

The concept sets fee rates and feature availability per country, so they move
out of the code and into a table. Trinidad & Tobago is seeded with the rates
already implemented in services/fees.py and is the only live market.

Revision ID: 0005
Revises: 0004
Create Date: 2026-11-08 09:00:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0005"
down_revision: str | None = "0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

# Every category, since the full concept is being built for this one market.
# Food delivery stays off: it needs couriers, not a flag.
_TT_TYPES = '["event", "accommodation", "vacation", "service", "store"]'


def upgrade() -> None:
    op.create_table(
        "countries",
        sa.Column("code", sa.String(length=2), primary_key=True),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("timezone", sa.String(length=64), nullable=False),
        sa.Column("is_live", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("buyer_fee_bps", sa.Integer(), nullable=False),
        sa.Column("buyer_fee_fixed_minor", sa.Integer(), nullable=False),
        sa.Column("promoter_fee_bps", sa.Integer(), nullable=False),
        sa.Column("enabled_listing_types", sa.JSON(), nullable=False),
        sa.Column("delivery_enabled", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("default_latitude", sa.Float(), nullable=True),
        sa.Column("default_longitude", sa.Float(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.execute(
        f"""
        INSERT INTO countries (
            code, name, currency, timezone, is_live,
            buyer_fee_bps, buyer_fee_fixed_minor, promoter_fee_bps,
            enabled_listing_types, delivery_enabled,
            default_latitude, default_longitude,
            created_at, updated_at
        ) VALUES (
            'TT', 'Trinidad and Tobago', 'TTD', 'America/Port_of_Spain', true,
            450, 300, 300,
            '{_TT_TYPES}', false,
            10.6918, -61.2225,
            now(), now()
        )
        """
    )


def downgrade() -> None:
    op.drop_table("countries")
