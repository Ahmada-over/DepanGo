import asyncio
from app.infrastructure.database.session import engine, Base
from app.infrastructure.database.models import ReviewModel
from sqlalchemy import text

async def fix_reviews_table():
    async with engine.begin() as conn:
        await conn.execute(text("DROP TABLE IF EXISTS reviews CASCADE"))
        # Recreate all tables (it will only create missing ones, i.e. reviews)
        await conn.run_sync(Base.metadata.create_all)
        print("Dropped and recreated 'reviews' table with new schema!")

asyncio.run(fix_reviews_table())
