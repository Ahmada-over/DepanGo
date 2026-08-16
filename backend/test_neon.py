import asyncio
from app.core.config import settings
from app.infrastructure.database.session import engine, Base

async def test():
    try:
        print(f"Connecting to: {settings.ASYNC_DATABASE_URL}")
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
            print("DB Connected and tables created!")
    except Exception as e:
        print(f"FAILED: {e}")

if __name__ == "__main__":
    asyncio.run(test())
