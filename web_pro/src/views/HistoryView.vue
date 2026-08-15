<template>
  <v-container fluid class="pa-6">
    
    <!-- Top Title -->
    <div class="d-flex flex-column flex-sm-row align-start align-sm-center justify-space-between ga-3 mb-6">
      <div>
        <div class="text-caption text-grey font-weight-bold text-uppercase">TechConnect Pro Operations • Archives</div>
        <div class="text-h5 font-weight-black text-white">Historique des Interventions & Registre</div>
      </div>

      <div class="d-flex align-center ga-3">
        <v-btn
          color="primary"
          variant="outlined"
          size="small"
          prepend-icon="mdi-download"
          class="text-none font-weight-bold"
        >
          Exporter (CSV/Excel)
        </v-btn>
      </div>
    </div>

    <!-- Archives Data Table Card -->
    <v-card class="rounded-lg border" elevation="3">
      
      <!-- Filter Bar -->
      <div class="pa-4 border-b d-flex flex-column flex-sm-row align-center justify-space-between ga-3">
        <v-text-field
          v-model="searchQuery"
          placeholder="Rechercher dans l'historique..."
          prepend-inner-icon="mdi-magnify"
          density="compact"
          variant="outlined"
          hide-details
          color="primary"
          class="max-w-300 w-100 rounded-lg"
        ></v-text-field>

        <div class="d-flex align-center ga-3">
          <v-chip color="primary" variant="tonal" size="small" class="font-weight-bold">
            Total : {{ filteredInterventions.length }} Dossiers
          </v-chip>
        </div>
      </div>

      <!-- Interventions Table -->
      <v-table density="comfortable" class="bg-surface">
        <thead>
          <tr>
            <th class="text-left font-weight-bold text-caption text-grey uppercase">N° Dossier</th>
            <th class="text-left font-weight-bold text-caption text-grey uppercase">Client / Emplacement</th>
            <th class="text-left font-weight-bold text-caption text-grey uppercase">Spécialité</th>
            <th class="text-left font-weight-bold text-caption text-grey uppercase">Statut</th>
            <th class="text-left font-weight-bold text-caption text-grey uppercase">Date & Heure</th>
            <th class="text-left font-weight-bold text-caption text-grey uppercase">Règlement Direct</th>
            <th class="text-right font-weight-bold text-caption text-grey uppercase">Avis Client</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in filteredInterventions" :key="item.id" class="hover:bg-slate-900">
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
              <v-chip :color="item.color || 'success'" size="x-small" variant="flat" class="font-weight-bold">
                {{ item.status_label || 'Terminée' }}
              </v-chip>
            </td>
            <td class="text-caption text-grey">
              {{ item.date }}
            </td>
            <td class="text-caption text-grey">
              {{ item.payment_type }}
            </td>
            <td class="text-right">
              <div v-if="item.rating" class="d-flex align-center justify-end ga-1 text-amber font-weight-bold text-caption">
                <v-icon icon="mdi-star" color="amber" size="x-small"></v-icon>
                {{ item.rating }}.0
              </div>
              <span v-else class="text-caption text-grey">—</span>
            </td>
          </tr>
        </tbody>
      </v-table>

    </v-card>
  </v-container>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useMissionStore } from '@/stores/mission'

const missionStore = useMissionStore()
const searchQuery = ref('')

const filteredInterventions = computed(() => {
  if (!searchQuery.value.trim()) return missionStore.interventions
  const q = searchQuery.value.toLowerCase()
  return missionStore.interventions.filter(i => 
    i.id.toLowerCase().includes(q) || 
    i.client_name.toLowerCase().includes(q) ||
    i.category.toLowerCase().includes(q)
  )
})
</script>

<style>
.max-w-300 {
  max-width: 300px;
}
</style>
