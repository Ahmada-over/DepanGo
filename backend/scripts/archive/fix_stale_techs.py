import asyncio
from app.infrastructure.database.session import AsyncSessionLocal
from sqlalchemy import text
from datetime import datetime

async def fix():
    async with AsyncSessionLocal() as session:
        await session.execute(text("UPDATE technician_profiles SET location_updated_at = :now"), {"now": datetime.utcnow()})
        await session.commit()
        print("Updated all technician locations to be fresh!")

if __name__ == "__main__":
    asyncio.run(fix())
