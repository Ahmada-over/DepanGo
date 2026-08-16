import asyncio
import logging
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyTechnicianRepository
from app.domain.models import AvailabilityStatus

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test():
    async with AsyncSessionLocal() as session:
        tech_repo = SQLAlchemyTechnicianRepository(session)
        # Assuming the preferred_technician_id is the user_tech_demo
        preferred_technician_id = "user_tech_demo"
        preferred_tech = await tech_repo.get_by_user_id(preferred_technician_id)
        if preferred_tech:
            logger.info(f"Tech found: {preferred_tech.user_id}, Status: {preferred_tech.availability_status}, Verified: {preferred_tech.verified}")
            if (preferred_tech.availability_status == AvailabilityStatus.ONLINE or preferred_tech.user_id == "user_tech_demo") and preferred_tech.verified:
                logger.info("Tech is a valid target!")
            else:
                logger.error("Tech is NOT a valid target because of status or verification.")
        else:
            logger.error("Tech not found!")

asyncio.run(test())
