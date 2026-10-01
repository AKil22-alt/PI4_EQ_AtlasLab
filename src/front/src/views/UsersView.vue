<script setup>
import { computed, ref } from 'vue';
import Table from '../components/Table.vue';
import Searchbar from '../components/Searchbar.vue';
import ConfirmModal from '../components/ConfirmModal.vue';
import { useAuthStore } from '../store/auth';

const authStore = useAuthStore();
const activeTab = ref('users');
const searchText = ref('');
const showConfirmation = ref(false);
const pendingRequestAction = ref(null);

const columns = [
	{ key: 'name', label: 'Nome', width: '24%' },
	{ key: 'role', label: 'Cargo', width: '28%' },
	{ key: 'email', label: 'Email', width: '38%' },
	{ key: 'actions', label: 'Ações', width: '10%' }
]

const defaultUsers = [
	{
		id: 1,
		name: 'Thainara',
		role: 'Instrutor',
		email: 'thainaramarques258@gmail.com'
	},
	{
		id: 2,
		name: 'Thainara',
		role: 'Instrutor',
		email: 'thainaramarques258@gmail.com'
	}
]

const users = computed(() => [...defaultUsers, ...authStore.approvedUsers])
const filteredUsers = computed(() => {
	const query = searchText.value.trim().toLowerCase()

	if (!query) return users.value

	return users.value.filter((user) => [user.name, user.role, user.email]
		.some((value) => value.toLowerCase().includes(query)))
})
const requests = computed(() => authStore.pendingRequests)

function approveRequest(request) {
	pendingRequestAction.value = { action: 'approve', request }
	showConfirmation.value = true
}

function rejectRequest(request) {
	pendingRequestAction.value = { action: 'reject', request }
	showConfirmation.value = true
}

function confirmRequestAction() {
	if (!pendingRequestAction.value) return

	const { action, request } = pendingRequestAction.value
	if (action === 'approve') authStore.approveRequest(request.id)
	if (action === 'reject') authStore.removeRequest(request.id)

	pendingRequestAction.value = null
}
</script>

<template>
	<main class="space-y-6 px-8 pb-8 pt-0">
		<nav class="-mx-8 flex gap-6 border-b border-red-1 bg-white px-8" aria-label="Seções de usuários">
			<button
				type="button"
				:class="[
					'border-b-2 px-2 pb-2 text-sm',
					activeTab === 'users'
						? 'border-red-primary font-semibold text-red-primary'
						: 'border-transparent text-text-secondary'
				]"
				:aria-selected="activeTab === 'users'"
				@click="activeTab = 'users'">
				Usuários cadastrados
			</button>
			<button
				type="button"
				:class="[
					'flex items-center gap-2 border-b-2 px-2 pb-2 text-sm',
					activeTab === 'requests'
						? 'border-red-primary font-semibold text-red-primary'
						: 'border-transparent text-text-secondary'
				]"
				:aria-selected="activeTab === 'requests'"
				@click="activeTab = 'requests'">
				Solicitações de entrada
				<span v-if="authStore.requestCount" class="rounded-full bg-red-1 px-2 py-0.5 text-[10px] text-white">
					{{ authStore.requestCount }}
				</span>
			</button>
		</nav>

		<section v-if="activeTab === 'users'" class="space-y-6">
			<div class="flex items-center justify-between gap-4">
				<div class="w-60">
					<Searchbar v-model="searchText" />
				</div>
			</div>

			<Table :columns="columns" :rows="filteredUsers" row-key="id" :actions="['delete']" />
		</section>

		<div v-else-if="requests.length" class="overflow-hidden rounded-xl bg-bg-red">
			<table class="w-full table-fixed text-left text-xs">
				<thead class="bg-red-1 text-white">
					<tr>
						<th class="w-[25%] px-3 py-2 font-semibold">Nome</th>
						<th class="w-[35%] px-3 py-2 font-semibold">Email</th>
						<th class="w-[20%] px-3 py-2 font-semibold">Solicitado em</th>
						<th class="w-[20%] px-3 py-2 font-semibold">Ações</th>
					</tr>
				</thead>
				<tbody>
					<tr v-for="request in requests" :key="request.id">
						<td class="px-3 py-3 text-text-secondary">{{ request.name }}</td>
						<td class="px-3 py-3 text-text-secondary">{{ request.email }}</td>
						<td class="px-3 py-3 text-text-secondary">{{ request.requestedAt }}</td>
						<td class="flex gap-2 px-3 py-2">
							<button type="button" class="rounded-lg bg-emerald-600 px-3 py-2 text-xs font-semibold text-white hover:bg-emerald-700" @click="approveRequest(request)">
								Aceitar
							</button>
							<button type="button" class="rounded-lg bg-white px-3 py-2 text-xs font-semibold text-red-1 hover:bg-red-2" @click="rejectRequest(request)">
								Recusar
							</button>
						</td>
					</tr>
				</tbody>
			</table>
		</div>
		<div v-else class="rounded-xl bg-bg-red px-6 py-10 text-center text-sm text-text-secondary">
			Não há solicitações de entrada pendentes.
		</div>

		<ConfirmModal
			v-model="showConfirmation"
			:title="pendingRequestAction?.action === 'approve' ? 'Aceitar solicitação' : 'Recusar solicitação'"
			:message="pendingRequestAction?.action === 'approve'
				? 'Tem certeza que deseja aceitar esta solicitação?'
				: 'Tem certeza que deseja recusar esta solicitação? Essa ação não pode ser revertida.'"
			:confirm-text="pendingRequestAction?.action === 'approve' ? 'Aceitar' : 'Recusar'"
			@confirm="confirmRequestAction"
		/>
	</main>
</template>
