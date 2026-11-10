<script setup>
import { onMounted, ref } from 'vue'
import {
    ClipboardList,
    FlaskConical,
    Package,
    Users,
    ClipboardCheck
} from 'lucide-vue-next'

import SummaryCard from '../components/SummaryCard.vue'
import ActivityList from '../components/ActivityList.vue'
import BarChart from '../components/BarChart.vue'
import DonutChart from '../components/DonutChart.vue'
import { listAllPagesRequest } from '../services/api'
import { useAuthStore } from '../store/auth'

const authStore = useAuthStore()
const summaryCards = ref([
    { id: 'users', title: 'Usuários', value: '—', icon: Users, to: '/users' },
    { id: 'labs', title: 'Laboratórios', value: 0, icon: FlaskConical, to: '/labs' },
    { id: 'assets', title: 'Ativos', value: 0, icon: Package, to: '/labs' },
    { id: 'orders', title: 'Ordens de Serviço', value: 0, icon: ClipboardList, to: '/orders', active: true }
])

const activities = ref([])

const weeklyActivity = ref({
    labels: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
    values: [0, 0, 0, 0, 0, 0, 0]
})

const assetDistribution = ref({
    labels: [],
    values: []
})

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

function buildWeeklyActivity(orders, movements) {
    const startOfWeek = new Date()
    startOfWeek.setHours(0, 0, 0, 0)
    startOfWeek.setDate(startOfWeek.getDate() - ((startOfWeek.getDay() + 6) % 7))

    const values = Array(7).fill(0)
    ;[...orders.map((order) => order.data_hora), ...movements.map((movement) => movement.data_hora)]
        .filter(Boolean)
        .forEach((dateValue) => {
            const date = new Date(dateValue)
            if (date < startOfWeek) return

            const dayIndex = Math.floor((date - startOfWeek) / 86400000)
            if (dayIndex >= 0 && dayIndex < values.length) values[dayIndex] += 1
        })

    return { labels: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'], values }
}

function buildRecentActivities(orders, movements) {
    const orderActivities = orders.map((order) => ({
        id: `order-${order.id_ordem}`,
        title: `OS criada: ${order.titulo}`,
        time: formatActivityTime(order.data_hora),
        timestamp: new Date(order.data_hora).getTime(),
        icon: ClipboardCheck,
        to: '/orders'
    }))
    const movementActivities = movements.map((movement) => ({
        id: `movement-${movement.id_mov}`,
        title: `${movement.usuario_detalhes?.nome || 'Usuário'} movimentou ${movement.contagem_mov_a} ativo(s)`,
        time: formatActivityTime(movement.data_hora),
        timestamp: new Date(movement.data_hora).getTime(),
        icon: Package,
        to: '/labs'
    }))

    return [...orderActivities, ...movementActivities]
        .sort((first, second) => second.timestamp - first.timestamp)
        .slice(0, 4)
}

async function loadDashboard() {
    try {
        const [laboratories, assets, orders, movements] = await Promise.all([
            listAllPagesRequest('/salas/'),
            listAllPagesRequest('/ativos/'),
            listAllPagesRequest('/ordens-servico/'),
            listAllPagesRequest('/movimentacoes/')
        ])

        summaryCards.value.find((card) => card.id === 'labs').value = laboratories.length
        summaryCards.value.find((card) => card.id === 'assets').value = assets.length
        summaryCards.value.find((card) => card.id === 'orders').value = orders.length

        if (authStore.currentUser?.cargo === 'ADM') {
            const users = await listAllPagesRequest('/usuarios/')
            summaryCards.value.find((card) => card.id === 'users').value = users.length
        }

        weeklyActivity.value = buildWeeklyActivity(orders, movements)
        activities.value = buildRecentActivities(orders, movements)

        const assetsByLaboratory = new Map()
        assets.forEach((asset) => {
            const label = asset.local_atual_detalhes?.localizacao ||
                laboratories.find((laboratory) => laboratory.id_sala === asset.local_atual)?.localizacao ||
                'Não informado'
            assetsByLaboratory.set(label, (assetsByLaboratory.get(label) || 0) + 1)
        })
        assetDistribution.value = {
            labels: [...assetsByLaboratory.keys()],
            values: [...assetsByLaboratory.values()]
        }
    } catch (error) {
        console.error('Erro ao carregar dados do dashboard:', error)
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
            <ActivityList title="Últimas atividades" :activities="activities" />

            <div
            class="min-h-0 space-y-4 min-[1200px]:grid min-[1200px]:h-full min-[1200px]:grid-rows-[minmax(0,1fr)_minmax(0,1fr)]">
                <BarChart title="Atividades Semanais" :labels="weeklyActivity.labels" :values="weeklyActivity.values"
                    compact />

                <DonutChart title="Distribuição de Ativos" :labels="assetDistribution.labels"
                    :values="assetDistribution.values" compact />
            </div>
        </section>
    </main>
</template>