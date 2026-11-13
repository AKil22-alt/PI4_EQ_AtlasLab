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
const emit = defineEmits(['close', 'mark-read', 'select', 'view-all'])
</script>

<template>
	<!-- O painel é um popover: fica abaixo do botão, sem bloquear a página inteira. -->
	<section class="absolute right-0 top-full z-50 mt-3 w-96 rounded-2xl bg-white p-5 pt-10 shadow-xl" role="dialog"
		aria-label="Notificações">
		<header class="flex items-center justify-between">
			<h2 class="text-lg font-semibold">Notificações</h2>

			<button type="button" aria-label="Fechar notificações" title="Fechar notificações" @click="emit('close')">
				<X :size="20" />
			</button>
		</header>

		<div v-if="notifications.length" class="mt-4 max-h-[60vh] divide-y divide-gray-100 overflow-y-auto pr-1">
			<!-- v-for cria uma linha para cada item recebido pela prop notifications. -->
			<article v-for="notification in notifications" :key="notification.id"
				:class="['rounded-lg py-3 first:pt-0 last:pb-0', !notification.lida && 'bg-bg-red px-3']">
				<button type="button" class="block w-full text-left hover:text-red-primary"
					@click="emit('select', notification)">
					<p class="text-sm text-text-primary">{{ notification.message }}</p>
					<span class="text-xs text-gray-500">{{ notification.time }}</span>
				</button>
				<button v-if="!notification.lida" type="button"
					class="mt-2 text-xs font-semibold text-red-primary hover:underline"
					@click="emit('mark-read', notification)">
					Marcar como lida
				</button>
				<span v-else class="mt-2 block text-xs text-gray-500">Lida</span>
			</article>
		</div>

		<p v-else class="mt-4 text-sm text-gray-500">
			Nenhuma notificação.
		</p>

		<button type="button" class="mt-5 w-full text-sm font-semibold text-red-primary" @click="emit('view-all')">
			Ver todas as notificações
		</button>
	</section>
</template>
