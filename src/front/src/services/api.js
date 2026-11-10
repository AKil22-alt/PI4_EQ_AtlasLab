import { ref } from 'vue'

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://127.0.0.1:8000/api'
export const apiLoadingCount = ref(0)

export async function apiRequest(path, options = {}) {
    apiLoadingCount.value += 1

    try {
        const token = localStorage.getItem('atlaslab-token')
        const headers = new Headers(options.headers || {})

        if (options.body && !headers.has('Content-Type')) {
            headers.set('Content-Type', 'application/json')
        }

        if (token) {
            headers.set('Authorization', `Token ${token}`)
        }

        const response = await fetch(`${API_BASE_URL}${path}`, {
            ...options,
            headers
        })

        const data = response.status === 204 ? null : await response.json()

        if (!response.ok) {
            const message =
                data?.senha?.[0] ||
                data?.email?.[0] ||
                data?.nome?.[0] ||
                data?.erro ||
                data?.detail ||
                data?.mensagem ||
                'Não foi possível concluir a solicitação.'
            const error = new Error(message)
            error.status = response.status
            throw error
        }

        return data
    } finally {
        apiLoadingCount.value = Math.max(0, apiLoadingCount.value - 1)
    }
}

export function dashboardSummaryRequest() {
    return apiRequest('/dashboard/')
}

export function loginRequest(email, senha) {
    return apiRequest('/auth/login/', {
        method: 'POST',
        body: JSON.stringify({ email, senha })
    })
}

export function registerRequest(nome, email, senha) {
    return apiRequest('/auth/cadastro/', {
        method: 'POST',
        body: JSON.stringify({ nome, email, senha })
    })
}

export function listUsersRequest() {
    return apiRequest('/usuarios/')
}

export function currentUserRequest() {
    return apiRequest('/auth/me/')
}

export function logoutRequest() {
    return apiRequest('/auth/logout/', { method: 'POST' })
}

export function updateUserRoleRequest(userId, cargo) {
    return apiRequest(`/usuarios/${userId}/`, {
        method: 'PATCH',
        body: JSON.stringify({ cargo })
    })
}

export function deleteUserRequest(userId) {
    return apiRequest(`/usuarios/${userId}/`, { method: 'DELETE' })
}

export function listRequestsRequest() {
    return apiRequest('/auth/solicitacoes/')
}

export function listNotificationsRequest() {
    return apiRequest('/auth/notificacoes/')
}

export function markNotificationReadRequest(notificationId) {
    return apiRequest(`/auth/notificacoes/${notificationId}/lida/`, { method: 'POST' })
}

export function approveRequestRequest(requestId) {
    return apiRequest(`/auth/solicitacoes/${requestId}/aprovar/`, {
        method: 'POST'
    })
}

export function rejectRequestRequest(requestId) {
    return apiRequest(`/auth/solicitacoes/${requestId}/`, { method: 'DELETE' })
}

export function listLaboratoriesRequest() {
    return apiRequest('/salas/')
}

export function listLaboratoryResponsiblesRequest() {
    return apiRequest('/usuarios/responsaveis/')
}

export function createLaboratoryRequest(laboratory) {
    return apiRequest('/salas/', {
        method: 'POST',
        body: JSON.stringify(laboratory)
    })
}

export function updateLaboratoryRequest(laboratoryId, laboratory) {
    return apiRequest(`/salas/${laboratoryId}/`, {
        method: 'PATCH',
        body: JSON.stringify(laboratory)
    })
}

export function deleteLaboratoryRequest(laboratoryId) {
    return apiRequest(`/salas/${laboratoryId}/`, {
        method: 'DELETE',
    })
}


export function listAssetsRequest() {
    return apiRequest('/ativos/')
}

export function listServiceOrdersRequest() {
    return apiRequest('/ordens-servico/')
}

export function createServiceOrderRequest(serviceOrder) {
    return apiRequest('/ordens-servico/', {
        method: 'POST',
        body: JSON.stringify(serviceOrder)
    })
}

export function updateServiceOrderRequest(serviceOrderId, serviceOrder) {
    return apiRequest(`/ordens-servico/${serviceOrderId}/`, {
        method: 'PATCH',
        body: JSON.stringify(serviceOrder)
    })
}

export function deleteServiceOrderRequest(serviceOrderId) {
    return apiRequest(`/ordens-servico/${serviceOrderId}/`, {
        method: 'DELETE'
    })
}

export function createAssetRequest(asset) {
    return apiRequest('/ativos/', {
        method: 'POST',
        body: JSON.stringify(asset)
    })
}

export function updateAssetRequest(assetId, asset) {
    return apiRequest(`/ativos/${assetId}/`, {
        method: 'PATCH',
        body: JSON.stringify(asset)
    })
}

export function listAssetGroupsRequest() {
    return apiRequest('/grupos/')
}

export function createAssetGroupRequest(group) {
    return apiRequest('/grupos/', {
        method: 'POST',
        body: JSON.stringify(group)
    })
}

export function updateAssetGroupRequest(groupId, group) {
    return apiRequest(`/grupos/${groupId}/`, {
        method: 'PATCH',
        body: JSON.stringify(group)
    })
}

export function moveAssetRequest(assetId, movement) {
    return apiRequest(`/ativos/${assetId}/movimentar/`, {
        method: 'POST',
        body: JSON.stringify(movement)
    })
}