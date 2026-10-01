<script setup>
import { computed, reactive, ref } from 'vue'
import Table from '../components/Table.vue'
import Button from '../components/Button.vue'
import Searchbar from '../components/Searchbar.vue'
import Modal from '../components/Modal.vue'
import ConfirmModal from '../components/ConfirmModal.vue'
import { Pencil, Play, Plus } from 'lucide-vue-next'

const columns = [
  { key: 'number', label: 'Nº da OS', width: '10%' },
  { key: 'openingDate', label: 'Data de Abertura', width: '15%' },
  { key: 'conclusionDate', label: 'Data de Conclusão', width: '15%' },
  { key: 'sector', label: 'Setor', width: '14%' },
  { key: 'lab', label: 'Laboratório', width: '12%' },
  { key: 'status', label: 'Status', width: '10%', type: 'status' },
  { key: 'description', label: 'Descrição', width: '16%' },
  { key: 'actions', label: 'Ações', width: '8%', type: 'actions' }
]

const rows = reactive([
	{
		id: 1,
		number: '00001',
		openingDate: '11/09/2026',
		conclusionDate: '15/09/2026',
		sector: 'Mecânica',
		lab: 'B-101',
		status: 'Aberto',
		description: 'Manutenção preventiva da centrífuga CT-02.'
	},
	{
		id: 2,
		number: '00002',
		openingDate: '11/09/2026',
		conclusionDate: '15/09/2026',
		sector: 'Mecânica',
		lab: 'B-101',
		status: 'Aberto',
		description: 'Inspeção e calibração dos equipamentos.'
	},
	{
		id: 3,
		number: '00003',
		openingDate: '12/09/2026',
		conclusionDate: '16/09/2026',
		sector: 'Elétrica',
		lab: 'B-102',
		status: 'Concluído',
		description: 'Revisão preventiva da bancada elétrica.'
	},
	{
		id: 4,
		number: '00004',
		openingDate: '12/09/2026',
		conclusionDate: '18/09/2026',
		sector: 'Mecânica',
		lab: 'B-101',
		status: 'Aberto',
		description: 'Manutenção preventiva da centrífuga CT-02.'
	},
	{
		id: 5,
		number: '00005',
		openingDate: '13/09/2026',
		conclusionDate: '19/09/2026',
		sector: 'Automação',
		lab: 'B-103',
		status: 'Aberto',
		description: 'Ajuste dos sensores do laboratório.'
	}
])

const showCreateModal = ref(false)
const showDetailsModal = ref(false)
const selectedOrder = ref(null)
const editingOrderId = ref(null)
const showConfirmation = ref(false)
const confirmationAction = ref(null)
const searchText = ref('')
const filters = reactive({ number: '', sector: '', lab: '', status: '' })
const orderForm = reactive({
	number: '', openingDate: '', conclusionDate: '', sector: '', lab: '', status: 'Aberto', description: ''
})

const isEditing = computed(() => editingOrderId.value !== null)

const numberOptions = computed(() => [...new Set(rows.map((row) => row.number))])
const sectorOptions = computed(() => [...new Set(rows.map((row) => row.sector))])
const labOptions = computed(() => [...new Set(rows.map((row) => row.lab))])
const statusOptions = computed(() => [...new Set(rows.map((row) => row.status))])

const filteredRows = computed(() => {
	const query = searchText.value.trim().toLowerCase()

	return rows.filter((row) => {
		const matchesSearch = !query || Object.values(row).some((value) => String(value).toLowerCase().includes(query))
		return matchesSearch
			&& (!filters.number || row.number === filters.number)
			&& (!filters.sector || row.sector === filters.sector)
			&& (!filters.lab || row.lab === filters.lab)
			&& (!filters.status || row.status === filters.status)
	})
})

function clearFilters() {
	searchText.value = ''
	filters.number = ''
	filters.sector = ''
	filters.lab = ''
	filters.status = ''
}

function resetOrderForm() {
	orderForm.number = ''
	orderForm.openingDate = ''
	orderForm.conclusionDate = ''
	orderForm.sector = ''
	orderForm.lab = ''
	orderForm.status = 'Aberto'
	orderForm.description = ''
}

function getNextOrderNumber() {
	const highestNumber = rows.reduce((highest, row) => {
		const currentNumber = Number.parseInt(row.number, 10)
		return Number.isNaN(currentNumber) ? highest : Math.max(highest, currentNumber)
	}, 0)

	return String(highestNumber + 1).padStart(5, '0')
}

function getTodayInputValue() {
	const today = new Date()
	const year = today.getFullYear()
	const month = String(today.getMonth() + 1).padStart(2, '0')
	const day = String(today.getDate()).padStart(2, '0')

	return `${year}-${month}-${day}`
}

function openCreateForm() {
	resetOrderForm()
	editingOrderId.value = null
	orderForm.number = getNextOrderNumber()
	orderForm.openingDate = getTodayInputValue()
	showCreateModal.value = true
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
	orderForm.sector = order.sector
	orderForm.lab = order.lab
	orderForm.status = order.status
	orderForm.description = order.description
	showCreateModal.value = true
}

function createOrder() {
	if (!orderForm.number.trim()) return
	if (isEditing.value) {
		requestConfirmation('save')
		return
	}

	rows.push({
		id: Date.now(),
		number: orderForm.number.trim(),
		openingDate: formatDate(orderForm.openingDate),
		conclusionDate: formatDate(orderForm.conclusionDate),
		sector: orderForm.sector,
		lab: orderForm.lab,
		status: orderForm.status,
		description: orderForm.description.trim()
	})

	showCreateModal.value = false
	editingOrderId.value = null
	resetOrderForm()
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

function confirmOrderAction() {
	if (confirmationAction.value === 'save') {
		const order = rows.find((row) => row.id === editingOrderId.value)

		if (order) {
			Object.assign(order, {
				number: orderForm.number.trim(),
				openingDate: formatDate(orderForm.openingDate),
				conclusionDate: formatDate(orderForm.conclusionDate),
				sector: orderForm.sector,
				lab: orderForm.lab,
				status: orderForm.status,
				description: orderForm.description.trim()
			})
		}

		showCreateModal.value = false
		editingOrderId.value = null
		resetOrderForm()
	}

	if (confirmationAction.value === 'finish' && selectedOrder.value) {
		selectedOrder.value.status = 'Concluído'
		showDetailsModal.value = false
	}

	confirmationAction.value = null
}

function handleRowAction({ action, row }) {
	if (action === 'view') {
		selectedOrder.value = row
		showDetailsModal.value = true
	} else if (action === 'edit') {
		openEditForm(row)
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

				<label class="flex min-w-36 flex-1 flex-col gap-2 text-sm text-text-primary">
					Status
					<select v-model="filters.status"
						class="rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-gray-200 focus:ring-red-primary">
						<option value="">Selecione</option>
						<option v-for="status in statusOptions" :key="status" :value="status">
							{{ status }}
						</option>
					</select>
				</label>

				<Button variant="outline" size="sm" @click="clearFilters">
					Limpar filtros
				</Button>
			</div>

			<Table
				:columns="columns"
				:rows="filteredRows"
				row-key="id"
				@row-action="handleRowAction"
			/>
			</div>

			<div v-else class="space-y-6 rounded-lg bg-bg px-8 py-2">
				<h2 class="text-lg font-semibold text-text-primary">
					{{ isEditing ? 'Editar Ordem de Serviço' : 'Criar Ordem de Serviço' }}
				</h2>

				<div class="space-y-2">
					<label for="order-number" class="text-xs font-medium text-text-primary">Nº da OS <span class="text-red-primary">*</span></label>
					<input id="order-number" v-model="orderForm.number" type="text" placeholder="00015" required disabled class="w-full cursor-not-allowed rounded-lg bg-gray-300 px-3 py-3 text-sm text-gray-600 outline-none" />
				</div>

				<div class="grid grid-cols-1 gap-5 md:grid-cols-2">
					<div class="space-y-2">
						<label for="order-opening-date" class="text-xs font-medium text-text-primary">Data de abertura <span class="text-red-primary">*</span></label>
						<input id="order-opening-date" v-model="orderForm.openingDate" type="date" disabled class="w-full cursor-not-allowed rounded-lg bg-gray-300 px-3 py-3 text-sm text-gray-600 outline-none" />
					</div>
					<div class="space-y-2">
						<label for="order-conclusion-date" class="text-xs font-medium text-text-primary">Data de conclusão</label>
						<input id="order-conclusion-date" v-model="orderForm.conclusionDate" type="date" class="w-full rounded-lg bg-white px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
					</div>
				</div>

				<div class="space-y-2">
					<label for="order-sector" class="text-xs font-medium text-text-primary">Setor <span class="text-red-primary">*</span></label>
					<select id="order-sector" v-model="orderForm.sector" class="w-full rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
						<option value="">Selecione</option>
						<option v-for="sector in sectorOptions" :key="sector" :value="sector">{{ sector }}</option>
					</select>
				</div>

				<div class="space-y-2">
					<label for="order-lab" class="text-xs font-medium text-text-primary">Laboratório</label>
					<select id="order-lab" v-model="orderForm.lab" class="w-full rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
						<option value="">Selecione</option>
						<option v-for="lab in labOptions" :key="lab" :value="lab">{{ lab }}</option>
					</select>
				</div>

				<div class="space-y-2">
					<label for="order-status" class="text-xs font-medium text-text-primary">Status <span class="text-red-primary">*</span></label>
					<select id="order-status" v-model="orderForm.status" class="w-full rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
						<option value="">Selecione</option>
						<option value="Aberto">Aberto</option>
						<option value="Concluído">Concluído</option>
					</select>
				</div>

				<div class="space-y-2">
					<label for="order-description" class="text-xs font-medium text-text-primary">Descrição <span class="text-red-primary">*</span></label>
					<textarea id="order-description" v-model="orderForm.description" rows="5" placeholder="Descreva com detalhes o serviço" class="w-full resize-none rounded-lg bg-white px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary"></textarea>
				</div>

				<div class="flex items-center justify-between pt-8">
					<Button variant="outline" @click="cancelForm">Cancelar</Button>
					<Button variant="primary" @click="createOrder">
						{{ isEditing ? 'Salvar' : 'Criar Ordem' }}
					</Button>
				</div>
			</div>

			<Modal v-model="showDetailsModal" title="Detalhes da OS" size="sm">
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
						<div class="space-y-2">
							<dt class="font-medium text-text-primary">Descrição</dt>
							<dd class="text-text-secondary">{{ selectedOrder.description }}</dd>
						</div>
					</dl>
				</div>

				<template #footer>
					<Button variant="outline" size="sm" @click="openEditForm(selectedOrder)">
						<Pencil :size="16" />
						Editar
					</Button>
					<Button variant="primary" size="sm" @click="requestConfirmation('finish')">
						<Play :size="16" fill="currentColor" />
						Finalizar
					</Button>
				</template>
			</Modal>

			<ConfirmModal
				v-model="showConfirmation"
				:title="confirmationAction === 'finish' ? 'Finalizar OS' : 'Salvar alterações'"
				:message="confirmationAction === 'finish'
					? 'Tem certeza que deseja finalizar essa Ordem de Serviço?'
					: 'Tem certeza que deseja salvar as alterações desta Ordem de Serviço?'"
				:confirm-text="confirmationAction === 'finish' ? 'Finalizar' : 'Salvar'"
				@confirm="confirmOrderAction"
			/>
		</section>
	</main>
</template>
