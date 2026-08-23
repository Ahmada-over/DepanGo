import asyncio
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyTechnicianRepository
import json

async def test():
    async with AsyncSessionLocal() as session:
        repo = SQLAlchemyTechnicianRepository(session)
        matches = await repo.get_available_near("cat_electrical", 14.6970783, -17.4626667, 15.0)
        for m in matches:
            print(f"Type of category_ids: {type(m.category_ids)}, value: {m.category_ids}")

if __name__ == "__main__":
    asyncio.run(test())
