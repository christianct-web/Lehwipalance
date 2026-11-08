"""events become listings: one base table for every category

Discovery, the map, search, filter profiles, follows, favourites, reviews, the
media feed and collaborators all have to work across the five categories in
docs/original-concept.md. Rather than a union over five sibling tables, they get
one `listings` base holding everything discovery touches, with a detail table
per category keyed by the same id (joined-table inheritance).

`events` becomes `listings` (type='event') plus `event_details`, which for now
holds only the event category. Rows carry over, and ticket_tiers, sellers and
orders are repointed at `event_details` — a tighter constraint than `listings`,
since those three can only ever belong to an event.

Revision ID: 0006
Revises: 0005
Create Date: 2026-11-08 09:30:00
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0006"
down_revision: str | None = "0005"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_LISTING_TYPES = ("event", "accommodation", "vacation", "service", "store")
_STATUSES = ("draft", "published", "cancelled")
_CATEGORIES = ("fete", "concert", "festival", "sport", "community", "other")

# Tables whose event_id must follow events -> event_details.
_CHILDREN = ("ticket_tiers", "sellers", "orders")


def upgrade() -> None:
    op.create_table(
        "listings",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("organisation_id", sa.Uuid(), nullable=False),
        sa.Column(
            "type",
            sa.Enum(*_LISTING_TYPES, name="listingtype", native_enum=False),
            nullable=False,
        ),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("slug", sa.String(length=160), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column(
            "status",
            sa.Enum(*_STATUSES, name="listingstatus", native_enum=False),
            nullable=False,
        ),
        sa.Column("country_code", sa.String(length=2), nullable=False),
        sa.Column("city", sa.String(length=120), nullable=True),
        sa.Column("venue_name", sa.String(length=200), nullable=True),
        sa.Column("address", sa.String(length=300), nullable=True),
        sa.Column("latitude", sa.Float(), nullable=True),
        sa.Column("longitude", sa.Float(), nullable=True),
        sa.Column("cover_image_url", sa.String(length=500), nullable=True),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("tags", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["organisation_id"], ["organisations.id"]),
        sa.ForeignKeyConstraint(["country_code"], ["countries.code"]),
        sa.CheckConstraint(
            "type <> 'event' OR starts_at IS NOT NULL",
            name="ck_listings_event_has_start",
        ),
    )
    op.create_index("ix_listings_organisation_id", "listings", ["organisation_id"])
    op.create_index("ix_listings_slug", "listings", ["slug"], unique=True)
    op.create_index("ix_listings_status", "listings", ["status"])
    op.create_index("ix_listings_type", "listings", ["type"])
    op.create_index("ix_listings_starts_at", "listings", ["starts_at"])
    op.create_index("ix_listings_country_code", "listings", ["country_code"])
    op.create_index("ix_listings_discovery", "listings", ["type", "status", "starts_at"])
    op.create_index("ix_listings_country_city", "listings", ["country_code", "city"])

    op.create_table(
        "event_details",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "category",
            sa.Enum(*_CATEGORIES, name="eventcategory", native_enum=False),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["id"], ["listings.id"], ondelete="CASCADE"),
    )

    # Carry the rows over. Every existing event is a Trinidad & Tobago event:
    # it is the only market, and the only one seeded in 0005.
    op.execute(
        """
        INSERT INTO listings (
            id, organisation_id, type, title, slug, description, status,
            country_code, city, venue_name, address, latitude, longitude,
            cover_image_url, starts_at, ends_at, tags, created_at, updated_at
        )
        SELECT
            id, organisation_id, 'event', title, slug, description, status,
            'TT', NULL, venue_name, address, latitude, longitude,
            cover_image_url, starts_at, ends_at, '[]', created_at, updated_at
        FROM events
        """
    )
    op.execute("INSERT INTO event_details (id, category) SELECT id, category FROM events")

    # Follow the children over before the old table goes.
    for table in _CHILDREN:
        op.drop_constraint(f"{table}_event_id_fkey", table, type_="foreignkey")
        op.create_foreign_key(
            f"{table}_event_id_fkey", table, "event_details", ["event_id"], ["id"]
        )

    op.drop_table("events")


def downgrade() -> None:
    op.create_table(
        "events",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("organisation_id", sa.Uuid(), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("slug", sa.String(length=160), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column(
            "category",
            sa.Enum(*_CATEGORIES, name="eventcategory", native_enum=False),
            nullable=False,
        ),
        sa.Column(
            "status",
            sa.Enum(*_STATUSES, name="eventstatus", native_enum=False),
            nullable=False,
        ),
        sa.Column("venue_name", sa.String(length=200), nullable=True),
        sa.Column("address", sa.String(length=300), nullable=True),
        sa.Column("latitude", sa.Float(), nullable=True),
        sa.Column("longitude", sa.Float(), nullable=True),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("cover_image_url", sa.String(length=500), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["organisation_id"], ["organisations.id"]),
    )
    op.create_index("ix_events_organisation_id", "events", ["organisation_id"])
    op.create_index("ix_events_slug", "events", ["slug"], unique=True)
    op.create_index("ix_events_status", "events", ["status"])
    op.create_index("ix_events_starts_at", "events", ["starts_at"])

    # Only events can go back; any other category would have nowhere to land.
    op.execute(
        """
        INSERT INTO events (
            id, organisation_id, title, slug, description, category, status,
            venue_name, address, latitude, longitude, starts_at, ends_at,
            cover_image_url, created_at, updated_at
        )
        SELECT
            l.id, l.organisation_id, l.title, l.slug, l.description,
            d.category, l.status, l.venue_name, l.address, l.latitude,
            l.longitude, l.starts_at, l.ends_at, l.cover_image_url,
            l.created_at, l.updated_at
        FROM listings l
        JOIN event_details d ON d.id = l.id
        WHERE l.type = 'event'
        """
    )

    for table in _CHILDREN:
        op.drop_constraint(f"{table}_event_id_fkey", table, type_="foreignkey")
        op.create_foreign_key(f"{table}_event_id_fkey", table, "events", ["event_id"], ["id"])

    op.drop_table("event_details")
    op.drop_table("listings")
