<script setup>
import { computed } from 'vue';
import { Bar } from 'vue-chartjs';
import {
    Chart as ChartJS,
    CategoryScale,
    LinearScale,
    BarElement,
    Tooltip,
    Legend
} from 'chart.js';
import ChartDataLabels from 'chartjs-plugin-datalabels';

ChartJS.register(CategoryScale, LinearScale, BarElement, Tooltip, Legend, ChartDataLabels);

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

const getCssColor = (variable, fallback) => {
    if (typeof document === 'undefined') {
        return fallback;
    }

    return getComputedStyle(document.documentElement)
        .getPropertyValue(variable)
        .trim() || fallback;
};

const colorPalette = [
    ['--color-dark-red', '#640509'],
    ['--color-red-1', '#985658'],
    ['--color-red-6', '#B40001'],
    ['--color-red-1', '#985658'],
    ['--color-red-primary', '#C8102E']
];

const chartData = computed(() => ({
    labels: props.labels,
    datasets: [
        {
            data: props.values,
            backgroundColor: props.values.map(
                (_, index) => {
                    const [variable, fallback] = colorPalette[index % colorPalette.length];

                    return getCssColor(variable, fallback);
                }
            ),
            borderRadius: 5,
            borderSkipped: false,
            barPercentage: 0.7,
            categoryPercentage: 0.8
        }
    ]
}));

const chartOptions = computed(() => {
    const highestValue = Math.max(...props.values.map(Number), 0);
    const suggestedMax = Math.max(Math.ceil(highestValue / 5) * 5, 5);

    return {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                display: false
            },
            tooltip: {
                enabled: true
            },
            datalabels: {
                color: getCssColor('--color-white', '#FFFFFF'),
                font: {
                    family: 'Montserrat',
                    size: 14,
                    weight: '600'
                },
                formatter: (value) => value
            }
        },
        scales: {
            x: {
                grid: {
                    display: false
                },
                border: {
                    color: '#AAAAAA'
                },
                ticks: {
                    color: '#AAAAAA',
                    font: {
                        family: 'Montserrat',
                        size: 14
                    }
                }
            },
            y: {
                beginAtZero: true,
                suggestedMax,
                ticks: {
                    stepSize: 5,
                    color: '#AAAAAA',
                    font: {
                        family: 'Montserrat',
                        size: 14
                    }
                },
                grid: {
                    color: '#DDDDDD'
                },
                border: {
                    color: '#AAAAAA'
                }
            }
        }
    };
});
</script>

<template>
    <article :class="[
        'w-full rounded-lg bg-white',
        props.compact ? 'min-h-0 h-[169px] overflow-hidden px-4 py-3 xl:h-full xl:px-5 xl:py-4' : 'min-h-[337px] max-w-[680px] px-9 py-6'
    ]">
        <h2 :class="props.compact ? 'text-sm font-semibold text-black' : 'text-2xl font-semibold text-black'">
            {{ props.title }}
        </h2>

        <div :class="props.compact ? 'mt-1 min-h-0 h-[122px] w-full xl:h-[calc(100%-28px)]' : 'mt-3 h-[250px] w-full'">
            <Bar :data="chartData" :options="chartOptions" />
        </div>
    </article>
</template>