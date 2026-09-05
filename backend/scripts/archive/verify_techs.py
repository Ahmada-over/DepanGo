import asyncio
from sqlalchemy import update
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.database.models import TechnicianProfileModel

async def verify_all():
    async with AsyncSessionLocal() as session:
        stmt = update(TechnicianProfileModel).values(verified=True)
        await session.execute(stmt)
        await session.commit()
        print("All technicians are now verified!")

asyncio.run(verify_all())
