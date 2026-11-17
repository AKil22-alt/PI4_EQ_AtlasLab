<script setup>
import { onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Bell, Check, ExternalLink, RefreshCw } from 'lucide-vue-next'
import Button from '../components/Button.vue'
import { listNotificationsRequest, markNotificationReadRequest } from '../services/api'

const router = useRouter()
const notifications = ref([])
const isLoading = ref(false)
const errorMessage = ref('')

async function loadNotifications() {
    isLoading.value = true
    errorMessage.value = ''

    try {
        const data = await listNotificationsRequest()
        notifications.value = data.map((notification) => ({
            ...notification,
            time: new Date(notification.criada_em).toLocaleString('pt-BR')
        }))
    } catch (error) {
        errorMessage.value = error.message || 'Não foi possível carregar as notificações.'
    } finally {
        isLoading.value = false
    }
}

async function markAsRead(notification) {
    try {
        await markNotificationReadRequest(notification.id)
        await loadNotifications()
    } catch (error) {
        errorMessage.value = error.message || 'Não foi possível marcar a notificação como lida.'
    }
}

async function openNotification(notification) {
    if (!notification.lida) {
        try {
            await markNotificationReadRequest(notification.id)
        } catch (error) {
            errorMessage.value = error.message || 'Não foi possível marcar a notificação como lida.'
        }
    }

    if (notification.destino?.name) {
        await router.push(notification.destino)
    }
}

function refreshNotifications() {
    void loadNotifications()
}

onMounted(() => {
    window.addEventListener('notifications-refresh', refreshNotifications)
    void loadNotifications()
})

onUnmounted(() => {
    window.removeEventListener('notifications-refresh', refreshNotifications)
})
</script>

<template>
    <main class="space-y-6 px-8 pb-8 pt-6">
        <header class="flex flex-wrap items-center justify-between gap-4 border-b border-gray-200 pb-4">
            <div>
                <h1 class="text-xl font-semibold text-text-primary">Notificações</h1>
                <p class="mt-1 text-sm text-text-secondary">{{ notifications.length }} notificações</p>
            </div>
            <Button variant="outline" size="sm" :disabled="isLoading" @click="loadNotifications">
                <RefreshCw :size="16" />
                Atualizar
            </Button>
        </header>

        <p v-if="isLoading && !notifications.length" class="py-8 text-center text-sm text-text-secondary" role="status">
            Carregando notificações...
        </p>
        <div v-else-if="errorMessage" class="space-y-3 py-8 text-center" role="alert">
            <p class="text-sm text-red-primary">{{ errorMessage }}</p>
            <Button variant="outline" size="sm" @click="loadNotifications">Tentar novamente</Button>
        </div>
        <div v-else-if="!notifications.length" class="flex flex-col items-center gap-3 py-12 text-text-secondary">
            <Bell :size="28" aria-hidden="true" />
            <p class="text-sm">Nenhuma notificação.</p>
        </div>
        <ul v-else class="divide-y divide-gray-200">
            <li v-for="notification in notifications" :key="notification.id" class="py-4 first:pt-0 last:pb-0">
                <div class="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
                    <button type="button" class="min-w-0 text-left" @click="openNotification(notification)">
                        <span class="flex items-center gap-2">
                            <span v-if="!notification.lida" class="h-2 w-2 shrink-0 rounded-full bg-red-primary"
                                aria-label="Não lida"></span>
                            <span class="text-sm font-medium text-text-primary">{{ notification.mensagem }}</span>
                        </span>
                        <span class="mt-1 block pl-4 text-xs text-text-secondary">{{ notification.time }}</span>
                    </button>
                    <div class="flex shrink-0 gap-2">
                        <Button v-if="!notification.lida" variant="outline" size="sm" @click="markAsRead(notification)">
                            <Check :size="16" />
                            Marcar como lida
                        </Button>
                        <Button variant="primary" size="sm" @click="openNotification(notification)">
                            <ExternalLink :size="16" />
                            Abrir
                        </Button>
                    </div>
                </div>
            </li>
        </ul>
    </main>
</template>