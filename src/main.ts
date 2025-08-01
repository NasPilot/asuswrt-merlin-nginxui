import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createI18n } from 'vue-i18n'
import App from './App.vue'
import router from './router'

// Create i18n instance
const i18n = createI18n({
  legacy: false,
  locale: 'en',
  fallbackLocale: 'en',
  messages: {
    en: {
      app: {
        title: 'NginxUI',
        subtitle: 'Nginx Management for ASUSWRT-Merlin'
      },
      nav: {
        dashboard: 'Dashboard',
        config: 'Configuration',
        logs: 'Logs',
        status: 'Status',
        settings: 'Settings'
      },
      status: {
        running: 'Running',
        stopped: 'Stopped',
        unknown: 'Unknown'
      },
      actions: {
        start: 'Start',
        stop: 'Stop',
        restart: 'Restart',
        save: 'Save',
        cancel: 'Cancel',
        edit: 'Edit',
        delete: 'Delete'
      }
    }
  }
})

// Create Pinia store
const pinia = createPinia()

// Create and mount the app
const app = createApp(App)

app.use(pinia)
app.use(router)
app.use(i18n)

app.mount('#app')

// Hide loading screen
setTimeout(() => {
  document.body.classList.add('app-ready')
}, 100)