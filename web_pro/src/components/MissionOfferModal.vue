<template>
  <v-dialog v-model="showModal" persistent max-width="500">
    <v-card class="border border-emerald-500 rounded-xl pa-4" color="surface">
      <div class="text-center py-2">
        <v-chip color="success" class="font-weight-bold text-uppercase px-4 py-2" size="small" variant="flat">
          <v-icon start icon="mdi-bell-ring" class="animate-pulse"></v-icon>
          Nouvelle Mission à Proximité !
        </v-chip>
      </div>

      <!-- Circular Countdown Timer -->
      <div class="d-flex justify-center align-center my-4">
        <v-progress-circular
          :model-value="(missionStore.countdown / 90) * 100"
          :size="110"
          :width="10"
          color="success"
        >
          <div class="text-center">
            <div class="text-h4 font-weight-black text-white">{{ missionStore.countdown }}s</div>
            <div class="text-caption text-grey-lighten-1 text-uppercase">Restant</div>
          </div>
        </v-progress-circular>
      </div>

      <v-card text class="bg-surface-variant rounded-lg pa-4 my-2">
        <div class="d-flex justify-space-between align-center mb-2">
          <div>
            <div class="text-h6 font-weight-bold text-white">{{ missionStore.activeOffer?.client_name }}</div>
            <div class="text-caption text-success font-weight-medium">Plomberie & Dépannage</div>
          </div>
          <v-chip size="x-small" color="amber" variant="outlined">Sur Devis</v-chip>
        </div>
        <div class="text-body-2 text-grey-lighten-2 mb-3">
          "{{ missionStore.activeOffer?.description }}"
        </div>
        <div class="d-flex align-center text-caption text-grey">
          <v-icon icon="mdi-map-marker" color="success" size="small" class="me-1"></v-icon>
          {{ missionStore.activeOffer?.address }}
        </div>
      </v-card>

      <v-card-actions class="pt-3">
        <v-row dense>
          <v-col cols="6">
            <v-btn
              block
              variant="outlined"
              color="grey"
              size="large"
              class="text-none font-weight-bold rounded-lg"
              @click="missionStore.rejectOffer"
            >
              Refuser
            </v-btn>
          </v-col>
          <v-col cols="6">
            <v-btn
              block
              color="success"
              variant="flat"
              size="large"
              :loading="missionStore.acceptLoading"
              class="text-none font-weight-bold rounded-lg"
              @click="missionStore.acceptOffer"
            >
              Accepter (90s)
            </v-btn>
          </v-col>
        </v-row>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup>
import { computed } from 'vue'
import { useMissionStore } from '@/stores/mission'

const missionStore = useMissionStore()
const showModal = computed(() => !!missionStore.activeOffer)
</script>
