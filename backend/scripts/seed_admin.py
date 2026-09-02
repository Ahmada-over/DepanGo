import asyncio
import os
import sys

# Add the app directory to the sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.infrastructure.database.session import AsyncSessionLocal, engine, Base
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyUserRepository
from app.infrastructure.database.models import UserModel
from app.core.security import hash_password

async def seed_admin():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as db:
        repo = SQLAlchemyUserRepository(db)
        # Check if admin exists
        admin_email = "admin@tekservice.com"
        existing = await repo.get_by_email(admin_email)
        if existing:
            print(f"Admin user already exists with email: {admin_email}")
            return

        new_admin = UserModel(
            role="admin",
            name="Super Admin",
            phone="+221770000000",
            email=admin_email,
            password_hash=hash_password("admin123")
        )
        db.add(new_admin)
        await db.commit()
        print(f"Admin user created successfully! Email: {admin_email}, Password: admin123")

if __name__ == "__main__":
    asyncio.run(seed_admin())
