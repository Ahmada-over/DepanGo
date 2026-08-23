from datetime import datetime
from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import update
from app.application.ports import (
    UserRepositoryPort, TechnicianRepositoryPort, CategoryRepositoryPort,
    BookingRepositoryPort, MessageRepositoryPort, ReviewRepositoryPort, PaymentRepositoryPort, SubscriptionRepositoryPort
)
from app.domain.models import (
    UserDomain, UserRole, TechnicianProfileDomain, AvailabilityStatus,
    ServiceCategoryDomain, BookingDomain, BookingStatus, MessageDomain,
    ReviewDomain, PaymentDomain, PaymentStatus, PaymentMethod, SubscriptionDomain
)
from app.infrastructure.database.models import (
    UserModel, TechnicianProfileModel, ServiceCategoryModel,
    BookingModel, MessageModel, ReviewModel, PaymentModel, SubscriptionModel, MatchingLogModel
)
from app.domain.matching_engine import haversine_distance

class SQLAlchemyUserRepository(UserRepositoryPort):
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, user: UserDomain) -> UserDomain:
        model = UserModel(
            id=user.id,
            name=user.name,
            phone=user.phone,
            email=user.email,
            role=user.role.value if isinstance(user.role, UserRole) else str(user.role),
            password_hash=user.password_hash
        )
        self.db.add(model)
        await self.db.commit()
        await self.db.refresh(model)
        return UserDomain(
            id=model.id,
            name=model.name,
            phone=model.phone,
            email=model.email,
            role=UserRole(model.role),
            password_hash=model.password_hash,
            created_at=model.created_at
        )

    async def get_by_email(self, email: str) -> Optional[UserDomain]:
        result = await self.db.execute(select(UserModel).where(UserModel.email == email))
        model = result.scalars().first()
        if not model:
            return None
        return UserDomain(
            id=model.id,
            name=model.name,
            phone=model.phone,
            email=model.email,
            role=UserRole(model.role),
            password_hash=model.password_hash,
            created_at=model.created_at
        )

    async def get_by_phone(self, phone: str) -> Optional[UserDomain]:
        clean_phone = phone.replace(" ", "").replace("-", "")
        result = await self.db.execute(select(UserModel))
        users = result.scalars().all()
        for u in users:
            u_clean = u.phone.replace(" ", "").replace("-", "") if u.phone else ""
            if u_clean == clean_phone or (len(clean_phone) >= 9 and clean_phone[-9:] in u_clean):
                return UserDomain(
                    id=u.id,
                    name=u.name,
                    phone=u.phone,
                    email=u.email,
                    role=UserRole(u.role),
                    password_hash=u.password_hash,
                    created_at=u.created_at
                )
        return None

    async def get_by_identifier(self, identifier: str) -> Optional[UserDomain]:
        if "@" in identifier:
            return await self.get_by_email(identifier)
        user = await self.get_by_email(identifier)
        if user:
            return user
        return await self.get_by_phone(identifier)

    async def get_by_id(self, user_id: str) -> Optional[UserDomain]:
        result = await self.db.execute(select(UserModel).where(UserModel.id == user_id))
        model = result.scalars().first()
        if not model:
            return None
        return UserDomain(
            id=model.id,
            name=model.name,
            phone=model.phone,
            email=model.email,
            role=UserRole(model.role),
            password_hash=model.password_hash,
            created_at=model.created_at
        )

class SQLAlchemyTechnicianRepository(TechnicianRepositoryPort):
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_profile(self, profile: TechnicianProfileDomain) -> TechnicianProfileDomain:
        model = TechnicianProfileModel(
            id=profile.id,
            user_id=profile.user_id,
            category_ids=profile.category_ids,
            latitude=profile.latitude,
            longitude=profile.longitude,
            availability_status=profile.availability_status.value if isinstance(profile.availability_status, AvailabilityStatus) else str(profile.availability_status),
            average_rating=profile.average_rating,
            verified=profile.verified
        )
        self.db.add(model)
        await self.db.commit()
        await self.db.refresh(model)
        return profile

    async def get_by_user_id(self, user_id: str) -> Optional[TechnicianProfileDomain]:
        from sqlalchemy import or_
        stmt = select(TechnicianProfileModel, UserModel).join(UserModel, TechnicianProfileModel.user_id == UserModel.id).where(
            or_(
                TechnicianProfileModel.user_id == user_id,
                TechnicianProfileModel.id == user_id
            )
        )
        result = await self.db.execute(stmt)
        row = result.first()
        if not row:
            return None
        tech, user = row
        return TechnicianProfileDomain(
            id=tech.id,
            user_id=tech.user_id,
            category_ids=tech.category_ids or [],
            latitude=tech.latitude,
            longitude=tech.longitude,
            availability_status=AvailabilityStatus(tech.availability_status),
            average_rating=tech.average_rating,
            verified=tech.verified,
            location_updated_at=tech.location_updated_at,
            user_name=user.name if user else None,
            user_phone=user.phone if user else None,
            transport_mode=tech.transport_mode
        )

    async def update_availability(self, user_id: str, status: str) -> None:
        stmt = update(TechnicianProfileModel).where(TechnicianProfileModel.user_id == user_id).values(availability_status=status)
        await self.db.execute(stmt)
        await self.db.commit()

    async def update_location(self, user_id: str, lat: float, lon: float) -> None:
        stmt = update(TechnicianProfileModel).where(TechnicianProfileModel.user_id == user_id).values(
            latitude=lat, 
            longitude=lon,
            location_updated_at=datetime.utcnow()
        )
        await self.db.execute(stmt)
        await self.db.commit()

    async def get_available_near(self, category_id: str, lat: float, lon: float, radius_km: float) -> List[TechnicianProfileDomain]:
        from datetime import datetime, timedelta
        from app.core.config import settings
        
        freshness_threshold = datetime.utcnow() - timedelta(minutes=settings.TECHNICIAN_LOCATION_FRESHNESS_MINUTES)
        
        stmt = select(TechnicianProfileModel, UserModel).join(UserModel, TechnicianProfileModel.user_id == UserModel.id).where(
            TechnicianProfileModel.availability_status == "online",
            TechnicianProfileModel.verified == True,
            TechnicianProfileModel.location_updated_at >= freshness_threshold
        )
        result = await self.db.execute(stmt)
        rows = result.all()
        
        matches = []
        for tech, user in rows:
            cats = tech.category_ids or []
            if category_id != "cat_express" and category_id not in cats:
                continue
            dist = haversine_distance(lat, lon, tech.latitude, tech.longitude)
            if dist <= radius_km:
                matches.append(TechnicianProfileDomain(
                    id=tech.id,
                    user_id=tech.user_id,
                    category_ids=cats,
                    latitude=tech.latitude,
                    longitude=tech.longitude,
                    availability_status=AvailabilityStatus(tech.availability_status),
                    average_rating=tech.average_rating,
                    verified=tech.verified,
                    location_updated_at=tech.location_updated_at,
                    user_name=user.name,
                    user_phone=user.phone
                ))
        return matches

    async def get_all(self) -> List[TechnicianProfileDomain]:
        stmt = select(TechnicianProfileModel, UserModel).join(UserModel, TechnicianProfileModel.user_id == UserModel.id)
        result = await self.db.execute(stmt)
        return [
            TechnicianProfileDomain(
                id=tech.id,
                user_id=tech.user_id,
                category_ids=tech.category_ids,
                latitude=tech.latitude,
                longitude=tech.longitude,
                availability_status=AvailabilityStatus(tech.availability_status),
                average_rating=tech.average_rating,
                verified=tech.verified,
                location_updated_at=tech.location_updated_at,
                user_name=user.name,
                user_phone=user.phone,
                transport_mode=tech.transport_mode
            ) for tech, user in result.all()
        ]

    async def update_user_info(self, user_id: str, name: Optional[str] = None, email: Optional[str] = None, phone: Optional[str] = None) -> None:
        values = {}
        if name: values["name"] = name
        if email: values["email"] = email
        if phone: values["phone"] = phone
        if values:
            stmt = update(UserModel).where(UserModel.id == user_id).values(**values)
            await self.db.execute(stmt)
            await self.db.commit()

    async def update_categories(self, user_id: str, category_ids: List[str]) -> None:
        stmt = update(TechnicianProfileModel).where(TechnicianProfileModel.user_id == user_id).values(category_ids=category_ids)
        await self.db.execute(stmt)
        await self.db.commit()

    async def update_rating(self, user_id: str, new_rating: float) -> None:
        stmt = update(TechnicianProfileModel).where(TechnicianProfileModel.user_id == user_id).values(average_rating=new_rating)
        await self.db.execute(stmt)
        await self.db.commit()

    async def update_verification_status(self, user_id: str, verified: bool) -> None:
        stmt = update(TechnicianProfileModel).where(TechnicianProfileModel.user_id == user_id).values(verified=verified)
        await self.db.execute(stmt)
        await self.db.commit()

    async def update_transport_mode(self, user_id: str, mode: str) -> None:
        stmt = update(TechnicianProfileModel).where(TechnicianProfileModel.user_id == user_id).values(transport_mode=mode)
        await self.db.execute(stmt)
        await self.db.commit()

    async def get_all_registered(self) -> List[TechnicianProfileDomain]:
        stmt = select(TechnicianProfileModel, UserModel).join(UserModel, TechnicianProfileModel.user_id == UserModel.id)
        result = await self.db.execute(stmt)
        rows = result.all()
        return [
            TechnicianProfileDomain(
                id=tech.id,
                user_id=tech.user_id,
                category_ids=tech.category_ids or [],
                latitude=tech.latitude,
                longitude=tech.longitude,
                availability_status=AvailabilityStatus(tech.availability_status),
                average_rating=tech.average_rating,
                verified=tech.verified,
                user_name=user.name,
                user_phone=user.phone,
                transport_mode=tech.transport_mode
            )
            for tech, user in rows
        ]

class SQLAlchemyCategoryRepository(CategoryRepositoryPort):
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_all(self) -> List[ServiceCategoryDomain]:
        result = await self.db.execute(select(ServiceCategoryModel))
        models = result.scalars().all()
        return [
            ServiceCategoryDomain(
                id=m.id,
                name=m.name,
                description=m.description or "",
                icon_name=m.icon_name or "build",
                base_price=m.base_price
            )
            for m in models
        ]

    async def seed_defaults(self) -> None:
        defaults = [
            {"id": "cat_plumbing", "name": "Plomberie", "description": "Dépannage, fuites d'eau, débouchage", "icon_name": "water_drop", "base_price": 5000.0},
            {"id": "cat_electrical", "name": "Électricité", "description": "Pannes, tableaux électriques, installation", "icon_name": "bolt", "base_price": 5000.0},
            {"id": "cat_hvac", "name": "Froid / Climatisation", "description": "Recharge gaz, réparation clim & frigo", "icon_name": "ac_unit", "base_price": 10000.0},
            {"id": "cat_appliances", "name": "Électroménager", "description": "Machine à laver, micro-ondes, four", "icon_name": "kitchen", "base_price": 5000.0},
            {"id": "cat_express", "name": "Recherche Rapide", "description": "Recherche immédiate d'un technicien", "icon_name": "bolt", "base_price": 5000.0}
        ]
        for item in defaults:
            res = await self.db.execute(select(ServiceCategoryModel).where(ServiceCategoryModel.id == item["id"]))
            if not res.scalars().first():
                self.db.add(ServiceCategoryModel(**item))
        await self.db.commit()

def _parse_booking_status(status_val: str) -> BookingStatus:
    if isinstance(status_val, BookingStatus):
        return status_val
    if not status_val:
        return BookingStatus.PENDING
    s = str(status_val).lower().strip()
    if s in ("accepted", "accept", "matched"):
        return BookingStatus.MATCHED
    if s in ("in_progress", "inprogress", "progress"):
        return BookingStatus.IN_PROGRESS
    if s in ("on_site", "onsite", "sur_place"):
        return BookingStatus.ON_SITE
    if s in ("completed", "done", "finished"):
        return BookingStatus.COMPLETED
    if s in ("cancelled", "canceled"):
        return BookingStatus.CANCELLED
    if s in ("no_technician_found", "no_technician", "failed"):
        return BookingStatus.NO_TECHNICIAN
    try:
        return BookingStatus(s)
    except Exception:
        return BookingStatus.PENDING


class SQLAlchemyBookingRepository(BookingRepositoryPort):
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, booking: BookingDomain) -> BookingDomain:
        model = BookingModel(
            id=booking.id,
            client_id=booking.client_id,
            category_id=booking.category_id,
            description=booking.description,
            photo_url=booking.photo_url,
            status=booking.status.value if isinstance(booking.status, BookingStatus) else str(booking.status),
            latitude=booking.latitude,
            longitude=booking.longitude,
            address_text=booking.address_text,
            technician_id=booking.technician_id,
            scheduled_eta=booking.scheduled_eta,
            cancellation_reason=booking.cancellation_reason
        )
        self.db.add(model)
        await self.db.commit()
        await self.db.refresh(model)
        return booking

    async def get_by_id(self, booking_id: str) -> Optional[BookingDomain]:
        stmt = select(BookingModel, UserModel.name).join(UserModel, BookingModel.client_id == UserModel.id).where(BookingModel.id == booking_id)
        result = await self.db.execute(stmt)
        row = result.first()
        if not row:
            return None
        model, client_name = row
        return BookingDomain(
            id=model.id,
            client_id=model.client_id,
            client_name=client_name,
            category_id=model.category_id,
            description=model.description,
            photo_url=model.photo_url,
            status=_parse_booking_status(model.status),
            latitude=model.latitude,
            longitude=model.longitude,
            address_text=model.address_text,
            technician_id=model.technician_id,
            scheduled_eta=model.scheduled_eta,
            cancellation_reason=model.cancellation_reason,
            created_at=model.created_at,
            version=model.version
        )

    async def update_status(self, booking_id: str, status: str, technician_id: Optional[str] = None, cancellation_reason: Optional[str] = None, expected_version: Optional[int] = None, technician_name: Optional[str] = None) -> Optional[BookingDomain]:
        parsed_status = _parse_booking_status(status)
        values = {"status": parsed_status.value}
        if technician_id:
            values["technician_id"] = technician_id
            values["scheduled_eta"] = "15-30 min"
        if cancellation_reason:
            values["cancellation_reason"] = cancellation_reason
            
        stmt = update(BookingModel).where(BookingModel.id == booking_id)
        if expected_version is not None:
            stmt = stmt.where(BookingModel.version == expected_version)
            values["version"] = expected_version + 1
            
        stmt = stmt.values(**values)
        result = await self.db.execute(stmt)
        if result.rowcount == 0 and expected_version is not None:
            # Maybe the booking doesn't exist, or version mismatch
            # To be safe, let's just return None, or we could raise an exception.
            # We'll return None and let the use case handle it.
            return None

        await self.db.commit()
        return await self.get_by_id(booking_id)

    async def get_by_user(self, user_id: str, role: str) -> List[BookingDomain]:
        if role == "client":
            stmt = select(BookingModel, UserModel.name).join(UserModel, BookingModel.client_id == UserModel.id).where(BookingModel.client_id == user_id).order_by(BookingModel.created_at.desc())
            result = await self.db.execute(stmt)
            rows = result.all()
            models_with_names = [(row[0], row[1]) for row in rows]
        else:
            # Get technician's category_ids so we only show relevant PENDING bookings
            tech_result = await self.db.execute(
                select(TechnicianProfileModel).where(TechnicianProfileModel.user_id == user_id)
            )
            tech_profile = tech_result.scalars().first()
            tech_categories = tech_profile.category_ids if tech_profile and tech_profile.category_ids else []

            # Bookings already assigned to this technician (any status) OR pending matching their category
            result = await self.db.execute(
                select(BookingModel, UserModel.name).join(UserModel, BookingModel.client_id == UserModel.id).where(
                    BookingModel.technician_id == user_id
                ).order_by(BookingModel.created_at.desc())
            )
            assigned_rows = result.all()

            if tech_categories:
                from sqlalchemy import and_
                pending_result = await self.db.execute(
                    select(BookingModel, UserModel.name).join(UserModel, BookingModel.client_id == UserModel.id).where(
                        and_(
                            BookingModel.status == BookingStatus.PENDING.value,
                            BookingModel.category_id.in_(tech_categories),
                            BookingModel.id.notin_(
                                select(MatchingLogModel.booking_id).where(
                                    and_(
                                        MatchingLogModel.technician_id == user_id,
                                        MatchingLogModel.status == "rejected"
                                    )
                                )
                            )
                        )
                    ).order_by(BookingModel.created_at.desc())
                )
                pending_rows = pending_result.all()
            else:
                pending_rows = []

            # Merge, deduplicate by id
            seen = set()
            models_with_names = []
            for m, c_name in list(assigned_rows) + list(pending_rows):
                if m.id not in seen:
                    seen.add(m.id)
                    models_with_names.append((m, c_name))

        return [
            BookingDomain(
                id=m.id,
                client_id=m.client_id,
                client_name=c_name,
                category_id=m.category_id,
                description=m.description,
                photo_url=m.photo_url,
                status=_parse_booking_status(m.status),
                latitude=m.latitude,
                longitude=m.longitude,
                address_text=m.address_text,
                technician_id=m.technician_id,
                scheduled_eta=m.scheduled_eta,
                cancellation_reason=m.cancellation_reason,
                created_at=m.created_at,
                version=m.version
            ) for m, c_name in models_with_names
        ]

class SQLAlchemyMessageRepository(MessageRepositoryPort):
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, message: MessageDomain) -> MessageDomain:
        model = MessageModel(
            id=message.id,
            booking_id=message.booking_id,
            sender_id=message.sender_id,
            content=message.content,
            sent_at=message.sent_at
        )
        self.db.add(model)
        await self.db.commit()
        await self.db.refresh(model)
        return message

    async def get_by_booking_id(self, booking_id: str) -> List[MessageDomain]:
        stmt = select(MessageModel, UserModel.name).join(UserModel, MessageModel.sender_id == UserModel.id).where(MessageModel.booking_id == booking_id).order_by(MessageModel.sent_at.asc())
        result = await self.db.execute(stmt)
        rows = result.all()
        return [
            MessageDomain(
                id=msg.id,
                booking_id=msg.booking_id,
                sender_id=msg.sender_id,
                content=msg.content,
                sent_at=msg.sent_at,
                sender_name=sender_name
            ) for msg, sender_name in rows
        ]

class SQLAlchemyReviewRepository(ReviewRepositoryPort):
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, review: ReviewDomain) -> ReviewDomain:
        model = ReviewModel(
            id=review.id,
            booking_id=review.booking_id,
            reviewer_id=review.reviewer_id,
            target_id=review.target_id,
            rating=review.rating,
            comment=review.comment,
            created_at=review.created_at
        )
        self.db.add(model)
        await self.db.commit()
        await self.db.refresh(model)
        return review

class SQLAlchemyPaymentRepository(PaymentRepositoryPort):
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, payment: PaymentDomain) -> PaymentDomain:
        model = PaymentModel(
            id=payment.id,
            booking_id=payment.booking_id,
            amount=payment.amount,
            status=payment.status.value if isinstance(payment.status, PaymentStatus) else str(payment.status),
            method=payment.method.value if isinstance(payment.method, PaymentMethod) else str(payment.method),
            created_at=payment.created_at
        )
        self.db.add(model)
        await self.db.commit()
        await self.db.refresh(model)
        return payment

class SQLAlchemySubscriptionRepository(SubscriptionRepositoryPort):
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, subscription: SubscriptionDomain) -> SubscriptionDomain:
        model = SubscriptionModel(
            id=subscription.id,
            technician_id=subscription.technician_id,
            plan_name=subscription.plan_name,
            status=subscription.status,
            start_date=subscription.start_date,
            end_date=subscription.end_date
        )
        self.db.add(model)
        await self.db.commit()
        return subscription

    async def get_active_by_technician(self, technician_id: str) -> Optional[SubscriptionDomain]:
        stmt = select(SubscriptionModel).where(
            SubscriptionModel.technician_id == technician_id,
            SubscriptionModel.status == "active"
        ).order_by(SubscriptionModel.start_date.desc())
        result = await self.db.execute(stmt)
        model = result.scalars().first()
        if not model:
            return None
        return SubscriptionDomain(
            id=model.id,
            technician_id=model.technician_id,
            plan_name=model.plan_name,
            status=model.status,
            start_date=model.start_date,
            end_date=model.end_date
        )
