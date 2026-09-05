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
            Document Légal
          </span>
          <h1 class="text-3xl sm:text-4xl font-black text-gray-900 tracking-tight mb-4">
            Conditions Générales d'Utilisation (CGU)
          </h1>
          <p class="text-gray-600 leading-relaxed text-base">
            Plateforme de mise en relation de dépannage et services techniques à domicile <span class="font-bold text-[#0D776C]">depanGo</span>.
          </p>
        </div>

        <div class="space-y-8 text-gray-700 leading-relaxed text-sm sm:text-base">
          <!-- Article 1 -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">1</span>
              Préambule et Objet
            </h2>
            <p class="mb-3">
              Les présentes Conditions Générales d’Utilisation (ci-après désignées les « <strong>CGU</strong> ») définissent les règles d'accès et d'utilisation de la plateforme technologique <strong>depanGo</strong>, accessible via les applications mobiles (iOS et Android) ainsi que le site internet associé.
            </p>
            <p>
              La plateforme est éditée par <strong>depanGo</strong> (contact officiel : <a href="mailto:contact@depango.sn" class="text-[#0D776C] underline font-medium">contact@depango.sn</a>). En téléchargeant l'une de nos applications ou en utilisant nos services, tout utilisateur (Client ou Technicien) accepte expressément et sans réserve l'intégralité des présentes conditions.
            </p>
          </section>

          <!-- Article 2 -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">2</span>
              Définitions
            </h2>
            <ul class="list-disc pl-5 space-y-2 text-gray-600">
              <li><strong>« Plateforme » :</strong> L'infrastructure logicielle, les serveurs, API, applications mobiles (depanGo Client et depanGo Pro) et sites web gérés par depanGo.</li>
              <li><strong>« Client » :</strong> Toute personne physique ou morale qui utilise l'application pour solliciter une intervention de dépannage ou d'entretien à une adresse donnée.</li>
              <li><strong>« Technicien / Artisan Pro » :</strong> Professionnel indépendant ou artisan qualifié, dûment inscrit, vérifié et validé sur la plateforme, fournissant des prestations de dépannage.</li>
              <li><strong>« Mission / Intervention » :</strong> Toute prestation d'assistance technique convenue entre un Client et un Technicien (plomberie, électricité, froid & climatisation, serrurerie, etc.).</li>
              <li><strong>« Devis » :</strong> Document chiffré établi par le Technicien sur place via l'application et soumis à la validation explicite du Client avant toute exécution de travaux.</li>
            </ul>
          </section>

          <!-- Article 3 -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">3</span>
              Rôle et Statut de la Plateforme (Intermédiaire Technique)
            </h2>
            <div class="bg-amber-50 border-l-4 border-amber-400 p-4 rounded-r-xl mb-3 text-amber-900">
              <p class="font-semibold text-sm">Avis fondamental sur la relation contractuelle :</p>
              <p class="text-xs sm:text-sm mt-1">
                depanGo intervient exclusivement en tant qu’<strong>intermédiaire technologique de mise en relation</strong>. Le contrat de prestation de services de dépannage est conclu directement entre le Client et le Technicien indépendant.
              </p>
            </div>
            <p>
              Les techniciens inscrits exercent leur profession en totale indépendance juridique et fiscale. depanGo n'est en aucun cas l'employeur des artisans ni une société d'artisanat du bâtiment. En conséquence, depanGo ne saurait être tenue pour responsable des malfaçons, retards imprévisibles ou fautes commises lors de l'exécution matérielle des travaux, hors obligations légales d'intermédiation.
            </p>
          </section>

          <!-- Article 4 -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">4</span>
              Inscription et Processus de Sécurité (KYC Techniciens)
            </h2>
            <p class="mb-3">
              <strong>Pour les Clients :</strong> L'accès s'effectue via un numéro de téléphone vérifié par mot de passe à usage unique (SMS OTP). L'utilisateur s'engage à fournir des informations exactes.
            </p>
            <p class="mb-3">
              <strong>Pour les Techniciens (depanGo Pro) :</strong> Afin d'assurer un niveau de sécurité optimal aux utilisateurs et de garantir la confiance à domicile (normes de traçabilité renforcée), l'activation du compte professionnel requiert la soumission obligatoire et la validation manuelle des éléments suivants :
            </p>
            <ul class="list-disc pl-5 space-y-2 text-gray-600">
              <li>Pièce d'identité nationale valide (CNI, Passeport ou Carte de séjour) avec selfie de concordance faciale ;</li>
              <li>Extrait de casier judiciaire récent ;</li>
              <li>Justificatifs de compétences ou certifications professionnelles ;</li>
              <li>Renseignements sur le moyen de transport (immatriculation, marque, modèle, permis de conduire le cas échéant).</li>
            </ul>
            <p class="mt-2 text-xs text-gray-500 italic">
              depanGo se réserve le droit souverain de refuser ou de révoquer l'accès à tout technicien dont le dossier s'avérerait incomplet, litigieux ou non conforme à nos critères d'éthique et de sécurité.
            </p>
          </section>

          <!-- Article 5 -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">5</span>
              Processus de Commande, Déplacement et Devis
            </h2>
            <ol class="list-decimal pl-5 space-y-3 text-gray-600">
              <li>
                <strong>Demande & Tarifs de base :</strong> Le Client sélectionne un service. Un prix indicatif de base (ex: diagnostic initial ou forfait de prise en charge) est affiché en amont.
              </li>
              <li>
                <strong>Acceptation & Déplacement :</strong> Le Technicien disponible accepte la mission. Le Client peut suivre l'arrivée du professionnel en direct sur la carte avec une estimation du délai (ETA).
              </li>
              <li>
                <strong>Établissement obligatoire d'un Devis :</strong> Une fois sur place et après diagnostic de la panne, le Technicien établit un devis détaillé sur l'application (détaillant le coût des pièces et la main d'œuvre). <strong>Aucuns travaux payants ne peuvent débuter sans acceptation expresse du devis par le Client sur son application.</strong>
              </li>
              <li>
                <strong>Clôture de mission :</strong> Dès les travaux achevés, le Technicien clôture la mission et le paiement est régularisé selon les modalités acceptées.
              </li>
            </ol>
          </section>

          <!-- Article 6 -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">6</span>
              Annulations et Frais de Déplacement
            </h2>
            <p class="mb-3">
              Une mission peut être annulée par l'une ou l'autre des parties en sélectionnant un motif légitime parmi les options prévues par l'application (ex: « Technicien injoignable », « Déplacement impossible », « Panne résolue », etc.).
            </p>
            <p>
              Si une annulation injustifiée intervient alors que le Technicien est déjà en route ou arrivé sur les lieux, un forfait d'indemnisation de déplacement peut être facturé au Client afin de dédommager le temps et le transport du professionnel.
            </p>
          </section>

          <!-- Article 7 -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">7</span>
              Règles de Conduite et Sécurité
            </h2>
            <p class="mb-2">
              Chaque utilisateur s'engage au respect mutuel, à la courtoisie et à la sécurité des biens et des personnes. Sont strictement prohibés :
            </p>
            <ul class="list-disc pl-5 space-y-1 text-gray-600">
              <li>Toute agression verbale, physique ou comportement discriminatoire ;</li>
              <li>Toute tentative d'entente illicite hors plateforme pour contourner les garanties et la traçabilité de depanGo ;</li>
              <li>La communication de fausses déclarations d'identité ou de faux justificatifs.</li>
            </ul>
            <p class="mt-2 text-sm">
              Tout manquement entraînera le blocage immédiat et définitif du compte utilisateur ou professionnel, sans préavis ni indemnité.
            </p>
          </section>

          <!-- Article 8 -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">8</span>
              Avis et Notations
            </h2>
            <p>
              À l'issue de chaque intervention, le Client est invité à évaluer la prestation. Les avis doivent refléter une expérience réelle et demeurer constructifs. depanGo se réserve le droit de modérer ou supprimer tout commentaire injurieux ou diffamatoire.
            </p>
          </section>

          <!-- Article 9 -->
          <section>
            <h2 class="text-xl font-bold text-gray-900 mb-3 flex items-center">
              <span class="w-7 h-7 bg-[#0D776C] text-white rounded-lg flex items-center justify-center text-sm mr-3 flex-shrink-0">9</span>
              Droit Applicable et Résolution des Litiges
            </h2>
            <p class="mb-3">
              Les présentes CGU sont soumises à la législation en vigueur. En cas de différend entre un Client et un Technicien, depanGo s'efforcera de proposer un cadre de médiation amiable à travers son service support.
            </p>
            <p>
              Pour toute réclamation, vous pouvez contacter notre assistance à : <a href="mailto:contact@depango.sn" class="text-[#0D776C] underline font-medium">contact@depango.sn</a>.
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
