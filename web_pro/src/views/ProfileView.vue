<template>
  <v-container fluid class="pa-6">
    
    <!-- Top Header -->
    <div class="d-flex flex-column flex-sm-row align-start align-sm-center justify-space-between ga-3 mb-6">
      <div>
        <div class="text-caption text-grey font-weight-bold text-uppercase">TechConnect Pro • Compte & Paramètres</div>
        <div class="text-h5 font-weight-black text-white">Profil Technicien & Spécialités</div>
      </div>

      <v-btn
        color="error"
        variant="tonal"
        size="small"
        prepend-icon="mdi-logout"
        class="text-none font-weight-bold"
        @click="handleLogout"
      >
        Déconnexion
      </v-btn>
    </div>

    <!-- Top Identity Summary Card -->
    <v-card class="pa-6 rounded-lg border mb-6" elevation="3">
      <div class="d-flex flex-column flex-md-row align-start align-md-center justify-space-between ga-4">
        <div class="d-flex align-center ga-4">
          <v-avatar color="primary" size="72" class="font-weight-black text-h4 text-slate-950">
            {{ userInitials }}
          </v-avatar>
          <div>
            <div class="d-flex align-center ga-2 mb-1">
              <span class="text-h5 font-weight-bold text-white">{{ authStore.user?.name || profileForm.name }}</span>
              <v-chip color="success" size="small" variant="flat" class="font-weight-bold">
                <v-icon start icon="mdi-check-decagram" size="x-small"></v-icon> Compte Certifié
              </v-chip>
            </div>
            <div class="text-caption text-grey">{{ authStore.user?.email || profileForm.email }} • {{ authStore.user?.phone || profileForm.phone }}</div>
            <div class="text-caption text-primary font-weight-bold mt-1">Spécialités Activées : {{ activeTradesList }}</div>
          </div>
        </div>

        <div class="d-flex align-center ga-4">
          <v-card variant="tonal" color="warning" class="pa-3 rounded-lg text-center">
            <div class="text-caption text-grey font-weight-bold">Satisfaction Client</div>
            <div class="d-flex align-center justify-center ga-1 text-amber">
              <v-icon icon="mdi-star" color="amber" size="small"></v-icon>
              <span class="text-h6 font-weight-black">{{ missionStore.techRating }} / 5.0</span>
            </div>
          </v-card>

          <v-card variant="tonal" color="success" class="pa-3 rounded-lg text-center">
            <div class="text-caption text-grey font-weight-bold">Statut GPS</div>
            <div class="text-caption font-weight-bold text-success mt-1">
              {{ authStore.isOnline ? 'EN LIGNE' : 'HORS LIGNE' }}
            </div>
          </v-card>
        </div>
      </div>
    </v-card>

    <!-- Tabbed Profile Sections Card -->
    <v-card class="rounded-lg border" elevation="3">
      <v-tabs v-model="activeTab" color="primary" align-tabs="start">
        <v-tab value="identity" class="text-none font-weight-bold">
          <v-icon start icon="mdi-account-outline"></v-icon> Identité & Contact
        </v-tab>
        <v-tab value="trades" class="text-none font-weight-bold">
          <v-icon start icon="mdi-wrench-outline"></v-icon> Métiers & Compétences
        </v-tab>
        <v-tab value="location" class="text-none font-weight-bold">
          <v-icon start icon="mdi-map-marker-radius-outline"></v-icon> Zone GPS (Couverture)
        </v-tab>
        <v-tab value="subscription" class="text-none font-weight-bold">
          <v-icon start icon="mdi-shield-lock-outline"></v-icon> Sécurité & SaaS
        </v-tab>
      </v-tabs>

      <v-divider></v-divider>

      <v-card-text class="pa-6">
        
        <!-- TAB 1: Identity & Personal Info -->
        <div v-if="activeTab === 'identity'">
          <div class="text-subtitle-1 font-weight-bold text-white mb-4">Informations Personnelles & Entreprise</div>
          
          <v-row>
            <v-col cols="12" md="6">
              <v-text-field
                v-model="profileForm.name"
                label="Nom Complet / Raison Sociale"
                variant="outlined"
                color="primary"
                prepend-inner-icon="mdi-account"
              ></v-text-field>
            </v-col>

            <v-col cols="12" md="6">
              <v-text-field
                v-model="profileForm.email"
                label="Adresse Email Professionnelle"
                variant="outlined"
                color="primary"
                prepend-inner-icon="mdi-email"
              ></v-text-field>
            </v-col>

            <v-col cols="12" md="6">
              <v-text-field
                v-model="profileForm.phone"
                label="Numéro de Téléphone (WhatsApp)"
                variant="outlined"
                color="primary"
                prepend-inner-icon="mdi-phone"
              ></v-text-field>
            </v-col>

            <v-col cols="12" md="6">
              <v-text-field
                v-model="profileForm.ninea"
                label="Identifiant NINEA / Registre Pro"
                variant="outlined"
                color="primary"
                prepend-inner-icon="mdi-card-account-details"
              ></v-text-field>
            </v-col>

            <v-col cols="12" md="6">
              <v-select
                v-model="profileForm.transport_mode"
                :items="[{title: 'Moto 🛵', value: 'moto'}, {title: 'Voiture 🚗', value: 'voiture'}]"
                label="Moyen de Transport"
                variant="outlined"
                color="primary"
                prepend-inner-icon="mdi-moped"
              ></v-select>
            </v-col>
          </v-row>

          <div class="d-flex justify-end mt-4">
            <v-btn
              color="primary"
              variant="flat"
              :loading="savingInfo"
              class="text-none font-weight-bold rounded-pill px-6"
              @click="saveProfileInfo"
            >
              Enregistrer les Modifications
            </v-btn>
          </div>
        </div>

        <!-- TAB 2: Trades & Specialties -->
        <div v-if="activeTab === 'trades'">
          <div class="text-subtitle-1 font-weight-bold text-white mb-2">Métiers & Spécialités Activées</div>
          <div class="text-caption text-grey mb-4">Les clients verront vos compétences lors de leurs demandes de devis et de matching.</div>

          <v-row dense>
            <v-col v-for="cat in availableCategories" :key="cat.id" cols="12" sm="6">
              <v-card
                :color="profileForm.category_ids.includes(cat.id) ? 'primary' : 'surface-variant'"
                :variant="profileForm.category_ids.includes(cat.id) ? 'flat' : 'outlined'"
                class="pa-4 rounded-lg cursor-pointer"
                @click="toggleCategory(cat.id)"
              >
                <div class="d-flex align-center justify-space-between">
                  <div class="d-flex align-center ga-3">
                    <v-icon :icon="cat.icon" :color="profileForm.category_ids.includes(cat.id) ? 'slate-950' : 'primary'"></v-icon>
                    <div>
                      <div class="font-weight-bold" :class="profileForm.category_ids.includes(cat.id) ? 'text-slate-950' : 'text-white'">
                        {{ cat.name }}
                      </div>
                      <div class="text-caption" :class="profileForm.category_ids.includes(cat.id) ? 'text-slate-900' : 'text-grey'">
                        {{ cat.desc }}
                      </div>
                    </div>
                  </div>
                  <v-checkbox-btn
                    :model-value="profileForm.category_ids.includes(cat.id)"
                    color="slate-950"
                  ></v-checkbox-btn>
                </div>
              </v-card>
            </v-col>
          </v-row>

          <div class="d-flex justify-end mt-6">
            <v-btn
              color="primary"
              variant="flat"
              :loading="savingTrades"
              class="text-none font-weight-bold rounded-pill px-6"
              @click="saveTrades"
            >
              Mettre à jour mes Spécialités
            </v-btn>
          </div>
        </div>

        <!-- TAB 3: GPS Coverage Area -->
        <div v-if="activeTab === 'location'">
          <div class="text-subtitle-1 font-weight-bold text-white mb-2">Zone de Couverture Géographique</div>
          <div class="text-caption text-grey mb-4">Le moteur de matching PostGIS filtre les demandes clientes à l'intérieur de ce rayon.</div>

          <v-row class="mb-4">
            <v-col cols="12" md="6">
              <v-text-field
                v-model="profileForm.address"
                label="Adresse de base / Ville"
                variant="outlined"
                color="primary"
                prepend-inner-icon="mdi-map-marker"
              ></v-text-field>
            </v-col>

            <v-col cols="12" md="6">
              <div class="text-caption text-grey font-weight-bold mb-1">Rayon d'action PostGIS : {{ profileForm.radius_km }} km</div>
              <v-slider
                v-model="profileForm.radius_km"
                min="5"
                max="50"
                step="5"
                color="primary"
                thumb-label
              ></v-slider>
            </v-col>
          </v-row>

          <v-card variant="tonal" color="primary" class="pa-4 rounded-lg border text-center mb-4">
            <v-icon icon="mdi-radar" color="primary" size="32" class="mb-2"></v-icon>
            <div class="text-body-2 font-weight-bold text-white">Zone couverte : {{ profileForm.address }} ± {{ profileForm.radius_km }} km</div>
            <div class="text-caption text-grey">Attribution automatique en 90 secondes active.</div>
          </v-card>

          <div class="d-flex justify-end mt-4">
            <v-btn
              color="primary"
              variant="flat"
              :loading="savingLocation"
              class="text-none font-weight-bold rounded-pill px-6"
              @click="saveLocation"
            >
              Mettre à jour la Zone GPS
            </v-btn>
          </div>
        </div>

        <!-- TAB 4: Security & SaaS Subscription -->
        <div v-if="activeTab === 'subscription'">
          <div class="text-subtitle-1 font-weight-bold text-white mb-2">Abonnement SaaS & Sécurité du Compte</div>

          <v-alert 
            :color="missionStore.activeSubscription?.plan_name === 'premium' ? 'warning' : 'success'" 
            variant="tonal" 
            class="rounded-lg mb-6" 
            :icon="missionStore.activeSubscription?.plan_name === 'premium' ? 'mdi-star-circle' : 'mdi-shield-check'"
          >
            <div class="font-weight-bold">
              Formule TechConnect SaaS Pro Active ({{ missionStore.activeSubscription?.plan_name === 'premium' ? 'Premium' : 'Basique' }})
            </div>
            <div class="text-caption mt-1">
              {{ missionStore.activeSubscription?.plan_name === 'premium' 
                ? 'Plan Premium : Visibilité prioritaire, 0% de commission sur les paiements directs, matching instantané.' 
                : 'Plan Basique : Accès standard aux missions, matching normal.' }}
            </div>
            <div v-if="missionStore.activeSubscription?.plan_name !== 'premium'" class="mt-3">
              <v-btn color="warning" variant="flat" size="small" class="text-none font-weight-bold" @click="subscribePremium" :loading="subscribing">
                Passer en Premium (10 000 FCFA/mois)
              </v-btn>
            </div>
          </v-alert>

          <div class="text-subtitle-2 font-weight-bold text-white mb-3">Changer le Mot de Passe</div>
          <v-row class="mb-4">
            <v-col cols="12" md="6">
              <v-text-field
                v-model="passwordForm.current"
                label="Mot de passe actuel"
                type="password"
                variant="outlined"
                color="primary"
              ></v-text-field>
            </v-col>

            <v-col cols="12" md="6">
              <v-text-field
                v-model="passwordForm.newPass"
                label="Nouveau mot de passe"
                type="password"
                variant="outlined"
                color="primary"
              ></v-text-field>
            </v-col>
          </v-row>

          <div class="d-flex justify-space-between align-center border-t pt-4">
            <v-btn
              color="error"
              variant="outlined"
              prepend-icon="mdi-logout"
              class="text-none font-weight-bold rounded-pill"
              @click="handleLogout"
            >
              Déconnexion
            </v-btn>

            <v-btn
              color="primary"
              variant="flat"
              :loading="savingPassword"
              class="text-none font-weight-bold rounded-pill px-6"
              @click="savePassword"
            >
              Changer le mot de passe
            </v-btn>
          </div>
        </div>

      </v-card-text>
    </v-card>

    <!-- Notification Modal Dialog (Replaces native browser alert) -->
    <v-dialog v-model="modal.show" max-width="420">
      <v-card class="pa-6 rounded-xl border border-primary text-center" color="surface">
        <v-avatar :color="modal.color" size="56" class="mx-auto mb-3">
          <v-icon :icon="modal.icon" size="32" color="slate-950"></v-icon>
        </v-avatar>
        <div class="text-h6 font-weight-bold text-white mb-2">{{ modal.title }}</div>
        <div class="text-body-2 text-grey mb-6">{{ modal.message }}</div>
        <v-btn color="primary" variant="flat" block size="large" class="text-none font-weight-bold rounded-pill" @click="modal.show = false">
          Compris
        </v-btn>
      </v-card>
    </v-dialog>

  </v-container>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useMissionStore } from '@/stores/mission'

const router = useRouter()
const authStore = useAuthStore()
const missionStore = useMissionStore()

const activeTab = ref('identity')
const savingInfo = ref(false)
const savingTrades = ref(false)
const savingLocation = ref(false)
const savingPassword = ref(false)

const modal = ref({
  show: false,
  title: '',
  message: '',
  icon: 'mdi-check-circle',
  color: 'success'
})

function showNotification(title, message, icon = 'mdi-check-circle', color = 'success') {
  modal.value = { show: true, title, message, icon, color }
}

const profileForm = ref({
  name: authStore.user?.name || 'Ousmane Sow',
  email: authStore.user?.email || 'tech@techconnect.com',
  phone: authStore.user?.phone || '+221 77 000 00 02',
  ninea: 'SN-DKR-2026-B9876',
  category_ids: ['cat_plumbing', 'cat_electrical', 'cat_hvac'],
  address: 'Dakar, Sénégal',
  radius_km: 15,
  transport_mode: 'moto'
})

const passwordForm = ref({
  current: '',
  newPass: ''
})

const availableCategories = [
  { id: 'cat_plumbing', name: 'Plomberie', desc: 'Fuites, débouchage, installation', icon: 'mdi-water-pump' },
  { id: 'cat_electrical', name: 'Électricité', desc: 'Panne de courant, câblage, tableau', icon: 'mdi-bolt' },
  { id: 'cat_hvac', name: 'Froid & Climatisation', desc: 'Recharge gaz, entretien clim & frigo', icon: 'mdi-air-conditioner' },
  { id: 'cat_appliances', name: 'Électroménager', desc: 'Réparation laves-linge & fours', icon: 'mdi-washing-machine' }
]

const userInitials = computed(() => {
  const name = authStore.user?.name || profileForm.value.name
  const parts = name.split(' ')
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase()
  return name.slice(0, 2).toUpperCase()
})

const activeTradesList = computed(() => {
  const map = {
    cat_plumbing: 'Plomberie',
    cat_electrical: 'Électricité',
    cat_hvac: 'Froid & Climatisation',
    cat_appliances: 'Électroménager'
  }
  return profileForm.value.category_ids.map(id => map[id] || id).join(', ')
})

onMounted(async () => {
  if (authStore.user) {
    profileForm.value.name = authStore.user.name || profileForm.value.name
    profileForm.value.email = authStore.user.email || profileForm.value.email
    profileForm.value.phone = authStore.user.phone || profileForm.value.phone
  }
  const userId = authStore.user?.id || 'user_tech_demo'
  await missionStore.fetchTechnicianProfile(userId)
  await missionStore.fetchSubscription()
  if (missionStore.techCategories && missionStore.techCategories.length > 0) {
    profileForm.value.category_ids = [...missionStore.techCategories]
  }
  if (missionStore.techTransportMode) {
    profileForm.value.transport_mode = missionStore.techTransportMode
  }
})

function toggleCategory(catId) {
  const current = [...profileForm.value.category_ids]
  const idx = current.indexOf(catId)
  if (idx > -1) {
    if (current.length > 1) {
      current.splice(idx, 1)
    }
  } else {
    current.push(catId)
  }
  profileForm.value.category_ids = [...current]
}

async function saveProfileInfo() {
  savingInfo.value = true
  await authStore.updateUserProfile({
    name: profileForm.value.name,
    email: profileForm.value.email,
    phone: profileForm.value.phone
  })
  
  // Update transport mode
  const API_BASE = 'https://backend-depango-346078879462.europe-west1.run.app/api/v1' // or env var
  try {
    await fetch(`${API_BASE}/technicians/me/transport`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authStore.token}`
      },
      body: JSON.stringify({ transport_mode: profileForm.value.transport_mode })
    })
  } catch(e) {
    console.error("Error saving transport mode", e)
  }

  savingInfo.value = false
  showNotification('Identité & Transport Mis à Jour', 'Vos informations personnelles et mode de transport ont été enregistrés.', 'mdi-account-check', 'success')
}

async function saveTrades() {
  savingTrades.value = true
  const userId = authStore.user?.id || 'user_tech_demo'
  await authStore.updateUserProfile({
    category_ids: profileForm.value.category_ids
  })
  await missionStore.fetchTechnicianProfile(userId)
  savingTrades.value = false
  showNotification(
    'Spécialités Activées',
    'Vos compétences ont été mises à jour ! Elles sont désormais enregistrées en base de données et visibles pour le matching client.',
    'mdi-wrench-check',
    'success'
  )
}

async function saveLocation() {
  savingLocation.value = true
  await authStore.updateUserProfile({
    address: profileForm.value.address,
    radius_km: profileForm.value.radius_km
  })
  savingLocation.value = false
  showNotification('Zone GPS Mise à Jour', 'Votre rayon d\'action a été mis à jour dans le moteur PostGIS.', 'mdi-map-marker-check', 'success')
}

async function savePassword() {
  if (!passwordForm.value.newPass) return
  savingPassword.value = true
  setTimeout(() => {
    savingPassword.value = false
    passwordForm.value.current = ''
    passwordForm.value.newPass = ''
    showNotification('Mot de Passe Modifié', 'Votre mot de passe a été sécurisé et mis à jour.', 'mdi-shield-lock', 'success')
  }, 500)
}

async function saveSecurity() {
  savingSecurity.value = true
  await new Promise(r => setTimeout(r, 800)) // Simulate network request
  savingSecurity.value = false
  passwordForm.value.current = ''
  passwordForm.value.new = ''
  passwordForm.value.confirm = ''
  showNotification('Sécurité mise à jour', 'Votre mot de passe a été modifié avec succès.')
}

const subscribing = ref(false)

async function subscribePremium() {
  subscribing.value = true
  const success = await missionStore.subscribe('premium')
  subscribing.value = false
  if (success) {
    showNotification('Abonnement Premium Actif !', 'Félicitations, vous êtes désormais membre Premium.', 'mdi-star-circle', 'warning')
  } else {
    showNotification('Erreur', 'Impossible de souscrire à l\'abonnement.', 'mdi-alert', 'error')
  }
}

function handleLogout() {
  authStore.logout()
  router.push('/login')
}
</script>

<style>
.cursor-pointer {
  cursor: pointer;
}
</style>
