"""Public organisation profiles and collaborator management."""

from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.listings import ListingSummaryOut


class OrganisationCardOut(BaseModel):
    """An organisation as a search result or a credit on a listing."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    slug: str
    instagram: str | None


class CollaboratorOut(OrganisationCardOut):
    # How the collaboration reads: "co-promoter", "sound by", "hosted by".
    credit: str | None


class OrganisationProfileOut(OrganisationCardOut):
    """An organisation's public page.

    Contact details are deliberately absent: `contact_email` and
    `contact_phone` are the promoter's own, collected for payouts and ticket
    admin, and publishing them is a decision nobody has made.
    """

    follower_count: int
    # The concept's split: what this organisation runs, and what it is credited on.
    owned_listings: list[ListingSummaryOut]
    collaborations: list[ListingSummaryOut]


class OrganisationPageOut(BaseModel):
    limit: int
    offset: int
    results: list[OrganisationCardOut]


class CollaboratorIn(BaseModel):
    organisation_id: UUID
    credit: str | None = Field(None, max_length=80)
