import asyncio
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.database.models import UserModel
from app.core.security import create_access_token
from sqlalchemy import select
from fastapi.testclient import TestClient
from app.main import app
import json

async def run():
    async with AsyncSessionLocal() as db:
        user = (await db.execute(select(UserModel).limit(1))).scalars().first()
        if not user:
            print("No user")
            return
        token = create_access_token(user.id)
    
    with TestClient(app) as client:
        res = client.get("/api/v1/technicians", headers={"Authorization": f"Bearer {token}"})
        print(res.status_code)
        print(json.dumps(res.json(), indent=2))

asyncio.run(run())
