"""accommodation: properties, room types and bookings

The second shape of `Offer`, and the reason it exists. A ticket tier holds one
pool that depletes; a room holds `units` on each night, so a room sold for
Friday is free again on Saturday. Availability is the worst night in a range,
not a single subtraction.

`bookings.stay_end` is the departure date and is exclusive, so a departure and
an arrival can share a day without colliding. Every overlap test in
app/services/bookings.py depends on that, and the check constraint here keeps
the dates ordered.

Revision ID: 0014
Revises: 0013
Create Date: 2026-11-08 20:00:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0014"
down_revision: str | None = "0013"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_PROPERTY_TYPES = ("hotel", "guesthouse", "villa", "apartment", "hostel", "other")
_BOOKING_STATUSES = (
    "held",
    "confirmed",
    "checked_in",
    "checked_out",
    "cancelled",
    "no_show",
)


def upgrade() -> None:
    op.create_table(
        "accommodation_details",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "property_type",
            sa.Enum(*_PROPERTY_TYPES, name="propertytype", native_enum=False),
            nullable=False,
        ),
        sa.Column("check_in_after", sa.Time(), nullable=True),
        sa.Column("check_out_before", sa.Time(), nullable=True),
        sa.ForeignKeyConstraint(["id"], ["listings.id"], ondelete="CASCADE"),
    )

    op.create_table(
        "room_types",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("units", sa.Integer(), nullable=False),
        sa.Column("max_guests", sa.Integer(), nullable=False),
        sa.Column("min_nights", sa.Integer(), nullable=False),
        sa.ForeignKeyConstraint(["id"], ["offers.id"], ondelete="CASCADE"),
    )

    op.create_table(
        "bookings",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("order_id", sa.Uuid(), nullable=False),
        sa.Column("offer_id", sa.Uuid(), nullable=False),
        sa.Column("guest_id", sa.Uuid(), nullable=True),
        sa.Column("stay_start", sa.Date(), nullable=False),
        sa.Column("stay_end", sa.Date(), nullable=False),
        sa.Column("rooms", sa.Integer(), nullable=False),
        sa.Column("guests", sa.Integer(), nullable=False),
        sa.Column("code", sa.String(length=64), nullable=False),
        sa.Column(
            "status",
            sa.Enum(*_BOOKING_STATUSES, name="bookingstatus", native_enum=False),
            nullable=False,
        ),
        sa.Column("checked_in_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("checked_out_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["order_id"], ["orders.id"]),
        sa.ForeignKeyConstraint(["offer_id"], ["offers.id"]),
        sa.ForeignKeyConstraint(["guest_id"], ["users.id"]),
        sa.CheckConstraint("stay_end > stay_start", name="ck_bookings_dates_ordered"),
        sa.CheckConstraint("rooms > 0", name="ck_bookings_rooms_positive"),
    )
    op.create_index("ix_bookings_order_id", "bookings", ["order_id"])
    op.create_index("ix_bookings_offer_id", "bookings", ["offer_id"])
    op.create_index("ix_bookings_code", "bookings", ["code"], unique=True)
    op.create_index("ix_bookings_status", "bookings", ["status"])
    # The shape of the availability query: this room type, these nights.
    op.create_index("ix_bookings_offer_dates", "bookings", ["offer_id", "stay_start", "stay_end"])


def downgrade() -> None:
    op.drop_index("ix_bookings_offer_dates", table_name="bookings")
    op.drop_index("ix_bookings_status", table_name="bookings")
    op.drop_index("ix_bookings_code", table_name="bookings")
    op.drop_index("ix_bookings_offer_id", table_name="bookings")
    op.drop_index("ix_bookings_order_id", table_name="bookings")
    op.drop_table("bookings")
    op.drop_table("room_types")
    op.drop_table("accommodation_details")
