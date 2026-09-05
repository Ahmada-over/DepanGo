# Processus d'Enregistrement et Sécurité des Techniciens (depanGo Pro)

Ce document décrit les spécifications et le flux de travail pour l'enregistrement d'un technicien sur la plateforme **depanGo**, en s'inspirant des standards de sécurité de l'industrie (ex: Uber, Yango, Bolt).

L'objectif est de garantir une sécurité maximale pour les clients (utilisateurs de l'application Client) en s'assurant que chaque technicien intervenant à leur domicile est strictement identifié, qualifié et traçable.

---

## 1. Informations Requises à l'Inscription

Lors de son inscription sur l'application **depanGo Pro**, le technicien devra fournir des informations réparties en 3 grandes catégories :

### A. Identité Personnelle (Vérification d'Identité - KYC)
- **Nom et Prénom complets** (identiques à la pièce d'identité).
- **Photo de profil claire et professionnelle** (sans lunettes de soleil, ni masque, prise de face).
- **Numéro de téléphone vérifié** (via OTP SMS Firebase, déjà implémenté).
- **Pièce d'identité officielle** (CNI, Passeport, ou Carte de Résident) :
  - Photo recto de la carte.
  - Photo verso de la carte.
- **Selfie de vérification** (photo prise en direct tenant la pièce d'identité pour éviter l'usurpation).

### B. Informations Professionnelles (Qualifications)
- **Spécialités / Catégories** (ex: Plomberie, Électricité, Froid, etc.).
- **Années d'expérience**.
- **Documents de certification ou diplômes** (Facultatif mais recommandé pour l'obtention du badge "Expert").
- **Extrait de casier judiciaire** (datant de moins de 3 mois) - *Critique pour les interventions à domicile.*

### C. Sécurité et Transport (Traçabilité type Uber/Yango)
Afin que le client puisse identifier formellement le technicien à son arrivée (et pour des raisons de traçabilité en cas d'incident) :
- **Mode de transport** (Moto, Voiture, Fourgonnette, À pied).
- **Marque et modèle du véhicule** (ex: Yamaha TMAX, Renault Kangoo).
- **Couleur du véhicule**.
- **Plaque d'immatriculation** (obligatoire si transport motorisé).
- **Permis de conduire** (photo recto/verso).
- *(Optionnel)* Attestation d'assurance du véhicule.

---

## 2. Le Flux de Validation (Workflow de Sécurité)

Afin de garantir que seuls des professionnels fiables utilisent l'application, l'inscription suit ce cycle de vie :

1. **Étape 1 : Inscription et Téléchargement**
   - Le technicien s'inscrit via OTP SMS.
   - Il remplit son profil et télécharge tous les documents (ID, Plaque, Casier judiciaire) via l'application Pro.
   - Son compte est créé dans la base de données avec le statut `verified = false` et `status = "pending_review"`.
   - *À ce stade, le technicien ne peut pas se mettre "En Ligne" ni recevoir de missions.*

2. **Étape 2 : Vérification par l'Admin (Back-Office)**
   - Un administrateur depanGo reçoit une alerte sur le tableau de bord web.
   - L'admin examine manuellement la cohérence entre le selfie, la CNI, et vérifie la plaque d'immatriculation et le casier judiciaire.
   - Si les documents sont flous ou invalides, l'admin rejette avec un motif (ex: "Photo de la plaque illisible"). Le technicien reçoit une notification push pour corriger.

3. **Étape 3 : Activation (Onboarding)**
   - Une fois tous les documents validés, l'admin clique sur "Approuver".
   - Le statut du technicien passe à `verified = true`.
   - Le technicien est notifié, il peut désormais se mettre "En ligne" et accepter des missions.

---

## 3. Ce que le Client voit (Côté Application Client)

Lorsqu'un technicien est assigné à une mission, le client reçoit une fiche de sécurité contenant :

- **La photo de profil du technicien** (pour reconnaissance visuelle immédiate).
- **Le prénom** (et l'initiale du nom) et la **note moyenne** (⭐ 4.8).
- **Le Badge "Vérifié"** (bouclier vert) certifiant que l'identité et le casier ont été contrôlés.
- **Les détails du véhicule** : "Arrive en Moto (Yamaha) - Plaque : AA-123-BB".
- **La position GPS en temps réel** sur la carte.

> **💡 Note de sécurité :** L'application Client encouragera les utilisateurs via une petite alerte : *"Pour votre sécurité, vérifiez toujours que la plaque d'immatriculation et le visage du technicien correspondent à son profil avant de le laisser entrer."*

---

## 4. Recommandations Techniques (Pour le développement futur)

Pour implémenter ce système, les modifications suivantes seront nécessaires dans le code :

- **Base de données (Modèles FastAPI)** : Ajouter les colonnes `vehicle_type`, `vehicle_model`, `license_plate`, `id_card_url`, `selfie_url`, `criminal_record_url` dans le modèle `TechnicianProfileModel`.
- **Stockage des documents** : Utiliser *Firebase Storage* ou *AWS S3* pour stocker les photos des documents de manière sécurisée et privée (liens inaccessibles au public).
- **Application Pro** : Créer un "Wizard" (formulaire multi-étapes) dans `mobile_pro` qui force le technicien à prendre ces photos lors de sa première connexion s'il n'est pas encore vérifié.
- **Protection des données (RGPD / CDP)** : Les photos des pièces d'identité et casiers judiciaires sont des données très sensibles. Elles doivent être chiffrées et purgées/supprimées des serveurs si un technicien quitte la plateforme.
