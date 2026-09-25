from fastapi import APIRouter, status
from sqlalchemy import text

from app.database.session import engine

router = APIRouter()


@router.get(
    "",
    status_code=status.HTTP_200_OK,
)
def api_health_check() -> dict:
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
