<script setup>
import { computed, nextTick, onMounted, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import Table from '../components/Table.vue';
import Searchbar from '../components/Searchbar.vue';
import ConfirmModal from '../components/ConfirmModal.vue';
import Modal from '../components/Modal.vue';
import Button from '../components/Button.vue';
import { useAuthStore } from '../store/auth';

const authStore = useAuthStore();
const route = useRoute();
const activeTab = ref('users');
const focusedRequestId = ref(null);
const searchText = ref('');
const showConfirmation = ref(false);
const pendingRequestAction = ref(null);
const showRoleModal = ref(false);
const selectedUser = ref(null);
const editCargo = ref('CLB');

const columns = [
	{ key: 'name', label: 'Nome', width: '24%' },
	{ key: 'role', label: 'Cargo', width: '28%' },
	{ key: 'email', label: 'Email', width: '38%' },
	{ key: 'actions', label: 'Ações', width: '10%' }
]

const cargoLabels = {
	ADM: 'Administrador',
	TEC: 'Técnico',
	CLB: 'Colaborador'
}
const users = computed(() => authStore.users.map((user) => ({
	id: user.id_user,
	name: user.nome,
	role: cargoLabels[user.cargo] || user.cargo,
	email: user.email
})))
const filteredUsers = computed(() => {
	const query = searchText.value.trim().toLowerCase()

	if (!query) return users.value

	return users.value.filter((user) => [user.name, user.role, user.email]
		.some((value) => value.toLowerCase().includes(query)))
})
const requests = computed(() => authStore.pendingRequests)
const isAdmin = computed(() => authStore.currentUser?.cargo === 'ADM')
const userActions = computed(() => isAdmin.value ? ['edit', 'delete'] : [])

watch(() => [route.query.tab, route.query.requestId], async () => {
	if (route.query.tab === 'requests') activeTab.value = 'requests'
	const requestId = Number(route.query.requestId)
	focusedRequestId.value = Number.isInteger(requestId) && requestId > 0 ? requestId : null

	if (!focusedRequestId.value || !isAdmin.value) return
	await nextTick()
	document.getElementById(`request-${focusedRequestId.value}`)?.scrollIntoView({
		behavior: 'smooth',
		block: 'center'
	})
})

onMounted(async () => {
	if (route.query.tab === 'requests') activeTab.value = 'requests'
	const requestId = Number(route.query.requestId)
	if (Number.isInteger(requestId) && requestId > 0) focusedRequestId.value = requestId

	try {
		await authStore.loadCurrentUser()
		if (isAdmin.value) await authStore.loadAdminData()
	} catch {
		// A API informa a permissão necessária quando a sessão não é administrativa.
	}

	if (focusedRequestId.value) {
		await nextTick()
		document.getElementById(`request-${focusedRequestId.value}`)?.scrollIntoView({
			behavior: 'smooth',
			block: 'center'
		})
	}
})

function handleUserAction({ action, row }) {
	if (action === 'edit') {
		selectedUser.value = row
		const sourceUser = authStore.users.find((user) => user.id_user === row.id)
		editCargo.value = sourceUser?.cargo || 'CLB'
		showRoleModal.value = true
	}
	if (action === 'delete') removeUser(row)
}

async function removeUser(user) {
	try {
		await authStore.removeUser(user.id)
	} catch {
		// A API continua sendo a fonte da verdade.
	}
}

async function saveUserRole() {
	if (!selectedUser.value) return
	try {
		await authStore.updateUserRole(selectedUser.value.id, editCargo.value)
		showRoleModal.value = false
		selectedUser.value = null
	} catch {
		// Mantém o modal aberto para permitir nova tentativa.
	}
}

function approveRequest(request) {
	pendingRequestAction.value = { action: 'approve', request }
	showConfirmation.value = true
}

function rejectRequest(request) {
	pendingRequestAction.value = { action: 'reject', request }
	showConfirmation.value = true
}

async function confirmRequestAction() {
	if (!pendingRequestAction.value) return

	const { action, request } = pendingRequestAction.value
	try {
		if (action === 'approve') {
			await authStore.approveRequest(request.id)
		}
		if (action === 'reject') await authStore.removeRequest(request.id)
	} catch {
		// Mantém a tela estável; a API continua sendo a fonte da verdade.
	}

	pendingRequestAction.value = null
}
</script>

<template>
	<main class="space-y-6 px-8 pb-8 pt-0">
		<nav class="-mx-8 flex gap-6 border-b border-red-1 bg-white px-8" aria-label="Seções de usuários">
			<button type="button" :class="[
				'border-b-2 px-2 pb-2 text-sm',
				activeTab === 'users'
					? 'border-red-primary font-semibold text-red-primary'
					: 'border-transparent text-text-secondary'
			]" :aria-selected="activeTab === 'users'" @click="activeTab = 'users'">
				Usuários cadastrados
			</button>
			<button v-if="isAdmin" type="button" :class="[
				'flex items-center gap-2 border-b-2 px-2 pb-2 text-sm',
				activeTab === 'requests'
					? 'border-red-primary font-semibold text-red-primary'
					: 'border-transparent text-text-secondary'
			]" :aria-selected="activeTab === 'requests'" @click="activeTab = 'requests'">
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

			<Table :columns="columns" :rows="filteredUsers" row-key="id" :actions="userActions"
				@row-action="handleUserAction" />
		</section>

		<div v-else-if="isAdmin && activeTab === 'requests' && requests.length"
			class="overflow-hidden rounded-xl bg-bg-red">
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
					<tr v-for="request in requests" :id="`request-${request.id}`" :key="request.id"
						:class="request.id === focusedRequestId ? 'bg-white outline outline-2 outline-red-primary' : ''">
						<td class="px-3 py-3 text-text-secondary">{{ request.name }}</td>
						<td class="px-3 py-3 text-text-secondary">{{ request.email }}</td>
						<td class="px-3 py-3 text-text-secondary">{{ request.requestedAt }}</td>
						<td class="flex gap-2 px-3 py-2">
							<button type="button"
								class="rounded-lg bg-emerald-600 px-3 py-2 text-xs font-semibold text-white hover:bg-emerald-700"
								@click="approveRequest(request)">
								Aceitar
							</button>
							<button type="button"
								class="rounded-lg bg-white px-3 py-2 text-xs font-semibold text-red-1 hover:bg-red-2"
								@click="rejectRequest(request)">
								Recusar
							</button>
						</td>
					</tr>
				</tbody>
			</table>
		</div>
		<div v-else-if="isAdmin && activeTab === 'requests'"
			class="rounded-xl bg-bg-red px-6 py-10 text-center text-sm text-text-secondary">
			Não há solicitações de entrada pendentes.
		</div>

		<ConfirmModal v-model="showConfirmation" :title="pendingRequestAction?.action === 'approve'
			? 'Aceitar solicitação'
			: 'Recusar solicitação'" :message="pendingRequestAction?.action === 'approve'
				? 'A conta será criada como colaborador.'
				: 'Tem certeza que deseja recusar esta solicitação? Essa ação não pode ser revertida.'" :confirm-text="pendingRequestAction?.action === 'approve'
				? 'Aceitar'
				: 'Recusar'" @confirm="confirmRequestAction" />

		<Modal v-model="showRoleModal" title="Editar cargo" size="sm">
			<label class="flex flex-col gap-2 text-sm font-medium text-text-primary">
				<span>Cargo</span>
				<select v-model="editCargo"
					class="w-full rounded-xl border border-gray-200 bg-gray-50 px-4 py-3 text-sm font-normal text-text-primary outline-none transition focus:border-red-primary focus:bg-white focus:ring-2 focus:ring-red-primary/15">
					<option value="CLB">Colaborador</option>
					<option value="TEC">Técnico</option>
					<option value="ADM">Administrador</option>
				</select>
			</label>
			<template #footer>
				<Button variant="outline" size="sm" @click="showRoleModal = false">Cancelar</Button>
				<Button variant="primary" size="sm" @click="saveUserRole">Salvar</Button>
			</template>
		</Modal>
	</main>
</template>
