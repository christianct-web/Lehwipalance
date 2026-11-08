"""Request and response bodies for follows and favourites."""

from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.schemas.listings import ListingSummaryOut


class FollowedOrganisationOut(BaseModel):
    """An organisation someone follows, as their following list shows it."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    slug: str
    instagram: str | None
    follower_count: int


class FavouritesOut(BaseModel):
    total: int
    results: list[ListingSummaryOut]


class FollowerCountOut(BaseModel):
    slug: str
    follower_count: int
