<script setup>
// computed atualiza o título quando a rota muda.
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { Menu, Bell, CircleUserRound } from 'lucide-vue-next'

import NotificationPanel from '../components/NotificationPanel.vue'
import { ref } from 'vue'

// A Navbar não controla a Sidebar; ela apenas avisa o App quando o menu é clicado.
const emit = defineEmits(['toggle-sidebar'])
const route = useRoute();

// Lê meta.title definido em router/index.js. Usa AtlasLab como fallback.
const pageTitle = computed(() => {
    return route.meta.title || 'AtlasLab'
})

const showNotifications = ref(false)
function toggleNotifications() {
    showNotifications.value = !showNotifications.value
}

// Dados temporários para testar o componente antes da integração com a API.
const notifications = [
    {
        id: 1,
        message: 'Nova ordem de serviço criada.',
        time: '2 minutos atrás'
    },
    {
        id: 2,
        message: 'O ativo Monitor Dell foi movimentado.',
        time: '20 minutos atrás'
    }
]
</script>

<template>
    <!-- relative permite centralizar a Searchbar com position absolute. -->
    <header class="sticky top-0 z-40 flex h-24 w-full items-center gap-8 bg-white px-8">
        <!-- Emite o evento que o App usa para abrir ou fechar a Sidebar. -->
        <button type="button" aria-label="Abrir ou fechar menu" @click="emit('toggle-sidebar')">
            <Menu :size="24" />
        </button>
        <h1 class="text-xl font-bold">{{ pageTitle }}</h1>

        <!-- ml-auto empurra notificações e usuário para o fim da barra. -->
        <div class="ml-auto flex items-center gap-6">
            <div class="relative">
                <button type="button" aria-label="Notificações" title="Notificações" @click="toggleNotifications">
                    <Bell :size="22" />
                </button>

                <!-- O painel é renderizado somente enquanto showNotifications for true. -->
                <NotificationPanel
                    v-if="showNotifications"
                    :notifications="notifications"
                    @close="showNotifications = false"
                    @view-all="showNotifications = false"
                />
            </div>


            <div class="flex items-center gap-2">
                <CircleUserRound class="text-dark-red" :size="32" />
                <span>Thainara</span>
            </div>
        </div>
    </header>
</template>