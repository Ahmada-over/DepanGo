import uuid
from datetime import datetime
from sqlalchemy import Column, String, Float, Boolean, Integer, DateTime, ForeignKey, Text, JSON
from sqlalchemy.orm import relationship
from app.infrastructure.database.session import Base

def generate_uuid():
    return str(uuid.uuid4())

class UserModel(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=generate_uuid)
    role = Column(String, nullable=False) # admin | client | technician
    name = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    technician_profile = relationship("TechnicianProfileModel", back_populates="user", uselist=False)

class ServiceCategoryModel(Base):
    __tablename__ = "service_categories"

    id = Column(String, primary_key=True, default=generate_uuid)
    name = Column(String, unique=True, nullable=False)
    description = Column(String, nullable=True)
    icon_name = Column(String, nullable=True)
    base_price = Column(Float, nullable=True)

class TechnicianProfileModel(Base):
    __tablename__ = "technician_profiles"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, unique=True)
    category_ids = Column(JSON, default=list) # Store array of category IDs
    latitude = Column(Float, default=14.6937)
    longitude = Column(Float, default=-17.4441)
    availability_status = Column(String, default="offline") # online | offline
    average_rating = Column(Float, default=5.0)
    verified = Column(Boolean, default=False)
    location_updated_at = Column(DateTime, default=datetime.utcnow)
    transport_mode = Column(String, default="moto") # moto | voiture

    user = relationship("UserModel", back_populates="technician_profile")

class BookingModel(Base):
    __tablename__ = "bookings"

    id = Column(String, primary_key=True, default=generate_uuid)
    client_id = Column(String, ForeignKey("users.id"), nullable=False)
    category_id = Column(String, ForeignKey("service_categories.id"), nullable=False)
    description = Column(Text, nullable=False)
    photo_url = Column(String, nullable=True)
    status = Column(String, default="pending") # pending | matched | in_progress | completed | cancelled | no_technician_found
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    address_text = Column(String, nullable=False)
    technician_id = Column(String, ForeignKey("users.id"), nullable=True)
    scheduled_eta = Column(String, nullable=True)
    cancellation_reason = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    version = Column(Integer, nullable=False, default=1)

    __mapper_args__ = {
        "version_id_col": version
    }
class MessageModel(Base):
    __tablename__ = "messages"

    id = Column(String, primary_key=True, default=generate_uuid)
    booking_id = Column(String, ForeignKey("bookings.id"), nullable=False)
    sender_id = Column(String, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    sent_at = Column(DateTime, default=datetime.utcnow)

class SubscriptionModel(Base):
    __tablename__ = "subscriptions"

    id = Column(String, primary_key=True, default=generate_uuid)
    technician_id = Column(String, ForeignKey("users.id"), nullable=False)
    plan_name = Column(String, nullable=False, default="basic") # basic | premium
    status = Column(String, default="active") # active | expired | cancelled
    start_date = Column(DateTime, default=datetime.utcnow)
    end_date = Column(DateTime, nullable=True)

class ReviewModel(Base):
    __tablename__ = "reviews"

    id = Column(String, primary_key=True, default=generate_uuid)
    booking_id = Column(String, ForeignKey("bookings.id"), nullable=False)
    reviewer_id = Column(String, ForeignKey("users.id"), nullable=False)
    target_id = Column(String, ForeignKey("users.id"), nullable=False)
    rating = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class PaymentModel(Base):
    __tablename__ = "payments"

    id = Column(String, primary_key=True, default=generate_uuid)
    booking_id = Column(String, ForeignKey("bookings.id"), nullable=False)
    amount = Column(Float, default=0.0)
    status = Column(String, default="pending") # pending | paid_direct | cancelled
    method = Column(String, default="direct_cash") # direct_cash | mobile_money_direct | sur_devis
    created_at = Column(DateTime, default=datetime.utcnow)

class MatchingLogModel(Base):
    __tablename__ = "matching_logs"

    id = Column(String, primary_key=True, default=generate_uuid)
    booking_id = Column(String, ForeignKey("bookings.id"), nullable=False)
    technician_id = Column(String, ForeignKey("users.id"), nullable=False)
    status = Column(String, nullable=False) # offered | accepted | rejected | timeout
    created_at = Column(DateTime, default=datetime.utcnow)

