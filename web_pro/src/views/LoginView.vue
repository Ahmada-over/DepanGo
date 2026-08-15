<template>
  <v-container class="fill-height d-flex align-center justify-center py-8">
    <v-card class="pa-8 max-w-450 w-100 rounded-xl border border-primary" elevation="6">
      <div class="text-center mb-6">
        <v-avatar color="primary" size="56" class="font-weight-black text-h4 text-slate-950 mb-2">
          TC
        </v-avatar>
        <div class="text-h5 font-weight-black text-white">Espace Professionnel</div>
        <div class="text-caption text-grey">Connectez-vous à votre compte TechConnect Pro</div>
      </div>

      <v-alert v-if="errorMessage" color="error" variant="tonal" class="mb-4 rounded-lg">
        {{ errorMessage }}
      </v-alert>

      <v-form @submit.prevent="handleLogin">
        <v-text-field
          v-model="email"
          label="Adresse Email Pro"
          type="email"
          required
          variant="outlined"
          color="primary"
          class="mb-3"
          prepend-inner-icon="mdi-email-outline"
        ></v-text-field>

        <v-text-field
          v-model="password"
          label="Mot de passe"
          type="password"
          required
          variant="outlined"
          color="primary"
          class="mb-4"
          prepend-inner-icon="mdi-lock-outline"
        ></v-text-field>

        <v-btn
          type="submit"
          color="primary"
          block
          size="large"
          variant="flat"
          :loading="loading"
          class="text-none font-weight-bold rounded-pill"
        >
          Se Connecter
        </v-btn>
      </v-form>

      <v-divider class="my-6"></v-divider>

      <div class="text-center text-caption text-grey">
        Nouveau professionnel ?
        <router-link to="/register" class="text-primary font-weight-bold ms-1">S'inscrire (SaaS Pro)</router-link>
      </div>
    </v-card>
  </v-container>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const email = ref('')
const password = ref('')
const loading = ref(false)
const errorMessage = ref('')
const router = useRouter()
const authStore = useAuthStore()

async function handleLogin() {
  loading.value = true
  errorMessage.value = ''
  try {
    await authStore.login(email.value, password.value)
    if (authStore.user?.role === 'admin') {
      router.push('/admin')
    } else {
      router.push('/')
    }
  } catch (err) {
    errorMessage.value = err.message || 'Échec de la connexion'
  } finally {
    loading.value = false
  }
}
</script>

<style>
.max-w-450 {
  max-width: 450px;
}
</style>
