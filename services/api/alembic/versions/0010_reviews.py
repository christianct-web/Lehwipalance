"""reviews, section ratings, and the rating rollup on listings

The concept's "community-driven feedback with structured ratings": an overall
score, optional per-section scores, and a verified-attendee badge.

The badge is settled when a review is written and then left alone. It records
that the person had a real, checked-in ticket — proof this platform holds
because it sold the ticket and scanned it. Simulated orders never earn it.

Section scores are a table, not a JSON blob: a listing page shows the average
per section, and averaging in SQL beats adding up numbers in Python.

The rollup on `listings` is a count and a sum rather than an average, so the
figures stay exact integers and discovery can filter on the average without
reading every review.

Revision ID: 0010
Revises: 0009
Create Date: 2026-11-08 16:00:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0010"
down_revision: str | None = "0009"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_SECTIONS = ("venue", "organisation", "value", "food", "music")


def upgrade() -> None:
    op.create_table(
        "reviews",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("listing_id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("rating", sa.SmallInteger(), nullable=False),
        sa.Column("comment", sa.Text(), nullable=True),
        sa.Column("is_verified_attendee", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["listing_id"], ["listings.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("listing_id", "user_id", name="uq_reviews_listing_user"),
        sa.CheckConstraint("rating BETWEEN 1 AND 5", name="ck_reviews_rating_range"),
    )
    op.create_index("ix_reviews_listing_id", "reviews", ["listing_id"])

    op.create_table(
        "review_section_ratings",
        sa.Column("review_id", sa.Uuid(), primary_key=True),
        sa.Column(
            "section",
            sa.Enum(*_SECTIONS, name="reviewsection", native_enum=False),
            primary_key=True,
        ),
        sa.Column("rating", sa.SmallInteger(), nullable=False),
        sa.ForeignKeyConstraint(["review_id"], ["reviews.id"], ondelete="CASCADE"),
        sa.CheckConstraint("rating BETWEEN 1 AND 5", name="ck_review_section_ratings_rating_range"),
    )

    op.add_column(
        "listings",
        sa.Column("rating_count", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "listings",
        sa.Column("rating_sum", sa.Integer(), nullable=False, server_default="0"),
    )
    op.create_index("ix_listings_rating", "listings", ["rating_count", "rating_sum"])


def downgrade() -> None:
    op.drop_index("ix_listings_rating", table_name="listings")
    op.drop_column("listings", "rating_sum")
    op.drop_column("listings", "rating_count")
    op.drop_table("review_section_ratings")
    op.drop_index("ix_reviews_listing_id", table_name="reviews")
    op.drop_table("reviews")
