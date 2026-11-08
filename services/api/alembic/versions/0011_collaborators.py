"""collaborators: organisations credited on a listing they do not own

From docs/original-concept.md: a collaborator is an organisation, not an
individual vendor, so this reuses `organisations` rather than inventing a
parallel kind of party. An organisation page then splits into owned listings
and collaborations, which is the concept's "Owned Listings / Shared Listings".

`credit` is how the collaboration reads on the listing — co-promoter, sound by,
hosted by — because "collaborator" alone says nothing about what someone did.

Revision ID: 0011
Revises: 0010
Create Date: 2026-11-08 17:00:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0011"
down_revision: str | None = "0010"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "listing_collaborators",
        sa.Column("listing_id", sa.Uuid(), primary_key=True),
        sa.Column("organisation_id", sa.Uuid(), primary_key=True),
        sa.Column("credit", sa.String(length=80), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["listing_id"], ["listings.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["organisation_id"], ["organisations.id"], ondelete="CASCADE"),
    )
    op.create_index(
        "ix_listing_collaborators_organisation_id",
        "listing_collaborators",
        ["organisation_id"],
    )


def downgrade() -> None:
    op.drop_index("ix_listing_collaborators_organisation_id", table_name="listing_collaborators")
    op.drop_table("listing_collaborators")
