import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, utcnow


class ListingCollaborator(Base):
    """An organisation credited on someone else's listing.

    From docs/original-concept.md: "a Collaborator is listed as an Organization
    — not as an individual vendor", it is discoverable alongside other
    organisations, and its profile shows every listing it is linked to. So this
    reuses `organisations` rather than inventing a parallel kind of party, and
    an organisation page splits into owned listings and collaborations.

    `credit` is how the collaboration reads on the listing — "co-promoter",
    "sound by", "hosted by" — because "collaborator" alone says nothing about
    what someone did.
    """

    __tablename__ = "listing_collaborators"

    listing_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("listings.id", ondelete="CASCADE"), primary_key=True
    )
    organisation_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("organisations.id", ondelete="CASCADE"), primary_key=True, index=True
    )
    credit: Mapped[str | None] = mapped_column(String(80), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
