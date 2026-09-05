import asyncio
from app.infrastructure.database.session import engine
from sqlalchemy import text

async def check_reviews():
    async with engine.connect() as conn:
        result = await conn.execute(text("SELECT column_name FROM information_schema.columns WHERE table_name='reviews'"))
        columns = [row[0] for row in result.fetchall()]
        print("Columns in 'reviews' table:", columns)

asyncio.run(check_reviews())
