import asyncio
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyTechnicianRepository

async def test():
    async with AsyncSessionLocal() as session:
        repo = SQLAlchemyTechnicianRepository(session)
        # Booking: 20763ec2-7bc2-4486-91db-d3cdc886965c | Cat: cat_electrical | Loc: 14.6970783,-17.4626667
        matches = await repo.get_available_near("cat_electrical", 14.6970783, -17.4626667, 15.0)
        print(f"Matches at 15km: {len(matches)}")
        
        matches = await repo.get_available_near("cat_electrical", 14.6970783, -17.4626667, 3.0)
        print(f"Matches at 3km: {len(matches)}")

if __name__ == "__main__":
    asyncio.run(test())
