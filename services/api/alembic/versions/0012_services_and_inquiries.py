"""services: the vendor directory, and the inquiry flow that books it

The first of the four new categories, taken first because it needs no
inventory engine: a service has no tiers, no dates and no checkout. Booking it
happens through an inquiry, which is the concept's "contact and booking flow
directly in-app".

The inquiry states match the Flutter customer app's existing
`InquiryStatus` (pending, responded, resolved, cancelled) so RealApiService
needs no translation layer.

`service_details.base_price_minor` stays null for a quote-only service, which
keeps the listing out of price filters rather than pretending it is free.

Revision ID: 0012
Revises: 0011
Create Date: 2026-11-08 18:00:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0012"
down_revision: str | None = "0011"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_CATEGORIES = (
    "catering",
    "bar",
    "av_production",
    "photography",
    "entertainment",
    "planning",
    "decor",
    "security",
    "transport",
    "staffing",
    "other",
)
_PRICE_MODELS = ("fixed", "from", "hourly", "per_person", "quote_only")
_INQUIRY_STATUSES = ("pending", "responded", "resolved", "cancelled")


def upgrade() -> None:
    op.create_table(
        "service_details",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "category",
            sa.Enum(*_CATEGORIES, name="servicecategory", native_enum=False),
            nullable=False,
        ),
        sa.Column(
            "price_model",
            sa.Enum(*_PRICE_MODELS, name="pricemodel", native_enum=False),
            nullable=False,
        ),
        sa.Column("base_price_minor", sa.Integer(), nullable=True),
        sa.Column("min_notice_days", sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(["id"], ["listings.id"], ondelete="CASCADE"),
        sa.CheckConstraint(
            "(price_model = 'quote_only') = (base_price_minor IS NULL)",
            name="ck_service_details_price_matches_model",
        ),
    )

    op.create_table(
        "inquiries",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("listing_id", sa.Uuid(), nullable=False),
        sa.Column("organisation_id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("subject", sa.String(length=200), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("event_date", sa.Date(), nullable=True),
        sa.Column("contact_phone", sa.String(length=32), nullable=True),
        sa.Column("response", sa.Text(), nullable=True),
        sa.Column(
            "status",
            sa.Enum(*_INQUIRY_STATUSES, name="inquirystatus", native_enum=False),
            nullable=False,
        ),
        sa.Column("responded_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["listing_id"], ["listings.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["organisation_id"], ["organisations.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_inquiries_listing_id", "inquiries", ["listing_id"])
    op.create_index("ix_inquiries_organisation_id", "inquiries", ["organisation_id"])
    op.create_index("ix_inquiries_status", "inquiries", ["status"])


def downgrade() -> None:
    op.drop_index("ix_inquiries_status", table_name="inquiries")
    op.drop_index("ix_inquiries_organisation_id", table_name="inquiries")
    op.drop_index("ix_inquiries_listing_id", table_name="inquiries")
    op.drop_table("inquiries")
    op.drop_table("service_details")
