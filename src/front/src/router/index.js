// Importa as funções que criam o roteador e o histórico de navegação do browser.
import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '../store/auth'

// Cada objeto representa uma URL e o componente que será renderizado nela.
// meta.title é usado pela Navbar para mostrar o título da página atual.
const routes = [
  {
    path: '/',
    name: 'Dashboard',
    component: () => import('../views/DashboardView.vue'),
    meta: { title: 'Dashboard' }
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/LoginView.vue'),
    meta: { title: 'Login' }
  },
  {
    path: '/orders',
    name: 'Orders',
    component: () => import('../views/OrdersView.vue'),
    meta: { title: 'Ordem de Serviço' }
  },
  {
    path: '/labs',
    name: 'Labs',
    component: () => import('../views/LabsView.vue'),
    meta: { title: 'Laboratórios e ativos' }
  },
  {
    path: '/users',
    name: 'Users',
    component: () => import('../views/UsersView.vue'),
    meta: { title: 'Usuários', requiresCargo: 'ADM' }
  }
]

const router = createRouter ({
  // createWebHistory permite URLs normais, como /orders e /users.
    history: createWebHistory(),
    routes,
});

router.beforeEach(async (to) => {
  const authStore = useAuthStore()
  const hasToken = Boolean(localStorage.getItem('atlaslab-token'))

  if (to.name === 'Login') {
    if (!hasToken) return true

    try {
      await authStore.loadCurrentUser()
    } catch {
      return true
    }

    return authStore.currentUser ? { name: 'Dashboard' } : true
  }

  if (!hasToken) return { name: 'Login' }

  let user = authStore.currentUser
  if (!user) {
    try {
      user = await authStore.loadCurrentUser()
    } catch {
      return { name: 'Login' }
    }
  }

  if (!user) return { name: 'Login' }
  if (to.meta.requiresCargo && user.cargo !== to.meta.requiresCargo) {
    return { name: 'Dashboard' }
  }
})

// O router é importado pelo main.js e registrado na aplicação.
export default router;