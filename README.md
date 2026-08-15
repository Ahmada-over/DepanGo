# TechConnect — Implémentation des Fonctionnalités (Phase 3 à 5)

Ce document résume les fonctionnalités et correctifs apportés au monorepo `tekservice` (FastAPI backend, Flutter mobile client, Vue 3 web pro) conformément aux recommandations d'amélioration.

## 1. Annulation avec motif (Phase 3.3)
- **Backend (FastAPI)**:
  - Mise à jour de `BookingModel`, `BookingDomain`, et du schéma Pydantic pour inclure le champ `cancellation_reason`.
  - Le endpoint `PATCH /bookings/{booking_id}/status` accepte désormais un motif d'annulation.
  - Le système WebSocket diffuse le motif d'annulation lors du changement de statut vers `cancelled`.
- **Frontend Web Pro (Vue 3)**:
  - Ajout d'une modale d'annulation permettant aux techniciens de choisir ou saisir un motif avant d'annuler.
  - Le store `mission.js` gère l'envoi du motif au backend.
- **Frontend Mobile (Flutter)**:
  - Ajout d'une boîte de dialogue avec liste déroulante et champ libre pour spécifier le motif lors de l'annulation par le client.
  - Le statut d'annulation et son motif sont reflétés dans l'historique et sur la page de suivi.

## 2. Tarification Initiale (Phase 3.4)
- **Base de Données**: 
  - Ajout de la colonne `base_price` (Float) sur `ServiceCategoryModel`.
  - Mise à jour du script de `seed_defaults` pour injecter un prix de base pour les catégories existantes (ex. Plomberie: 15000 FCFA, Électricité: 10000 FCFA, etc.).
- **Mobile (Flutter)**:
  - L'écran `CreateBookingScreen` affiche dynamiquement le prix de base de la catégorie sélectionnée avant validation, renforçant la transparence.

## 3. Monétisation (Phase 4.1)
- **Modèle de Données**:
  - Création des entités `SubscriptionModel` et `SubscriptionDomain` pour gérer les abonnements des techniciens.
- **Backend**:
  - Ajout du routeur `subscriptions.py` permettant de souscrire à un plan (Basique ou Premium) et de consulter l'abonnement actif.
- **Web Pro (Vue 3)**:
  - Dans la vue `ProfileView`, ajout d'un onglet "Abonnement SaaS & Sécurité".
  - Possibilité pour le technicien de voir son statut d'abonnement et de souscrire au plan "Premium" sans commission.

## 4. Dashboard Administrateur (Phase 5.1)
- **Backend (FastAPI)**:
  - Implémentation de `GET /admin/technicians` pour lister tous les techniciens avec leur statut de vérification (`verified`).
  - Utilisation d'un système de vérification des droits (Rôle `admin` requis).
- **Web Admin (Vue 3)**:
  - Création d'une vue `AdminView.vue` permettant de lister les techniciens.
  - Ajout d'un bouton pour valider manuellement le compte d'un technicien depuis l'interface, afin d'assurer la sécurité et l'authenticité des professionnels sur la plateforme.

## 5. Résolution de Bugs
- **Logique de Transition (Web Pro)**: Correction du store `mission.js` qui sautait l'étape "Sur Place" lors de la détection des missions actives et correction des transitions.
- **Notifications WebSocket (Mobile)**: Correction de `app_providers.dart` pour éviter que l'utilisateur reçoive une notification push pour ses *propres* messages envoyés via le chat WebSocket.

## Prochaines Étapes
- Intégrer les variables d'environnement (`.env`) et supprimer les accès en dur (`user_tech_demo`, etc.) pour la sécurité en production.
- Refonte des UI Snackbars sur le client mobile pour un design plus premium, comme demandé par l'utilisateur.
