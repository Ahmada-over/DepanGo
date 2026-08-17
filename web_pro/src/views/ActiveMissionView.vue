<template>
  <v-container fluid class="pa-6">
    
    <!-- Empty State if No Active Mission -->
    <div v-if="!missionStore.activeMission" class="text-center py-12">
      <v-card class="pa-8 max-w-500 mx-auto rounded-lg border text-center" elevation="2">
        <v-icon icon="mdi-file-search-outline" size="64" color="grey" class="mb-4"></v-icon>
        <div class="text-h6 font-weight-bold text-white mb-2">Aucun Dossier d'Intervention Sélectionné</div>
        <div class="text-body-2 text-grey mb-6">Sélectionnez une mission active dans le tableau de bord ou attendez une nouvelle attribution.</div>
        <v-btn to="/" color="primary" variant="flat" class="text-none font-weight-bold">
          Retour au Tableau de Bord
        </v-btn>
      </v-card>
    </div>

    <!-- Active Dispatch Detail View -->
    <div v-else>
      
      <!-- Top Dispatch Header -->
      <div class="d-flex flex-column flex-sm-row align-start align-sm-center justify-space-between ga-3 mb-6">
        <div>
          <div class="d-flex align-center ga-3">
            <span class="text-h5 font-weight-black text-white">Dossier #{{ missionStore.activeMission.id }}</span>
            <v-chip :color="missionStore.activeMission.color || 'primary'" size="small" variant="flat" class="font-weight-bold text-uppercase">
              {{ missionStore.activeMission.status_label || 'En cours' }}
            </v-chip>
          </div>
          <div class="text-caption text-grey">Attribué à {{ authStore.user?.name || 'Technicien' }} • Service Pro</div>
        </div>

        <div class="d-flex align-center ga-3">
          <!-- Step 1: Accepter (only visible when pending) -->
          <v-btn
            v-if="missionStore.activeMission.status === 'pending'"
            color="success"
            variant="flat"
            size="small"
            prepend-icon="mdi-check-circle"
            :loading="missionStore.acceptLoading"
            class="text-none font-weight-bold"
            @click="missionStore.acceptManualMission(missionStore.activeMission.id)"
          >
            Accepter cette demande
          </v-btn>

          <!-- Step 2: En Route (only visible when matched) -->
          <v-btn
            v-if="missionStore.activeMission.status === 'matched'"
            color="primary"
            variant="flat"
            size="small"
            prepend-icon="mdi-navigation"
            :loading="missionStore.statusLoading"
            class="text-none font-weight-bold"
            @click="missionStore.updateMissionStatus('in_progress')"
          >
            🚗 Passer : En Route
          </v-btn>

          <!-- Step 3: Sur Place (only visible when in_progress) -->
          <v-btn
            v-if="missionStore.activeMission.status === 'in_progress'"
            color="warning"
            variant="flat"
            size="small"
            prepend-icon="mdi-map-marker-check"
            :loading="missionStore.statusLoading"
            class="text-none font-weight-bold"
            @click="missionStore.updateMissionStatus('on_site')"
          >
            📍 Passer : Sur Place
          </v-btn>

          <!-- Step 4: Clôturer (only visible when on_site) -->
          <v-btn
            v-if="missionStore.activeMission.status === 'on_site'"
            color="success"
            variant="flat"
            size="small"
            prepend-icon="mdi-check-circle-outline"
            :loading="missionStore.statusLoading"
            class="text-none font-weight-bold"
            @click="missionStore.updateMissionStatus('completed')"
          >
            ✅ Clôturer Dossier (Règlement Effectué)
          </v-btn>

          <!-- Cancel Button -->
          <v-btn
            color="error"
            variant="flat"
            size="small"
            prepend-icon="mdi-close-circle-outline"
            class="text-none font-weight-bold ml-2"
            @click="showCancelModal = true"
          >
            Annuler l'intervention
          </v-btn>
        </div>
      </div>

      <!-- Step Progression Bar -->
      <v-row class="mb-6">
        <v-col cols="12">
          <v-card class="pa-4 rounded-lg border" elevation="2">
            <div class="text-caption text-grey font-weight-bold text-uppercase mb-3">Progression du Workflow d'Intervention</div>
            
            <v-row class="text-center">
              <v-col cols="3">
                <v-avatar :color="stepIndex >= 1 ? 'primary' : 'surface-variant'" size="32" class="font-weight-bold mb-1">1</v-avatar>
                <div class="text-caption" :class="stepIndex >= 1 ? 'text-primary font-weight-bold' : 'text-grey'">Assignée</div>
              </v-col>
              <v-col cols="3">
                <v-avatar :color="stepIndex >= 2 ? 'primary' : 'surface-variant'" size="32" class="font-weight-bold mb-1">2</v-avatar>
                <div class="text-caption" :class="stepIndex >= 2 ? 'text-primary font-weight-bold' : 'text-grey'">En Route</div>
              </v-col>
              <v-col cols="3">
                <v-avatar :color="stepIndex >= 3 ? 'primary' : 'surface-variant'" size="32" class="font-weight-bold mb-1">3</v-avatar>
                <div class="text-caption" :class="stepIndex >= 3 ? 'text-primary font-weight-bold' : 'text-grey'">Sur Place</div>
              </v-col>
              <v-col cols="3">
                <v-avatar :color="stepIndex >= 4 ? 'success' : 'surface-variant'" size="32" class="font-weight-bold mb-1">4</v-avatar>
                <div class="text-caption" :class="stepIndex >= 4 ? 'text-success font-weight-bold' : 'text-grey'">Clôturée</div>
              </v-col>
            </v-row>
          </v-card>
        </v-col>
      </v-row>

      <!-- Main Split Grid -->
      <v-row>
        
        <!-- Left Column: Client Dossier & Diagnostic -->
        <v-col cols="12" lg="6">
          
          <v-card class="pa-5 rounded-lg border mb-4" elevation="3">
            <div class="d-flex justify-space-between align-center mb-3">
              <span class="text-subtitle-2 font-weight-bold text-white text-uppercase">Dossier Client</span>
              <v-chip size="x-small" color="amber" variant="outlined">Sur Devis Direct</v-chip>
            </div>

            <v-table density="compact" class="bg-surface-variant rounded-lg mb-4">
              <tbody>
                <tr>
                  <td class="font-weight-bold text-caption text-grey" style="width: 140px;">Nom du Client :</td>
                  <td class="font-weight-bold text-white">{{ missionStore.activeMission.client_name }}</td>
                </tr>
                <tr>
                  <td class="font-weight-bold text-caption text-grey">Adresse :</td>
                  <td class="text-white">{{ missionStore.activeMission.address }}</td>
                </tr>
                <tr>
                  <td class="font-weight-bold text-caption text-grey">Spécialité :</td>
                  <td><v-chip size="x-small" color="primary" variant="flat">{{ missionStore.activeMission.category_id || 'Plomberie' }}</v-chip></td>
                </tr>
              </tbody>
            </v-table>

            <div class="text-subtitle-2 font-weight-bold text-white mb-2">Diagnostic & Description :</div>
            <v-card variant="tonal" class="pa-3 rounded-lg bg-surface border mb-4">
              <div class="text-body-2 text-grey-lighten-2">"{{ missionStore.activeMission.description }}"</div>
            </v-card>

            <!-- GPS Trip Simulation Section -->
            <div v-if="['matched', 'in_progress'].includes(missionStore.activeMission.status)" class="mt-4">
              <v-card variant="tonal" class="pa-4 rounded-lg bg-surface border mb-3">
                <div class="d-flex align-center justify-space-between mb-2">
                  <div class="d-flex align-center ga-2">
                    <v-icon :icon="isSimulatingTrip ? 'mdi-navigation' : 'mdi-map-marker-distance'" color="primary" class="animate-pulse"></v-icon>
                    <span class="text-subtitle-2 font-weight-bold text-white">Simulateur de Déplacement GPS</span>
                  </div>
                  <v-chip v-if="isSimulatingTrip" color="warning" size="x-small" variant="flat" class="font-weight-bold">
                    En Direct ({{ Math.round(simulationProgress) }}%)
                  </v-chip>
                </div>

                <div v-if="isSimulatingTrip" class="my-3">
                  <div class="d-flex justify-space-between text-caption text-grey mb-1">
                    <span>Progression du trajet</span>
                    <span class="text-primary font-weight-bold">ETA : {{ currentSimulationEta }}</span>
                  </div>
                  <v-progress-linear
                    v-model="simulationProgress"
                    color="primary"
                    height="8"
                    rounded
                    striped
                  ></v-progress-linear>
                </div>

                <div class="d-flex ga-2 mt-3">
                  <v-btn
                    v-if="!isSimulatingTrip"
                    color="primary"
                    variant="flat"
                    block
                    prepend-icon="mdi-scooter"
                    class="text-none font-weight-bold"
                    @click="startTripSimulation"
                  >
                    🛵 Simuler le Trajet vers le Client
                  </v-btn>
                  <v-btn
                    v-else
                    color="error"
                    variant="flat"
                    block
                    prepend-icon="mdi-pause-circle"
                    class="text-none font-weight-bold"
                    @click="stopTripSimulation"
                  >
                    ⏸️ Stopper la Simulation
                  </v-btn>
                </div>
              </v-card>
            </div>

            <!-- Single Location Ping (Fallback) -->
            <v-btn
              v-if="!isSimulatingTrip"
              block
              color="grey"
              variant="outlined"
              size="small"
              prepend-icon="mdi-crosshairs-gps"
              :loading="sendingLocation"
              class="text-none"
              @click="sendMockLocation"
            >
              Émettre un Ping GPS Unique
            </v-btn>
          </v-card>

          <!-- Pricing & Direct Settlement Note -->
          <v-card v-if="missionStore.activeMission.status !== 'completed'" color="warning" variant="tonal" class="pa-3 rounded-lg border mb-4">
            <div class="text-caption font-weight-bold">💡 Consigne de Règlement Direct :</div>
            <div class="text-caption">L'application ne fixe pas de tarif figé. Établissez le devis sur place et percevez le règlement directement auprès du client (Espèces ou Mobile Money direct).</div>
          </v-card>

          <!-- Rate Client Button (when completed) -->
          <v-card v-if="missionStore.activeMission.status === 'completed'" class="pa-5 rounded-lg border text-center bg-surface-variant" elevation="2">
            <div class="text-subtitle-2 font-weight-bold text-white mb-3">Évaluer le Client</div>
            <div class="text-caption text-grey mb-4">Votre avis nous aide à maintenir la qualité du réseau TechConnect.</div>
            <v-btn
              color="success"
              variant="flat"
              block
              class="text-none font-weight-bold"
              @click="showRatingModal = true"
              prepend-icon="mdi-star"
            >
              Laisser un avis
            </v-btn>
          </v-card>

        </v-col>

        <!-- Right Column: Real-Time Chat -->
        <v-col cols="12" lg="6">
          
          <v-card class="pa-4 rounded-lg border d-flex flex-column" style="height: 480px;" elevation="3">
            <div class="d-flex align-center justify-space-between mb-3 border-b pb-2">
              <div class="d-flex align-center ga-2">
                <v-icon icon="mdi-message-text-outline" color="primary"></v-icon>
                <span class="text-subtitle-2 font-weight-bold text-white">Messagerie Directe Client</span>
              </div>
              <v-chip color="success" size="x-small" variant="dot">Connecté WebSocket</v-chip>
            </div>

            <div class="flex-grow-1 overflow-y-auto pa-3 rounded-lg bg-surface-variant mb-3">
              <div v-if="chatStore.messages.length === 0" class="text-center text-grey text-caption py-12">
                Canal d'échange ouvert. Écrivez un message au client ci-dessous.
              </div>
              <div
                v-for="msg in chatStore.messages"
                :key="msg.id"
                class="mb-3 d-flex"
                :class="msg.sender_id === (authStore.user?.id || 'user_tech_demo') ? 'justify-end' : 'justify-start'"
              >
                <div
                  class="pa-3 rounded-lg"
                  style="max-width: 80%;"
                  :class="msg.sender_id === (authStore.user?.id || 'user_tech_demo') ? 'bg-primary text-slate-950 font-weight-medium' : 'bg-surface border text-white'"
                >
                  <div class="text-caption font-weight-bold opacity-75">{{ msg.sender_name }}</div>
                  <div class="text-body-2">{{ msg.content }}</div>
                </div>
              </div>
            </div>

            <v-form @submit.prevent="handleSend" class="d-flex ga-2">
              <v-text-field
                v-model="inputMsg"
                placeholder="Transmettre un message au client..."
                hide-details
                density="compact"
                variant="outlined"
                color="primary"
                class="rounded-lg"
              ></v-text-field>
              <v-btn type="submit" color="primary" icon="mdi-send" variant="flat" :loading="sendingMsg"></v-btn>
            </v-form>
          </v-card>

        </v-col>

      </v-row>

    </div>

    <!-- Notification Modal Dialog -->
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

    <!-- Rating Modal -->
    <v-dialog v-model="showRatingModal" max-width="500">
      <v-card class="pa-6 rounded-xl border" color="surface">
        <div class="text-h6 font-weight-bold text-white mb-2">Évaluer l'intervention</div>
        <div class="text-body-2 text-grey mb-4">Comment s'est passée votre interaction avec le client ?</div>
        
        <div class="text-center mb-6">
          <v-rating
            v-model="rating"
            color="amber"
            background-color="grey"
            size="x-large"
            hover
          ></v-rating>
        </div>

        <v-textarea
          v-model="ratingComment"
          label="Commentaire (optionnel)"
          variant="outlined"
          density="comfortable"
          class="mb-4"
          hide-details
        ></v-textarea>

        <div class="d-flex justify-end ga-3">
          <v-btn color="grey" variant="text" class="text-none" @click="showRatingModal = false">Annuler</v-btn>
          <v-btn color="primary" variant="flat" class="text-none font-weight-bold" :loading="submittingRating" @click="submitReview">
            Soumettre l'avis
          </v-btn>
        </div>
      </v-card>
    </v-dialog>

    <!-- Cancel Modal -->
    <v-dialog v-model="showCancelModal" max-width="500">
      <v-card class="pa-6 rounded-xl border" color="surface">
        <div class="text-h6 font-weight-bold text-white mb-2">Annuler l'intervention</div>
        <div class="text-body-2 text-grey mb-4">Veuillez préciser le motif de l'annulation.</div>

        <v-select
          v-model="cancelReason"
          :items="cancelReasons"
          label="Motif d'annulation"
          variant="outlined"
          density="comfortable"
          class="mb-4"
        ></v-select>

        <v-textarea
          v-if="cancelReason === 'Autre'"
          v-model="cancelReasonOther"
          label="Précisez le motif"
          variant="outlined"
          density="comfortable"
          class="mb-4"
        ></v-textarea>

        <div class="d-flex justify-end ga-3">
          <v-btn color="grey" variant="text" class="text-none" @click="showCancelModal = false">Retour</v-btn>
          <v-btn color="error" variant="flat" class="text-none font-weight-bold" :loading="missionStore.statusLoading" @click="cancelMission">
            Confirmer l'annulation
          </v-btn>
        </div>
      </v-card>
    </v-dialog>

  </v-container>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useMissionStore } from '@/stores/mission'
import { useChatStore } from '@/stores/chat'

import { API_BASE } from '@/config'

const authStore = useAuthStore()
const missionStore = useMissionStore()
const chatStore = useChatStore()

const inputMsg = ref('')
const sendingMsg = ref(false)
const sendingLocation = ref(false)

const modal = ref({
  show: false,
  title: '',
  message: '',
  icon: 'mdi-check-circle',
  color: 'success'
})

const showRatingModal = ref(false)
const rating = ref(5)
const ratingComment = ref('')
const submittingRating = ref(false)

const showCancelModal = ref(false)
const cancelReason = ref('')
const cancelReasonOther = ref('')
const cancelReasons = [
  'Client absent',
  'Problème technique complexe / Matériel manquant',
  'Le client a refusé le devis',
  'Autre'
]

function showNotification(title, message, icon = 'mdi-check-circle', color = 'success') {
  modal.value = { show: true, title, message, icon, color }
}

const stepIndex = computed(() => {
  if (!missionStore.activeMission) return 0
  const st = missionStore.activeMission.status
  if (st === 'matched')     return 1
  if (st === 'in_progress') return 2
  if (st === 'on_site')     return 3
  if (st === 'completed')   return 4
  return 1
})

onMounted(async () => {
  const authStore = useAuthStore()
  if (!missionStore.activeMission) {
    await missionStore.fetchInterventions(authStore.user?.id)
  }
  if (missionStore.activeMission) {
    chatStore.connectBookingChat(missionStore.activeMission.id)
  }
})

onUnmounted(() => {
  stopTripSimulation()
})

function handleSend() {
  if (!inputMsg.value.trim() || !missionStore.activeMission) return
  sendingMsg.value = true
  chatStore.sendMessage(missionStore.activeMission.id, authStore.user?.id || 'user_tech_demo', inputMsg.value.trim())
  inputMsg.value = ''
  setTimeout(() => {
    sendingMsg.value = false
  }, 300)
}

const isSimulatingTrip = ref(false)
const simulationProgress = ref(0)
const currentSimulationEta = ref('15 min')
let simulationInterval = null

async function startTripSimulation() {
  if (!missionStore.activeMission) return
  if (missionStore.activeMission.status === 'matched') {
    await missionStore.updateMissionStatus('in_progress')
  }

  isSimulatingTrip.value = true
  simulationProgress.value = 0
  currentSimulationEta.value = '15 min'

  const destLat = missionStore.activeMission.latitude || 14.6937
  const destLng = missionStore.activeMission.longitude || -17.4441

  // Start position ~2 km away (south-west offset in Dakar)
  const startLat = destLat - 0.018
  const startLng = destLng - 0.014

  let routePoints = []

  // Try fetching actual road coordinates from OSRM public router
  try {
    const res = await fetch(`https://router.project-osrm.org/route/v1/driving/${startLng},${startLat};${destLng},${destLat}?overview=full&geometries=geojson`)
    if (res.ok) {
      const data = await res.json()
      if (data.routes && data.routes[0]?.geometry?.coordinates) {
        // OSRM returns [lng, lat]
        routePoints = data.routes[0].geometry.coordinates.map(c => ({
          lat: c[1],
          lng: c[0]
        }))
      }
    }
  } catch (e) {
    console.warn('OSRM routing fetch warning:', e)
  }

  // Fallback to dense road steps if offline
  if (routePoints.length === 0) {
    const totalSteps = 25
    for (let i = 0; i <= totalSteps; i++) {
      const t = i / totalSteps
      routePoints.push({
        lat: startLat + (destLat - startLat) * t,
        lng: startLng + (destLng - startLng) * t
      })
    }
  }

  const totalSteps = routePoints.length
  let stepIndex = 0

  if (simulationInterval) clearInterval(simulationInterval)

  showNotification(
    'Simulation sur route réelle démarrée !',
    'Le technicien se déplace pas à pas le long du réseau routier réel vers le client.',
    'mdi-navigation',
    'primary'
  )

  simulationInterval = setInterval(async () => {
    stepIndex++
    if (stepIndex >= totalSteps) {
      stepIndex = totalSteps - 1
    }

    simulationProgress.value = ((stepIndex + 1) / totalSteps) * 100
    const currentPt = routePoints[stepIndex]

    const remainingSteps = totalSteps - stepIndex - 1
    const remainingMinutes = Math.max(0, Math.round((remainingSteps / totalSteps) * 15))
    const etaStr = remainingMinutes === 0 ? 'Sur place' : `${remainingMinutes} min`
    currentSimulationEta.value = etaStr

    try {
      await fetch(`${API_BASE}/technicians/me/location?booking_id=${missionStore.activeMission.id}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authStore.token}`
        },
        body: JSON.stringify({
          latitude: currentPt.lat,
          longitude: currentPt.lng,
          eta: etaStr
        })
      })
    } catch (e) {
      console.warn('Simulation step error:', e)
    }

    if (stepIndex >= totalSteps - 1) {
      stopTripSimulation()
      showNotification(
        'Arrivée à destination !',
        'Le déplacement sur route est terminé. Le statut passe automatiquement à "Sur Place".',
        'mdi-map-marker-check',
        'success'
      )
      await missionStore.updateMissionStatus('on_site')
    }
  }, 1200)
}

function stopTripSimulation() {
  if (simulationInterval) {
    clearInterval(simulationInterval)
    simulationInterval = null
  }
  isSimulatingTrip.value = false
}

async function sendMockLocation() {
  if (missionStore.activeMission) {
    sendingLocation.value = true
    await chatStore.sendLocationUpdate(missionStore.activeMission.id, 14.6950, -17.4450)
    sendingLocation.value = false
    showNotification(
      'Position GPS Transmise !',
      'Votre position actuelle a été mise à jour et partagée en temps réel sur la carte du client.',
      'mdi-crosshairs-gps',
      'primary'
    )
  }
}

async function submitReview() {
  if (!missionStore.activeMission) return
  submittingRating.value = true
  try {
    await fetch(`${API_BASE}/bookings/${missionStore.activeMission.id}/review`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        rating: rating.value,
        comment: ratingComment.value
      })
    })
    showRatingModal.value = false
    showNotification('Merci !', 'Votre avis a été enregistré avec succès.')
  } catch (err) {
    console.error('Error submitting review', err)
    showNotification('Erreur', "Impossible d'envoyer l'avis.", 'mdi-alert', 'error')
  } finally {
    submittingRating.value = false
  }
}

async function cancelMission() {
  if (!cancelReason.value) {
    showNotification('Erreur', "Veuillez sélectionner un motif d'annulation.", 'mdi-alert', 'error')
    return
  }
  
  const finalReason = cancelReason.value === 'Autre' ? cancelReasonOther.value : cancelReason.value
  await missionStore.updateMissionStatus('cancelled', finalReason)
  showCancelModal.value = false
  showNotification('Intervention Annulée', "L'intervention a été annulée et le client a été notifié.", 'mdi-close-circle', 'error')
}
</script>
