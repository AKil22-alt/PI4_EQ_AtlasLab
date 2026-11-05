<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import {
  createLaboratoryRequest,
  listLaboratoriesRequest,
  listLaboratoryResponsiblesRequest,
  updateLaboratoryRequest,
  deleteLaboratoryRequest,
  listAssetsRequest,
  listAssetGroupsRequest,
  createAssetGroupRequest,
  updateAssetGroupRequest,
  createAssetRequest,
  updateAssetRequest,
  moveAssetRequest
} from '../services/api'
import Table from '../components/Table.vue';
import LineChart from '../components/LineChart.vue'
import LabCard from '../components/LabCard.vue';
import Button from '../components/Button.vue';
import Searchbar from '../components/Searchbar.vue';
import { AlertTriangle, ArrowRightLeft, Layers, Pencil, Plus } from 'lucide-vue-next';
import Modal from '../components/Modal.vue';
import ConfirmModal from '../components/ConfirmModal.vue';
import { useAuthStore } from '../store/auth'

const authStore = useAuthStore()
const activeTab = ref('labs')
const searchText = ref('')
const assetSearchText = ref('')

const labs = reactive([])
const groups = reactive([])
const laboratoryResponsibles = reactive([])
const canManageLabs = computed(() => ['ADM', 'TEC'].includes(authStore.currentUser?.cargo))
const canManageAssets = computed(() => ['ADM', 'TEC'].includes(authStore.currentUser?.cargo))

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
  return {
    id: asset.id_ativos,
    patrimony: asset.qr_code || '',
    name: asset.nome,
    origin: asset.local_origem,
    current: asset.local_atual,
    roomId: asset.sala,
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
  origin: '',
  current: '',
  room: '',
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
  local: '',
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
  assetForm.origin = ''
  assetForm.current = ''
  assetForm.room = ''
  assetForm.group = ''
  assetForm.status = 'Ativo'
  assetForm.description = ''
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
  editingAssetId.value = asset?.id ?? null
  assetForm.qrCode = asset?.patrimony ?? ''
  assetForm.name = asset?.name ?? ''
  assetForm.origin = asset?.origin ?? ''
  assetForm.current = asset?.current ?? ''
  assetForm.room = asset?.roomId ?? ''
  assetForm.group = asset?.groupId ?? ''
  assetForm.status = asset?.status ?? 'Ativo'
  assetForm.description = asset?.description ?? ''
  showAssetModal.value = true
}

async function createAsset() {
  if (!assetForm.name.trim() || !assetForm.origin.trim() || !assetForm.current.trim() || !assetForm.group) {
    return
  }

  if (editingAssetId.value !== null) {
    requestConfirmation('save-asset')
    return
  }

  try {
    const payload = {
      nome: assetForm.name.trim(),
      local_origem: assetForm.origin.trim(),
      local_atual: assetForm.current.trim(),
      grupo: Number(assetForm.group),
      sala: assetForm.room ? Number(assetForm.room) : null,
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

  try {
    const updatedAsset = await updateAssetRequest(asset.id, {
      nome: assetForm.name.trim(),
      local_origem: assetForm.origin.trim(),
      local_atual: assetForm.current.trim(),
      grupo: Number(assetForm.group),
      sala: assetForm.room ? Number(assetForm.room) : null,
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

function openMovementForm(asset) {
  selectedAsset.value = asset
  showDetailsModal.value = false
  movementForm.local = asset.current
  movementForm.justification = ''
  showMovementModal.value = true
}

async function submitMovement() {
  if (!selectedAsset.value || !movementForm.local.trim() || !movementForm.justification.trim()) return

  try {
    await moveAssetRequest(selectedAsset.value.id, {
      local_m: movementForm.local.trim(),
      justificativa: movementForm.justification.trim()
    })

    const updatedLocation = movementForm.local.trim()
    selectedAsset.value.current = updatedLocation
    const asset = rows.find((row) => row.id === selectedAsset.value.id)
    if (asset) asset.current = updatedLocation
    showMovementModal.value = false
  } catch (error) {
    console.error('Erro ao movimentar ativo:', error)
  }
}

function requestConfirmation(action) {
  confirmationAction.value = action
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
    showDetailsModal.value = true
  } else if (action === 'edit') {
    openAssetForm(row)
  }
}
</script>

<template>
  <main class="min-w-0 space-y-6 px-4 pb-8 pt-0 sm:px-8">
    <nav class="-mx-8 flex gap-6 border-b border-red-1 bg-white px-8" aria-label="Seções de laboratórios e ativos">
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

      <LineChart title="Histórico de Ativos" :labels="[
        'B-101', 'B-101', 'B-101', 'B-101', 'B-101',
        'B-101', 'B-101', 'B-101', 'B-101', 'B-101'
      ]" :values="[5, 12, 8, 15, 15, 22, 18, 22, 8, 5]" />
      <div class="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-3">
        <LabCard v-for="lab in filteredLabs" :key="lab.id" :acronym="lab.acronym" :title="lab.title"
          :responsible="lab.responsible" :can-manage="canManageLabs"
          @view-assets="activeTab = 'assets'" @view-details="openLabDetails(lab)"
          @edit="openLabForm(lab)" @delete="requestLabDeletion(lab)" />
      </div>
    </section>

    <section v-else class="space-y-6" aria-labelledby="assets-title">
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
                <input id="asset-origin" v-model="assetForm.origin" type="text" placeholder="Ex.: Almoxarifado" required
                  class="w-full rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
              </div>

              <div class="space-y-2">
                <label for="asset-current" class="text-sm font-medium text-text-primary">
                  Local Atual <span class="text-red-primary">*</span>
                </label>
                <input id="asset-current" v-model="assetForm.current" type="text" placeholder="Ex.: Laboratório B-101" required
                  class="w-full rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
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
              <label for="asset-room" class="text-sm font-medium text-text-primary">Sala vinculada</label>
              <select id="asset-room" v-model="assetForm.room"
                class="w-full rounded-lg bg-bg px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
                <option value="">Sem sala vinculada</option>
                <option v-for="lab in labs" :key="`asset-room-${lab.id}`" :value="lab.id">
                  {{ lab.acronym }} - {{ lab.title }}
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

      <Modal v-model="showMovementModal" title="Movimentar ativo" size="md">
        <div class="space-y-5">
          <div class="space-y-2">
            <label for="movement-location" class="text-sm font-medium text-text-primary">
              Novo local <span class="text-red-primary">*</span>
            </label>
            <input id="movement-location" v-model="movementForm.local" type="text" required
              class="w-full rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
          </div>
          <div class="space-y-2">
            <label for="movement-justification" class="text-sm font-medium text-text-primary">
              Justificativa <span class="text-red-primary">*</span>
            </label>
            <textarea id="movement-justification" v-model="movementForm.justification" rows="3" required
              class="w-full resize-none rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary"></textarea>
          </div>
        </div>
        <template #footer>
          <Button variant="outline" @click="showMovementModal = false">Cancelar</Button>
          <Button variant="primary" @click="submitMovement">Confirmar movimentação</Button>
        </template>
      </Modal>

    </section>

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
      : 'Salvar ativo'" :message="confirmationAction === 'delete-lab'
        ? 'Tem certeza que deseja excluir este laboratório? Essa ação não pode ser revertida.'
        : 'Tem certeza que deseja salvar as alterações deste ativo?'"
      :confirm-text="confirmationAction === 'delete-lab' ? 'Excluir' : 'Salvar'"
      @confirm="confirmAction" />
  </main>
</template>
