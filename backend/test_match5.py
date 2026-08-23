import asyncio
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyTechnicianRepository
from app.domain.matching_engine import MatchingEngine

async def test():
    async with AsyncSessionLocal() as session:
        repo = SQLAlchemyTechnicianRepository(session)
        # Booking: 20763ec2-7bc2-4486-91db-d3cdc886965c | Cat: cat_electrical | Loc: 14.6970783,-17.4626667
        matches = await repo.get_available_near("cat_electrical", 14.6970783, -17.4626667, 15.0)
        print(f"Matches at 15km: {len(matches)}")
        
        ranked = MatchingEngine.filter_and_rank_technicians(matches, 14.6970783, -17.4626667, "cat_electrical", 15.0, {})
        print(f"Ranked: {len(ranked)}")

if __name__ == "__main__":
    asyncio.run(test())
