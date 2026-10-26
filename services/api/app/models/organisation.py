import enum
import uuid

from sqlalchemy import Enum, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, IdMixin, TimestampMixin


class MemberRole(enum.StrEnum):
    owner = "owner"
    manager = "manager"
    seller = "seller"
    scanner = "scanner"


class Organisation(IdMixin, TimestampMixin, Base):
    """A promoter, band or venue that runs events and receives payouts."""

    __tablename__ = "organisations"

    name: Mapped[str] = mapped_column(String(200))
    slug: Mapped[str] = mapped_column(String(120), unique=True, index=True)
    contact_email: Mapped[str | None] = mapped_column(String(320), nullable=True)
    contact_phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    instagram: Mapped[str | None] = mapped_column(String(120), nullable=True)
    # Payout details are held by the payment provider; store only a reference here.
    payout_reference: Mapped[str | None] = mapped_column(String(120), nullable=True)

    members: Mapped[list["OrgMember"]] = relationship(back_populates="organisation")


class OrgMember(IdMixin, TimestampMixin, Base):
    __tablename__ = "org_members"
    __table_args__ = (UniqueConstraint("organisation_id", "user_id"),)

    organisation_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("organisations.id"))
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"))
    role: Mapped[MemberRole] = mapped_column(Enum(MemberRole, native_enum=False))

    organisation: Mapped[Organisation] = relationship(back_populates="members")
