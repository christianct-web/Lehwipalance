import enum
import uuid

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Enum,
    ForeignKey,
    SmallInteger,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, IdMixin, TimestampMixin

MIN_RATING = 1
MAX_RATING = 5


class ReviewSection(enum.StrEnum):
    """The concept's "section-based ratings (venue, food, organization, value,
    etc.)". A fixed set so per-section averages are comparable across listings.

    These suit an event. Accommodation and tours will want their own — rooms
    want cleanliness, a tour wants the guide — so this grows per category when
    those land rather than being guessed at now.
    """

    venue = "venue"
    organisation = "organisation"
    value = "value"
    food = "food"
    music = "music"


class Review(IdMixin, TimestampMixin, Base):
    """One person's verdict on one listing.

    `is_verified_attendee` is settled when the review is written and then left
    alone. It records that this person had a real, checked-in ticket — proof
    this platform holds and a directory cannot fake. It is a statement about
    the past, so a ticket later being voided does not retract it.

    Simulated (`is_test`) orders never grant it: a demo ticket must not buy
    credibility any more than it buys entry.
    """

    __tablename__ = "reviews"
    __table_args__ = (
        UniqueConstraint("listing_id", "user_id", name="uq_reviews_listing_user"),
        CheckConstraint(
            f"rating BETWEEN {MIN_RATING} AND {MAX_RATING}", name="ck_reviews_rating_range"
        ),
    )

    listing_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("listings.id", ondelete="CASCADE"), index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    rating: Mapped[int] = mapped_column(SmallInteger)
    comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_verified_attendee: Mapped[bool] = mapped_column(Boolean, default=False)

    sections: Mapped[list["ReviewSectionRating"]] = relationship(
        back_populates="review", cascade="all, delete-orphan", lazy="selectin"
    )


class ReviewSectionRating(Base):
    """One section score on one review.

    A table rather than a JSON blob on the review: a listing page shows the
    average per section, and averaging in SQL beats reading every review to add
    up numbers in Python.
    """

    __tablename__ = "review_section_ratings"
    __table_args__ = (
        CheckConstraint(
            f"rating BETWEEN {MIN_RATING} AND {MAX_RATING}",
            name="ck_review_section_ratings_rating_range",
        ),
    )

    review_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("reviews.id", ondelete="CASCADE"), primary_key=True
    )
    section: Mapped[ReviewSection] = mapped_column(
        Enum(ReviewSection, native_enum=False), primary_key=True
    )
    rating: Mapped[int] = mapped_column(SmallInteger)

    review: Mapped[Review] = relationship(back_populates="sections")
