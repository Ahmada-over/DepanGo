import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.app.infrastructure.database.session import SessionLocal
from sqlalchemy import text

def add_version_column():
    db = SessionLocal()
    try:
        db.execute(text("ALTER TABLE bookings ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1"))
        db.commit()
        print("Successfully added version column to bookings table")
    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    add_version_column()
