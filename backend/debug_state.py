import asyncio
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyBookingRepository, SQLAlchemyTechnicianRepository
from sqlalchemy import select
from app.infrastructure.database.models import BookingModel, TechnicianProfileModel, UserModel

async def debug_bookings():
    async with AsyncSessionLocal() as session:
        # Get last 3 bookings
        stmt = select(BookingModel).order_by(BookingModel.created_at.desc()).limit(3)
        result = await session.execute(stmt)
        bookings = result.scalars().all()
        
        for b in bookings:
            print(f"Booking {b.id}: category={b.category_id}, status={b.status}, client={b.client_id}, tech={b.technician_id}")
            
        print("\nTechnicians:")
        stmt = select(TechnicianProfileModel, UserModel).join(UserModel, TechnicianProfileModel.user_id == UserModel.id)
        result = await session.execute(stmt)
        for tech, user in result.all():
            print(f"Tech Profile ID: {tech.id}, User ID: {tech.user_id}, Name: {user.name}, Verified: {tech.verified}, Status: {tech.availability_status}")

asyncio.run(debug_bookings())
