import asyncio
import logging
from datetime import datetime, timedelta
from sqlalchemy import select
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.database.models import BookingModel, MatchingLogModel
from app.presentation.api.v1.websockets import ws_manager

logger = logging.getLogger(__name__)

async def expire_stale_bookings_loop():
    """Background task to set MATCHED bookings to PENDING if they have been waiting for > 90s"""
    while True:
        try:
            await asyncio.sleep(10)
            async with AsyncSessionLocal() as db:
                timeout_threshold = datetime.utcnow() - timedelta(seconds=90)
                
                # We need to find MATCHED bookings whose latest MatchingLogModel (offered) is older than 90s
                stmt = select(BookingModel).where(BookingModel.status == "matched")
                result = await db.execute(stmt)
                bookings = result.scalars().all()
                
                for booking in bookings:
                    log_stmt = select(MatchingLogModel).where(
                        MatchingLogModel.booking_id == booking.id,
                        MatchingLogModel.status == "offered"
                    ).order_by(MatchingLogModel.created_at.desc())
                    
                    log_result = await db.execute(log_stmt)
                    latest_log = log_result.scalars().first()
                    
                    if latest_log and latest_log.created_at < timeout_threshold:
                        # Timeout! 
                        latest_log.status = "timeout"
                        booking.status = "pending"
                        booking.version += 1
                        
                        logger.info(f"[TIMEOUT] Booking {booking.id} offered to {latest_log.technician_id} timed out.")
                        
                        # Notify client that status is pending again (optional)
                        # Or let the matching engine pick it up again.
                        
                await db.commit()
                
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error(f"[TASKS] Error in expire_stale_bookings_loop: {e}", exc_info=True)
            await asyncio.sleep(5)
