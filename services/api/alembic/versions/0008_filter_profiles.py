"""filter profiles: saved discovery preferences per country or city

From docs/original-concept.md: a logged-in customer keeps several of these and
switches between them to change their feed. The columns mirror
app.services.listings.Filters, which is what the feed runs.

`listing_types` and `tags` are JSON here, unlike `listing_tags` on a listing:
they are read back whole to build a query, never themselves queried.

Exactly one profile per user is active, enforced in the service rather than by a
partial unique index, which would have to be spelled differently per backend.

Revision ID: 0008
Revises: 0007
Create Date: 2026-11-08 14:00:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0008"
down_revision: str | None = "0007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_PRICE_BANDS = ("any", "free", "paid", "custom")
_DATE_PREFERENCES = ("upcoming", "this_weekend", "this_month", "custom")


def upgrade() -> None:
    op.create_table(
        "filter_profiles",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=80), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("country_code", sa.String(length=2), nullable=False),
        sa.Column("city", sa.String(length=120), nullable=True),
        sa.Column("listing_types", sa.JSON(), nullable=False),
        sa.Column("tags", sa.JSON(), nullable=False),
        sa.Column(
            "price_band",
            sa.Enum(*_PRICE_BANDS, name="priceband", native_enum=False),
            nullable=False,
        ),
        sa.Column("price_min_minor", sa.Integer(), nullable=True),
        sa.Column("price_max_minor", sa.Integer(), nullable=True),
        sa.Column(
            "date_preference",
            sa.Enum(*_DATE_PREFERENCES, name="datepreference", native_enum=False),
            nullable=False,
        ),
        sa.Column("starts_after", sa.DateTime(timezone=True), nullable=True),
        sa.Column("starts_before", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sort", sa.String(length=20), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["country_code"], ["countries.code"]),
        sa.UniqueConstraint("user_id", "name", name="uq_filter_profiles_user_name"),
    )
    op.create_index("ix_filter_profiles_user_id", "filter_profiles", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_filter_profiles_user_id", table_name="filter_profiles")
    op.drop_table("filter_profiles")
