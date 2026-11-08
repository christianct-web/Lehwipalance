"""offers: one sellable base for every category

Accommodation needs an inventory shape the ticket engine cannot express. A
ticket tier counts a single pool; a room counts per night. So what an order line
points at becomes an `offers` base — price, currency, sales window, the listing
it belongs to — and how many are left stays the subclass's business.

This is the generalisation deliberately left out of Phase A, done now that
there is a second real shape to generalise against rather than speculatively.
It is a pure refactor: nothing about ticketing changes behaviourally.

Ticket tiers keep their ids, so nothing that references them has to be remapped.
Three columns are renamed to say what they now mean: `order_items.tier_id` and
`tickets.tier_id` become `offer_id`, and `orders.event_id` becomes `listing_id`,
because an accommodation order is not for an event.

Revision ID: 0013
Revises: 0012
Create Date: 2026-11-08 19:00:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0013"
down_revision: str | None = "0012"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_OFFER_TYPES = ("ticket_tier", "room_type")

# Columns that move from ticket_tiers up onto offers.
_MOVED = (
    "name",
    "price_minor",
    "currency",
    "sort_order",
    "sales_start_at",
    "sales_end_at",
    "created_at",
    "updated_at",
)


def upgrade() -> None:
    op.create_table(
        "offers",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("listing_id", sa.Uuid(), nullable=False),
        sa.Column(
            "type",
            sa.Enum(*_OFFER_TYPES, name="offertype", native_enum=False),
            nullable=False,
        ),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("price_minor", sa.Integer(), nullable=False),
        sa.Column("currency", sa.String(length=3), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False),
        sa.Column("sales_start_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sales_end_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["listing_id"], ["listings.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_offers_listing_id", "offers", ["listing_id"])
    op.create_index("ix_offers_type", "offers", ["type"])
    op.create_index("ix_offers_listing_type", "offers", ["listing_id", "type"])

    # Same ids, so order_items, tickets and anything else keep pointing at the
    # right row without a remap.
    op.execute(
        """
        INSERT INTO offers (
            id, listing_id, type, name, price_minor, currency, sort_order,
            sales_start_at, sales_end_at, created_at, updated_at
        )
        SELECT id, event_id, 'ticket_tier', name, price_minor, currency,
               sort_order, sales_start_at, sales_end_at, created_at, updated_at
        FROM ticket_tiers
        """
    )

    # ticket_tiers shrinks to what is genuinely tier-specific.
    op.drop_index("ix_ticket_tiers_event_id", table_name="ticket_tiers")
    op.drop_constraint("ticket_tiers_event_id_fkey", "ticket_tiers", type_="foreignkey")
    op.drop_column("ticket_tiers", "event_id")
    for column in _MOVED:
        op.drop_column("ticket_tiers", column)
    op.create_foreign_key(
        "ticket_tiers_id_fkey", "ticket_tiers", "offers", ["id"], ["id"], ondelete="CASCADE"
    )

    # Order lines and tickets point at an offer.
    op.drop_index("ix_order_items_tier_id", table_name="order_items")
    op.drop_constraint("order_items_tier_id_fkey", "order_items", type_="foreignkey")
    op.alter_column("order_items", "tier_id", new_column_name="offer_id")
    op.create_foreign_key(
        "order_items_offer_id_fkey", "order_items", "offers", ["offer_id"], ["id"]
    )
    op.create_index("ix_order_items_offer_id", "order_items", ["offer_id"])

    op.drop_index("ix_tickets_tier_id", table_name="tickets")
    op.drop_constraint("tickets_tier_id_fkey", "tickets", type_="foreignkey")
    op.alter_column("tickets", "tier_id", new_column_name="offer_id")
    op.create_foreign_key("tickets_offer_id_fkey", "tickets", "offers", ["offer_id"], ["id"])
    op.create_index("ix_tickets_offer_id", "tickets", ["offer_id"])

    # An order is for a listing, of whatever category.
    op.drop_index("ix_orders_event_id", table_name="orders")
    op.drop_constraint("orders_event_id_fkey", "orders", type_="foreignkey")
    op.alter_column("orders", "event_id", new_column_name="listing_id")
    op.create_foreign_key("orders_listing_id_fkey", "orders", "listings", ["listing_id"], ["id"])
    op.create_index("ix_orders_listing_id", "orders", ["listing_id"])


def downgrade() -> None:
    op.drop_index("ix_orders_listing_id", table_name="orders")
    op.drop_constraint("orders_listing_id_fkey", "orders", type_="foreignkey")
    op.alter_column("orders", "listing_id", new_column_name="event_id")
    op.create_foreign_key("orders_event_id_fkey", "orders", "event_details", ["event_id"], ["id"])
    op.create_index("ix_orders_event_id", "orders", ["event_id"])

    op.drop_index("ix_tickets_offer_id", table_name="tickets")
    op.drop_constraint("tickets_offer_id_fkey", "tickets", type_="foreignkey")
    op.alter_column("tickets", "offer_id", new_column_name="tier_id")
    op.create_foreign_key("tickets_tier_id_fkey", "tickets", "ticket_tiers", ["tier_id"], ["id"])
    op.create_index("ix_tickets_tier_id", "tickets", ["tier_id"])

    op.drop_index("ix_order_items_offer_id", table_name="order_items")
    op.drop_constraint("order_items_offer_id_fkey", "order_items", type_="foreignkey")
    op.alter_column("order_items", "offer_id", new_column_name="tier_id")
    op.create_foreign_key(
        "order_items_tier_id_fkey", "order_items", "ticket_tiers", ["tier_id"], ["id"]
    )
    op.create_index("ix_order_items_tier_id", "order_items", ["tier_id"])

    # Put the moved columns back and refill them from offers.
    op.drop_constraint("ticket_tiers_id_fkey", "ticket_tiers", type_="foreignkey")
    op.add_column("ticket_tiers", sa.Column("event_id", sa.Uuid(), nullable=True))
    op.add_column("ticket_tiers", sa.Column("name", sa.String(length=120), nullable=True))
    op.add_column("ticket_tiers", sa.Column("price_minor", sa.Integer(), nullable=True))
    op.add_column("ticket_tiers", sa.Column("currency", sa.String(length=3), nullable=True))
    op.add_column("ticket_tiers", sa.Column("sort_order", sa.Integer(), nullable=True))
    op.add_column(
        "ticket_tiers", sa.Column("sales_start_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.add_column(
        "ticket_tiers", sa.Column("sales_end_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.add_column(
        "ticket_tiers", sa.Column("created_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.add_column(
        "ticket_tiers", sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.execute(
        """
        UPDATE ticket_tiers t
        SET event_id = o.listing_id, name = o.name, price_minor = o.price_minor,
            currency = o.currency, sort_order = o.sort_order,
            sales_start_at = o.sales_start_at, sales_end_at = o.sales_end_at,
            created_at = o.created_at, updated_at = o.updated_at
        FROM offers o
        WHERE o.id = t.id
        """
    )
    for column in (
        "event_id",
        "name",
        "price_minor",
        "currency",
        "sort_order",
        "created_at",
        "updated_at",
    ):
        op.alter_column("ticket_tiers", column, nullable=False)
    op.create_foreign_key(
        "ticket_tiers_event_id_fkey", "ticket_tiers", "event_details", ["event_id"], ["id"]
    )
    op.create_index("ix_ticket_tiers_event_id", "ticket_tiers", ["event_id"])

    op.drop_index("ix_offers_listing_type", table_name="offers")
    op.drop_index("ix_offers_type", table_name="offers")
    op.drop_index("ix_offers_listing_id", table_name="offers")
    op.drop_table("offers")
