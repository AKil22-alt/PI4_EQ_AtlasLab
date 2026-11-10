<script setup>
import { onMounted, ref } from 'vue'
import {
    ClipboardList,
    FlaskConical,
    Package,
    Users,
    ClipboardCheck,
    RefreshCw
} from 'lucide-vue-next'

import SummaryCard from '../components/SummaryCard.vue'
import ActivityList from '../components/ActivityList.vue'
import BarChart from '../components/BarChart.vue'
import DonutChart from '../components/DonutChart.vue'
import { dashboardSummaryRequest } from '../services/api'

const summaryCards = ref([
    { id: 'users', title: 'Usuários', value: '—', icon: Users, to: '/users' },
    { id: 'labs', title: 'Laboratórios', value: '—', icon: FlaskConical, to: '/labs' },
    { id: 'assets', title: 'Ativos', value: '—', icon: Package, to: '/labs' },
    { id: 'orders', title: 'Ordens de Serviço', value: '—', icon: ClipboardList, to: '/orders', active: true }
])

const isLoading = ref(true)
const loadError = ref('')
const activities = ref([])
const weeklyActivity = ref({
    labels: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
    values: []
})
const assetDistribution = ref({ labels: [], values: [] })

function formatActivityTime(value) {
    if (!value) return ''

    return new Date(value).toLocaleString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    })
}

const activityTargets = {
    Ativo: { icon: Package, to: (id) => ({ path: '/labs', query: { tab: 'assets', assetId: id } }) },
    OrdemServico: { icon: ClipboardCheck, to: (id) => ({ path: '/orders', query: { orderId: id } }) },
    SalaLab: { icon: FlaskConical, to: (id) => ({ path: '/labs', query: { tab: 'labs', labId: id } }) },
    Usuario: { icon: Users, to: (id) => ({ path: '/users', query: { userId: id } }) },
    GrupoA: { icon: Package, to: () => ({ path: '/labs', query: { tab: 'assets' } }) },
    ManutencaoA: { icon: ClipboardCheck, to: () => ({ path: '/orders' }) },
    MovimentacoesA: { icon: Package, to: (id) => ({ path: '/labs', query: { tab: 'movements', movementId: id } }) },
    DenunciaF: { icon: ClipboardList },
    SolicitacaoCadastro: { icon: Users, to: (id) => ({ path: '/users', query: { tab: 'requests', requestId: id } }) }
}

async function loadDashboard() {
    isLoading.value = true
    loadError.value = ''

    try {
        const data = await dashboardSummaryRequest()
        const totals = data.totals
        summaryCards.value.find((card) => card.id === 'users').value = totals.users
        summaryCards.value.find((card) => card.id === 'labs').value = totals.laboratories
        summaryCards.value.find((card) => card.id === 'assets').value = totals.assets
        summaryCards.value.find((card) => card.id === 'orders').value = totals.service_orders
        weeklyActivity.value = data.weekly_activity
        assetDistribution.value = data.asset_distribution
        activities.value = data.recent_activities.map((activity) => {
            const target = activityTargets[activity.type] || { icon: ClipboardList }
            return {
                id: activity.id,
                title: activity.title,
                time: formatActivityTime(activity.created_at),
                icon: target.icon,
                ...(target.to ? { to: target.to(activity.entity_id) } : {})
            }
        })
    } catch (error) {
        console.error('Erro ao carregar dados do dashboard:', error)
        loadError.value = 'Não foi possível carregar os dados do dashboard. Verifique a conexão e tente novamente.'
    } finally {
        isLoading.value = false
    }
}

onMounted(loadDashboard)
</script>

<template>
    <main class="box-border flex min-h-[calc(100vh-96px)] w-full flex-col gap-6 overflow-y-auto px-4 pb-8 pt-6 sm:px-8 min-[1200px]:h-[calc(100vh-96px)] min-[1200px]:min-h-0 min-[1200px]:overflow-hidden">
        <section class="grid grid-cols-1 gap-4 min-[700px]:grid-cols-4" aria-label="Resumo da aplicação">
            <SummaryCard v-for="card in summaryCards" :key="card.id" :title="card.title" :value="card.value"
                :icon="card.icon" :to="card.to" :active="card.active" />
        </section>

        <section class="grid min-h-0 flex-1 grid-cols-1 gap-4 min-[1200px]:grid-cols-2"
            aria-label="Atividades e indicadores">
            <div v-if="isLoading" class="flex min-h-[280px] items-center justify-center rounded-lg bg-white text-sm text-text-secondary" role="status">
                Carregando dados do dashboard...
            </div>
            <div v-else-if="loadError" class="flex min-h-[280px] flex-col items-center justify-center gap-3 rounded-lg bg-white px-5 text-center" role="alert">
                <p class="text-sm text-text-secondary">{{ loadError }}</p>
                <button class="inline-flex items-center gap-2 text-sm font-semibold text-red-primary hover:underline" type="button" @click="loadDashboard">
                    <RefreshCw :size="16" /> Tentar novamente
                </button>
            </div>
            <ActivityList v-else-if="activities.length" title="Últimas atividades" :activities="activities" />
            <article v-else class="min-h-[280px] rounded-lg bg-white px-4 py-4 xl:px-5 xl:py-5">
                <h2 class="text-lg font-semibold text-text-primary">Últimas atividades</h2>
                <p class="mt-5 text-sm text-text-secondary">Nenhuma atividade registrada.</p>
            </article>

            <div v-if="!isLoading && !loadError"
            class="min-h-0 space-y-4 min-[1200px]:grid min-[1200px]:h-full min-[1200px]:grid-rows-[minmax(0,1fr)_minmax(0,1fr)]">
                <BarChart v-if="weeklyActivity.values.some((value) => value > 0)" title="Atividades Semanais"
                    :labels="weeklyActivity.labels" :values="weeklyActivity.values" compact />
                <article v-else class="flex min-h-[169px] flex-col rounded-lg bg-white px-4 py-3 xl:px-5 xl:py-4">
                    <h2 class="text-sm font-semibold text-black">Atividades Semanais</h2>
                    <p class="mt-4 text-sm text-text-secondary">Nenhuma atividade nesta semana.</p>
                </article>

                <DonutChart v-if="assetDistribution.values.length" title="Distribuição de Ativos"
                    :labels="assetDistribution.labels" :values="assetDistribution.values" compact />
                <article v-else class="flex min-h-[202px] flex-col rounded-lg bg-white px-4 py-3 xl:px-5 xl:py-4">
                    <h2 class="text-sm font-semibold text-black">Distribuição de Ativos</h2>
                    <p class="mt-4 text-sm text-text-secondary">Nenhum ativo cadastrado.</p>
                </article>
            </div>
        </section>
    </main>
</template>