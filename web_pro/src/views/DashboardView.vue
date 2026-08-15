<template>
  <v-container fluid class="pa-6">
    
    <!-- Top Title & Quick Actions Toolbar -->
    <div class="d-flex flex-column flex-sm-row align-start align-sm-center justify-space-between ga-3 mb-6">
      <div>
        <div class="text-caption text-grey font-weight-bold text-uppercase">TechConnect Operations • Vue Synthétique</div>
        <div class="text-h5 font-weight-black text-white">Tableau de Bord des Interventions</div>
      </div>

      <div class="d-flex align-center ga-3">
        <v-btn
          color="primary"
          variant="tonal"
          size="small"
          prepend-icon="mdi-refresh"
          :loading="missionStore.refreshLoading"
          class="text-none font-weight-bold"
          @click="refreshData"
        >
          Actualiser
        </v-btn>

        <v-btn
          color="primary"
          variant="flat"
          size="small"
          prepend-icon="mdi-lightning-bolt"
          :loading="simulating"
          class="text-none font-weight-bold"
          @click="triggerSimulatedOffer"
        >
          ⚡ Simuler Mission Client (90s)
        </v-btn>
      </div>
    </div>

    <!-- Active Offer / Active Mission Banner -->
    <v-row v-if="missionStore.activeMission" class="mb-4">
      <v-col cols="12">
        <v-card color="surface" class="pa-4 border border-primary rounded-lg" elevation="4">
          <div class="d-flex justify-space-between align-center">
            <div class="d-flex align-center ga-3">
              <v-chip color="primary" size="small" variant="flat" class="font-weight-bold text-uppercase">
                Mission Active #{{ missionStore.activeMission.id }}
              </v-chip>
              <div class="text-subtitle-1 font-weight-bold text-white">{{ missionStore.activeMission.client_name }}</div>
            </div>
            <v-btn to="/mission" color="primary" variant="text" size="small" class="text-none font-weight-bold">
              Consulter Dossier & Chat →
            </v-btn>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <!-- Real KPI Metric Cards Grid -->
    <v-row class="mb-6">
      
      <v-col cols="12" sm="6" md="3">
        <v-card class="pa-4 rounded-lg border" elevation="2">
          <div class="d-flex justify-space-between align-center mb-2">
            <span class="text-caption text-grey font-weight-bold text-uppercase">Dossiers Registre</span>
            <v-avatar color="primary" variant="tonal" size="32" rounded="lg">
              <v-icon icon="mdi-file-check-outline" size="18"></v-icon>
            </v-avatar>
          </div>
          <div class="text-h4 font-weight-black text-white">{{ missionStore.interventions.length }}</div>
          <div class="text-caption text-success font-weight-bold mt-1">
            <v-icon icon="mdi-check-all" size="x-small"></v-icon> Synchro Base de données (Auto)
          </div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="3">
        <v-card class="pa-4 rounded-lg border" elevation="2">
          <div class="d-flex justify-space-between align-center mb-2">
            <span class="text-caption text-grey font-weight-bold text-uppercase">Taux Réponse 90s</span>
            <v-avatar color="info" variant="tonal" size="32" rounded="lg">
              <v-icon icon="mdi-timer-sand" size="18"></v-icon>
            </v-avatar>
          </div>
          <div class="text-h4 font-weight-black text-white">100%</div>
          <div class="text-caption text-grey mt-1">Fenêtre moyenne : 12 secondes</div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="3">
        <v-card class="pa-4 rounded-lg border" elevation="2">
          <div class="d-flex justify-space-between align-center mb-2">
            <span class="text-caption text-grey font-weight-bold text-uppercase">Note Profil API</span>
            <v-avatar color="warning" variant="tonal" size="32" rounded="lg">
              <v-icon icon="mdi-star" size="18"></v-icon>
            </v-avatar>
          </div>
          <div class="d-flex align-center ga-2">
            <span class="text-h4 font-weight-black text-amber">{{ missionStore.techRating }}</span>
            <v-rating :model-value="missionStore.techRating" color="amber" density="compact" half-increments readonly size="x-small"></v-rating>
          </div>
          <div class="text-caption text-grey mt-1">Évaluation vérifiée</div>
        </v-card>
      </v-col>

      <v-col cols="12" sm="6" md="3">
        <v-card class="pa-4 rounded-lg border" elevation="2">
          <div class="d-flex justify-space-between align-center mb-2">
            <span class="text-caption text-grey font-weight-bold text-uppercase">Règlement Prestations</span>
            <v-avatar color="success" variant="tonal" size="32" rounded="lg">
              <v-icon icon="mdi-cash-multiple" size="18"></v-icon>
            </v-avatar>
          </div>
          <div class="text-subtitle-1 font-weight-bold text-success">Direct Technicien</div>
          <div class="text-caption text-grey mt-1">Sur devis • Espèces / Mobile Money</div>
        </v-card>
      </v-col>

    </v-row>

    <!-- Main Content Split Row -->
    <v-row>
      
      <!-- Left Table Column: Interventions Data Table -->
      <v-col cols="12" lg="8">
        <v-card class="rounded-lg border" elevation="3">
          
          <div class="pa-4 border-b d-flex justify-space-between align-center">
            <div>
              <div class="text-subtitle-1 font-weight-bold text-white">Registre des Interventions</div>
              <div class="text-caption text-grey">Missions réelles de la base de données</div>
            </div>
            
            <v-chip color="primary" variant="outlined" size="small" class="font-weight-bold">
              {{ missionStore.interventions.length }} Enregistrements
            </v-chip>
          </div>

          <v-table density="comfortable" class="bg-surface">
            <thead>
              <tr>
                <th class="text-left font-weight-bold text-caption text-grey uppercase">N° Dossier</th>
                <th class="text-left font-weight-bold text-caption text-grey uppercase">Client / Emplacement</th>
                <th class="text-left font-weight-bold text-caption text-grey uppercase">Spécialité</th>
                <th class="text-left font-weight-bold text-caption text-grey uppercase">Statut</th>
                <th class="text-left font-weight-bold text-caption text-grey uppercase">Date & Heure</th>
                <th class="text-right font-weight-bold text-caption text-grey uppercase">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="missionStore.interventions.length === 0">
                <td colspan="6" class="text-center py-6 text-grey text-caption">
                  Aucune intervention enregistrée pour l'instant.
                </td>
              </tr>
              <tr v-for="item in missionStore.interventions" :key="item.id" class="hover:bg-slate-900">
                <td class="font-weight-bold text-caption text-primary">{{ item.id }}</td>
                <td>
                  <div class="font-weight-bold text-body-2 text-white">{{ item.client_name }}</div>
                  <div class="text-caption text-grey line-clamp-1">{{ item.address }}</div>
                </td>
                <td>
                  <v-chip size="x-small" color="primary" variant="tonal" class="font-weight-medium">
                    {{ item.category }}
                  </v-chip>
                </td>
                <td>
                  <v-chip :color="item.color || 'primary'" size="x-small" variant="flat" class="font-weight-bold">
                    {{ item.status_label }}
                  </v-chip>
                </td>
                <td class="text-caption text-grey">
                  {{ item.date }}
                </td>
                <td class="text-right">
                  <v-btn @click="viewMission(item)" icon="mdi-eye-outline" size="x-small" variant="text" color="primary"></v-btn>
                </td>
              </tr>
            </tbody>
          </v-table>

        </v-card>
      </v-col>

      <!-- Right Column: Fleet Status & Activity -->
      <v-col cols="12" lg="4">
        
        <!-- Status Availability Box -->
        <v-card class="pa-5 rounded-lg border mb-4" elevation="3">
          <div class="text-subtitle-2 font-weight-bold text-white mb-3">Statut de Disponibilité GPS</div>
          
          <div class="d-flex align-center justify-space-between pa-3 rounded-lg bg-surface-variant border mb-3">
            <div class="d-flex align-center ga-3">
              <v-avatar :color="authStore.isOnline ? 'success' : 'grey'" size="12"></v-avatar>
              <span class="text-body-2 font-weight-bold text-white">
                {{ authStore.isOnline ? 'Prêt à recevoir des dispatches' : 'Session Hors Ligne' }}
              </span>
            </div>
            <v-switch
              v-model="authStore.isOnline"
              color="primary"
              density="compact"
              hide-details
              @change="authStore.toggleAvailability"
            ></v-switch>
          </div>

          <div class="text-caption text-grey">
            <v-icon icon="mdi-crosshairs-gps" color="primary" size="x-small" class="me-1"></v-icon>
            Rayon de couverture géospatiale PostGIS : <strong>15 km</strong>.
          </div>
        </v-card>

        <!-- System Logs -->
        <v-card class="pa-5 rounded-lg border" elevation="3">
          <div class="text-subtitle-2 font-weight-bold text-white mb-3">Journal d'Activité Pro</div>
          
          <v-timeline density="compact" side="end">
            <v-timeline-item dot-color="success" size="x-small">
              <div class="text-caption font-weight-bold text-white">Session Pro Établie</div>
              <div class="text-caption text-grey">{{ authStore.user?.name || 'Technicien' }}</div>
            </v-timeline-item>
            <v-timeline-item dot-color="primary" size="x-small">
              <div class="text-caption font-weight-bold text-white">Canal WebSocket Actif</div>
              <div class="text-caption text-grey">Attente d'offres match 90s</div>
            </v-timeline-item>
          </v-timeline>
        </v-card>

      </v-col>

    </v-row>
  </v-container>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useMissionStore } from '@/stores/mission'

const router = useRouter()
const authStore = useAuthStore()
const missionStore = useMissionStore()
const simulating = ref(false)

function viewMission(item) {
  // Use a minimal object compatible with activeMission structure
  missionStore.activeMission = {
    id: item.id,
    client_name: item.client_name,
    description: item.description,
    address: item.address,
    status: item.status,
    category_id: item.category_id || (item.category === 'Plomberie' ? 'cat_plumbing' : (item.category === 'Électricité' ? 'cat_electrical' : 'cat_hvac')),
    color: item.color,
    status_label: item.status_label
  }
  router.push('/mission')
}

onMounted(async () => {
  const userId = authStore.user?.id || 'user_tech_demo'
  await missionStore.fetchInterventions(userId)
  await missionStore.fetchTechnicianProfile(userId)
})

onUnmounted(() => {
  // polling removed
})

async function refreshData() {
  const userId = authStore.user?.id || 'user_tech_demo'
  await missionStore.fetchInterventions(userId)
  await missionStore.fetchTechnicianProfile(userId)
}

function triggerSimulatedOffer() {
  simulating.value = true
  missionStore.receiveOffer({
    booking_id: 'INT-' + Math.floor(Math.random() * 9000 + 1000),
    client_name: 'Fatou Bintou Sow',
    category_id: 'cat_plumbing',
    description: 'Fuite d\'eau sous l\'évier de la cuisine et pression très faible.',
    address: 'Point E, Rue 4x3, Dakar',
    timeout_seconds: 90
  })
  setTimeout(() => {
    simulating.value = false
  }, 600)
}
</script>
