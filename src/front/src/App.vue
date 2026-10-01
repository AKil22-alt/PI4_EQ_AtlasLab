<script setup>
// ref cria um valor reativo: quando sidebarOpen muda, o template é atualizado.
import { ref } from 'vue'

import Navbar from './components/Navbar.vue'
import Sidebar from './components/Sidebar.vue'

// Controla a abertura e o fechamento da Sidebar no layout principal.
const sidebarOpen = ref(true)
</script>

<template>
  <!-- A tela de login não usa o layout administrativo com Navbar e Sidebar. -->
  <div v-if="$route.name !== 'Login'" class="flex min-h-screen">
    <!-- A prop open informa à Sidebar se ela deve estar aberta ou fechada. -->
    <Sidebar :open="sidebarOpen" />

    <div
      class="flex min-w-0 flex-1 flex-col"
      :style="{ '--sidebar-width': sidebarOpen ? '280px' : '72px' }"
    >
      <!-- Navbar emite toggle-sidebar quando o usuário clica no menu. -->
      <Navbar @toggle-sidebar="sidebarOpen = !sidebarOpen" />

      <main class="flex-1">
        <!-- Renderiza aqui o componente da rota atual. -->
        <RouterView />
      </main>
    </div>
  </div>

  <!-- Quando a rota é Login, renderiza somente a página de autenticação. -->
  <RouterView v-else />
</template>