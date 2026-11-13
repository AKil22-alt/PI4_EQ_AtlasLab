<script setup>
// computed atualiza o título quando a rota muda.
import { computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Menu, Bell, CircleUserRound } from 'lucide-vue-next'
import { useAuthStore } from '../store/auth'
import { listNotificationsRequest, markNotificationReadRequest } from '../services/api'

import NotificationPanel from '../components/NotificationPanel.vue'
import { ref } from 'vue'

// A Navbar não controla a Sidebar; ela apenas avisa o App quando o menu é clicado.
const emit = defineEmits(['toggle-sidebar'])
const route = useRoute();
const router = useRouter()
const authStore = useAuthStore()

// Lê meta.title definido em router/index.js. Usa AtlasLab como fallback.
const pageTitle = computed(() => {
    return route.meta.title || 'AtlasLab'
})

const userName = computed(() => {
    const user = authStore.currentUser
    return user?.nome || user?.first_name || user?.username || user?.email || 'Usuário'
})

onMounted(async () => {
    if (!authStore.currentUser && localStorage.getItem('atlaslab-token')) {
        try {
            await authStore.loadCurrentUser()
        } catch (error) {
            console.error('Erro ao carregar usuário atual:', error)
        }
    }

    if (authStore.currentUser?.cargo === 'ADM') {
        window.addEventListener('notifications-refresh', refreshNotifications)
        try {
            await loadNotifications()
            notificationsTimer = setInterval(() => {
                loadNotifications().catch(error => console.error('Erro ao atualizar notificações:', error))
            }, 20000)
        } catch (error) {
            console.error('Erro ao carregar notificações:', error)
        }
    }
})

const showNotifications = ref(false)
const notifications = ref([])
const hasUnreadNotifications = computed(() => notifications.value.some(notification => !notification.lida))
let notificationsTimer

async function loadNotifications() {
    const data = await listNotificationsRequest()
    notifications.value = data.map(notification => ({
        ...notification,
        message: notification.mensagem,
        time: new Date(notification.criada_em).toLocaleString('pt-BR')
    }))
}

function refreshNotifications() {
    loadNotifications().catch(error => console.error('Erro ao atualizar notificações:', error))
}

async function toggleNotifications() {
    if (showNotifications.value) {
        showNotifications.value = false
        return
    }

    showNotifications.value = true
    try {
        await loadNotifications()
    } catch (error) {
        console.error('Erro ao carregar notificações:', error)
    }
}

async function markNotificationAsRead(notification) {
    try {
        await markNotificationReadRequest(notification.id)
        await loadNotifications()
    } catch (error) {
        console.error('Erro ao marcar notificação como lida:', error)
    }
}

function openNotification(notification) {
    showNotifications.value = false
    if (!notification.lida) {
        markNotificationAsRead(notification)
    }
    if (notification.destino?.name) router.push(notification.destino)
}

function viewAllNotifications() {
    showNotifications.value = false
    router.push({ name: 'Notifications' })
}

onUnmounted(() => {
    clearInterval(notificationsTimer)
    window.removeEventListener('notifications-refresh', refreshNotifications)
})
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
                <button type="button" aria-label="Notificações" title="Notificações" class="relative"
                    @click="toggleNotifications">
                    <Bell :size="22" />
                    <span v-if="hasUnreadNotifications"
                        class="absolute -right-1 -top-1 h-2.5 w-2.5 rounded-full bg-red-600"
                        aria-label="Notificações não lidas"></span>
                </button>

                <!-- O painel é renderizado somente enquanto showNotifications for true. -->
                <NotificationPanel v-if="showNotifications" :notifications="notifications"
                    @close="showNotifications = false" @mark-read="markNotificationAsRead" @select="openNotification"
                    @view-all="viewAllNotifications" />
            </div>


            <div class="flex items-center gap-2">
                <CircleUserRound class="text-dark-red" :size="32" />
                <span>{{ userName }}</span>
            </div>
        </div>
    </header>
</template>