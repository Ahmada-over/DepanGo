from fastapi import APIRouter, Depends
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.database.session import get_db
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyCategoryRepository
from app.presentation.api.v1.schemas import CategoryResponse

router = APIRouter(prefix="/categories", tags=["Categories"])

@router.get("", response_model=List[CategoryResponse])
async def list_categories(db: AsyncSession = Depends(get_db)):
    repo = SQLAlchemyCategoryRepository(db)
    await repo.seed_defaults()
    cats = await repo.get_all()
    return [
        CategoryResponse(
            id=c.id,
            name=c.name,
            description=c.description,
            icon_name=c.icon_name
        ) for c in cats
    ]
