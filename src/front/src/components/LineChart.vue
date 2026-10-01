<script setup>
import { computed } from 'vue';
import { Line } from 'vue-chartjs';
import {
	Chart as ChartJS,
	CategoryScale,
	LinearScale,
	PointElement,
	LineElement,
	Tooltip,
	Legend
} from 'chart.js';
import ChartDataLabels from 'chartjs-plugin-datalabels';

ChartJS.register(
	CategoryScale,
	LinearScale,
	PointElement,
	LineElement,
	Tooltip,
	Legend,
	ChartDataLabels
);

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
	seriesLabel: {
		type: String,
		default: 'Movimentações'
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

const chartData = computed(() => ({
	labels: props.labels,
	datasets: [
		{
			data: props.values,
			label: props.seriesLabel,
			borderColor: getCssColor('--color-dark-red', '#640509'),
			backgroundColor: getCssColor('--color-dark-red', '#640509'),
			pointBackgroundColor: getCssColor('--color-dark-red', '#640509'),
			pointBorderColor: getCssColor('--color-dark-red', '#640509'),
			pointRadius: 5,
			pointHoverRadius: 6,
			borderWidth: 1.5,
			tension: 0,
			fill: false
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
				display: true,
				position: 'bottom',
				align: 'center',
				labels: {
					color: getCssColor('--color-text-secondary', '#3D3D3D'),
					boxWidth: 24,
					padding: 12,
					font: {
						family: 'Montserrat',
						size: 12
					}
				}
			},
			tooltip: {
				enabled: true
			},
			datalabels: {
				display: false
			}
		},
		scales: {
			x: {
				grid: {
					display: false
				},
				border: {
					color: getCssColor('--color-text-placeholder', '#AAAAAA')
				},
				ticks: {
					color: getCssColor('--color-text-secondary', '#3D3D3D'),
					autoSkip: false,
					maxRotation: 45,
					minRotation: 45,
					font: {
						family: 'Montserrat',
						size: 11
					}
				}
			},
			y: {
				beginAtZero: true,
				suggestedMax,
				ticks: {
					display: true,
					stepSize: 5,
					color: getCssColor('--color-text-placeholder', '#AAAAAA'),
					font: {
						family: 'Montserrat',
						size: 12
					}
				},
				grid: {
					color: '#E6DADC'
				},
				border: {
					color: getCssColor('--color-text-placeholder', '#AAAAAA')
				}
			}
		}
	};
});
</script>

<template>
	<article class="w-full rounded-lg bg-red-2 px-8 py-6">
		<h2 class="text-2xl font-semibold text-black">
			{{ props.title }}
		</h2>

		<div class="mt-3 h-[250px] w-full">
			<Line :data="chartData" :options="chartOptions" />
		</div>
	</article>
</template>
