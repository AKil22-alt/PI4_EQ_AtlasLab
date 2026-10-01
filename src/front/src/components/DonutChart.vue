<script setup>
import { computed } from 'vue';
import { Doughnut } from 'vue-chartjs';
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js';
import ChartDataLabels from 'chartjs-plugin-datalabels';

ChartJS.register(ArcElement, Tooltip, Legend, ChartDataLabels);

const props = defineProps ({
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
    '#830E08'
];

const chartData = computed (() => ({
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

const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    cutout: '35%',
    layout: {
        padding: 0
    },
    plugins: {
        legend: {
            position: 'right',
            labels: {
                color: '#3D3D3D',
                boxWidth: 15,
                boxHeight: 15,
                padding: 14,
                font: {
                    family: 'Montserrat',
                    size: 16
                }
            }
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
</script>

<template>
    <article :class="[
        'w-full rounded-lg bg-white',
        props.compact ? 'min-h-0 h-[202px] overflow-hidden px-4 py-3 xl:h-full xl:px-5 xl:py-4' : 'min-h-[361px] max-w-[608px] px-8 py-5'
    ]">
        <h2 :class="props.compact ? 'text-sm font-semibold text-black' : 'text-2xl font-semibold text-black'">
            {{ props.title }}
        </h2>

        <div :class="props.compact ? 'mx-auto mt-1 min-h-0 h-[164px] w-full max-w-[330px] xl:h-[calc(100%-28px)] xl:max-w-[390px]' : 'mx-auto mt-3 h-[270px] w-full max-w-[500px]'">
            <Doughnut :data="chartData" :options="chartOptions" />
        </div>
    </article>
</template>