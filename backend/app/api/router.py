from fastapi import APIRouter

from app.api.routes import (
    advisory,
    auth,
    crop_health,
    crop_health_analysis,
    crop_health_history,
    farm,
    farm_boundary,
    farmer,
    health,
)

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

api_router.include_router(
    farm.router,
    prefix="/farms",
    tags=["Farms"],
)

api_router.include_router(
    farm_boundary.router,
    prefix="/farms",
    tags=["Farm Boundaries"],
)

api_router.include_router(
    crop_health.router,
    prefix="/crops",
    tags=["Crop Health"],
)

api_router.include_router(
    advisory.router,
    prefix="/crops",
    tags=["Advisories"],
)

api_router.include_router(
    crop_health_analysis.router,
    prefix="/crops",
    tags=["Crop Health Analysis"],
)

api_router.include_router(
    crop_health_history.router,
    prefix="/crops",
    tags=["Crop Health History"],
)
