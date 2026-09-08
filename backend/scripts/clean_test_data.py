#!/usr/bin/env python3
"""
Script pour nettoyer les utilisateurs et données de test générés lors des tests automatisés.
Supprime toutes les références en cascade pour respecter les contraintes Foreign Key.
Ne supprime PAS les utilisateurs réels.
"""
import asyncio
import os
import sys

# Permettre l'exécution depuis la racine du projet ou depuis backend/
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from sqlalchemy import select, delete, or_
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.database.models import (
    UserModel,
    TechnicianProfileModel,
    BookingModel,
    QuoteModel,
    QuoteItemModel,
    MessageModel,
    ReviewModel,
    PaymentModel,
    SubscriptionModel,
    MatchingLogModel,
)


async def clean_test_data(dry_run: bool = False):
    async with AsyncSessionLocal() as session:
        # Identifier les utilisateurs de test
        test_pattern = or_(
            UserModel.email.like("client_%@test.com"),
            UserModel.email.like("tech_%@test.com"),
            UserModel.email.like("%@techconnect.com"),
            UserModel.email.like("test_%"),
            UserModel.email.like("%@fake.com"),
            UserModel.name.like("Client_%"),
            UserModel.name.like("Tech_%"),
            UserModel.name.like("Test %"),
        )

        query = select(UserModel).where(test_pattern)
        res = await session.execute(query)
        test_users = res.scalars().all()

        if not test_users:
            print("✨ Aucun utilisateur de test trouvé dans la base.")
            return

        print(f"🔍 Trouvé {len(test_users)} utilisateur(s) de test :")
        test_user_ids = []
        for u in test_users:
            print(f"   - [{u.role}] {u.name} ({u.email} | {u.phone})")
            test_user_ids.append(u.id)

        if dry_run:
            print("\n⚠️ Mode simulation (dry-run). Aucune suppression effectuée.")
            return

        # 0. Récupérer tous les bookings liés à ces utilisateurs
        bookings_res = await session.execute(
            select(BookingModel.id).where(
                or_(
                    BookingModel.client_id.in_(test_user_ids),
                    BookingModel.technician_id.in_(test_user_ids),
                )
            )
        )
        booking_ids = bookings_res.scalars().all()

        # 1. Supprimer les items de devis et devis
        quotes_res = await session.execute(
            select(QuoteModel.id).where(
                or_(
                    QuoteModel.technician_id.in_(test_user_ids),
                    QuoteModel.client_id.in_(test_user_ids),
                    QuoteModel.booking_id.in_(booking_ids) if booking_ids else False,
                )
            )
        )
        quote_ids = quotes_res.scalars().all()
        if quote_ids:
            await session.execute(
                delete(QuoteItemModel).where(QuoteItemModel.quote_id.in_(quote_ids))
            )
            await session.execute(
                delete(QuoteModel).where(QuoteModel.id.in_(quote_ids))
            )
            print(f"🗑️ Supprimé {len(quote_ids)} devis de test.")

        # 2. Supprimer les paiements
        if booking_ids:
            await session.execute(
                delete(PaymentModel).where(PaymentModel.booking_id.in_(booking_ids))
            )

        # 3. Supprimer les messages
        await session.execute(
            delete(MessageModel).where(
                or_(
                    MessageModel.sender_id.in_(test_user_ids),
                    MessageModel.booking_id.in_(booking_ids) if booking_ids else False,
                )
            )
        )

        # 4. Supprimer les avis (reviews)
        await session.execute(
            delete(ReviewModel).where(
                or_(
                    ReviewModel.reviewer_id.in_(test_user_ids),
                    ReviewModel.target_id.in_(test_user_ids),
                    ReviewModel.booking_id.in_(booking_ids) if booking_ids else False,
                )
            )
        )

        # 5. Supprimer les matching logs (technicien OU booking)
        await session.execute(
            delete(MatchingLogModel).where(
                or_(
                    MatchingLogModel.technician_id.in_(test_user_ids),
                    MatchingLogModel.booking_id.in_(booking_ids) if booking_ids else False,
                )
            )
        )

        # 6. Supprimer les bookings de test
        if booking_ids:
            await session.execute(
                delete(BookingModel).where(BookingModel.id.in_(booking_ids))
            )
            print(f"🗑️ Supprimé {len(booking_ids)} intervention(s) de test.")

        # 7. Supprimer les abonnements (subscriptions)
        await session.execute(
            delete(SubscriptionModel).where(
                SubscriptionModel.technician_id.in_(test_user_ids)
            )
        )

        # 8. Supprimer les profils techniciens de test
        await session.execute(
            delete(TechnicianProfileModel).where(
                TechnicianProfileModel.user_id.in_(test_user_ids)
            )
        )

        # 9. Supprimer les utilisateurs de test
        await session.execute(
            delete(UserModel).where(UserModel.id.in_(test_user_ids))
        )

        await session.commit()
        print(f"✅ {len(test_users)} utilisateur(s) de test et toutes leurs données associées nettoyés avec succès !")


if __name__ == "__main__":
    dry = "--dry-run" in sys.argv
    asyncio.run(clean_test_data(dry_run=dry))
