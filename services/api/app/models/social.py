import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, utcnow


class Follow(Base):
    """A customer following an organisation.

    From docs/original-concept.md: following an organisation is how someone
    gets "a personalized feed of updates from followed orgs". People follow
    organisations, not listings — a listing is an event that ends, an
    organisation is the promoter you keep up with.

    A composite primary key, so following twice is the same as following once
    and there is no surrogate id nobody needs.
    """

    __tablename__ = "follows"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    organisation_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("organisations.id", ondelete="CASCADE"), primary_key=True, index=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Favourite(Base):
    """A listing someone saved. The concept's "like and save favorite listings"."""

    __tablename__ = "favourites"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    listing_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("listings.id", ondelete="CASCADE"), primary_key=True, index=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
