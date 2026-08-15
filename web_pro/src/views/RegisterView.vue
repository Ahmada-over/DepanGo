<template>
  <v-container class="fill-height d-flex align-center justify-center py-8">
    <v-card class="pa-8 max-w-650 w-100 rounded-xl border border-primary" elevation="6">
      
      <!-- SaaS Branding Header -->
      <div class="text-center mb-6">
        <v-avatar color="primary" size="56" class="font-weight-black text-h4 text-slate-950 mb-2">
          TC
        </v-avatar>
        <div class="text-h5 font-weight-black text-white">Rejoindre la Plateforme TechConnect Pro</div>
        <div class="text-caption text-grey">Création de votre compte professionnel et activation de votre espace pro</div>
      </div>

      <!-- Multi-step Progress Window Header -->
      <v-row class="mb-6">
        <v-col cols="3" class="text-center">
          <v-avatar :color="step >= 1 ? 'primary' : 'surface-variant'" size="28" class="font-weight-bold mb-1">1</v-avatar>
          <div class="text-caption font-weight-bold" :class="step >= 1 ? 'text-primary' : 'text-grey'">Identité</div>
        </v-col>
        <v-col cols="3" class="text-center">
          <v-avatar :color="step >= 2 ? 'primary' : 'surface-variant'" size="28" class="font-weight-bold mb-1">2</v-avatar>
          <div class="text-caption font-weight-bold" :class="step >= 2 ? 'text-primary' : 'text-grey'">Métiers</div>
        </v-col>
        <v-col cols="3" class="text-center">
          <v-avatar :color="step >= 3 ? 'primary' : 'surface-variant'" size="28" class="font-weight-bold mb-1">3</v-avatar>
          <div class="text-caption font-weight-bold" :class="step >= 3 ? 'text-primary' : 'text-grey'">Zone GPS</div>
        </v-col>
        <v-col cols="4" sm="3" class="text-center">
          <v-avatar :color="step >= 4 ? 'success' : 'surface-variant'" size="28" class="font-weight-bold mb-1">4</v-avatar>
          <div class="text-caption font-weight-bold" :class="step >= 4 ? 'text-success' : 'text-grey'">Validation</div>
        </v-col>
      </v-row>

      <v-divider class="mb-6"></v-divider>

      <v-form @submit.prevent="handleSubmit">
        
        <!-- STEP 1: Account Information -->
        <div v-if="step === 1" class="space-y-4">
          <div class="text-subtitle-1 font-weight-bold text-white mb-3">Étape 1 : Vos Informations Personnelles</div>
          
          <v-text-field
            v-model="form.name"
            label="Nom Complet / Raison Sociale"
            required
            variant="outlined"
            color="primary"
            prepend-inner-icon="mdi-account-outline"
            placeholder="Ex: Ousmane Sow"
          ></v-text-field>

          <v-text-field
            v-model="form.email"
            label="Adresse Email Pro"
            type="email"
            required
            variant="outlined"
            color="primary"
            prepend-inner-icon="mdi-email-outline"
            placeholder="ousmane@techconnect.com"
          ></v-text-field>

          <v-text-field
            v-model="form.phone"
            label="Numéro de Téléphone (WhatsApp / Appel)"
            required
            variant="outlined"
            color="primary"
            prepend-inner-icon="mdi-phone-outline"
            placeholder="+221 77 000 00 00"
          ></v-text-field>

          <v-text-field
            v-model="form.password"
            label="Mot de passe sécurisé"
            type="password"
            required
            variant="outlined"
            color="primary"
            prepend-inner-icon="mdi-lock-outline"
          ></v-text-field>
        </div>

        <!-- STEP 2: Specialties / Service Categories -->
        <div v-if="step === 2">
          <div class="text-subtitle-1 font-weight-bold text-white mb-2">Étape 2 : Vos Métiers & Domaines d'Intervention</div>
          <div class="text-caption text-grey mb-4">Sélectionnez les prestations que vous réalisez auprès des clients :</div>

          <v-row dense>
            <v-col v-for="cat in availableCategories" :key="cat.id" cols="12" sm="6">
              <v-card
                :color="form.category_ids.includes(cat.id) ? 'primary' : 'surface-variant'"
                :variant="form.category_ids.includes(cat.id) ? 'flat' : 'outlined'"
                class="pa-4 rounded-lg cursor-pointer transition-all"
                @click="toggleCategory(cat.id)"
              >
                <div class="d-flex align-center justify-space-between">
                  <div class="d-flex align-center ga-3">
                    <v-icon :icon="cat.icon" :color="form.category_ids.includes(cat.id) ? 'slate-950' : 'primary'"></v-icon>
                    <div>
                      <div class="font-weight-bold" :class="form.category_ids.includes(cat.id) ? 'text-slate-950' : 'text-white'">
                        {{ cat.name }}
                      </div>
                      <div class="text-caption" :class="form.category_ids.includes(cat.id) ? 'text-slate-900' : 'text-grey'">
                        {{ cat.desc }}
                      </div>
                    </div>
                  </div>
                  <v-checkbox-btn
                    :model-value="form.category_ids.includes(cat.id)"
                    color="slate-950"
                  ></v-checkbox-btn>
                </div>
              </v-card>
            </v-col>
          </v-row>
        </div>

        <!-- STEP 3: Coverage Area & Verification -->
        <div v-if="step === 3">
          <div class="text-subtitle-1 font-weight-bold text-white mb-2">Étape 3 : Zone de Couverture GPS & Profil</div>
          
          <v-text-field
            v-model="form.address"
            label="Adresse de base / Ville"
            required
            variant="outlined"
            color="primary"
            prepend-inner-icon="mdi-map-marker-outline"
            placeholder="Dakar, Sénégal"
            class="mb-3"
          ></v-text-field>

          <div class="text-caption text-grey font-weight-bold mb-2">Rayon d'action d'intervention (km) : {{ form.radius_km }} km</div>
          <v-slider
            v-model="form.radius_km"
            min="5"
            max="50"
            step="5"
            color="primary"
            thumb-label
            class="mb-4"
          ></v-slider>

          <v-text-field
            v-model="form.pro_id"
            label="Numéro NINEA / Registre Pro (Optionnel)"
            variant="outlined"
            color="primary"
            prepend-inner-icon="mdi-card-account-details-outline"
            placeholder="SN-DKR-2026-B1234"
          ></v-text-field>
        </div>

        <!-- STEP 4: Plan Confirmation & Finalize -->
        <div v-if="step === 4" class="text-center py-4">
          <v-icon icon="mdi-check-decagram" color="success" size="64" class="mb-3"></v-icon>
          <div class="text-h6 font-weight-bold text-white mb-2">Votre Compte Pro est Prêt !</div>
          <div class="text-body-2 text-grey mb-4">
            Formule TechConnect SaaS Pro active. Aucun frais d'inscription. Vous êtes prêt à recevoir des demandes en temps réel.
          </div>

          <v-card color="surface-variant" class="pa-4 rounded-lg border text-left mb-4">
            <div class="d-flex justify-space-between align-center mb-2">
              <span class="font-weight-bold text-white">{{ form.name }}</span>
              <v-chip color="success" size="x-small" variant="flat">Vérifié</v-chip>
            </div>
            <div class="text-caption text-grey">Email: {{ form.email }}</div>
            <div class="text-caption text-grey">Téléphone: {{ form.phone }}</div>
            <div class="text-caption text-primary font-weight-bold mt-2">
              Métiers sélectionnés : {{ selectedCategoryNames.join(', ') }}
            </div>
          </v-card>
        </div>

        <!-- Error Alert -->
        <v-alert v-if="errorMessage" color="error" variant="tonal" class="mb-4 rounded-lg">
          {{ errorMessage }}
        </v-alert>

        <!-- Form Navigation Actions -->
        <div class="d-flex justify-space-between align-center mt-6">
          <v-btn
            v-if="step > 1"
            variant="outlined"
            color="grey"
            class="text-none font-weight-bold rounded-pill"
            @click="step--"
          >
            Précédent
          </v-btn>
          <div v-else></div>

          <v-btn
            v-if="step < 4"
            color="primary"
            variant="flat"
            class="text-none font-weight-bold rounded-pill px-6"
            @click="nextStep"
          >
            Suivant →
          </v-btn>

          <v-btn
            v-else
            type="submit"
            color="success"
            variant="flat"
            size="large"
            :loading="loading"
            class="text-none font-weight-bold rounded-pill px-8"
          >
            Activer mon Espace Pro
          </v-btn>
        </div>

      </v-form>

      <v-divider class="my-6"></v-divider>

      <div class="text-center text-caption text-grey">
        Vous avez déjà un compte professionnel ?
        <router-link to="/login" class="text-primary font-weight-bold ms-1">Se connecter</router-link>
      </div>

    </v-card>
  </v-container>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const step = ref(1)
const loading = ref(false)
const errorMessage = ref('')

const form = ref({
  name: '',
  email: '',
  phone: '',
  password: '',
  category_ids: ['cat_plumbing'],
  address: 'Dakar, Sénégal',
  radius_km: 15,
  pro_id: ''
})

const availableCategories = [
  { id: 'cat_plumbing', name: 'Plomberie', desc: 'Fuites, débouchage, installation', icon: 'mdi-water-pump' },
  { id: 'cat_electrical', name: 'Électricité', desc: 'Panne de courant, câblage, tableau', icon: 'mdi-bolt' },
  { id: 'cat_hvac', name: 'Froid & Climatisation', desc: 'Recharge gaz, entretien clim & frigo', icon: 'mdi-air-conditioner' },
  { id: 'cat_appliances', name: 'Électroménager', desc: 'Réparation laves-linge & fours', icon: 'mdi-washing-machine' }
]

const selectedCategoryNames = computed(() => {
  return availableCategories
    .filter(c => form.value.category_ids.includes(c.id))
    .map(c => c.name)
})

function toggleCategory(catId) {
  const idx = form.value.category_ids.indexOf(catId)
  if (idx > -1) {
    if (form.value.category_ids.length > 1) {
      form.value.category_ids.splice(idx, 1)
    }
  } else {
    form.value.category_ids.push(catId)
  }
}

function nextStep() {
  errorMessage.value = ''
  if (step.value === 1) {
    if (!form.value.name || !form.value.email || !form.value.phone || !form.value.password) {
      errorMessage.value = 'Veuillez remplir tous les champs obligatoires.'
      return
    }
  }
  step.value++
}

async function handleSubmit() {
  loading.value = true
  errorMessage.value = ''
  try {
    await authStore.registerTechnician(form.value)
    router.push('/')
  } catch (err) {
    errorMessage.value = err.message || 'Échec de l\'inscription'
  } finally {
    loading.value = false
  }
}
</script>

<style>
.max-w-650 {
  max-width: 650px;
}
.space-y-4 > * + * {
  margin-top: 1rem;
}
</style>
