"""follows and favourites

The concept's "followings": follow an organisation to see what it has on, and
save listings you like. Composite primary keys, so following or saving twice is
the same as once and there is no surrogate id nobody needs.

Revision ID: 0009
Revises: 0008
Create Date: 2026-11-08 15:00:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0009"
down_revision: str | None = "0008"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "follows",
        sa.Column("user_id", sa.Uuid(), primary_key=True),
        sa.Column("organisation_id", sa.Uuid(), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["organisation_id"], ["organisations.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_follows_organisation_id", "follows", ["organisation_id"])

    op.create_table(
        "favourites",
        sa.Column("user_id", sa.Uuid(), primary_key=True),
        sa.Column("listing_id", sa.Uuid(), primary_key=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["listing_id"], ["listings.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_favourites_listing_id", "favourites", ["listing_id"])


def downgrade() -> None:
    op.drop_index("ix_favourites_listing_id", table_name="favourites")
    op.drop_table("favourites")
    op.drop_index("ix_follows_organisation_id", table_name="follows")
    op.drop_table("follows")
