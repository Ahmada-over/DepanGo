import asyncio
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.database.models import ServiceCategoryModel
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyCategoryRepository
from sqlalchemy.future import select

async def main():
    async with AsyncSessionLocal() as session:
        repo = SQLAlchemyCategoryRepository(session)
        await repo.seed_defaults()
        result = await session.execute(select(ServiceCategoryModel.id))
        print("Categories in DB:", result.scalars().all())

if __name__ == "__main__":
    asyncio.run(main())
