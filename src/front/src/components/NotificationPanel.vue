<script setup>
import { X } from 'lucide-vue-next'

// A Navbar ou outra página fornece os dados para manter o painel reutilizável.
// Cada notificação deve ter: id, message e time.
defineProps({
	notifications: {
		type: Array,
		default: () => []
	}
})

// O componente pai decide o que fazer ao fechar ou abrir a lista completa.
const emit = defineEmits(['close', 'view-all'])
</script>

<template>
	<!-- O painel é um popover: fica abaixo do botão, sem bloquear a página inteira. -->
	<section
		class="absolute right-0 top-full z-50 mt-3 w-96 rounded-2xl bg-white p-5 shadow-xl"
		role="dialog"
		aria-label="Notificações"
	>
		<header class="flex items-center justify-between">
			<h2 class="text-lg font-semibold">Notificações</h2>

			<button
				type="button"
				aria-label="Fechar notificações"
				title="Fechar notificações"
				@click="emit('close')"
			>
				<X :size="20" />
			</button>
		</header>

		<div v-if="notifications.length" class="mt-4 divide-y divide-gray-100">
			<!-- v-for cria uma linha para cada item recebido pela prop notifications. -->
			<article
				v-for="notification in notifications"
				:key="notification.id"
				class="py-3 first:pt-0 last:pb-0"
			>
				<p class="text-sm text-text-primary">{{ notification.message }}</p>
				<span class="text-xs text-gray-500">{{ notification.time }}</span>
			</article>
		</div>

		<p v-else class="mt-4 text-sm text-gray-500">
			Nenhuma notificação nova.
		</p>

		<button
			type="button"
			class="mt-5 w-full text-sm font-semibold text-red-primary"
			@click="emit('view-all')"
		>
			Ver todas as notificações
		</button>
	</section>
</template>
