import asyncio
from app.infrastructure.database.session import AsyncSessionLocal
from sqlalchemy import text
from datetime import datetime, timedelta

async def test():
    async with AsyncSessionLocal() as session:
        freshness_threshold = datetime.utcnow() - timedelta(minutes=30)
        res = await session.execute(
            text("""
            SELECT t.id, t.availability_status, t.verified, t.location_updated_at, u.name 
            FROM technician_profiles t 
            JOIN users u ON t.user_id = u.id 
            WHERE t.availability_status = 'online' 
            AND t.verified = true 
            AND t.location_updated_at >= :thresh
            """), 
            {"thresh": freshness_threshold}
        )
        rows = list(res)
        print(f"Total matching: {len(rows)}")
        for row in rows:
            print(f"Tech: {row.name} | Verified: {row.verified} | Loc updated: {row.location_updated_at}")

if __name__ == "__main__":
    asyncio.run(test())
