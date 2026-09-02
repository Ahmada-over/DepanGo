import asyncio
from app.infrastructure.database.session import AsyncSessionLocal
from sqlalchemy import text

async def test():
    async with AsyncSessionLocal() as session:
        res = await session.execute(text("SELECT id, category_id, latitude, longitude, status FROM bookings ORDER BY created_at DESC LIMIT 5"))
        for row in res:
            print(f"Booking: {row.id} | Cat: {row.category_id} | Loc: {row.latitude},{row.longitude} | Status: {row.status}")

if __name__ == "__main__":
    asyncio.run(test())
