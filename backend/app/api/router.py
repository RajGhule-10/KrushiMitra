from fastapi import APIRouter

from app.api.routes import auth, farmer, health

api_router = APIRouter()

api_router.include_router(
    health.router,
    prefix="/health",
    tags=["Health"],
)

api_router.include_router(
    auth.router,
    prefix="/auth",
    tags=["Authentication"],
)

api_router.include_router(
    farmer.router,
    prefix="/farmer",
    tags=["Farmer Profile"],
)
