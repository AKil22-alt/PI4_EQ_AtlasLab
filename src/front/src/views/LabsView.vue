<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import {
  createLaboratoryRequest,
  listLaboratoriesRequest,
  listLaboratoryResponsiblesRequest,
  updateLaboratoryRequest,
  deleteLaboratoryRequest,
  listAssetsRequest,
  assetHistoryRequest,
  listAssetGroupsRequest,
  createAssetGroupRequest,
  updateAssetGroupRequest,
  createAssetRequest,
  updateAssetRequest,
  moveAssetRequest,
  listAllPagesRequest,
  clearMovementHistoryRequest
} from '../services/api'
import Table from '../components/Table.vue';
import LineChart from '../components/LineChart.vue'
import LabCard from '../components/LabCard.vue';
import Button from '../components/Button.vue';
import Searchbar from '../components/Searchbar.vue';
import { AlertTriangle, ArrowRightLeft, Layers, Pencil, Plus, RefreshCw, Trash2 } from 'lucide-vue-next';
import Modal from '../components/Modal.vue';
import ConfirmModal from '../components/ConfirmModal.vue';
import { useAuthStore } from '../store/auth'

const authStore = useAuthStore()
const activeTab = ref('labs')
const searchText = ref('')
const assetSearchText = ref('')
const movementSearchText = ref('')
const allMovementRecords = ref([])
const movementHistory = ref({ labels: [], values: [] })
const isLoadingMovementHistory = ref(false)
const movementHistoryError = ref('')
const clearMovementHistoryError = ref('')
const selectedAssetMovements = ref([])
const isLoadingAssetMovements = ref(false)
const assetMovementsError = ref('')

const labs = reactive([])
const groups = reactive([])
const laboratoryResponsibles = reactive([])
const canManageLabs = computed(() => ['ADM', 'TEC'].includes(authStore.currentUser?.cargo))
const canManageAssets = computed(() => ['ADM', 'TEC'].includes(authStore.currentUser?.cargo))
const canClearMovementHistory = computed(() => authStore.currentUser?.cargo === 'ADM')

const movementColumns = [
  { key: 'date', label: 'Data e hora', width: '16%' },
  { key: 'asset', label: 'Ativo', width: '18%' },
  { key: 'patrimony', label: 'Patrimônio', width: '16%' },
  { key: 'user', label: 'Responsável', width: '15%' },
  { key: 'destination', label: 'Destino', width: '12%' },
  { key: 'quantity', label: 'Quantidade', width: '10%' },
  { key: 'justification', label: 'Justificativa', width: '13%' }
]

const filteredMovementRows = computed(() => {
  const query = movementSearchText.value.trim().toLowerCase()

  return allMovementRecords.value.map((movement) => ({
    id: movement.id_mov,
    date: formatMovementDate(movement.data_hora),
    asset: movement.ativo_detalhes?.nome || `Ativo ${movement.ativo}`,
    patrimony: movement.ativo_detalhes?.qr_code || 'Não informado',
    user: movement.usuario_detalhes?.nome || 'Usuário',
    destination: movement.local_m || 'Não informado',
    quantity: movement.contagem_mov_a ?? 1,
    justification: movement.justificativa || 'Não informada'
  })).filter((movement) => !query || Object.values(movement)
    .some((value) => String(value).toLowerCase().includes(query)))
})

function buildMovementHistory(movements) {
  const days = Array.from({ length: 10 }, (_, index) => {
    const date = new Date()
    date.setHours(0, 0, 0, 0)
    date.setDate(date.getDate() - (9 - index))
    return date
  })
  const dailyTotals = new Map(days.map((date) => [date.toLocaleDateString('sv-SE'), 0]))

  movements.forEach((movement) => {
    const dateKey = movement.data_hora?.slice(0, 10)
    if (dailyTotals.has(dateKey)) {
      dailyTotals.set(dateKey, dailyTotals.get(dateKey) + Number(movement.contagem_mov_a ?? 1))
    }
  })

  return {
    labels: days.map((date) => date.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' })),
    values: days.map((date) => dailyTotals.get(date.toLocaleDateString('sv-SE')))
  }
}

async function loadMovementHistory() {
  isLoadingMovementHistory.value = true
  movementHistoryError.value = ''

  try {
    const movements = await listAllPagesRequest('/movimentacoes/')
    allMovementRecords.value = movements.sort(
      (first, second) => new Date(second.data_hora) - new Date(first.data_hora)
    )
    movementHistory.value = buildMovementHistory(movements)
  } catch (error) {
    console.error('Erro ao carregar histórico de movimentações:', error)
    movementHistoryError.value = 'Não foi possível carregar o histórico de movimentações. Tente novamente.'
  } finally {
    isLoadingMovementHistory.value = false
  }
}

function formatMovementDate(value) {
  if (!value) return 'Data não informada'

  return new Date(value).toLocaleString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

async function loadSelectedAssetHistory(assetId) {
  isLoadingAssetMovements.value = true
  assetMovementsError.value = ''
  selectedAssetMovements.value = []

  try {
    const history = await assetHistoryRequest(assetId)
    selectedAssetMovements.value = (history.movimentacoes || []).sort(
      (first, second) => new Date(second.data_hora) - new Date(first.data_hora)
    )
  } catch (error) {
    console.error('Erro ao carregar histórico do ativo:', error)
    assetMovementsError.value = 'Não foi possível carregar as movimentações deste ativo.'
  } finally {
    isLoadingAssetMovements.value = false
  }
}

function mapLaboratory(laboratory) {
  return {
    id: laboratory.id_sala,
    acronym: laboratory.localizacao,
    title: laboratory.nome,
    responsible: laboratory.responsavel_detalhes?.nome || 'Não informado',
    responsibleId: laboratory.responsavel,
    numeroTa: laboratory.numero_ta
  }
}

function mapAsset(asset) {
  const originLab = labs.find((lab) => lab.id === asset.local_origem)
  const currentLab = labs.find((lab) => lab.id === asset.local_atual)

  return {
    id: asset.id_ativos,
    patrimony: asset.qr_code || '',
    name: asset.nome,
    origin: asset.local_origem_detalhes?.localizacao || originLab?.acronym || 'Não informado',
    current: asset.local_atual_detalhes?.localizacao || currentLab?.acronym || 'Não informado',
    originLabId: asset.local_origem,
    currentLabId: asset.local_atual,
    groupId: asset.grupo,
    category: asset.grupo_detalhes?.nome || 'Não informado',
    status: asset.status ? 'Ativo' : 'Inativo',
    description: asset.descricao || ''
  }
}

onMounted(async () => {
  try {
    const response = await listLaboratoriesRequest()
    const laboratories = Array.isArray(response) ? response : response.results
    labs.push(...laboratories.map(mapLaboratory))
  } catch (error) {
    console.error('Erro ao carregar laboratórios:', error)
  }

  if (canManageLabs.value) {
    try {
      const responsibles = await listLaboratoryResponsiblesRequest()
      laboratoryResponsibles.push(...responsibles)
    } catch (error) {
      console.error('Erro ao carregar responsáveis dos laboratórios:', error)
    }
  }

  try {
    const assets = await listAssetsRequest()
    rows.push(...(Array.isArray(assets) ? assets : assets.results).map(mapAsset))
  } catch (error) {
    console.error('Erro ao carregar ativos:', error)
  }

  try {
    const response = await listAssetGroupsRequest()
    groups.push(...(Array.isArray(response) ? response : response.results))
  } catch (error) {
    console.error('Erro ao carregar grupos de ativos:', error)
  }

  await loadMovementHistory()
})

const filteredLabs = computed(() => {
  const query = searchText.value.trim().toLowerCase()

  if (!query) {
    return labs
  }

  return labs.filter((lab) => [lab.acronym, lab.title, lab.responsible]
    .some((value) => value.toLowerCase().includes(query)))
})

const columns = [
  { key: 'patrimony', label: 'QR Code', width: '14%' },
  { key: 'name', label: 'Nome', width: '16%' },
  { key: 'origin', label: 'Local de origem', width: '15%' },
  { key: 'current', label: 'Local atual', width: '15%' },
  { key: 'status', label: 'Status', width: '10%', type: 'status' },
  { key: 'description', label: 'Descrição', width: '28%' },
  { key: 'actions', label: 'Ações', width: '112px', type: 'actions' }
]

const rows = reactive([])

const showLabModal = ref(false)
const showLabDetailsModal = ref(false)
const showAssetModal = ref(false)
const showGroupModal = ref(false)
const showDetailsModal = ref(false)
const showMovementModal = ref(false)
const selectedAsset = ref(null)
const selectedLab = ref(null)
const showConfirmation = ref(false)
const confirmationAction = ref(null)
const editingLabId = ref(null)
const editingAssetId = ref(null)
const editingGroupId = ref(null)
const pendingLabId = ref(null)
const labValidationMessage = ref('')
const groupValidationMessage = ref('')
const assetValidationMessage = ref('')
const movementValidationMessage = ref('')
const showLabDeletionErrorModal = ref(false)
const labDeletionErrorMessage = ref('')

const labForm = reactive({
  acronym: '',
  name: '',
  numeroTa: '',
  responsible: null
})

const assetForm = reactive({
  qrCode: '',
  name: '',
  originLab: '',
  currentLab: '',
  group: '',
  status: 'Ativo',
  description: ''
})

const groupForm = reactive({
  nome: '',
  numeroTa: '',
  tipo: '',
  setor: ''
})

const movementForm = reactive({
  assetId: '',
  labId: '',
  justification: ''
})

const assetFilters = reactive({
  patrimony: '',
  name: '',
  location: '',
  status: ''
})

const patrimonyOptions = computed(() => [...new Set(rows.map((row) => row.patrimony))])
const nameOptions = computed(() => [...new Set(rows.map((row) => row.name))])
const locationOptions = computed(() => [
  ...new Set(rows.flatMap((row) => [row.origin, row.current]))
])
const statusOptions = computed(() => [...new Set(rows.map((row) => row.status))])

const filteredRows = computed(() => {
  const query = assetSearchText.value.trim().toLowerCase()

  return rows.filter((row) => {
    const matchesSearch = !query || Object.values(row)
      .some((value) => String(value).toLowerCase().includes(query))
    const matchesPatrimony = !assetFilters.patrimony || row.patrimony === assetFilters.patrimony
    const matchesName = !assetFilters.name || row.name === assetFilters.name
    const matchesLocation = !assetFilters.location
      || row.origin === assetFilters.location
      || row.current === assetFilters.location
    const matchesStatus = !assetFilters.status || row.status === assetFilters.status

    return matchesSearch
      && matchesPatrimony
      && matchesName
      && matchesLocation
      && matchesStatus
  })
})

function clearAssetFilters() {
  assetSearchText.value = ''
  assetFilters.patrimony = ''
  assetFilters.name = ''
  assetFilters.location = ''
  assetFilters.status = ''
}

function resetAssetForm() {
  assetForm.qrCode = ''
  assetForm.name = ''
  assetForm.originLab = ''
  assetForm.currentLab = ''
  assetForm.group = ''
  assetForm.status = 'Ativo'
  assetForm.description = ''
  assetValidationMessage.value = ''
}

function resetGroupForm() {
  groupForm.nome = ''
  groupForm.numeroTa = ''
  groupForm.tipo = ''
  groupForm.setor = ''
  editingGroupId.value = null
  groupValidationMessage.value = ''
}

function openGroupManager() {
  resetGroupForm()
  showGroupModal.value = true
}

function editGroup(group) {
  editingGroupId.value = group.id_grupo_a
  groupForm.nome = group.nome
  groupForm.numeroTa = group.numero_ta
  groupForm.tipo = group.tipo
  groupForm.setor = group.setor
  groupValidationMessage.value = ''
}

async function saveGroup() {
  if (!groupForm.nome.trim() || !groupForm.tipo.trim() || !groupForm.setor.trim()) {
    groupValidationMessage.value = 'Preencha nome, tipo e setor.'
    return
  }

  const numeroTa = Number(groupForm.numeroTa)
  if (!Number.isInteger(numeroTa) || numeroTa < 1) {
    groupValidationMessage.value = 'Informe um Número TA válido.'
    return
  }

  const payload = {
    nome: groupForm.nome.trim(),
    numero_ta: numeroTa,
    tipo: groupForm.tipo.trim(),
    setor: groupForm.setor.trim()
  }

  try {
    if (editingGroupId.value !== null) {
      const updatedGroup = await updateAssetGroupRequest(editingGroupId.value, payload)
      const existingGroup = groups.find((group) => group.id_grupo_a === editingGroupId.value)
      if (existingGroup) Object.assign(existingGroup, updatedGroup)
    } else {
      const createdGroup = await createAssetGroupRequest(payload)
      groups.push(createdGroup)
    }
    resetGroupForm()
  } catch (error) {
    groupValidationMessage.value = error.message
  }
}

function resetLabForm() {
  labForm.acronym = ''
  labForm.name = ''
  labForm.numeroTa = ''
  labForm.responsible = null
  labValidationMessage.value = ''
}

function openLabForm(lab = null) {
  showLabDetailsModal.value = false
  labValidationMessage.value = ''
  editingLabId.value = lab?.id ?? null
  labForm.acronym = lab?.acronym ?? ''
  labForm.name = lab?.title ?? ''
  labForm.numeroTa = lab?.numeroTa ?? ''
  labForm.responsible = lab?.responsibleId ?? null
  showLabModal.value = true
}

function openLabDetails(lab) {
  selectedLab.value = lab
  showLabDetailsModal.value = true
}

async function saveLab() {
  if (!labForm.name.trim()) {
    labValidationMessage.value = 'Preencha o nome do laboratório.'
    return
  }

  if (!labForm.acronym.trim()) {
    labValidationMessage.value = 'Preencha a sigla do laboratório.'
    return
  }

  const numeroTa = Number(labForm.numeroTa)
  if (!Number.isInteger(numeroTa) || numeroTa < 1) {
    labValidationMessage.value = 'Informe um Número TA válido.'
    return
  }

  labValidationMessage.value = ''
  if (editingLabId.value !== null) {
    const laboratoryId = editingLabId.value
    const lab = labs.find((item) => String(item.id) === String(laboratoryId))
    if (!lab) {
      console.error('Laboratório não encontrado para edição:', laboratoryId)
      return
    }

    try {
      const laboratory = await updateLaboratoryRequest(laboratoryId, {
        nome: labForm.name.trim(),
        localizacao: labForm.acronym.trim(),
        numero_ta: numeroTa,
        responsavel: labForm.responsible || null
      })

      Object.assign(lab, mapLaboratory(laboratory))
      showLabModal.value = false
      editingLabId.value = null
      resetLabForm()
    } catch (error) {
      console.error('Erro ao editar laboratório:', error)
    }
    return
  }

  try {
    const laboratory = await createLaboratoryRequest({
      nome: labForm.name.trim(),
      localizacao: labForm.acronym.trim(),
      numero_ta: numeroTa,
      responsavel: labForm.responsible || null
    })

    labs.unshift(mapLaboratory(laboratory))
    showLabModal.value = false
    resetLabForm()
  } catch (error) {
    console.error('Erro ao criar laboratório:', error)
  }
}

function openAssetForm(asset = null) {
  showDetailsModal.value = false
  assetValidationMessage.value = ''
  editingAssetId.value = asset?.id ?? null
  assetForm.qrCode = asset?.patrimony ?? ''
  assetForm.name = asset?.name ?? ''
  assetForm.originLab = asset?.originLabId
    ?? labs.find((lab) => lab.acronym === asset?.origin)?.id
    ?? ''
  assetForm.currentLab = asset?.currentLabId
    ?? labs.find((lab) => lab.acronym === asset?.current)?.id
    ?? ''
  assetForm.group = asset?.groupId ?? ''
  assetForm.status = asset?.status ?? 'Ativo'
  assetForm.description = asset?.description ?? ''
  showAssetModal.value = true
}

async function createAsset() {
  const originLab = labs.find((lab) => String(lab.id) === String(assetForm.originLab))
  const currentLab = labs.find((lab) => String(lab.id) === String(assetForm.currentLab))
  const missingFields = []
  if (!assetForm.name.trim()) missingFields.push('nome')
  if (!originLab) missingFields.push('local de origem')
  if (!currentLab) missingFields.push('local atual')
  if (!assetForm.group) missingFields.push('grupo')
  if (missingFields.length) {
    assetValidationMessage.value = `Preencha os campos obrigatórios: ${missingFields.join(', ')}.`
    return
  }
  assetValidationMessage.value = ''

  if (editingAssetId.value !== null) {
    requestConfirmation('save-asset')
    return
  }

  try {
    const payload = {
      nome: assetForm.name.trim(),
      local_origem: originLab.id,
      local_atual: currentLab.id,
      grupo: Number(assetForm.group),
      descricao: assetForm.description.trim(),
      status: assetForm.status === 'Ativo'
    }
    const asset = await createAssetRequest(payload)

    rows.push(mapAsset(asset))

    showAssetModal.value = false
    resetAssetForm()
  } catch (error) {
    console.error('Erro ao criar ativo:', error)
  }
}

async function saveAsset() {
  const asset = rows.find((row) => row.id === editingAssetId.value)
  if (!asset) return
  const originLab = labs.find((lab) => String(lab.id) === String(assetForm.originLab))
  const currentLab = labs.find((lab) => String(lab.id) === String(assetForm.currentLab))
  const missingFields = []
  if (!assetForm.name.trim()) missingFields.push('nome')
  if (!originLab) missingFields.push('local de origem')
  if (!currentLab) missingFields.push('local atual')
  if (!assetForm.group) missingFields.push('grupo')
  if (missingFields.length) {
    assetValidationMessage.value = `Preencha os campos obrigatórios: ${missingFields.join(', ')}.`
    return
  }
  assetValidationMessage.value = ''

  try {
    const updatedAsset = await updateAssetRequest(asset.id, {
      nome: assetForm.name.trim(),
      local_origem: originLab.id,
      local_atual: currentLab.id,
      grupo: Number(assetForm.group),
      descricao: assetForm.description.trim(),
      status: assetForm.status === 'Ativo'
    })

    Object.assign(asset, mapAsset(updatedAsset))
    showAssetModal.value = false
    editingAssetId.value = null
    resetAssetForm()
  } catch (error) {
    console.error('Erro ao editar ativo:', error)
  }
}

function openMovementForm(asset = null) {
  selectedAsset.value = asset
  showDetailsModal.value = false
  movementValidationMessage.value = ''
  movementForm.assetId = asset?.id ?? ''
  movementForm.labId = asset?.currentLabId ?? asset?.roomId ?? ''
  movementForm.justification = ''
  showMovementModal.value = true
}

function selectMovementAsset() {
  const asset = rows.find((item) => String(item.id) === String(movementForm.assetId))
  movementForm.labId = asset?.currentLabId ?? ''
}

async function submitMovement() {
  const assetId = selectedAsset.value?.id ?? movementForm.assetId
  const asset = rows.find((item) => String(item.id) === String(assetId))
  const lab = labs.find((item) => String(item.id) === String(movementForm.labId))
  const missingFields = []
  if (!asset) missingFields.push('ativo')
  if (!lab) missingFields.push('novo local')
  if (!movementForm.justification.trim()) missingFields.push('justificativa')
  if (missingFields.length) {
    movementValidationMessage.value = `Preencha os campos obrigatórios: ${missingFields.join(', ')}.`
    return
  }
  movementValidationMessage.value = ''

  try {
    await moveAssetRequest(asset.id, {
      local_m: lab.acronym,
      sala_id: lab.id,
      justificativa: movementForm.justification.trim()
    })

    const updatedLocation = lab.acronym
    asset.current = updatedLocation
    asset.currentLabId = lab.id
    asset.roomId = lab.id
    if (selectedAsset.value?.id === asset.id) Object.assign(selectedAsset.value, asset)
    showMovementModal.value = false
    movementForm.assetId = ''
    movementForm.labId = ''
    movementForm.justification = ''
    void loadMovementHistory()
  } catch (error) {
    console.error('Erro ao movimentar ativo:', error)
  }
}

function requestConfirmation(action) {
  confirmationAction.value = action
  if (action === 'clear-movements') clearMovementHistoryError.value = ''
  showConfirmation.value = true
}

function requestLabDeletion(lab) {
  pendingLabId.value = lab.id
  requestConfirmation('delete-lab')
}

function goToAssetsFromLabDeletionError() {
  showLabDeletionErrorModal.value = false
  activeTab.value = 'assets'
}

async function confirmAction() {
  const action = confirmationAction.value

  if (action === 'save-asset') await saveAsset()

  if (action === 'clear-movements') {
    try {
      await clearMovementHistoryRequest()
      allMovementRecords.value = []
      movementHistory.value = buildMovementHistory([])
      selectedAssetMovements.value = []
      movementHistoryError.value = ''
      clearMovementHistoryError.value = ''
    } catch (error) {
      clearMovementHistoryError.value = error.message || 'Não foi possível limpar o histórico.'
    }
  }

  if (action === 'delete-lab') {
    try {
      await deleteLaboratoryRequest(pendingLabId.value)

      const labIndex = labs.findIndex(
        (lab) => String(lab.id) === String(pendingLabId.value)
      )

      if (labIndex !== -1) {
        labs.splice(labIndex, 1)
      }

      pendingLabId.value = null
    } catch (error) {
      console.error('Erro ao excluir laboratório:', error)
      labDeletionErrorMessage.value = error.message
      showLabDeletionErrorModal.value = true
    }
  }

  confirmationAction.value = null
}

function handleRowAction({ action, row }) {
  if (action === 'view') {
    selectedAsset.value = row
    selectedAssetMovements.value = []
    showDetailsModal.value = true
    void loadSelectedAssetHistory(row.id)
  } else if (action === 'edit') {
    openAssetForm(row)
  }
}
</script>

<template>
  <main class="min-w-0 space-y-6 px-4 pb-8 pt-0 sm:px-8">
    <nav class="-mx-8 flex gap-6 border-b border-red-1 bg-white px-8" aria-label="Seções de laboratórios, ativos e movimentações">
      <button type="button" :class="[
        'border-b-2 px-2 pb-2 text-sm',
        activeTab === 'labs'
          ? 'border-red-primary font-semibold text-red-primary'
          : 'border-transparent text-text-secondary'
      ]" :aria-selected="activeTab === 'labs'" @click="activeTab = 'labs'">
        Labs
      </button>

      <button type="button" :class="[
        'border-b-2 px-2 pb-2 text-sm',
        activeTab === 'assets'
          ? 'border-red-primary font-semibold text-red-primary'
          : 'border-transparent text-text-secondary'
      ]" :aria-selected="activeTab === 'assets'" @click="activeTab = 'assets'">
        Ativos
      </button>

      <button type="button" :class="[
        'border-b-2 px-2 pb-2 text-sm',
        activeTab === 'movements'
          ? 'border-red-primary font-semibold text-red-primary'
          : 'border-transparent text-text-secondary'
      ]" :aria-selected="activeTab === 'movements'" @click="activeTab = 'movements'">
        Movimentações
      </button>
    </nav>

    <section v-if="activeTab === 'labs'" class="space-y-6">
      <div class="flex flex-col items-stretch justify-between gap-4 sm:flex-row sm:items-center">
        <div class="w-full sm:w-60">
          <Searchbar v-model="searchText" />
        </div>

        <Button v-if="canManageLabs" @click="openLabForm()" variant="primary" size="sm">
          <Plus :size="18" />
          Criar Laboratório
        </Button>
      </div>
      <Modal v-model="showLabModal" :title="editingLabId === null ? 'Criar Laboratório' : 'Editar Laboratório'"
        size="lg">
        <div class="space-y-5">
          <div class="space-y-2">
            <label for="lab-acronym" class="text-sm font-medium text-text-primary">
              Sigla <span class="text-red-primary">*</span>
            </label>
            <input id="lab-acronym" v-model="labForm.acronym" type="text" placeholder="B-101" required
              class="w-full rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
          </div>

          <div class="space-y-2">
            <label for="lab-name" class="text-sm font-medium text-text-primary">
              Nome <span class="text-red-primary">*</span>
            </label>
            <input id="lab-name" v-model="labForm.name" type="text" placeholder="Laboratório CAM" required
              class="w-full rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
          </div>

          <div class="space-y-2">
            <label for="lab-number-ta" class="text-sm font-medium text-text-primary">
              Número TA <span class="text-red-primary">*</span>
            </label>
            <input id="lab-number-ta" v-model="labForm.numeroTa" type="number" min="1" step="1" placeholder="1" required
              class="w-full rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
          </div>

          <div class="space-y-2">
            <label for="lab-responsible" class="text-sm font-medium text-text-primary">
              Responsável
            </label>
            <select id="lab-responsible" v-model.number="labForm.responsible"
              class="w-full rounded-lg bg-bg px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
              <option :value="null">Sem responsável</option>
              <option v-for="responsible in laboratoryResponsibles" :key="responsible.id_user"
                :value="responsible.id_user">
                {{ responsible.nome }} ({{ responsible.cargo }})
              </option>
            </select>
          </div>

          <p v-if="labValidationMessage" class="text-sm font-medium text-red-primary" role="alert">
            {{ labValidationMessage }}
          </p>
        </div>

        <template #footer>
          <Button variant="outline" @click="showLabModal = false; editingLabId = null">
            Cancelar
          </Button>
          <Button variant="primary" @click="saveLab">
            {{ editingLabId === null ? 'Criar' : 'Salvar' }}
          </Button>
        </template>
      </Modal>

      <Modal v-model="showLabDetailsModal" title="Detalhes do laboratório" size="sm">
        <div v-if="selectedLab" class="space-y-5 border-t border-red-primary pt-4">
          <dl class="space-y-4 text-sm">
            <div class="grid grid-cols-1 gap-1 sm:grid-cols-[minmax(0,auto)_minmax(0,1fr)] sm:gap-6">
              <dt class="font-medium text-text-primary">Sigla</dt>
              <dd class="break-words text-text-secondary sm:text-right">{{ selectedLab.acronym }}</dd>
            </div>
            <div class="grid grid-cols-1 gap-1 sm:grid-cols-[minmax(0,auto)_minmax(0,1fr)] sm:gap-6">
              <dt class="font-medium text-text-primary">Nome</dt>
              <dd class="break-words text-text-secondary sm:text-right">{{ selectedLab.title }}</dd>
            </div>
            <div class="grid grid-cols-1 gap-1 sm:grid-cols-[minmax(0,auto)_minmax(0,1fr)] sm:gap-6">
              <dt class="font-medium text-text-primary">Número TA</dt>
              <dd class="break-words text-text-secondary sm:text-right">{{ selectedLab.numeroTa }}</dd>
            </div>
            <div class="grid grid-cols-1 gap-1 sm:grid-cols-[minmax(0,auto)_minmax(0,1fr)] sm:gap-6">
              <dt class="font-medium text-text-primary">Responsável</dt>
              <dd class="break-words text-text-secondary sm:text-right">{{ selectedLab.responsible }}</dd>
            </div>
          </dl>
        </div>

        <template #footer>
          <Button variant="outline" size="sm" @click="openLabForm(selectedLab)">
            <Pencil :size="16" />
            Editar
          </Button>
          <Button variant="primary" size="sm" @click="activeTab = 'assets'; showLabDetailsModal = false">
            Ver Ativos
          </Button>
        </template>
      </Modal>

      <LineChart v-if="!isLoadingMovementHistory && !movementHistoryError && movementHistory.values.some((value) => value > 0)"
        title="Histórico de Ativos" :labels="movementHistory.labels" :values="movementHistory.values"
        series-label="Ativos movimentados" />
      <article v-else class="w-full rounded-lg bg-red-2 px-8 py-6" aria-live="polite">
        <h2 class="text-2xl font-semibold text-black">Histórico de Ativos</h2>
        <p class="mt-3 text-sm text-text-secondary">
          {{ isLoadingMovementHistory ? 'Carregando movimentações...' : movementHistoryError || 'Nenhuma movimentação nos últimos 10 dias.' }}
        </p>
        <button v-if="movementHistoryError" class="mt-3 inline-flex items-center gap-2 text-sm font-semibold text-red-primary hover:underline"
          type="button" @click="loadMovementHistory">
          <RefreshCw :size="16" /> Tentar novamente
        </button>
      </article>
      <div class="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-3">
        <LabCard v-for="lab in filteredLabs" :key="lab.id" :acronym="lab.acronym" :title="lab.title"
          :responsible="lab.responsible" :can-manage="canManageLabs"
          @view-assets="activeTab = 'assets'" @view-details="openLabDetails(lab)"
          @edit="openLabForm(lab)" @delete="requestLabDeletion(lab)" />
      </div>
    </section>

    <section v-else-if="activeTab === 'assets'" class="space-y-6" aria-labelledby="assets-title">
      <div class="flex flex-wrap justify-end gap-3">
        <Button v-if="canManageAssets" @click="openGroupManager" variant="outline" size="sm">
          <Layers :size="18" />
          Gerenciar grupos
        </Button>
        <Button v-if="canManageAssets" @click="openAssetForm()" variant="primary" size="sm">
          <Plus :size="18" />
          Criar Ativo
        </Button>
        <Modal v-model="showAssetModal" :title="editingAssetId === null ? 'Criar Ativo' : 'Editar Ativo'" size="lg">
          <div class="space-y-5">
            <div class="space-y-2">
              <label for="asset-qr-code" class="text-sm font-medium text-text-primary">
                QR Code
              </label>
              <input id="asset-qr-code" :value="assetForm.qrCode || 'Gerado automaticamente ao criar'" type="text" readonly
                class="w-full rounded-lg bg-gray-100 px-3 py-3 text-sm text-text-secondary outline-none" />
            </div>

            <div class="space-y-2">
              <label for="asset-name" class="text-sm font-medium text-text-primary">
                Nome <span class="text-red-primary">*</span>
              </label>
              <input id="asset-name" v-model="assetForm.name" type="text" placeholder="Digite o nome do ativo" required
                class="w-full rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
            </div>

            <div class="grid grid-cols-1 gap-5 md:grid-cols-2">
              <div class="space-y-2">
                <label for="asset-origin" class="text-sm font-medium text-text-primary">
                  Local de Origem <span class="text-red-primary">*</span>
                </label>
                <select id="asset-origin" v-model.number="assetForm.originLab" required
                  class="w-full rounded-lg bg-bg px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
                  <option disabled value="">Selecione um laboratório</option>
                  <option v-for="lab in labs" :key="`origin-${lab.id}`" :value="lab.id">
                    {{ lab.title }} - {{ lab.acronym }}
                  </option>
                </select>
              </div>

              <div class="space-y-2">
                <label for="asset-current" class="text-sm font-medium text-text-primary">
                  Local Atual <span class="text-red-primary">*</span>
                </label>
                <select id="asset-current" v-model.number="assetForm.currentLab" required
                  class="w-full rounded-lg bg-bg px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
                  <option disabled value="">Selecione um laboratório</option>
                  <option v-for="lab in labs" :key="`current-${lab.id}`" :value="lab.id">
                    {{ lab.title }} - {{ lab.acronym }}
                  </option>
                </select>
              </div>
            </div>

            <div class="space-y-2">
              <label for="asset-group" class="text-sm font-medium text-text-primary">
                Grupo <span class="text-red-primary">*</span>
              </label>
              <select id="asset-group" v-model="assetForm.group" required
                class="w-full rounded-lg bg-bg px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
                <option value="">Selecione</option>
                <option v-for="group in groups" :key="group.id_grupo_a" :value="group.id_grupo_a">
                  {{ group.nome }}
                </option>
              </select>
            </div>

            <div class="space-y-2">
              <label for="asset-status" class="text-sm font-medium text-text-primary">
                Status
              </label>
              <select id="asset-status" v-model="assetForm.status"
                class="w-full rounded-lg bg-bg px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
                <option value="Ativo">Ativo</option>
                <option value="Inativo">Inativo</option>
              </select>
            </div>

            <div class="space-y-2">
              <label for="asset-description" class="text-sm font-medium text-text-primary">
                Descrição
              </label>
              <textarea id="asset-description" v-model="assetForm.description" rows="4" placeholder="Descreva o ativo"
                class="w-full resize-none rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary"></textarea>
            </div>
            <p v-if="assetValidationMessage" class="text-sm font-medium text-red-primary" role="alert">
              {{ assetValidationMessage }}
            </p>
          </div>

          <template #footer>
            <Button variant="outline" @click="showAssetModal = false; editingAssetId = null">
              Cancelar
            </Button>
            <Button variant="primary" @click="createAsset">
              {{ editingAssetId === null ? 'Criar' : 'Salvar' }}
            </Button>
          </template>
        </Modal>

        <Modal v-model="showGroupModal" title="Gerenciar grupos" size="lg">
          <div class="grid gap-8 md:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
            <section class="space-y-4" aria-label="Formulário de grupo">
              <h3 class="text-base font-semibold text-text-primary">
                {{ editingGroupId === null ? 'Novo grupo' : 'Editar grupo' }}
              </h3>
              <div class="space-y-2">
                <label for="group-name" class="text-sm font-medium text-text-primary">Nome *</label>
                <input id="group-name" v-model="groupForm.nome" type="text" maxlength="100" required
                  class="w-full rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
              </div>
              <div class="space-y-2">
                <label for="group-number-ta" class="text-sm font-medium text-text-primary">Número TA *</label>
                <input id="group-number-ta" v-model="groupForm.numeroTa" type="number" min="1" step="1" required
                  class="w-full rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
              </div>
              <div class="space-y-2">
                <label for="group-type" class="text-sm font-medium text-text-primary">Tipo *</label>
                <input id="group-type" v-model="groupForm.tipo" type="text" maxlength="50" required
                  class="w-full rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
              </div>
              <div class="space-y-2">
                <label for="group-sector" class="text-sm font-medium text-text-primary">Setor *</label>
                <input id="group-sector" v-model="groupForm.setor" type="text" maxlength="100" required
                  class="w-full rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
              </div>
              <p v-if="groupValidationMessage" class="text-sm font-medium text-red-primary" role="alert">
                {{ groupValidationMessage }}
              </p>
              <div class="flex flex-wrap gap-3">
                <Button variant="primary" size="sm" @click="saveGroup">
                  {{ editingGroupId === null ? 'Criar grupo' : 'Salvar alterações' }}
                </Button>
                <Button v-if="editingGroupId !== null" variant="outline" size="sm" @click="resetGroupForm">
                  Cancelar edição
                </Button>
              </div>
            </section>

            <section class="min-w-0" aria-label="Grupos cadastrados">
              <h3 class="mb-3 text-base font-semibold text-text-primary">Grupos cadastrados</h3>
              <p v-if="groups.length === 0" class="rounded-lg bg-bg-red px-4 py-6 text-sm text-text-secondary">
                Nenhum grupo cadastrado.
              </p>
              <ul v-else class="max-h-80 divide-y divide-gray-200 overflow-y-auto">
                <li v-for="group in groups" :key="group.id_grupo_a"
                  class="flex min-w-0 items-center justify-between gap-3 py-3">
                  <div class="min-w-0">
                    <p class="break-words text-sm font-medium text-text-primary">{{ group.nome }}</p>
                    <p class="break-words text-xs text-text-secondary">
                      TA {{ group.numero_ta }} · {{ group.tipo }} · {{ group.setor }}
                    </p>
                  </div>
                  <button type="button" class="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-red-1 hover:bg-red-2"
                    :aria-label="`Editar grupo ${group.nome}`" :title="`Editar grupo ${group.nome}`"
                    @click="editGroup(group)">
                    <Pencil :size="16" />
                  </button>
                </li>
              </ul>
            </section>
          </div>
          <template #footer>
            <Button variant="outline" size="sm" @click="showGroupModal = false; resetGroupForm()">Fechar</Button>
          </template>
        </Modal>
      </div>

      <div class="flex flex-wrap items-end gap-3">
        <div class="w-60">
          <Searchbar v-model="assetSearchText" />
        </div>

        <label class="flex min-w-36 flex-1 flex-col gap-2 text-sm text-text-primary">
          Patrimônio
          <select v-model="assetFilters.patrimony"
            class="rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-gray-200 focus:ring-red-primary">
            <option value="">Selecione</option>
            <option v-for="patrimony in patrimonyOptions" :key="patrimony" :value="patrimony">
              {{ patrimony }}
            </option>
          </select>
        </label>

        <label class="flex min-w-36 flex-1 flex-col gap-2 text-sm text-text-primary">
          Nome
          <select v-model="assetFilters.name"
            class="rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-gray-200 focus:ring-red-primary">
            <option value="">Selecione</option>
            <option v-for="name in nameOptions" :key="name" :value="name">
              {{ name }}
            </option>
          </select>
        </label>

        <label class="flex min-w-36 flex-1 flex-col gap-2 text-sm text-text-primary">
          Local
          <select v-model="assetFilters.location"
            class="rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-gray-200 focus:ring-red-primary">
            <option value="">Selecione</option>
            <option v-for="location in locationOptions" :key="location" :value="location">
              {{ location }}
            </option>
          </select>
        </label>

        <label class="flex min-w-36 flex-1 flex-col gap-2 text-sm text-text-primary">
          Status
          <select v-model="assetFilters.status"
            class="rounded-lg bg-white px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-gray-200 focus:ring-red-primary">
            <option value="">Selecione</option>
            <option v-for="status in statusOptions" :key="status" :value="status">
              {{ status }}
            </option>
          </select>
        </label>

        <Button variant="outline" size="sm" @click="clearAssetFilters">
          Limpar filtros
        </Button>
      </div>

      <Table :columns="columns" :rows="filteredRows" row-key="id"
        :actions="canManageAssets ? ['view', 'edit'] : ['view']" @row-action="handleRowAction" />

      <Modal v-model="showDetailsModal" title="Detalhes do ativo" size="md">
        <div v-if="selectedAsset" class="space-y-5 border-t border-red-primary pt-4">
          <dl class="space-y-4 text-sm">
            <div class="grid grid-cols-1 gap-1 sm:grid-cols-[minmax(0,auto)_minmax(0,1fr)] sm:gap-6">
              <dt class="font-medium text-text-primary">QR Code</dt>
              <dd class="break-words text-text-secondary sm:text-right">{{ selectedAsset.patrimony }}</dd>
            </div>
            <div class="grid grid-cols-1 gap-1 sm:grid-cols-[minmax(0,auto)_minmax(0,1fr)] sm:gap-6">
              <dt class="font-medium text-text-primary">Nome</dt>
              <dd class="break-words text-text-secondary sm:text-right">{{ selectedAsset.name }}</dd>
            </div>
            <div class="grid grid-cols-1 gap-1 sm:grid-cols-[minmax(0,auto)_minmax(0,1fr)] sm:gap-6">
              <dt class="font-medium text-text-primary">Local de Origem</dt>
              <dd class="break-words text-text-secondary sm:text-right">{{ selectedAsset.origin }}</dd>
            </div>
            <div class="grid grid-cols-1 gap-1 sm:grid-cols-[minmax(0,auto)_minmax(0,1fr)] sm:gap-6">
              <dt class="font-medium text-text-primary">Local Atual</dt>
              <dd class="break-words text-text-secondary sm:text-right">{{ selectedAsset.current }}</dd>
            </div>
            <div class="grid grid-cols-1 gap-1 sm:grid-cols-[minmax(0,auto)_minmax(0,1fr)] sm:gap-6">
              <dt class="font-medium text-text-primary">Grupo</dt>
              <dd class="break-words text-text-secondary sm:text-right">{{ selectedAsset.category }}</dd>
            </div>
            <div class="grid grid-cols-1 gap-1 sm:grid-cols-[minmax(0,auto)_minmax(0,1fr)] sm:gap-6">
              <dt class="font-medium text-text-primary">Status</dt>
              <dd class="break-words text-text-secondary sm:text-right">{{ selectedAsset.status }}</dd>
            </div>
            <div class="space-y-2">
              <dt class="font-medium text-text-primary">Descrição</dt>
              <dd class="break-words whitespace-pre-wrap text-text-secondary">{{ selectedAsset.description }}</dd>
            </div>
          </dl>

          <section class="border-t border-gray-200 pt-4" aria-label="Histórico de movimentações">
            <h3 class="text-base font-semibold text-text-primary">Histórico de movimentações</h3>
            <p v-if="isLoadingAssetMovements" class="mt-3 text-sm text-text-secondary" role="status">
              Carregando movimentações...
            </p>
            <p v-else-if="assetMovementsError" class="mt-3 text-sm text-red-primary" role="alert">
              {{ assetMovementsError }}
              <button class="ml-1 font-semibold underline" type="button" @click="loadSelectedAssetHistory(selectedAsset.id)">
                Tentar novamente
              </button>
            </p>
            <p v-else-if="selectedAssetMovements.length === 0" class="mt-3 text-sm text-text-secondary">
              Nenhuma movimentação registrada para este ativo.
            </p>
            <ol v-else class="mt-3 max-h-56 space-y-3 overflow-y-auto pr-1">
              <li v-for="movement in selectedAssetMovements" :key="movement.id_mov"
                class="border-l-2 border-red-primary/30 pl-3">
                <p class="text-sm font-semibold text-text-primary">
                  {{ movement.usuario_detalhes?.nome || 'Usuário' }} · {{ formatMovementDate(movement.data_hora) }}
                </p>
                <p class="mt-1 text-sm text-text-secondary">Destino: {{ movement.local_m }}</p>
                <p class="mt-1 break-words text-xs text-text-secondary">{{ movement.justificativa }}</p>
              </li>
            </ol>
          </section>
        </div>

        <template #footer>
          <Button v-if="canManageAssets" variant="outline" @click="openAssetForm(selectedAsset)">
            <Pencil :size="16" />
            Editar
          </Button>
          <Button variant="primary" @click="openMovementForm(selectedAsset)">
            <ArrowRightLeft :size="16" />
            Movimentar
          </Button>
        </template>
      </Modal>

    </section>

    <section v-else class="space-y-6" aria-labelledby="movements-title">
      <div class="flex flex-col items-start justify-between gap-4 sm:flex-row sm:items-center">
        <div>
          <h1 id="movements-title" class="text-xl font-semibold text-text-primary">Histórico de movimentações</h1>
          <p class="mt-1 text-sm text-text-secondary">Movimentações de todos os ativos disponíveis para sua conta.</p>
        </div>
        <div class="w-full sm:w-72">
          <Searchbar v-model="movementSearchText" />
        </div>
        <div class="flex flex-wrap gap-2">
          <Button variant="primary" size="sm" @click="openMovementForm()">
            <ArrowRightLeft :size="18" />
            Nova movimentação
          </Button>
          <button v-if="canClearMovementHistory && allMovementRecords.length"
            class="inline-flex items-center gap-2 rounded-lg border border-red-primary px-3 py-2 text-sm font-semibold text-red-primary transition hover:bg-red-2"
            type="button" @click="requestConfirmation('clear-movements')">
            <Trash2 :size="16" /> Limpar histórico
          </button>
        </div>
      </div>

      <p v-if="clearMovementHistoryError" class="text-sm text-red-primary" role="alert">
        {{ clearMovementHistoryError }}
      </p>
      <p v-if="isLoadingMovementHistory" class="rounded-lg bg-white px-4 py-6 text-sm text-text-secondary" role="status">
        Carregando movimentações...
      </p>
      <div v-else-if="movementHistoryError" class="rounded-lg bg-white px-4 py-6" role="alert">
        <p class="text-sm text-red-primary">{{ movementHistoryError }}</p>
        <button class="mt-3 inline-flex items-center gap-2 text-sm font-semibold text-red-primary hover:underline"
          type="button" @click="loadMovementHistory">
          <RefreshCw :size="16" /> Tentar novamente
        </button>
      </div>
      <p v-else-if="allMovementRecords.length === 0" class="rounded-lg bg-white px-4 py-6 text-sm text-text-secondary">
        Nenhuma movimentação registrada.
      </p>
      <p v-else-if="filteredMovementRows.length === 0" class="rounded-lg bg-white px-4 py-6 text-sm text-text-secondary">
        Nenhuma movimentação corresponde à pesquisa.
      </p>
      <Table v-else :columns="movementColumns" :rows="filteredMovementRows" row-key="id" :actions="[]" />
    </section>

    <Modal v-model="showMovementModal" title="Movimentar ativo" size="md">
      <div class="space-y-5">
        <div v-if="selectedAsset" class="space-y-2">
          <span class="text-sm font-medium text-text-primary">Ativo</span>
          <p class="rounded-lg bg-bg px-3 py-3 text-sm text-text-secondary">
            {{ selectedAsset.name }} · {{ selectedAsset.patrimony }}
          </p>
        </div>
        <div v-else class="space-y-2">
          <label for="movement-asset" class="text-sm font-medium text-text-primary">
            Ativo <span class="text-red-primary">*</span>
          </label>
          <select id="movement-asset" v-model.number="movementForm.assetId" required @change="selectMovementAsset"
            class="w-full rounded-lg bg-bg px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
            <option disabled value="">Selecione um ativo</option>
            <option v-for="asset in rows" :key="`movement-asset-${asset.id}`" :value="asset.id">
              {{ asset.name }} · {{ asset.patrimony }} · {{ asset.current }}
            </option>
          </select>
        </div>
        <div class="space-y-2">
          <label for="movement-location" class="text-sm font-medium text-text-primary">
            Novo local <span class="text-red-primary">*</span>
          </label>
          <select id="movement-location" v-model.number="movementForm.labId" required
            class="w-full rounded-lg bg-bg px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
            <option disabled value="">Selecione um laboratório</option>
            <option v-for="lab in labs" :key="`movement-${lab.id}`" :value="lab.id">
              {{ lab.title }} - {{ lab.acronym }}
            </option>
          </select>
        </div>
        <div class="space-y-2">
          <label for="movement-justification" class="text-sm font-medium text-text-primary">
            Justificativa <span class="text-red-primary">*</span>
          </label>
          <textarea id="movement-justification" v-model="movementForm.justification" rows="3" required
            class="w-full resize-none rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary"></textarea>
        </div>
        <p v-if="movementValidationMessage" class="text-sm font-medium text-red-primary" role="alert">
          {{ movementValidationMessage }}
        </p>
      </div>
      <template #footer>
        <Button variant="outline" @click="showMovementModal = false">Cancelar</Button>
        <Button variant="primary" @click="submitMovement">Confirmar movimentação</Button>
      </template>
    </Modal>

    <Modal v-model="showLabDeletionErrorModal" title="Não foi possível excluir" size="sm">
      <div class="flex items-start gap-3 rounded-2xl bg-bg-red p-4 text-sm text-text-primary">
        <AlertTriangle class="mt-0.5 shrink-0 text-red-primary" :size="20" aria-hidden="true" />
        <p>{{ labDeletionErrorMessage }}</p>
      </div>

      <template #footer>
        <Button variant="outline" size="sm" @click="showLabDeletionErrorModal = false">
          Fechar
        </Button>
        <Button variant="primary" size="sm" @click="goToAssetsFromLabDeletionError">
          Ir para ativos
        </Button>
      </template>
    </Modal>

    <ConfirmModal v-model="showConfirmation" :title="confirmationAction === 'delete-lab'
      ? 'Excluir laboratório'
      : confirmationAction === 'clear-movements'
        ? 'Limpar histórico de movimentações'
        : 'Salvar ativo'" :message="confirmationAction === 'delete-lab'
        ? 'Tem certeza que deseja excluir este laboratório? Essa ação não pode ser revertida.'
        : confirmationAction === 'clear-movements'
          ? 'Tem certeza que deseja excluir permanentemente todas as movimentações? Esta ação não pode ser desfeita.'
          : 'Tem certeza que deseja salvar as alterações deste ativo?'"
      :confirm-text="confirmationAction === 'delete-lab' || confirmationAction === 'clear-movements' ? 'Excluir permanentemente' : 'Salvar'"
      @confirm="confirmAction" />
  </main>
</template>
