"""discovery: a price rollup on listings, and tags as their own table

Two things the filter set in docs/original-concept.md needs and Phase A did not
give it.

Price: a filter profile filters by price range, and each category stores price
differently (ticket tiers now; rate plans and tour departures later). A rollup
on the listing lets discovery filter and sort without knowing which. Backfilled
from ticket_tiers and maintained by app.services.listings.refresh_price_range.

Tags: `listings.tags` was a JSON column. Tags are a first-class filter, and a
table is indexable and behaves the same on Postgres and on the SQLite test
database, where JSON containment would need JSONB. Any existing values are
moved over, normalised, before the column goes.

Revision ID: 0007
Revises: 0006
Create Date: 2026-11-08 12:00:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0007"
down_revision: str | None = "0006"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("listings", sa.Column("price_min_minor", sa.Integer(), nullable=True))
    op.add_column("listings", sa.Column("price_max_minor", sa.Integer(), nullable=True))
    op.create_index("ix_listings_price_min", "listings", ["price_min_minor"])

    op.create_table(
        "listing_tags",
        sa.Column("listing_id", sa.Uuid(), primary_key=True),
        sa.Column("tag", sa.String(length=60), primary_key=True),
        sa.ForeignKeyConstraint(["listing_id"], ["listings.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_listing_tags_tag", "listing_tags", ["tag"])

    # Move any authored tags across, lowercased and whitespace-collapsed, the
    # same normalisation ListingTag.normalise applies.
    op.execute(
        """
        INSERT INTO listing_tags (listing_id, tag)
        SELECT DISTINCT l.id,
               lower(regexp_replace(btrim(t.value), '\\s+', ' ', 'g'))
        FROM listings l
        CROSS JOIN json_array_elements_text(l.tags::json) AS t(value)
        WHERE btrim(t.value) <> ''
        ON CONFLICT DO NOTHING
        """
    )
    op.drop_column("listings", "tags")

    # An event's price range is the span of its tiers. All tiers, not just the
    # ones on sale right now: a sales window opening or closing must not need a
    # background job to keep discovery honest.
    op.execute(
        """
        UPDATE listings l
        SET price_min_minor = t.lo, price_max_minor = t.hi
        FROM (
            SELECT event_id, MIN(price_minor) AS lo, MAX(price_minor) AS hi
            FROM ticket_tiers
            GROUP BY event_id
        ) t
        WHERE t.event_id = l.id
        """
    )


def downgrade() -> None:
    op.add_column("listings", sa.Column("tags", sa.JSON(), nullable=False, server_default="[]"))
    op.execute(
        """
        UPDATE listings l
        SET tags = COALESCE(t.arr, '[]'::json)
        FROM (
            SELECT listing_id, json_agg(tag ORDER BY tag) AS arr
            FROM listing_tags
            GROUP BY listing_id
        ) t
        WHERE t.listing_id = l.id
        """
    )
    op.drop_index("ix_listing_tags_tag", table_name="listing_tags")
    op.drop_table("listing_tags")
    op.drop_index("ix_listings_price_min", table_name="listings")
    op.drop_column("listings", "price_max_minor")
    op.drop_column("listings", "price_min_minor")
