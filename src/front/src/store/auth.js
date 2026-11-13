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
import {
	approveRequestRequest,
	currentUserRequest,
	deleteUserRequest,
	listAllPagesRequest,
	loginRequest,
	logoutRequest,
	registerRequest,
	rejectRequestRequest,
	updateUserRoleRequest
} from '../services/api'

export const useAuthStore = defineStore('auth', () => {
	const currentUser = ref(null)
	const pendingRequests = ref([])
	const approvedUsers = ref([])
	const users = ref([])
	const requestCount = computed(() => pendingRequests.value.length)
	let currentUserPromise = null

	async function login(email, senha) {
		const data = await loginRequest(email.trim(), senha)
		localStorage.setItem('atlaslab-token', data.token)
		localStorage.removeItem('atlaslab-refresh')
		currentUser.value = data.usuario
		return data.usuario
	}

	async function register(nome, email, senha) {
		return registerRequest(nome.trim(), email.trim().toLowerCase(), senha)
	}

	function clearAuthState() {
		localStorage.removeItem('atlaslab-token')
		localStorage.removeItem('atlaslab-refresh')
		currentUser.value = null
	}

	async function loadCurrentUser() {
		if (!localStorage.getItem('atlaslab-token')) {
			clearAuthState()
			return null
		}

		if (!currentUserPromise) {
			currentUserPromise = currentUserRequest()
				.then((user) => {
					currentUser.value = user
					return user
				})
				.catch((error) => {
					if (error.status === 401) clearAuthState()
					throw error
				})
				.finally(() => {
					currentUserPromise = null
				})
		}

		return currentUserPromise
	}

	async function loadAdminData() {
		const [loadedUsers, loadedRequests] = await Promise.all([
			listAllPagesRequest('/usuarios/'),
			listAllPagesRequest('/auth/solicitacoes/')
		])
		users.value = loadedUsers
			.slice()
			.sort((first, second) => second.id_user - first.id_user)
		pendingRequests.value = loadedRequests
			.slice()
			.sort((first, second) => new Date(second.criada_em) - new Date(first.criada_em))
			.map((request) => ({
			id: request.id,
			name: request.nome,
			email: request.email,
			requestedAt: new Date(request.criada_em).toLocaleDateString('pt-BR')
			}))
	}

	async function approveRequest(requestId) {
		await approveRequestRequest(requestId)
		await loadAdminData()
	}

	async function removeRequest(requestId) {
		await rejectRequestRequest(requestId)
		await loadAdminData()
	}

	async function updateUserRole(userId, cargo) {
		await updateUserRoleRequest(userId, cargo)
		await loadAdminData()
	}

	async function removeUser(userId) {
		await deleteUserRequest(userId)
		await loadAdminData()
	}

	async function logout() {
		try {
			if (localStorage.getItem('atlaslab-token')) await logoutRequest()
		} catch (error) {
			console.error('Erro ao revogar a sessão no servidor:', error)
		} finally {
			clearAuthState()
		}
	}

	return {
		currentUser,
		pendingRequests,
		approvedUsers,
		requestCount,
		login,
		register,
		loadCurrentUser,
		loadAdminData,
		approveRequest,
		removeRequest,
		updateUserRole,
		removeUser,
		users,
		logout
	}
})