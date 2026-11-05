<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import {
  createLaboratoryRequest,
  listLaboratoriesRequest,
  listLaboratoryResponsiblesRequest,
  updateLaboratoryRequest,
  deleteLaboratoryRequest,
  listAssetsRequest,
  listCategoriesRequest,
  createAssetRequest,
  updateAssetRequest,
  deleteAssetRequest
} from '../services/api'
import Table from '../components/Table.vue';
import LineChart from '../components/LineChart.vue'
import LabCard from '../components/LabCard.vue';
import Button from '../components/Button.vue';
import Searchbar from '../components/Searchbar.vue';
import { AlertTriangle, ArrowRightLeft, Pencil, Plus } from 'lucide-vue-next';
import Modal from '../components/Modal.vue';
import ConfirmModal from '../components/ConfirmModal.vue';
import { useAuthStore } from '../store/auth'

const authStore = useAuthStore()
const activeTab = ref('labs')
const searchText = ref('')
const assetSearchText = ref('')

const labs = reactive([])
const categories = reactive([])
const laboratoryResponsibles = reactive([])
const canManageLabs = computed(() => ['ADM', 'TEC'].includes(authStore.currentUser?.cargo))

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
  const origin = asset.laboratorio_origem_detalhes || asset.laboratorio_detalhes
  const originId = asset.laboratorio_origem ?? asset.laboratorio

  return {
    id: asset.id,
    patrimony: asset.patrimonio || '',
    name: asset.nome,
    originId,
    currentId: asset.laboratorio,
    origin: origin?.localizacao || 'Não informado',
    current: asset.laboratorio_detalhes?.localizacao || 'Não informado',
    categoryId: asset.categoria,
    category: asset.categoria_detalhes?.nome || 'Não informado',
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
    const categoryList = await listCategoriesRequest()
    categories.push(...(Array.isArray(categoryList) ? categoryList : categoryList.results))
  } catch (error) {
    console.error('Erro ao carregar categorias:', error)
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
  { key: 'patrimony', label: 'Patrimônio', width: '8%' },
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
const showDetailsModal = ref(false)
const selectedAsset = ref(null)
const selectedLab = ref(null)
const showConfirmation = ref(false)
const confirmationAction = ref(null)
const editingLabId = ref(null)
const editingAssetId = ref(null)
const pendingLabId = ref(null)
const pendingAssetId = ref(null)
const labValidationMessage = ref('')
const showLabDeletionErrorModal = ref(false)
const labDeletionErrorMessage = ref('')

const labForm = reactive({
  acronym: '',
  name: '',
  numeroTa: '',
  responsible: null
})

const assetForm = reactive({
  patrimony: '',
  name: '',
  origin: '',
  current: '',
  category: '',
  status: 'Ativo',
  description: ''
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
  assetForm.patrimony = ''
  assetForm.name = ''
  assetForm.origin = ''
  assetForm.current = ''
  assetForm.category = ''
  assetForm.status = 'Ativo'
  assetForm.description = ''
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
  assetForm.patrimony = asset?.patrimony ?? ''
  assetForm.name = asset?.name ?? ''
  assetForm.origin = asset?.originId ?? ''
  assetForm.current = asset?.currentId ?? ''
  assetForm.category = asset?.categoryId ?? ''
  assetForm.status = asset?.status ?? 'Ativo'
  assetForm.description = asset?.description ?? ''
  showAssetModal.value = true
}

async function createAsset() {
  if (!assetForm.name.trim()) {
    return
  }

  if (!assetForm.category || !assetForm.current) {
    return
  }

  if (editingAssetId.value !== null) {
    requestConfirmation('save-asset')
    return
  }

  try {
    const asset = await createAssetRequest({
      patrimonio: assetForm.patrimony.trim(),
      nome: assetForm.name.trim(),
      descricao: assetForm.description.trim(),
      status: assetForm.status === 'Ativo',
      categoria: Number(assetForm.category),
      laboratorio_origem: Number(assetForm.origin),
      laboratorio: Number(assetForm.current)
    })

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
      patrimonio: assetForm.patrimony.trim(),
      nome: assetForm.name.trim(),
      descricao: assetForm.description.trim(),
      status: assetForm.status === 'Ativo',
      categoria: Number(assetForm.category),
      laboratorio_origem: Number(assetForm.origin),
      laboratorio: Number(assetForm.current)
    })

    Object.assign(asset, {
      patrimony: updatedAsset.patrimonio || '',
      name: updatedAsset.nome,
      originId: updatedAsset.laboratorio_origem ?? updatedAsset.laboratorio,
      currentId: updatedAsset.laboratorio,
      origin: (updatedAsset.laboratorio_origem_detalhes || updatedAsset.laboratorio_detalhes)?.localizacao || 'Não informado',
      current: updatedAsset.laboratorio_detalhes?.localizacao || 'Não informado',
      categoryId: updatedAsset.categoria,
      category: updatedAsset.categoria_detalhes?.nome || 'Não informado',
      status: updatedAsset.status ? 'Ativo' : 'Inativo',
      description: updatedAsset.descricao || ''
    })
    showAssetModal.value = false
    editingAssetId.value = null
    resetAssetForm()
  } catch (error) {
    console.error('Erro ao editar ativo:', error)
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

function requestAssetDeletion(asset) {
  pendingAssetId.value = asset.id
  requestConfirmation('delete-asset')
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

  if (action === 'delete-asset') {
    try {
      await deleteAssetRequest(pendingAssetId.value)

      const assetIndex = rows.findIndex(
        (asset) => String(asset.id) === String(pendingAssetId.value)
      )

      if (assetIndex !== -1) {
        rows.splice(assetIndex, 1)
      }

      if (selectedAsset.value?.id === pendingAssetId.value) {
        selectedAsset.value = null
        showDetailsModal.value = false
      }

      pendingAssetId.value = null
    } catch (error) {
      console.error('Erro ao excluir ativo:', error)
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
  } else if (action === 'delete') {
    requestAssetDeletion(row)
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
      <div class="flex justify-end">
        <Button @click="openAssetForm()" variant="primary" size="sm">
          <Plus :size="18" />
          Criar Ativo
        </Button>
        <Modal v-model="showAssetModal" :title="editingAssetId === null ? 'Criar Ativo' : 'Editar Ativo'" size="lg">
          <div class="space-y-5">
            <div class="space-y-2">
              <label for="asset-patrimony" class="text-sm font-medium text-text-primary">
                Patrimônio <span class="text-red-primary">*</span>
              </label>
              <input id="asset-patrimony" v-model="assetForm.patrimony" type="text"
                placeholder="Digite o patrimônio do ativo" required
                class="w-full rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
            </div>

            <div class="space-y-2">
              <label for="asset-name" class="text-sm font-medium text-text-primary">
                Nome
              </label>
              <input id="asset-name" v-model="assetForm.name" type="text" placeholder="Digite o nome do ativo"
                class="w-full rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
            </div>

            <div class="grid grid-cols-1 gap-5 md:grid-cols-2">
              <div class="space-y-2">
                <label for="asset-origin" class="text-sm font-medium text-text-primary">
                  Local de Origem
                </label>
                <select id="asset-origin" v-model="assetForm.origin"
                  class="w-full rounded-lg bg-bg px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
                  <option value="">Selecione</option>
                  <option v-for="lab in labs" :key="`origin-${lab.id}`" :value="lab.id">
                    {{ lab.acronym }} - {{ lab.title }}
                  </option>
                </select>
              </div>

              <div class="space-y-2">
                <label for="asset-current" class="text-sm font-medium text-text-primary">
                  Local Atual
                </label>
                <select id="asset-current" v-model="assetForm.current"
                  class="w-full rounded-lg bg-bg px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
                  <option value="">Selecione</option>
                  <option v-for="lab in labs" :key="`current-${lab.id}`" :value="lab.id">
                    {{ lab.acronym }} - {{ lab.title }}
                  </option>
                </select>
              </div>
            </div>

            <div class="space-y-2">
              <label for="asset-category" class="text-sm font-medium text-text-primary">
                Categoria
              </label>
              <select id="asset-category" v-model="assetForm.category"
                class="w-full rounded-lg bg-bg px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
                <option value="">Selecione</option>
                <option v-for="category in categories" :key="category.id" :value="category.id">
                  {{ category.nome }}
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

      <Table :columns="columns" :rows="filteredRows" row-key="id" @row-action="handleRowAction" />

      <Modal v-model="showDetailsModal" title="Detalhes do ativo" size="md">
        <div v-if="selectedAsset" class="space-y-5 border-t border-red-primary pt-4">
          <dl class="space-y-4 text-sm">
            <div class="grid grid-cols-1 gap-1 sm:grid-cols-[minmax(0,auto)_minmax(0,1fr)] sm:gap-6">
              <dt class="font-medium text-text-primary">Patrimônio</dt>
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
              <dt class="font-medium text-text-primary">Categoria</dt>
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
          <Button variant="outline" @click="openAssetForm(selectedAsset)">
            <Pencil :size="16" />
            Editar
          </Button>
          <Button variant="primary">
            <ArrowRightLeft :size="16" />
            Movimentar
          </Button>
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
      : confirmationAction === 'delete-asset'
        ? 'Excluir ativo'
        : 'Salvar ativo'" :message="confirmationAction === 'delete-lab'
        ? 'Tem certeza que deseja excluir este laboratório? Essa ação não pode ser revertida.'
        : confirmationAction === 'delete-asset'
          ? 'Tem certeza que deseja excluir este ativo? Essa ação não pode ser revertida.'
          : 'Tem certeza que deseja salvar as alterações deste ativo?'"
      :confirm-text="confirmationAction === 'delete-lab' || confirmationAction === 'delete-asset' ? 'Excluir' : 'Salvar'"
      @confirm="confirmAction" />
  </main>
</template>
