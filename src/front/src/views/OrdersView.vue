<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import Table from '../components/Table.vue'
import Button from '../components/Button.vue'
import Searchbar from '../components/Searchbar.vue'
import Modal from '../components/Modal.vue'
import ConfirmModal from '../components/ConfirmModal.vue'
import PaginationControls from '../components/PaginationControls.vue'
import { ArrowLeft, Check, Pencil, Play, Plus, X } from 'lucide-vue-next'
import { useAuthStore } from '../store/auth'
import {
	createServiceOrderRequest,
	deleteServiceOrderRequest,
	listAssetGroupsRequest,
	listAssetsRequest,
	listLaboratoriesRequest,
	listLaboratoryResponsiblesRequest,
	listAllPagesRequest,
	updateServiceOrderRequest
} from '../services/api'

const columns = [
	{ key: 'number', label: 'Nº da OS', width: '10%' },
	{ key: 'openingDate', label: 'Data de Abertura', width: '15%' },
	{ key: 'conclusionDate', label: 'Data de Conclusão', width: '15%' },
	{ key: 'sector', label: 'Setor', width: '14%' },
	{ key: 'lab', label: 'Laboratório', width: '12%' },
	{ key: 'responsible', label: 'Responsável', width: '14%' },
	{ key: 'status', label: 'Status', width: '10%', type: 'status' },
	{ key: 'description', label: 'Descrição', width: '10%' },
	{ key: 'actions', label: 'Ações', width: '112px', type: 'actions' }
]

const rows = reactive([])
const laboratories = reactive([])
const assetGroups = reactive([])
const assets = reactive([])
const responsibles = reactive([])
const isLoadingOrders = ref(false)
const isLoadingOptions = ref(false)
const isSaving = ref(false)
const ordersError = ref('')
const formError = ref('')
const optionsError = ref('')

const statusLabels = {
	ABERTA: 'Aberto',
	EM_ANDAMENTO: 'Em andamento',
	CONCLUIDA: 'Concluído',
	CANCELADA: 'Cancelado'
}
const authStore = useAuthStore()
const route = useRoute()
const canManageOrders = computed(() => ['ADM', 'TEC'].includes(authStore.currentUser?.cargo))

function mapServiceOrder(order) {
	const assets = order.ativos_detalhes || []
	const rooms = order.salas_detalhes || []
	const responsible = order.responsavel_detalhes
	const sectors = assets
		.map((asset) => asset.grupo_detalhes?.setor)
		.filter(Boolean)

	return {
		id: order.id_ordem,
		number: String(order.id_ordem).padStart(5, '0'),
		title: order.titulo,
		labId: rooms[0]?.id_sala || '',
		assetId: assets[0]?.id_ativos || '',
		sectorValue: assets[0]?.grupo_detalhes?.setor || '',
		statusValue: order.status,
		openingDate: formatDate(order.data_hora?.slice(0, 10)),
		conclusionDate: order.data_termino ? formatDate(order.data_termino) : '',
		sector: [...new Set(sectors)].join(', ') || '—',
		lab: rooms.map((room) => room.localizacao || room.nome).join(', ') || '—',
		responsibleId: order.responsavel || '',
		responsible: responsible?.nome || 'Não informado',
		status: statusLabels[order.status] || order.status,
		description: order.descricao,
		completionDescription: order.descricao_conclusao || ''
	}
}

async function loadOrders() {
	isLoadingOrders.value = true
	ordersError.value = ''

	try {
		const orders = await listAllPagesRequest('/ordens-servico/')
		const newestFirst = orders.map(mapServiceOrder).sort((first, second) => second.id - first.id)
		rows.splice(0, rows.length, ...newestFirst)
	} catch (error) {
		ordersError.value = error.message || 'Não foi possível carregar as ordens de serviço.'
	} finally {
		isLoadingOrders.value = false
	}
}

function responseItems(response) {
	return Array.isArray(response) ? response : response.results || []
}

async function loadFormOptions() {
	isLoadingOptions.value = true
	optionsError.value = ''

	try {
		const requests = [
			listLaboratoriesRequest(),
			listAssetGroupsRequest(),
			listAssetsRequest()
		]
		if (canManageOrders.value) requests.push(listLaboratoryResponsiblesRequest())
		const [labResponse, groupResponse, assetResponse, responsibleResponse] = await Promise.all(requests)
		laboratories.splice(0, laboratories.length, ...responseItems(labResponse))
		assetGroups.splice(0, assetGroups.length, ...responseItems(groupResponse))
		assets.splice(0, assets.length, ...responseItems(assetResponse))
		if (responsibleResponse) responsibles.splice(0, responsibles.length, ...responseItems(responsibleResponse))
	} catch (error) {
		optionsError.value = error.message || 'Não foi possível carregar laboratórios, setores e ativos.'
	} finally {
		isLoadingOptions.value = false
	}
}

onMounted(async () => {
	await Promise.all([loadOrders(), loadFormOptions()])
	const orderId = Number(route.query.orderId)
	const order = rows.find((item) => item.id === orderId)
	if (order) {
		selectedOrder.value = order
		showDetailsModal.value = true
	}
})
const showCreateModal = ref(false)
const showDetailsModal = ref(false)
const selectedOrder = ref(null)
const editingOrderId = ref(null)
const showConfirmation = ref(false)
const confirmationAction = ref(null)
const statusActionError = ref('')
const completionDescription = ref('')
const isUpdatingStatus = ref(false)
const actionError = ref('')
const searchText = ref('')
const activeTab = ref('all')
const filters = reactive({ number: '', sector: '', lab: '' })
const ordersPageSize = ref(10)
const ordersCurrentPage = ref(1)
const orderForm = reactive({
	number: '', openingDate: '', conclusionDate: '', title: '', sector: '', lab: '', asset: '', responsible: '', status: 'ABERTA', description: ''
})

const orderTabs = [
	{ key: 'all', label: 'Todas', status: '' },
	{ key: 'open', label: 'Abertas', status: 'ABERTA' },
	{ key: 'inProgress', label: 'Em andamento', status: 'EM_ANDAMENTO' },
	{ key: 'completed', label: 'Concluídas', status: 'CONCLUIDA' }
]

const isEditing = computed(() => editingOrderId.value !== null)

const numberOptions = computed(() => [...new Set(rows.map((row) => row.number))])
const sectorOptions = computed(() => [...new Set(rows.map((row) => row.sector))])
const labOptions = computed(() => [...new Set(rows.map((row) => row.lab))])
const formSectorOptions = computed(() => [...new Set(assetGroups.map((group) => group.setor).filter(Boolean))].sort())
const formAssetOptions = computed(() => assets.filter((asset) =>
	asset.status !== false && asset.grupo_detalhes?.setor === orderForm.sector
))

const filteredRows = computed(() => {
	const query = searchText.value.trim().toLowerCase()
	const selectedTab = orderTabs.find((tab) => tab.key === activeTab.value)

	return rows.filter((row) => {
		const matchesSearch = !query || Object.values(row).some((value) => String(value).toLowerCase().includes(query))
		return (!selectedTab?.status || row.statusValue === selectedTab.status)
			&& matchesSearch
			&& (!filters.number || row.number === filters.number)
			&& (!filters.sector || row.sector === filters.sector)
			&& (!filters.lab || row.lab === filters.lab)
	})
})
const paginatedOrderRows = computed(() => {
	const start = (ordersCurrentPage.value - 1) * ordersPageSize.value
	return filteredRows.value.slice(start, start + ordersPageSize.value)
})

watch([filteredRows, ordersPageSize], () => {
	ordersCurrentPage.value = 1
})

function clearFilters() {
	searchText.value = ''
	filters.number = ''
	filters.sector = ''
	filters.lab = ''
}

function resetOrderForm() {
	orderForm.number = ''
	orderForm.openingDate = ''
	orderForm.conclusionDate = ''
	orderForm.title = ''
	orderForm.sector = ''
	orderForm.lab = ''
	orderForm.asset = ''
	orderForm.responsible = ''
	orderForm.status = 'ABERTA'
	orderForm.description = ''
	formError.value = ''
}

function openCreateForm() {
	resetOrderForm()
	editingOrderId.value = null
	orderForm.openingDate = getTodayInputValue()
	showCreateModal.value = true
}

function getTodayInputValue() {
	const today = new Date()
	const year = today.getFullYear()
	const month = String(today.getMonth() + 1).padStart(2, '0')
	const day = String(today.getDate()).padStart(2, '0')

	return `${year}-${month}-${day}`
}

function handleSectorChange() {
	orderForm.asset = ''
}

function requestStatusAction(action) {
	statusActionError.value = ''
	if (action === 'finish') completionDescription.value = ''
	requestConfirmation(action)
}

function formatDate(date) {
	if (!date) return ''

	const [year, month, day] = date.split('-')
	return `${day}/${month}/${year}`
}

function toInputDate(date) {
	if (!date) return ''

	const [day, month, year] = date.split('/')
	return `${year}-${month}-${day}`
}

function openEditForm(order) {
	selectedOrder.value = null
	showDetailsModal.value = false
	editingOrderId.value = order.id
	orderForm.number = order.number
	orderForm.openingDate = toInputDate(order.openingDate)
	orderForm.conclusionDate = toInputDate(order.conclusionDate)
	orderForm.title = order.title || ''
	orderForm.sector = order.sectorValue || order.sector
	orderForm.lab = order.labId ? String(order.labId) : ''
	orderForm.asset = order.assetId ? String(order.assetId) : ''
	orderForm.responsible = order.responsibleId ? String(order.responsibleId) : ''
	orderForm.status = order.statusValue || 'ABERTA'
	orderForm.description = order.description
	showCreateModal.value = true
}

function createOrder() {
	if (!orderForm.title.trim() || !orderForm.openingDate || !orderForm.description.trim() || !orderForm.sector || !orderForm.lab || !orderForm.asset || !orderForm.status) {
		formError.value = 'Preencha título, início, descrição, setor, ativo, laboratório e status.'
		return
	}
	if (isEditing.value) {
		requestConfirmation('save')
		return
	}

	return submitNewOrder()
}

async function submitOrderChanges() {
	isSaving.value = true
	formError.value = ''

	try {
		const updatedOrder = await updateServiceOrderRequest(editingOrderId.value, {
			titulo: orderForm.title.trim(),
			descricao: orderForm.description.trim(),
			data_termino: orderForm.conclusionDate || null,
			status: orderForm.status,
			responsavel: orderForm.responsible ? Number(orderForm.responsible) : null,
			sala_ids: [Number(orderForm.lab)],
			ativo_ids: [Number(orderForm.asset)]
		})
		const updatedRow = mapServiceOrder(updatedOrder)
		const rowIndex = rows.findIndex((row) => row.id === editingOrderId.value)
		if (rowIndex !== -1) rows.splice(rowIndex, 1, updatedRow)
		showCreateModal.value = false
		editingOrderId.value = null
		resetOrderForm()
	} catch (error) {
		formError.value = error.message || 'Não foi possível salvar as alterações da ordem.'
	} finally {
		isSaving.value = false
	}
}

async function submitNewOrder() {
	isSaving.value = true
	formError.value = ''

	try {
		await createServiceOrderRequest({
			titulo: orderForm.title.trim(),
			descricao: orderForm.description.trim(),
			data_hora: `${orderForm.openingDate}T00:00:00`,
			data_termino: orderForm.conclusionDate || null,
			status: orderForm.status,
			...(orderForm.responsible ? { responsavel: Number(orderForm.responsible) } : {}),
			sala_ids: [Number(orderForm.lab)],
			ativo_ids: [Number(orderForm.asset)]
		})
		await loadOrders()
		showCreateModal.value = false
		editingOrderId.value = null
		resetOrderForm()
	} catch (error) {
		formError.value = error.message || 'Não foi possível criar a ordem de serviço.'
	} finally {
		isSaving.value = false
	}
}

function cancelForm() {
	showCreateModal.value = false
	editingOrderId.value = null
	resetOrderForm()
}

function requestConfirmation(action) {
	confirmationAction.value = action
	showConfirmation.value = true
}

function requestDeleteOrder(order) {
	selectedOrder.value = order
	actionError.value = ''
	requestConfirmation('delete')
}

async function confirmOrderAction() {
	if (isUpdatingStatus.value) return

	const action = confirmationAction.value

	if (action === 'save') {
		await submitOrderChanges()
		confirmationAction.value = null
		return
	}

	if (action === 'delete' && selectedOrder.value) {
		try {
			await deleteServiceOrderRequest(selectedOrder.value.id)
			const rowIndex = rows.findIndex((row) => row.id === selectedOrder.value.id)
			if (rowIndex !== -1) rows.splice(rowIndex, 1)
			selectedOrder.value = null
		} catch (error) {
			actionError.value = error.message || 'Não foi possível excluir a ordem de serviço.'
		}
		confirmationAction.value = null
		return
	}

	const nextStatus = {
		start: 'EM_ANDAMENTO',
		finish: 'CONCLUIDA',
		cancel: 'CANCELADA'
	}[action]

	if (action === 'finish' && !completionDescription.value.trim()) {
		statusActionError.value = 'Descreva o que foi feito antes de finalizar a ordem.'
		return
	}

	if (nextStatus && selectedOrder.value) {
		isUpdatingStatus.value = true
		statusActionError.value = ''

		try {
			const updatedOrder = await updateServiceOrderRequest(selectedOrder.value.id, {
				status: nextStatus,
				...(action === 'finish' ? { descricao_conclusao: completionDescription.value.trim() } : {})
			})
			const updatedRow = mapServiceOrder(updatedOrder)
			const rowIndex = rows.findIndex((row) => row.id === selectedOrder.value.id)
			if (rowIndex !== -1) rows.splice(rowIndex, 1, updatedRow)
			selectedOrder.value = updatedRow
			if (action === 'finish') showConfirmation.value = false
		} catch (error) {
			statusActionError.value = error.message || 'Não foi possível atualizar o status da ordem.'
		} finally {
			isUpdatingStatus.value = false
		}
	}

	confirmationAction.value = null
}

function handleRowAction({ action, row }) {
	if (action === 'view') {
		selectedOrder.value = row
		showDetailsModal.value = true
	} else if (action === 'edit') {
		openEditForm(row)
	} else if (action === 'delete') {
		requestDeleteOrder(row)
	}
}
</script>
<template>
	<main class="space-y-6 px-8 pb-8 pt-6">
		<section class="space-y-6" aria-labelledby="orders-title">
			<div class="flex justify-end">
				<Button v-if="!showCreateModal" @click="openCreateForm" variant="primary" size="sm">
					<Plus :size="18" />
					Criar Ordem
				</Button>
			</div>

			<div v-if="!showCreateModal" class="space-y-6">
				<nav class="-mx-8 flex gap-6 border-b border-red-1 bg-white px-8"
					aria-label="Filtrar ordens por status">
					<button v-for="tab in orderTabs" :key="tab.key" type="button" :aria-pressed="activeTab === tab.key"
						:class="[
							'border-b-2 px-2 pb-2 text-sm transition-colors',
							activeTab === tab.key
								? 'border-red-primary font-semibold text-red-primary'
								: 'border-transparent text-text-secondary hover:text-text-primary'
						]" @click="activeTab = tab.key">
						{{ tab.label }}
					</button>
				</nav>

				<div class="flex flex-wrap items-end gap-3">
					<div class="w-60">
						<Searchbar v-model="searchText" />
					</div>

					<label class="flex min-w-36 flex-1 flex-col gap-2 text-sm text-text-primary">
						Nº da OS
						<select v-model="filters.number"
							class="rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-gray-200 focus:ring-red-primary">
							<option value="">Selecione</option>
							<option v-for="number in numberOptions" :key="number" :value="number">
								{{ number }}
							</option>
						</select>
					</label>

					<label class="flex min-w-36 flex-1 flex-col gap-2 text-sm text-text-primary">
						Setor
						<select v-model="filters.sector"
							class="rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-gray-200 focus:ring-red-primary">
							<option value="">Selecione</option>
							<option v-for="sector in sectorOptions" :key="sector" :value="sector">
								{{ sector }}
							</option>
						</select>
					</label>

					<label class="flex min-w-36 flex-1 flex-col gap-2 text-sm text-text-primary">
						Laboratório
						<select v-model="filters.lab"
							class="rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-gray-200 focus:ring-red-primary">
							<option value="">Selecione</option>
							<option v-for="lab in labOptions" :key="lab" :value="lab">
								{{ lab }}
							</option>
						</select>
					</label>

					<Button variant="outline" size="sm" @click="clearFilters">
						Limpar filtros
					</Button>
				</div>

				<p v-if="isLoadingOrders" class="py-8 text-center text-sm text-text-secondary" role="status">
					Carregando ordens de serviço...
				</p>
				<div v-else-if="ordersError" class="space-y-3 py-8 text-center" role="alert">
					<p class="text-sm text-red-primary">{{ ordersError }}</p>
					<Button variant="outline" size="sm" @click="loadOrders">Tentar novamente</Button>
				</div>
				<p v-else-if="filteredRows.length === 0" class="py-8 text-center text-sm text-text-secondary">
					Nenhuma ordem de serviço encontrada.
				</p>
				<p v-if="actionError" class="text-sm text-red-primary" role="alert">{{ actionError }}</p>
				<Table v-if="!isLoadingOrders && !ordersError && filteredRows.length > 0" :columns="columns"
					:rows="paginatedOrderRows" row-key="id" :actions="canManageOrders ? ['view', 'edit', 'delete'] : ['view']"
					@row-action="handleRowAction" />
				<PaginationControls v-if="!isLoadingOrders && !ordersError && filteredRows.length > 0"
					v-model:page="ordersCurrentPage" v-model:page-size="ordersPageSize" :total="filteredRows.length"
					item-label="Ordens" />
			</div>

			<div v-else class="space-y-6 rounded-lg bg-bg px-8 py-2">
				<div class="-mt-2 space-y-4">
					<button type="button"
						class="inline-flex items-center gap-1 text-sm font-medium text-red-primary hover:underline"
						@click="cancelForm">
						<ArrowLeft :size="16" />
						Voltar
					</button>
					<h2 class="text-lg font-semibold text-text-primary">
						{{ isEditing ? 'Editar Ordem de Serviço' : 'Criar Ordem de Serviço' }}
					</h2>
				</div>

				<div v-if="isLoadingOptions" class="py-2 text-sm text-text-secondary" role="status">
					Carregando laboratórios e setores...
				</div>
				<div v-if="optionsError" class="space-y-2" role="alert">
					<p class="text-sm text-red-primary">{{ optionsError }}</p>
					<Button variant="outline" size="sm" :disabled="isLoadingOptions" @click="loadFormOptions">
						Tentar carregar opções novamente
					</Button>
				</div>

				<div v-if="isEditing" class="space-y-2">
					<label for="order-number" class="text-xs font-medium text-text-primary">Nº da OS <span
							class="text-red-primary">*</span></label>
					<input id="order-number" v-model="orderForm.number" type="text" required disabled
						class="w-full cursor-not-allowed rounded-lg bg-gray-300 px-3 py-3 text-sm text-gray-600 outline-none" />
				</div>

				<div class="grid grid-cols-1 gap-5 md:grid-cols-2">
					<div class="space-y-2">
						<label for="order-opening-date" class="text-xs font-medium text-text-primary">Data de início
							<span class="text-red-primary">*</span></label>
						<input id="order-opening-date" v-model="orderForm.openingDate" type="date" required
							:disabled="isEditing"
							class="w-full rounded-lg bg-white px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary disabled:cursor-not-allowed disabled:bg-gray-300 disabled:text-gray-600" />
					</div>
					<div class="space-y-2">
						<label for="order-conclusion-date" class="text-xs font-medium text-text-primary">Data de
							término</label>
						<input id="order-conclusion-date" v-model="orderForm.conclusionDate" type="date"
							class="w-full rounded-lg bg-white px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
					</div>
				</div>

				<div class="space-y-2">
					<label for="order-title" class="text-xs font-medium text-text-primary">Título <span
							class="text-red-primary">*</span></label>
					<input id="order-title" v-model="orderForm.title" type="text" maxlength="100" required
						placeholder="Ex.: Manutenção de equipamento"
						class="w-full rounded-lg bg-white px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
				</div>

				<div class="space-y-2">
					<label for="order-sector" class="text-xs font-medium text-text-primary">Setor <span
							class="text-red-primary">*</span></label>
					<select id="order-sector" v-model="orderForm.sector" required
						:disabled="isLoadingOptions || Boolean(optionsError)"
						class="w-full rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary"
						@change="handleSectorChange">
						<option value="">Selecione</option>
						<option v-for="sector in formSectorOptions" :key="sector" :value="sector">{{ sector }}</option>
					</select>
				</div>

				<div class="space-y-2">
					<label for="order-asset" class="text-xs font-medium text-text-primary">Ativo do setor <span
							class="text-red-primary">*</span></label>
					<select id="order-asset" v-model="orderForm.asset" required
						:disabled="!orderForm.sector || isLoadingOptions || Boolean(optionsError)"
						class="w-full rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
						<option value="">{{ orderForm.sector ? 'Selecione um ativo' : 'Selecione primeiro um setor' }}
						</option>
						<option v-for="asset in formAssetOptions" :key="asset.id_ativos"
							:value="String(asset.id_ativos)">
							{{ asset.nome }}
						</option>
					</select>
					<p v-if="orderForm.sector && !formAssetOptions.length && !isLoadingOptions"
						class="text-xs text-text-secondary">
						Não há ativos ativos cadastrados neste setor.
					</p>
				</div>

				<div class="space-y-2">
					<label for="order-lab" class="text-xs font-medium text-text-primary">Laboratório <span
							class="text-red-primary">*</span></label>
					<select id="order-lab" v-model="orderForm.lab" required
						:disabled="isLoadingOptions || Boolean(optionsError)"
						class="w-full rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
						<option value="">Selecione</option>
						<option v-for="lab in laboratories" :key="lab.id_sala" :value="String(lab.id_sala)">
							{{ lab.localizacao }} - {{ lab.nome }}
						</option>
					</select>
				</div>

				<div v-if="canManageOrders" class="space-y-2">
					<label for="order-responsible" class="text-xs font-medium text-text-primary">Responsável</label>
					<select id="order-responsible" v-model="orderForm.responsible"
						:disabled="isLoadingOptions || Boolean(optionsError)"
						class="w-full rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
						<option value="">Não atribuído</option>
						<option v-for="responsible in responsibles" :key="responsible.id_user"
							:value="String(responsible.id_user)">
							{{ responsible.nome }}
						</option>
					</select>
				</div>

				<div class="space-y-2">
					<label for="order-status" class="text-xs font-medium text-text-primary">Status <span
							class="text-red-primary">*</span></label>
					<select id="order-status" v-model="orderForm.status"
						class="w-full rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
						<option value="">Selecione</option>
						<option value="ABERTA">Aberta</option>
						<option value="EM_ANDAMENTO">Em andamento</option>
						<option value="CANCELADA">Cancelada</option>
					</select>
				</div>

				<div class="space-y-2">
					<label for="order-description" class="text-xs font-medium text-text-primary">Descrição <span
							class="text-red-primary">*</span></label>
					<textarea id="order-description" v-model="orderForm.description" rows="5"
						placeholder="Descreva com detalhes o serviço"
						class="w-full resize-none rounded-lg bg-white px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary"></textarea>
				</div>

				<p v-if="formError" class="text-sm text-red-primary" role="alert">{{ formError }}</p>

				<div class="flex items-center justify-between pt-8">
					<Button variant="outline" @click="cancelForm">Cancelar</Button>
					<Button variant="primary" :disabled="isSaving || isLoadingOptions || Boolean(optionsError)"
						@click="createOrder">
						{{ isSaving ? 'Criando...' : isEditing ? 'Salvar' : 'Criar Ordem' }}
					</Button>
				</div>
			</div>

			<Modal v-model="showDetailsModal" title="Detalhes da OS" size="md">
				<div v-if="selectedOrder" class="space-y-5 border-t border-red-primary pt-4">
					<dl class="space-y-4 text-sm">
						<div class="flex items-start justify-between gap-6">
							<dt class="font-medium text-text-primary">Nº da OS</dt>
							<dd class="text-right text-text-secondary">{{ selectedOrder.number }}</dd>
						</div>
						<div class="flex items-start justify-between gap-6">
							<dt class="font-medium text-text-primary">Data de Abertura</dt>
							<dd class="text-right text-text-secondary">{{ selectedOrder.openingDate }}</dd>
						</div>
						<div class="flex items-start justify-between gap-6">
							<dt class="font-medium text-text-primary">Data de Conclusão</dt>
							<dd class="text-right text-text-secondary">{{ selectedOrder.conclusionDate || '-' }}</dd>
						</div>
						<div class="flex items-start justify-between gap-6">
							<dt class="font-medium text-text-primary">Setor</dt>
							<dd class="text-right text-text-secondary">{{ selectedOrder.sector }}</dd>
						</div>
						<div class="flex items-start justify-between gap-6">
							<dt class="font-medium text-text-primary">Laboratório</dt>
							<dd class="text-right text-text-secondary">{{ selectedOrder.lab }}</dd>
						</div>
						<div class="flex items-start justify-between gap-6">
							<dt class="font-medium text-text-primary">Status</dt>
							<dd class="text-right text-text-secondary">{{ selectedOrder.status }}</dd>
						</div>
						<div class="flex items-start justify-between gap-6">
							<dt class="font-medium text-text-primary">Responsável</dt>
							<dd class="text-right text-text-secondary">{{ selectedOrder.responsible }}</dd>
						</div>
						<div class="space-y-2">
							<dt class="font-medium text-text-primary">Descrição do serviço</dt>
							<dd class="text-text-secondary">{{ selectedOrder.description }}</dd>
						</div>
						<div v-if="selectedOrder.completionDescription" class="space-y-2">
							<dt class="font-medium text-text-primary">Serviço realizado</dt>
							<dd class="text-text-secondary">{{ selectedOrder.completionDescription }}</dd>
						</div>
					</dl>
				</div>
				<p v-if="statusActionError" class="mt-4 text-sm text-red-primary" role="alert">
					{{ statusActionError }}
				</p>

				<template #footer
					v-if="canManageOrders && ['ABERTA', 'EM_ANDAMENTO'].includes(selectedOrder?.statusValue)">
					<div class="flex w-full flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
						<Button variant="outline" size="sm" class="self-start" @click="openEditForm(selectedOrder)">
							<Pencil :size="16" />
							Editar
						</Button>
						<div class="flex flex-wrap gap-2 sm:justify-end">
							<Button v-if="selectedOrder.statusValue === 'ABERTA'" variant="primary" size="sm"
								:disabled="isUpdatingStatus" @click="requestStatusAction('start')">
								<Play :size="16" fill="currentColor" />
								Iniciar
							</Button>
							<template v-else>
								<Button variant="outline" size="sm" :disabled="isUpdatingStatus"
									@click="requestStatusAction('cancel')">
									<X :size="16" />
									Cancelar ordem
								</Button>
								<Button variant="primary" size="sm" :disabled="isUpdatingStatus"
									@click="requestStatusAction('finish')">
									<Check :size="16" />
									Finalizar
								</Button>
							</template>
						</div>
					</div>
				</template>
			</Modal>

			<ConfirmModal v-model="showConfirmation" :title="{
				start: 'Iniciar OS',
				finish: 'Finalizar OS',
				cancel: 'Cancelar OS',
				save: 'Salvar alterações',
				delete: 'Excluir OS'
			}[confirmationAction]" :message="{
					start: 'Deseja iniciar esta Ordem de Serviço?',
					finish: 'Deseja finalizar esta Ordem de Serviço?',
					cancel: 'Deseja cancelar esta Ordem de Serviço?',
					save: 'Tem certeza que deseja salvar as alterações desta Ordem de Serviço?',
					delete: 'Tem certeza que deseja excluir esta Ordem de Serviço? Essa ação não pode ser revertida.'
				}[confirmationAction]" :confirm-text="{
					start: 'Iniciar',
					finish: 'Finalizar',
					cancel: 'Cancelar ordem',
					save: 'Salvar',
					delete: 'Excluir'
				}[confirmationAction]" :close-on-confirm="confirmationAction !== 'finish'"
					@confirm="confirmOrderAction">
					<template v-if="confirmationAction === 'finish'">
						<label for="completion-description" class="block text-sm font-medium text-text-primary">
							Descreva o que foi feito <span class="text-red-primary">*</span>
						</label>
						<textarea id="completion-description" v-model="completionDescription" rows="4" required
							placeholder="Informe os serviços realizados"
							class="mt-2 w-full resize-y rounded-lg bg-white px-3 py-3 text-sm text-text-primary outline-none ring-1 ring-gray-200 transition focus:ring-red-primary"></textarea>
						<p v-if="statusActionError" class="mt-2 text-sm text-red-primary" role="alert">
							{{ statusActionError }}
						</p>
					</template>
				</ConfirmModal>
		</section>
	</main>
</template>
