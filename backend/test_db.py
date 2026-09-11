import asyncio
from sqlalchemy import select
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.database.models import TechnicianProfileModel, UserModel

async def run():
    async with AsyncSessionLocal() as db:
        stmt = select(TechnicianProfileModel, UserModel).outerjoin(UserModel, TechnicianProfileModel.user_id == UserModel.id)
        res = await db.execute(stmt)
        for tech, user in res.all():
            print(f"Tech ID: {tech.id}, User ID: {tech.user_id}, Name in User: {user.name if user else 'NO USER FOUND'}")

asyncio.run(run())
