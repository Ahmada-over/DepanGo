import asyncio
from app.infrastructure.database.session import AsyncSessionLocal
from sqlalchemy import text

async def test():
    async with AsyncSessionLocal() as session:
        res = await session.execute(text("SELECT id, user_id, availability_status, latitude, longitude, category_ids FROM technician_profiles"))
        rows = list(res)
        print(f"Total technicians: {len(rows)}")
        for row in rows:
            print(f"Status: {row.availability_status} | Loc: {row.latitude},{row.longitude} | Cats: {row.category_ids}")

if __name__ == "__main__":
    asyncio.run(test())
