<template>
  <div class="py-12 bg-gray-50 min-h-screen">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Breadcrumb & Back -->
      <div class="mb-8 flex items-center justify-between">
        <button
          @click="$emit('back')"
          class="inline-flex items-center text-sm font-semibold text-[#0D776C] hover:text-[#095f56] transition-colors group"
        >
          <svg class="w-4 h-4 mr-2 transform group-hover:-translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
          </svg>
          Retour à l'accueil
        </button>
        <span class="text-xs font-medium text-gray-500 bg-gray-200/60 px-3 py-1 rounded-full">
          Dernière mise à jour : 5 Septembre 2026
        </span>
      </div>

      <!-- Main Card -->
      <div class="bg-white rounded-3xl shadow-sm border border-gray-100 p-8 sm:p-12">
        <div class="border-b border-gray-100 pb-8 mb-8">
          <span class="inline-block px-3 py-1 bg-[#0D776C]/10 text-[#0D776C] text-xs font-bold uppercase tracking-wider rounded-lg mb-4">
            Protection de la vie privée
          </span>
          <h1 class="text-3xl sm:text-4xl font-black text-gray-900 tracking-tight mb-4">
            Politique de Confidentialité
          </h1>
          <p class="text-gray-600 leading-relaxed text-base">
            Comment <span class="font-bold text-[#0D776C]">depanGo</span> recueille, utilise, sécurise et protège vos données à caractère personnel.
          </p>
        </div>

        <div class="space-y-8 text-gray-700 leading-relaxed text-sm sm:text-base">
          <!-- Introduction -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">1</span>
              Introduction et Responsable du Traitement
            </h2>
            <p class="mb-3">
              La présente Politique de Confidentialité s’applique à l’ensemble des services proposés par <strong>depanGo</strong> (incluant les applications mobiles <em>depanGo Client</em>, <em>depanGo Pro</em> et nos plateformes web).
            </p>
            <p>
              Le responsable du traitement des données est la direction de <strong>depanGo</strong>, joignable par courrier électronique à l'adresse dédiée : <a href="mailto:privacy@depango.sn" class="text-[#0D776C] underline font-medium">privacy@depango.sn</a> ou <a href="mailto:contact@depango.sn" class="text-[#0D776C] underline font-medium">contact@depango.sn</a>.
            </p>
          </section>

          <!-- Données Collectées -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">2</span>
              Données Personnelles Collectées
            </h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 my-3">
              <div class="p-4 rounded-2xl bg-slate-50 border border-slate-100">
                <h3 class="font-bold text-gray-900 text-sm mb-2 flex items-center">
                  <span class="text-base mr-2">👤</span> Pour les Utilisateurs Clients
                </h3>
                <ul class="text-xs sm:text-sm text-gray-600 space-y-1.5 list-disc pl-4">
                  <li>Numéro de téléphone portable (vérification SMS).</li>
                  <li>Nom, prénom et éventuelle photo de profil.</li>
                  <li>Adresse d'intervention et coordonnées GPS de la demande.</li>
                  <li>Photos transmises pour illustrer la panne ou le besoin.</li>
                  <li>Historique des réservations, devis acceptés et factures.</li>
                  <li>Messages échangés via le chat interne de l'application.</li>
                  <li>Évaluations, notes et retours d'expérience.</li>
                </ul>
              </div>

              <div class="p-4 rounded-2xl bg-emerald-50/40 border border-emerald-100">
                <h3 class="font-bold text-gray-900 text-sm mb-2 flex items-center">
                  <span class="text-base mr-2">🔧</span> Pour les Techniciens (depanGo Pro)
                </h3>
                <ul class="text-xs sm:text-sm text-gray-600 space-y-1.5 list-disc pl-4">
                  <li>État civil complet et coordonnées de contact.</li>
                  <li>Pièce d'identité officielle (CNI, Passeport) et selfie de vérification.</li>
                  <li>Extrait de casier judiciaire (vérification de sécurité pour interventions à domicile).</li>
                  <li>Données de transport : marque, modèle, couleur, immatriculation du véhicule, permis de conduire.</li>
                  <li>Qualifications professionnelles, attestations ou diplômes.</li>
                  <li>Coordonnées bancaires ou numéro Mobile Money (versement des gains).</li>
                  <li>Historique d'interventions, devis émis et notes attribuées.</li>
                </ul>
              </div>
            </div>
          </section>

          <!-- Géolocalisation & Permissions Mobiles -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">3</span>
              Permissions Mobiles & Géolocalisation
            </h2>
            <div class="bg-blue-50 border-l-4 border-blue-500 p-4 rounded-r-xl mb-4 text-blue-950">
              <p class="font-semibold text-sm">Transparence sur les autorisations système :</p>
              <p class="text-xs sm:text-sm mt-1">
                Conformément aux directives de Google Play et de l'Apple App Store, voici l'usage exact des autorisations sollicitées :
              </p>
            </div>

            <div class="space-y-3">
              <div class="border border-gray-100 rounded-xl p-3">
                <p class="font-bold text-sm text-gray-800">📍 Données de Localisation (GPS) :</p>
                <ul class="text-xs sm:text-sm text-gray-600 list-disc pl-5 mt-1 space-y-1">
                  <li><strong>Client :</strong> Localisation requise uniquement lors de la création d'une demande pour situer précisément le lieu de dépannage.</li>
                  <li><strong>Technicien Pro :</strong> La géolocalisation est collectée <em>en premier plan et en arrière-plan</em> lorsque le technicien est marqué « En Ligne » ou « En Route » pour permettre le dispatching automatisé, le calcul de l'heure estimée d'arrivée (ETA), le guidage GPS et le suivi en temps réel par le client pour des motifs évidents de sécurité. La collecte s'interrompt dès que le technicien se met « Hors Ligne ».</li>
                </ul>
              </div>

              <div class="border border-gray-100 rounded-xl p-3">
                <p class="font-bold text-sm text-gray-800">📷 Appareil Photo & Stockage :</p>
                <p class="text-xs sm:text-sm text-gray-600 mt-1">
                  Utilisé pour photographier le matériel en panne (Client) ou pour téléverser les documents de conformité KYC (CNI, permis, casier judiciaire, selfie pour les Techniciens).
                </p>
              </div>

              <div class="border border-gray-100 rounded-xl p-3">
                <p class="font-bold text-sm text-gray-800">🔔 Notifications Push :</p>
                <p class="text-xs sm:text-sm text-gray-600 mt-1">
                  Nécessaires pour vous avertir de l'attribution d'une mission, de l'arrivée du technicien, de l'émission d'un devis ou des nouveaux messages du chat.
                </p>
              </div>
            </div>
          </section>

          <!-- Finalités -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">4</span>
              Finalités et Bases Légales du Traitement
            </h2>
            <p class="mb-2">Nous traitons vos données afin de :</p>
            <ul class="list-disc pl-5 space-y-1.5 text-gray-600 text-sm">
              <li>Assurer l'exécution du service de mise en relation et l'acheminement des techniciens (<em>Exécution contractuelle</em>).</li>
              <li>Garantir la sécurité des utilisateurs grâce à la vérification approfondie des professionnels (<em>Intérêt légitime et sécurité publique</em>).</li>
              <li>Permettre l'établissement et l'approbation formelle des devis d'intervention.</li>
              <li>Assurer le versement sécurisé des rémunérations sur le portefeuille des artisans.</li>
              <li>Prévenir la fraude et résoudre les éventuelles réclamations.</li>
            </ul>
            <p class="mt-3 font-semibold text-gray-900">
              Important : depanGo ne vend, ne loue, ni ne cède jamais vos données personnelles à des fins publicitaires ou commerciales à des tiers.
            </p>
          </section>

          <!-- Partage et Sous-traitance -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">5</span>
              Destinataires et Partage des Données
            </h2>
            <p class="mb-2">Vos informations ne sont partagées que dans les strictes limites suivantes :</p>
            <ul class="list-disc pl-5 space-y-1.5 text-gray-600 text-sm">
              <li><strong>Entre le Client et le Technicien assigné :</strong> Seules les informations nécessaires à l'accomplissement de la mission sont partagées (prénom, téléphone, adresse du lieu de panne, plaque d'immatriculation du technicien).</li>
              <li><strong>Sous-traitants techniques de confiance :</strong> Hébergement sécurisé (serveurs cloud), envoi de SMS OTP et notifications push (services certifiés Firebase / Google Cloud), et services cartographiques.</li>
              <li><strong>Autorités compétentes :</strong> Uniquement sur réquisition judiciaire légale.</li>
            </ul>
          </section>

          <!-- Sécurité & Conservation -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">6</span>
              Sécurité et Conservation des Données
            </h2>
            <p class="mb-3">
              Toutes les communications entre vos applications et nos serveurs sont chiffrées via les protocoles de sécurité standards (HTTPS/TLS). Les mots de passe et données sensibles sont hachés et sécurisés.
            </p>
            <p>
              Les données personnelles sont conservées pendant toute la durée d'activité de votre compte, augmentée des délais légaux de prescription fiscale et commerciale applicables.
            </p>
          </section>

          <!-- Suppression de compte & Droits -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">7</span>
              Vos Droits et Suppression de Compte (Conformité Stores)
            </h2>
            <p class="mb-3">
              Conformément à la réglementation sur la protection des données personnelles, vous disposez d’un droit d’accès, de rectification, de portabilité et de suppression de vos informations personnelles.
            </p>
            
            <div class="bg-red-50 border border-red-200 rounded-2xl p-5 my-4">
              <h3 class="font-bold text-red-900 text-base mb-2 flex items-center">
                <svg class="w-5 h-5 mr-2 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                </svg>
                Comment demander la suppression complète de votre compte et de vos données ?
              </h3>
              <p class="text-xs sm:text-sm text-red-800 leading-relaxed mb-3">
                Vous pouvez à tout moment solliciter la clôture de votre compte et la purge de vos données :
              </p>
              <ol class="text-xs sm:text-sm text-red-800 space-y-1 list-decimal pl-5">
                <li>Directement depuis votre application mobile dans l'onglet <strong>« Mon Profil » → « Supprimer mon compte »</strong> ; ou</li>
                <li>En envoyant une simple demande par email à <a href="mailto:privacy@depango.sn" class="font-bold underline">privacy@depango.sn</a> ou <a href="mailto:contact@depango.sn" class="font-bold underline">contact@depango.sn</a> avec pour objet <em>« Demande de suppression de compte »</em> et votre numéro de téléphone.</li>
              </ol>
              <p class="text-xs text-red-700 mt-2">
                Le traitement de la suppression et l'anonymisation des données s'effectuent sous un délai maximal de 30 jours, sous réserve des obligations légales de conservation (facturation/comptabilité).
              </p>
            </div>
          </section>

          <!-- Contact -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">8</span>
              Contact et Réclamations
            </h2>
            <p>
              Pour toute question relative à cette politique ou pour exercer vos droits, vous pouvez nous écrire à :
            </p>
            <p class="mt-2 font-medium">
              📧 Email : <a href="mailto:privacy@depango.sn" class="text-[#0D776C] underline">privacy@depango.sn</a> / <a href="mailto:contact@depango.sn" class="text-[#0D776C] underline">contact@depango.sn</a><br />
              📞 Téléphone : +221 77 000 00 00
            </p>
          </section>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineEmits(['back']);
</script>
