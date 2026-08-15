import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'

// Custom Global Styles
import './assets/main.css'

// Vuetify 3
import 'vuetify/styles'
import '@mdi/font/css/materialdesignicons.css'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'

const techTheme = {
  dark: true,
  colors: {
    background: '#020617',
    surface: '#0F172A',
    'surface-variant': '#1E293B',
    primary: '#10B981',
    'primary-darken-1': '#059669',
    secondary: '#06B6D4',
    error: '#EF4444',
    info: '#3B82F6',
    success: '#10B981',
    warning: '#F59E0B'
  }
}

const vuetify = createVuetify({
  components,
  directives,
  theme: {
    defaultTheme: 'techTheme',
    themes: {
      techTheme
    }
  }
})

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(vuetify)

app.mount('#app')
