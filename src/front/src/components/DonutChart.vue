<script setup>
import { computed } from 'vue';
import { Doughnut } from 'vue-chartjs';
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js';
import ChartDataLabels from 'chartjs-plugin-datalabels';

ChartJS.register(ArcElement, Tooltip, Legend, ChartDataLabels);

const props = defineProps({
    title: {
        type: String,
        required: true
    },
    labels: {
        type: Array,
        required: true
    },
    values: {
        type: Array,
        required: true
    },
    compact: {
        type: Boolean,
        default: false
    }
});

const colorPalette = [
    '#8F0B20',
    '#640509',
    '#985658',
    '#B68C8E',
    '#B40001',
    '#830E08',
    '#A3233D',
    '#6F2633',
    '#C3434B',
    '#9B1B2A',
    '#7D3D47',
    '#C16A70'
];

const chartData = computed(() => ({
    labels: props.labels,
    datasets: [
        {
            data: props.values,
            backgroundColor: props.values.map(
                (_, index) => colorPalette[index % colorPalette.length]
            ),
            borderWidth: 0,
        }
    ]
}));

const legendItems = computed(() => props.labels.map((label, index) => ({
    label,
    color: colorPalette[index % colorPalette.length]
})));

const chartOptions = computed(() => {
    return {
        responsive: true,
        maintainAspectRatio: false,
        cutout: '35%',
        layout: {
            padding: 0
        },
        plugins: {
            legend: {
                display: false
            },
            tooltip: {
                enabled: true
            },
            datalabels: {
                color: '#FFFFFF',
                font: {
                    family: 'Montserrat',
                    size: 16,
                    weight: '600'
                },
                formatter: (value, context) => {
                    const values = context.chart.data.datasets[0].data;
                    const total = values.reduce((sum, item) => sum + Number(item), 0);

                    return `${Math.round((Number(value) / total) * 100)}%`;
                }
            }
        }
    }
})
</script>

<template>
    <article :class="[
        'w-full rounded-lg bg-white',
        props.compact ? 'min-h-0 h-[202px] overflow-hidden px-4 py-3 xl:h-full xl:px-5 xl:py-4' : 'min-h-[361px] max-w-[608px] px-8 py-5'
    ]">
        <h2 :class="props.compact ? 'text-sm font-semibold text-black' : 'text-2xl font-semibold text-black'">
            {{ props.title }}
        </h2>

        <div
            :class="props.compact
                ? 'mx-auto mt-1 grid min-h-0 h-[164px] w-full max-w-[540px] grid-cols-[minmax(0,0.9fr)_minmax(0,1.1fr)] items-center gap-2 xl:h-[calc(100%-28px)]'
                : 'mx-auto mt-3 grid h-[270px] w-full max-w-[600px] grid-cols-[minmax(0,0.9fr)_minmax(0,1.1fr)] items-center gap-5'">
            <div class="flex h-full min-h-0 min-w-0 items-center">
                <div :class="props.compact ? 'h-full w-full max-w-[190px]' : 'h-full w-full max-w-[250px]'">
                    <Doughnut class="h-full w-full" :data="chartData" :options="chartOptions" />
                </div>
            </div>
            <ul class="grid max-h-full min-w-0 grid-cols-2 content-center gap-x-2 gap-y-1 overflow-y-auto">
                <li v-for="item in legendItems" :key="item.label" class="flex min-w-0 items-start gap-1.5">
                    <span class="mt-0.5 h-2.5 w-2.5 shrink-0 rounded-sm" :style="{ backgroundColor: item.color }"
                        aria-hidden="true"></span>
                    <span class="min-w-0 break-words text-[10px] leading-tight text-text-secondary">
                        {{ item.label }}
                    </span>
                </li>
            </ul>
        </div>
    </article>
</template>