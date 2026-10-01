/* 
(Pinia)
A pasta store serve para guardar estado global da aplicação, 
ou seja, dados usados por várias páginas e componentes.

Exemplos para o seu projeto:

usuário logado;
token de autenticação;
permissões do usuário;
estado aberto/fechado da Sidebar;
filtros compartilhados;
dados carregados e reutilizados em várias telas.
*/

import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

const STORAGE_KEY = 'atlaslab-entry-requests'
const APPROVED_STORAGE_KEY = 'atlaslab-approved-users'

function loadRequests() {
	try {
		return JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]')
	} catch {
		return []
	}
}

function loadApprovedUsers() {
	try {
		return JSON.parse(localStorage.getItem(APPROVED_STORAGE_KEY) || '[]')
	} catch {
		return []
	}
}

export const useAuthStore = defineStore('auth', () => {
	const pendingRequests = ref(loadRequests())
	const approvedUsers = ref(loadApprovedUsers())
	const currentUser = ref(null)
	const requestCount = computed(() => pendingRequests.value.length)

	function persistRequests() {
		localStorage.setItem(STORAGE_KEY, JSON.stringify(pendingRequests.value))
	}

	function persistApprovedUsers() {
		localStorage.setItem(APPROVED_STORAGE_KEY, JSON.stringify(approvedUsers.value))
	}

	function requestEntry({ name, email }) {
		const normalizedEmail = email.trim().toLowerCase()
		if (pendingRequests.value.some((request) => request.email === normalizedEmail)) return false

		pendingRequests.value.push({
			id: Date.now(),
			name: name.trim() || normalizedEmail.split('@')[0],
			email: normalizedEmail,
			requestedAt: new Date().toLocaleDateString('pt-BR')
		})
		persistRequests()
		return true
	}

	function removeRequest(requestId) {
		const requestIndex = pendingRequests.value.findIndex(({ id }) => id === requestId)
		if (requestIndex === -1) return

		pendingRequests.value.splice(requestIndex, 1)
		persistRequests()
	}

	function approveRequest(requestId) {
		const requestIndex = pendingRequests.value.findIndex(({ id }) => id === requestId)
		if (requestIndex === -1) return

		const [request] = pendingRequests.value.splice(requestIndex, 1)
		approvedUsers.value.push(request)
		persistRequests()
		persistApprovedUsers()
	}

	function isApproved(email) {
		return approvedUsers.value.some((user) => user.email === email.trim().toLowerCase())
	}

	return {
		currentUser,
		pendingRequests,
		approvedUsers,
		requestCount,
		requestEntry,
		removeRequest,
		approveRequest,
		isApproved
	}
})