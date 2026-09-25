from sqlalchemy.orm import Session

from app.auth.repository import AuthRepository
from app.auth.security import (
    create_access_token,
    hash_password,
    verify_password,
)
from app.core.errors import (
    BadRequestException,
    UnauthorizedException,
)
from app.models.user import FarmerProfile, User
from app.schemas.auth import LoginRequest, RegisterRequest


class AuthService:
    def __init__(self, db: Session) -> None:
        self.repository = AuthRepository(db)

    def register(
        self,
        request: RegisterRequest,
    ) -> User:
        existing_user = self.repository.get_user_by_phone(request.phone_number)

        if existing_user is not None:
            raise BadRequestException("A user with this phone number already exists.")

        user = User(
            phone_number=request.phone_number,
            password_hash=hash_password(request.password),
            role="farmer",
            is_active=True,
        )

        self.repository.create_user(user)

        profile = FarmerProfile(
            user_id=user.id,
            full_name=request.full_name,
            village=request.village,
            district=request.district,
            state=request.state,
            preferred_language=request.preferred_language,
        )

        self.repository.create_farmer_profile(profile)

        self.repository.commit()

        return user

    def login(
        self,
        request: LoginRequest,
    ) -> str:
        user = self.repository.get_user_by_phone(request.phone_number)

        if user is None:
            raise UnauthorizedException("Invalid phone number or password.")

        if not user.password_hash:
            raise UnauthorizedException(
                "Password authentication is not enabled for this account."
            )

        if not verify_password(
            request.password,
            user.password_hash,
        ):
            raise UnauthorizedException("Invalid phone number or password.")

        if not user.is_active:
            raise UnauthorizedException("User account is inactive.")

        return create_access_token(
            subject=str(user.id),
            role=user.role,
        )
