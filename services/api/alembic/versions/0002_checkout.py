"""guest checkout, inventory holds and staff-recorded sales

Revision ID: 0002
Revises: 0001
Create Date: 2026-11-07 12:00:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("orders", sa.Column("buyer_name", sa.String(length=200), nullable=True))
    op.add_column("orders", sa.Column("buyer_email", sa.String(length=320), nullable=True))
    op.add_column("orders", sa.Column("buyer_phone", sa.String(length=32), nullable=True))
    op.add_column("orders", sa.Column("access_token", sa.String(length=64), nullable=True))
    op.add_column("orders", sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("orders", sa.Column("recorded_by", sa.Uuid(), nullable=True))
    op.create_foreign_key("fk_orders_recorded_by_users", "orders", "users", ["recorded_by"], ["id"])
    op.create_index(op.f("ix_orders_buyer_email"), "orders", ["buyer_email"], unique=False)
    op.create_index(op.f("ix_orders_access_token"), "orders", ["access_token"], unique=True)
    op.create_index(op.f("ix_order_items_tier_id"), "order_items", ["tier_id"], unique=False)
    op.create_index(op.f("ix_tickets_tier_id"), "tickets", ["tier_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_tickets_tier_id"), table_name="tickets")
    op.drop_index(op.f("ix_order_items_tier_id"), table_name="order_items")
    op.drop_index(op.f("ix_orders_access_token"), table_name="orders")
    op.drop_index(op.f("ix_orders_buyer_email"), table_name="orders")
    op.drop_constraint("fk_orders_recorded_by_users", "orders", type_="foreignkey")
    for column in (
        "recorded_by",
        "expires_at",
        "access_token",
        "buyer_phone",
        "buyer_email",
        "buyer_name",
    ):
        op.drop_column("orders", column)
