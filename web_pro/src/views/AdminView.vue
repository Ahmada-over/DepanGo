<template>
  <v-container fluid class="pa-6">
    <div class="d-flex align-center justify-space-between mb-6">
      <div class="text-h5 font-weight-black text-white">Administration TechConnect</div>
    </div>

    <v-card class="rounded-lg border mb-6" elevation="3" bg-color="surface">
      <v-tabs v-model="tab" color="primary" class="border-bottom">
        <v-tab value="overview"><v-icon start>mdi-view-dashboard</v-icon>Vue d'ensemble</v-tab>
        <v-tab value="technicians"><v-icon start>mdi-account-hard-hat</v-icon>Techniciens</v-tab>
        <v-tab value="bookings"><v-icon start>mdi-clipboard-text</v-icon>Réservations</v-tab>
        <v-tab value="reports"><v-icon start>mdi-alert-circle</v-icon>Signalements / Annulations</v-tab>
      </v-tabs>

      <v-card-text class="pa-6">
        <v-window v-model="tab">
          
          <!-- TAB: VUE D'ENSEMBLE -->
          <v-window-item value="overview">
            <v-row v-if="adminStore.statsOverview">
              <v-col cols="12" sm="6" md="3">
                <v-card class="pa-4 bg-primary text-white rounded-lg">
                  <div class="text-subtitle-2 mb-1">Techniciens en ligne</div>
                  <div class="text-h4 font-weight-black">{{ adminStore.statsOverview.online_technicians }}</div>
                </v-card>
              </v-col>
              <v-col cols="12" sm="6" md="3">
                <v-card class="pa-4 bg-info text-white rounded-lg">
                  <div class="text-subtitle-2 mb-1">Missions en cours</div>
                  <div class="text-h4 font-weight-black">{{ adminStore.statsOverview.active_missions }}</div>
                </v-card>
              </v-col>
              <v-col cols="12" sm="6" md="3">
                <v-card class="pa-4 bg-warning text-white rounded-lg">
                  <div class="text-subtitle-2 mb-1">En attente (Pending)</div>
                  <div class="text-h4 font-weight-black">{{ adminStore.statsOverview.pending_missions }}</div>
                </v-card>
              </v-col>
              <v-col cols="12" sm="6" md="3">
                <v-card class="pa-4 bg-error text-white rounded-lg">
                  <div class="text-subtitle-2 mb-1">Échecs (24h)</div>
                  <div class="text-h4 font-weight-black">{{ adminStore.statsOverview.failed_missions_24h }}</div>
                </v-card>
              </v-col>
            </v-row>
            <v-row v-else>
              <v-col cols="12" class="text-center">
                <v-progress-circular indeterminate color="primary"></v-progress-circular>
              </v-col>
            </v-row>
          </v-window-item>

          <!-- TAB: TECHNICIENS -->
          <v-window-item value="technicians">
            <v-table>
              <thead>
                <tr>
                  <th class="text-left font-weight-bold">Nom / User ID</th>
                  <th class="text-left font-weight-bold">Statut Vérification</th>
                  <th class="text-left font-weight-bold">Note</th>
                  <th class="text-left font-weight-bold">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="tech in adminStore.technicians" :key="tech.id">
                  <td>
                    <div class="font-weight-bold">{{ tech.user_name || 'N/A' }}</div>
                    <div class="text-caption text-grey">{{ tech.user_id }}</div>
                  </td>
                  <td>
                    <v-chip :color="tech.verified ? 'success' : 'warning'" size="small">
                      {{ tech.verified ? 'Vérifié' : 'En attente' }}
                    </v-chip>
                  </td>
                  <td>
                    <v-icon color="amber" size="small" class="mr-1">mdi-star</v-icon>
                    {{ tech.average_rating }}
                  </td>
                  <td>
                    <v-btn
                      v-if="!tech.verified"
                      color="primary"
                      size="small"
                      variant="flat"
                      @click="adminStore.verifyTechnician(tech.user_id)"
                    >
                      Vérifier
                    </v-btn>
                  </td>
                </tr>
                <tr v-if="adminStore.technicians.length === 0">
                  <td colspan="4" class="text-center text-grey py-4">Aucun technicien trouvé</td>
                </tr>
              </tbody>
            </v-table>
          </v-window-item>

          <!-- TAB: RÉSERVATIONS -->
          <v-window-item value="bookings">
            <v-table>
              <thead>
                <tr>
                  <th class="text-left font-weight-bold">ID / Date</th>
                  <th class="text-left font-weight-bold">Statut</th>
                  <th class="text-left font-weight-bold">Catégorie</th>
                  <th class="text-left font-weight-bold">Technicien</th>
                  <th class="text-left font-weight-bold">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="bk in adminStore.bookings" :key="bk.id">
                  <td>
                    <div class="font-weight-bold text-truncate" style="max-width: 150px;">{{ bk.id }}</div>
                    <div class="text-caption text-grey">{{ new Date(bk.created_at).toLocaleString() }}</div>
                  </td>
                  <td>
                    <v-chip size="small" :color="getStatusColor(bk.status)">
                      {{ bk.status }}
                    </v-chip>
                  </td>
                  <td>{{ bk.category_id }}</td>
                  <td>{{ bk.technician_id || 'Non assigné' }}</td>
                  <td>
                    <v-btn
                      v-if="bk.status === 'pending' || bk.status === 'no_technician_found'"
                      color="primary"
                      size="small"
                      variant="outlined"
                      @click="openAssignDialog(bk)"
                    >
                      Assigner
                    </v-btn>
                  </td>
                </tr>
                <tr v-if="adminStore.bookings.length === 0">
                  <td colspan="5" class="text-center text-grey py-4">Aucune réservation trouvée</td>
                </tr>
              </tbody>
            </v-table>
          </v-window-item>

          <!-- TAB: SIGNALEMENTS -->
          <v-window-item value="reports">
            <v-table>
              <thead>
                <tr>
                  <th class="text-left font-weight-bold">ID / Date</th>
                  <th class="text-left font-weight-bold">Technicien Impliqué</th>
                  <th class="text-left font-weight-bold">Motif d'annulation</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="bk in reportedBookings" :key="bk.id">
                  <td>
                    <div class="font-weight-bold text-truncate" style="max-width: 150px;">{{ bk.id }}</div>
                    <div class="text-caption text-grey">{{ new Date(bk.created_at).toLocaleString() }}</div>
                  </td>
                  <td>{{ bk.technician_id || 'Non assigné' }}</td>
                  <td>
                    <div class="text-error font-weight-medium">{{ bk.cancellation_reason || 'Non spécifié' }}</div>
                  </td>
                </tr>
                <tr v-if="reportedBookings.length === 0">
                  <td colspan="3" class="text-center text-grey py-4">Aucun signalement ou annulation</td>
                </tr>
              </tbody>
            </v-table>
          </v-window-item>

        </v-window>
      </v-card-text>
    </v-card>

    <!-- Dialog Assignation Manuelle -->
    <v-dialog v-model="assignDialog" max-width="500">
      <v-card rounded="lg">
        <v-card-title class="font-weight-bold">Assignation Manuelle</v-card-title>
        <v-card-text>
          <div class="mb-4 text-body-2 text-grey">
            Sélectionnez un technicien à assigner de force pour la réservation <b>{{ selectedBooking?.id }}</b>.
          </div>
          <v-select
            v-model="selectedTechId"
            :items="verifiedTechs"
            item-title="label"
            item-value="user_id"
            label="Technicien"
            variant="outlined"
            density="comfortable"
          ></v-select>
        </v-card-text>
        <v-card-actions class="pa-4 pt-0">
          <v-spacer></v-spacer>
          <v-btn variant="text" @click="assignDialog = false">Annuler</v-btn>
          <v-btn 
            color="primary" 
            variant="flat" 
            :loading="assignLoading"
            :disabled="!selectedTechId"
            @click="confirmAssign"
          >Confirmer</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

  </v-container>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useAdminStore } from '@/stores/admin'

const adminStore = useAdminStore()
const tab = ref('overview')

// Assign Dialog
const assignDialog = ref(false)
const selectedBooking = ref(null)
const selectedTechId = ref(null)
const assignLoading = ref(false)

const verifiedTechs = computed(() => {
  return adminStore.technicians
    .filter(t => t.verified)
    .map(t => ({
      label: `${t.user_name || t.user_id} (${t.availability_status})`,
      user_id: t.user_id
    }))
})

const reportedBookings = computed(() => {
  return adminStore.bookings.filter(b => b.status === 'cancelled' || b.cancellation_reason)
})

onMounted(async () => {
  await adminStore.fetchOverview()
  await adminStore.fetchTechnicians()
  await adminStore.fetchBookings()
})

function getStatusColor(status) {
  const map = {
    'pending': 'warning',
    'matched': 'info',
    'in_progress': 'primary',
    'completed': 'success',
    'cancelled': 'error',
    'no_technician_found': 'error'
  }
  return map[status] || 'grey'
}

function openAssignDialog(booking) {
  selectedBooking.value = booking
  selectedTechId.value = null
  assignDialog.value = true
}

async function confirmAssign() {
  if (!selectedBooking.value || !selectedTechId.value) return
  assignLoading.value = true
  const success = await adminStore.manualAssign(selectedBooking.value.id, selectedTechId.value)
  assignLoading.value = false
  if (success) {
    assignDialog.value = false
  }
}
</script>
