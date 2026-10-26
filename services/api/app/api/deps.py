from collections.abc import Callable
from typing import Annotated
from uuid import UUID

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.db.session import get_db
from app.models import MemberRole, OrgMember, User

DbSession = Annotated[Session, Depends(get_db)]
_bearer = HTTPBearer(auto_error=False)


def get_current_user(
    db: DbSession,
    creds: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
) -> User:
    unauthorized = HTTPException(status.HTTP_401_UNAUTHORIZED, "Not authenticated")
    if creds is None:
        raise unauthorized
    try:
        user_id = decode_access_token(creds.credentials)
    except (jwt.PyJWTError, KeyError, ValueError):
        raise unauthorized from None
    user = db.get(User, user_id)
    if user is None or not user.is_active:
        raise unauthorized
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]


def require_org_role(*roles: MemberRole) -> Callable[..., OrgMember]:
    """Dependency: the current user's membership of `org_id`, limited to `roles`.

    Non-members get 404 so organisation IDs can't be probed; members without the
    role get 403. With no roles given, any member passes.
    """

    def dependency(org_id: UUID, user: CurrentUser, db: DbSession) -> OrgMember:
        member = db.scalar(
            select(OrgMember).where(
                OrgMember.organisation_id == org_id, OrgMember.user_id == user.id
            )
        )
        if member is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Organisation not found")
        if roles and member.role not in roles:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Your role can't do this")
        return member

    return dependency


AnyMember = Annotated[OrgMember, Depends(require_org_role())]
OrgAdmin = Annotated[OrgMember, Depends(require_org_role(MemberRole.owner, MemberRole.manager))]
OrgOwner = Annotated[OrgMember, Depends(require_org_role(MemberRole.owner))]
