<script setup>
import { computed, watch } from 'vue'
import { ArrowLeft, ArrowRight } from 'lucide-vue-next'

const props = defineProps({
	page: {
		type: Number,
		required: true
	},
	pageSize: {
		type: Number,
		required: true
	},
	total: {
		type: Number,
		required: true
	},
	itemLabel: {
		type: String,
		required: true
	}
})

const emit = defineEmits(['update:page', 'update:pageSize'])

const pageCount = computed(() => Math.max(1, Math.ceil(props.total / props.pageSize)))
const firstVisible = computed(() => props.total ? (props.page - 1) * props.pageSize + 1 : 0)
const lastVisible = computed(() => Math.min(props.page * props.pageSize, props.total))

watch(pageCount, (count) => {
	if (props.page > count) emit('update:page', count)
})

function changePageSize(event) {
	emit('update:pageSize', Number(event.target.value))
	emit('update:page', 1)
}
</script>

<template>
	<div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
		<p class="text-sm text-text-secondary" aria-live="polite">
			Mostrando {{ firstVisible }}–{{ lastVisible }} de {{ total }} {{ itemLabel.toLowerCase() }}
		</p>
		<div class="flex flex-wrap items-center justify-between gap-3 sm:justify-end">
			<label class="flex items-center gap-2 text-sm text-text-secondary">
				{{ itemLabel }} por página
				<select :value="pageSize" @change="changePageSize"
					class="rounded-lg bg-white px-2 py-2 text-sm text-text-primary outline-none ring-1 ring-gray-200 focus:ring-red-primary">
					<option :value="5">5</option>
					<option :value="10">10</option>
					<option :value="50">50</option>
					<option :value="100">100</option>
				</select>
			</label>
			<div class="flex items-center gap-2">
				<button type="button" aria-label="Página anterior" title="Página anterior"
					class="flex h-9 w-9 items-center justify-center rounded-lg bg-white text-red-1 ring-1 ring-gray-200 hover:bg-red-2 disabled:cursor-not-allowed disabled:opacity-40"
					:disabled="page === 1" @click="emit('update:page', page - 1)">
					<ArrowLeft :size="16" />
				</button>
				<span class="min-w-20 text-center text-sm text-text-secondary">
					{{ page }} / {{ pageCount }}
				</span>
				<button type="button" aria-label="Próxima página" title="Próxima página"
					class="flex h-9 w-9 items-center justify-center rounded-lg bg-white text-red-1 ring-1 ring-gray-200 hover:bg-red-2 disabled:cursor-not-allowed disabled:opacity-40"
					:disabled="page >= pageCount" @click="emit('update:page', page + 1)">
					<ArrowRight :size="16" />
				</button>
			</div>
		</div>
	</div>
</template>
