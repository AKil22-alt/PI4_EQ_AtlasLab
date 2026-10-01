<script setup>
import { ref } from 'vue'
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

// Estes dados têm o mesmo formato esperado pela API e podem ser substituídos pela resposta do backend.
const summaryCards = ref([
    { id: 'users', title: 'Usuários', value: 50, icon: Users },
    { id: 'labs', title: 'Laboratórios', value: 10, icon: FlaskConical },
    { id: 'assets', title: 'Ativos', value: 140, icon: Package },
    { id: 'orders', title: 'Ordens de Serviço', value: 15, icon: ClipboardList, active: true }
])

const activities = ref([
    { id: 1, title: 'Guilherme movimentou 10 ativos', time: '40 s - 14/09/2026', icon: Package, to: '/labs' },
    { id: 2, title: 'Eduardo criou uma OS', time: '10 m - 14/09/2026', icon: ClipboardCheck, to: '/orders' },
    { id: 3, title: 'Cauã completou uma OS', time: '2 h - 14/09/2026', icon: ClipboardCheck, to: '/orders' },
    { id: 4, title: 'Thainara adicionou um laboratório', time: 'Ontem - 13/09/2026', icon: FlaskConical, to: '/labs' }
])

const weeklyActivity = ref({
    labels: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex'],
    values: [15, 30, 20, 10, 25]
})

const assetDistribution = ref({
    labels: ['B-101', 'B-102', 'B-111', 'B-112'],
    values: [50, 25, 15, 10]
})
</script>

<template>
    <main class="box-border flex h-[calc(100vh-96px)] w-full flex-col gap-6 overflow-hidden px-8 pb-8 pt-6">
        <section class="grid grid-cols-1 gap-4 min-[700px]:grid-cols-4" aria-label="Resumo da aplicação">
            <SummaryCard
                v-for="card in summaryCards"
                :key="card.id"
                :title="card.title"
                :value="card.value"
                :icon="card.icon"
                :active="card.active"
            />
        </section>

        <section class="grid min-h-0 flex-1 grid-cols-1 gap-4 min-[700px]:grid-cols-2" aria-label="Atividades e indicadores">
            <ActivityList title="Últimas atividades" :activities="activities" />

            <div class="min-h-0 space-y-2 min-[700px]:grid min-[700px]:h-full min-[700px]:grid-rows-[minmax(0,1fr)_minmax(0,1fr)]">
                <BarChart
                    title="Atividades Semanais"
                    :labels="weeklyActivity.labels"
                    :values="weeklyActivity.values"
                    compact
                />

                <DonutChart
                    title="Distribuição de Ativos"
                    :labels="assetDistribution.labels"
                    :values="assetDistribution.values"
                    compact
                />
            </div>
        </section>
    </main>
</template>