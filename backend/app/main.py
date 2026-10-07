from contextlib import asynccontextmanager

from fastapi import FastAPI
from sqlalchemy import text

from app.api.router import api_router
from app.core.config import settings
from app.database.session import engine
from fastapi.middleware.cors import CORSMiddleware
from app.remote_sensing.exceptions import RemoteSensingProviderError
from app.remote_sensing.gee.client import initialize_earth_engine


@asynccontextmanager
async def lifespan(_app: FastAPI):
    project_id = settings.gee_project_id
    credentials_path = settings.gee_credentials_path

    if bool(project_id) != bool(credentials_path):
        raise RemoteSensingProviderError(
            "Google Earth Engine project ID and credentials path "
            "must be configured together."
        )

    if project_id and credentials_path:
        initialize_earth_engine(
            project_id=project_id,
            credentials_path=credentials_path,
        )

    yield


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    debug=settings.debug,
    lifespan=lifespan,
)

app.include_router(
    api_router,
    prefix="/api/v1",
)


@app.get("/")
async def root():
    return {
        "message": "KrushiMitra API is running",
        "version": settings.app_version,
        "environment": settings.environment,
    }


@app.get("/health")
async def health_check():
    database_status = "healthy"

    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
    except Exception:
        database_status = "unhealthy"

    overall_status = "healthy" if database_status == "healthy" else "degraded"

    return {
        "status": overall_status,
        "service": "krushimitra-api",
        "database": database_status,
    }
