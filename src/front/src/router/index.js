// Importa as funções que criam o roteador e o histórico de navegação do browser.
import { createRouter, createWebHistory } from 'vue-router';

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
    meta: { title: 'Usuários' }
  }
]

const router = createRouter ({
  // createWebHistory permite URLs normais, como /orders e /users.
    history: createWebHistory(),
    routes,
});

// O router é importado pelo main.js e registrado na aplicação.
export default router;