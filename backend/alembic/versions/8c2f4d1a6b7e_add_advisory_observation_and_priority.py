"""add observation and priority to advisories

Revision ID: 8c2f4d1a6b7e
Revises: b0f7f5ee2eba
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "8c2f4d1a6b7e"
down_revision: Union[str, Sequence[str], None] = "b0f7f5ee2eba"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "advisories",
        sa.Column("observation_id", sa.UUID(), nullable=False),
    )
    op.add_column(
        "advisories",
        sa.Column("priority", sa.String(length=50), nullable=False),
    )
    op.create_index(
        "ix_advisories_observation_id",
        "advisories",
        ["observation_id"],
        unique=False,
    )
    op.create_foreign_key(
        "fk_advisories_observation_id_crop_observations",
        "advisories",
        "crop_observations",
        ["observation_id"],
        ["id"],
        ondelete="CASCADE",
    )


def downgrade() -> None:
    op.drop_constraint(
        "fk_advisories_observation_id_crop_observations",
        "advisories",
        type_="foreignkey",
    )
    op.drop_index("ix_advisories_observation_id", table_name="advisories")
    op.drop_column("advisories", "priority")
    op.drop_column("advisories", "observation_id")
