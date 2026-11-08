"""Request and response bodies for reviews."""

from datetime import datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.models import ReviewSection
from app.models.review import MAX_RATING, MIN_RATING

_Rating = Field(ge=MIN_RATING, le=MAX_RATING)
# Section scores are bounded exactly like the overall one. Without this the
# dict values were unvalidated and only the database stood in the way.
Score = Annotated[int, Field(ge=MIN_RATING, le=MAX_RATING)]


class ReviewIn(BaseModel):
    rating: int = _Rating
    comment: str | None = Field(None, max_length=4_000)
    # Section scores, keyed by section name. Partial is fine: someone rating
    # the venue but having eaten nothing should not have to score the food.
    sections: dict[ReviewSection, Score] = Field(default_factory=dict)

    def section_scores(self) -> dict[str, int]:
        return {str(k): v for k, v in self.sections.items()}


class ReviewPatch(BaseModel):
    rating: int | None = Field(None, ge=MIN_RATING, le=MAX_RATING)
    comment: str | None = Field(None, max_length=4_000)
    sections: dict[ReviewSection, Score] | None = None


class SectionRatingOut(BaseModel):
    section: str
    rating: int


class ReviewOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    rating: int
    comment: str | None
    # Proof this person was scanned in at the gate.
    is_verified_attendee: bool
    author_name: str
    created_at: datetime
    updated_at: datetime
    sections: list[SectionRatingOut]


class SectionSummaryOut(BaseModel):
    section: str
    count: int
    average: float


class ReviewSummaryOut(BaseModel):
    count: int
    average: float | None
    verified_count: int
    sections: list[SectionSummaryOut]


class ReviewPageOut(BaseModel):
    listing_slug: str
    summary: ReviewSummaryOut
    limit: int
    offset: int
    results: list[ReviewOut]
