import { createRouter, createWebHistory } from 'vue-router'
import Dashboard from '../views/Dashboard.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'dashboard',
      component: Dashboard
    },
    {
      path: '/config',
      name: 'config',
      component: () => import('../views/Config.vue')
    },
    {
      path: '/logs',
      name: 'logs',
      component: () => import('../views/Logs.vue')
    },
    {
      path: '/status',
      name: 'status',
      component: () => import('../views/Status.vue')
    },
    {
      path: '/settings',
      name: 'settings',
      component: () => import('../views/Settings.vue')
    }
  ]
})

export default router