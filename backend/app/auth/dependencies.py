from uuid import UUID

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth.security import decode_access_token
from app.core.errors import UnauthorizedException
from app.database.session import get_db
from app.models.user import User


bearer_scheme = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    token = credentials.credentials

    try:
        payload = decode_access_token(token)
    except Exception as exc:
        raise UnauthorizedException("Invalid or expired access token.") from exc

    subject = payload.get("sub")

    if not subject:
        raise UnauthorizedException("Invalid access token.")

    try:
        user_id = UUID(subject)
    except ValueError as exc:
        raise UnauthorizedException("Invalid access token subject.") from exc

    user = db.scalar(select(User).where(User.id == user_id))

    if user is None:
        raise UnauthorizedException("User not found.")

    if not user.is_active:
        raise UnauthorizedException("User account is inactive.")

    return user
