import asyncio
from app.infrastructure.database.session import AsyncSessionLocal
from sqlalchemy import text

async def test():
    async with AsyncSessionLocal() as session:
        res = await session.execute(text("SELECT id, booking_id, status, created_at FROM matching_logs ORDER BY created_at DESC LIMIT 5"))
        for row in res:
            print(f"Log: {row.id} | Booking: {row.booking_id} | Status: {row.status} | Time: {row.created_at}")

if __name__ == "__main__":
    asyncio.run(test())
