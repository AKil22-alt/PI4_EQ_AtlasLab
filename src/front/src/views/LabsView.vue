<script setup>
import { computed, reactive, ref } from 'vue';
import Table from '../components/Table.vue';
import LineChart from '../components/LineChart.vue'
import LabCard from '../components/LabCard.vue';
import Button from '../components/Button.vue';
import Searchbar from '../components/Searchbar.vue';
import { ArrowRightLeft, Pencil, Plus } from 'lucide-vue-next';
import Modal from '../components/Modal.vue';
import ConfirmModal from '../components/ConfirmModal.vue';

const activeTab = ref('labs')
const searchText = ref('')
const assetSearchText = ref('')

const labs = reactive([
  { id: 1, acronym: 'B-101', title: 'Laboratório CAM', responsible: 'Thainara' },
  { id: 2, acronym: 'B-102', title: 'Laboratório CAD', responsible: 'Thainara' },
  { id: 3, acronym: 'B-103', title: 'Laboratório de Eletrônica', responsible: 'Thainara' },
  { id: 4, acronym: 'B-104', title: 'Laboratório de Automação', responsible: 'Thainara' }
])

const filteredLabs = computed(() => {
  const query = searchText.value.trim().toLowerCase()

  if (!query) {
    return labs
  }

  return labs.filter((lab) => [lab.acronym, lab.title, lab.responsible]
    .some((value) => value.toLowerCase().includes(query)))
})

const columns = [
  { key: 'id', label: 'Patrimônio', width: '8%' },
  { key: 'name', label: 'Nome', width: '16%' },
  { key: 'origin', label: 'Local de origem', width: '15%' },
  { key: 'current', label: 'Local atual', width: '15%' },
  { key: 'status', label: 'Status', width: '10%', type: 'status' },
  { key: 'description', label: 'Descrição', width: '28%' },
  { key: 'actions', label: 'Ações', width: '8%', type: 'actions' }
]

const rows = reactive([
  {
    id: '1256652',
    name: 'Monitor Dell 24"',
    origin: 'B-101',
    current: 'B-102',
    category: 'Tecnologia',
    status: 'Ativo',
    description: 'Manutenção preventiva da centrífuga CT-02: limpeza, inspeção do rotor, calibração.'
  },
  {
    id: '1256653',
    name: 'Monitor Dell 24"',
    origin: 'B-101',
    current: 'B-102',
    category: 'Tecnologia',
    status: 'Ativo',
    description: 'Manutenção preventiva da centrífuga CT-02: limpeza, inspeção do rotor, calibração.'
  },
  {
    id: '1256654',
    name: 'Monitor Dell 24"',
    origin: 'B-101',
    current: 'B-102',
    category: 'Tecnologia',
    status: 'Ativo',
    description: 'Manutenção preventiva da centrífuga CT-02: limpeza, inspeção do rotor, calibração.'
  }
])

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

const labForm = reactive({
  acronym: '',
  name: '',
  responsible: ''
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

const patrimonyOptions = computed(() => [...new Set(rows.map((row) => row.id))])
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
    const matchesPatrimony = !assetFilters.patrimony || row.id === assetFilters.patrimony
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
  labForm.responsible = ''
}

function openLabForm(lab = null) {
  showLabDetailsModal.value = false
  editingLabId.value = lab?.id ?? null
  labForm.acronym = lab?.acronym ?? ''
  labForm.name = lab?.title ?? ''
  labForm.responsible = lab?.responsible ?? ''
  showLabModal.value = true
}

function openLabDetails(lab) {
  selectedLab.value = lab
  showLabDetailsModal.value = true
}

function saveLab() {
  if (!labForm.acronym.trim()) return
  if (editingLabId.value !== null) {
    requestConfirmation('save-lab')
    return
  }

  labs.push({
    id: Date.now(),
    acronym: labForm.acronym.trim(),
    title: labForm.name.trim(),
    responsible: labForm.responsible
  })
  showLabModal.value = false
  resetLabForm()
}

function openAssetForm(asset = null) {
  showDetailsModal.value = false
  editingAssetId.value = asset?.id ?? null
  assetForm.patrimony = asset?.id ?? ''
  assetForm.name = asset?.name ?? ''
  assetForm.origin = asset?.origin ?? ''
  assetForm.current = asset?.current ?? ''
  assetForm.category = asset?.category ?? ''
  assetForm.status = asset?.status ?? 'Ativo'
  assetForm.description = asset?.description ?? ''
  showAssetModal.value = true
}

function createAsset() {
  if (!assetForm.patrimony.trim()) {
    return
  }

  if (editingAssetId.value !== null) {
    requestConfirmation('save-asset')
    return
  }

  rows.push({
    id: assetForm.patrimony.trim(),
    name: assetForm.name.trim(),
    origin: assetForm.origin,
    current: assetForm.current,
    category: assetForm.category,
    status: assetForm.status,
    description: assetForm.description.trim()
  })

  showAssetModal.value = false
  resetAssetForm()
}

function saveAsset() {
  const asset = rows.find((row) => row.id === editingAssetId.value)
  if (!asset) return

  Object.assign(asset, {
    id: assetForm.patrimony.trim(),
    name: assetForm.name.trim(),
    origin: assetForm.origin,
    current: assetForm.current,
    category: assetForm.category,
    status: assetForm.status,
    description: assetForm.description.trim()
  })
  showAssetModal.value = false
  editingAssetId.value = null
  resetAssetForm()
}

function requestConfirmation(action) {
  confirmationAction.value = action
  showConfirmation.value = true
}

function requestLabDeletion(lab) {
  pendingLabId.value = lab.id
  requestConfirmation('delete-lab')
}

function confirmAction() {
  if (confirmationAction.value === 'save-lab') {
    const lab = labs.find((item) => item.id === editingLabId.value)
    if (lab) Object.assign(lab, {
      acronym: labForm.acronym.trim(),
      title: labForm.name.trim(),
      responsible: labForm.responsible
    })
    showLabModal.value = false
    editingLabId.value = null
    resetLabForm()
  }

  if (confirmationAction.value === 'save-asset') saveAsset()

  if (confirmationAction.value === 'delete-lab') {
    const labIndex = labs.findIndex((lab) => lab.id === pendingLabId.value)
    if (labIndex !== -1) labs.splice(labIndex, 1)
    pendingLabId.value = null
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
  <main class="space-y-6 px-8 pb-8 pt-0">
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
      <div class="flex items-center justify-between gap-4">
        <div class="w-60">
          <Searchbar v-model="searchText" />
        </div>

        <Button @click="openLabForm()" variant="primary" size="sm">
          <Plus :size="18" />
          Criar Laboratório
        </Button>
      </div>
      <Modal v-model="showLabModal" :title="editingLabId === null ? 'Criar Laboratório' : 'Editar Laboratório'" size="lg">
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
              Nome
            </label>
            <input id="lab-name" v-model="labForm.name" type="text" placeholder="Laboratório CAM"
              class="w-full rounded-lg bg-bg px-3 py-3 text-sm outline-none ring-1 ring-transparent transition focus:ring-red-primary" />
          </div>

          <div class="space-y-2">
            <label for="lab-responsible" class="text-sm font-medium text-text-primary">
              Responsável <span class="text-red-primary">*</span>
            </label>
            <select id="lab-responsible" v-model="labForm.responsible" required
              class="w-full rounded-lg bg-bg px-3 py-3 text-sm text-text-secondary outline-none ring-1 ring-transparent transition focus:ring-red-primary">
              <option disabled value="">Selecione</option>
              <option value="responsible-1">Responsável 1</option>
              <option value="responsible-2">Responsável 2</option>
            </select>
          </div>
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
            <div class="flex items-start justify-between gap-6">
              <dt class="font-medium text-text-primary">Sigla</dt>
              <dd class="text-right text-text-secondary">{{ selectedLab.acronym }}</dd>
            </div>
            <div class="flex items-start justify-between gap-6">
              <dt class="font-medium text-text-primary">Nome</dt>
              <dd class="text-right text-text-secondary">{{ selectedLab.title }}</dd>
            </div>
            <div class="flex items-start justify-between gap-6">
              <dt class="font-medium text-text-primary">Responsável</dt>
              <dd class="text-right text-text-secondary">{{ selectedLab.responsible }}</dd>
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
          :responsible="lab.responsible" @view-assets="activeTab = 'assets'" @view-details="openLabDetails(lab)"
          @edit="openLabDetails(lab)"
          @delete="requestLabDeletion(lab)" />
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
            <input id="asset-patrimony" v-model="assetForm.patrimony" type="text" placeholder="Digite o patrimônio do ativo" required
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
                <option v-for="location in locationOptions" :key="`origin-${location}`" :value="location">
                  {{ location }}
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
                <option v-for="location in locationOptions" :key="`current-${location}`" :value="location">
                  {{ location }}
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
              <option value="Equipamento">Equipamento</option>
              <option value="Mobiliário">Mobiliário</option>
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
            <textarea id="asset-description" v-model="assetForm.description" rows="4"
              placeholder="Descreva o ativo"
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

      <Table
        :columns="columns"
        :rows="filteredRows"
        row-key="id"
        @row-action="handleRowAction"
      />

      <Modal v-model="showDetailsModal" title="Detalhes do ativo" size="md">
        <div v-if="selectedAsset" class="space-y-5 border-t border-red-primary pt-4">
          <dl class="space-y-4 text-sm">
            <div class="flex items-start justify-between gap-6">
              <dt class="font-medium text-text-primary">Patrimônio</dt>
              <dd class="text-right text-text-secondary">{{ selectedAsset.id }}</dd>
            </div>
            <div class="flex items-start justify-between gap-6">
              <dt class="font-medium text-text-primary">Nome</dt>
              <dd class="text-right text-text-secondary">{{ selectedAsset.name }}</dd>
            </div>
            <div class="flex items-start justify-between gap-6">
              <dt class="font-medium text-text-primary">Local de Origem</dt>
              <dd class="text-right text-text-secondary">{{ selectedAsset.origin }}</dd>
            </div>
            <div class="flex items-start justify-between gap-6">
              <dt class="font-medium text-text-primary">Local Atual</dt>
              <dd class="text-right text-text-secondary">{{ selectedAsset.current }}</dd>
            </div>
            <div class="flex items-start justify-between gap-6">
              <dt class="font-medium text-text-primary">Categoria</dt>
              <dd class="text-right text-text-secondary">{{ selectedAsset.category }}</dd>
            </div>
            <div class="flex items-start justify-between gap-6">
              <dt class="font-medium text-text-primary">Status</dt>
              <dd class="text-right text-text-secondary">{{ selectedAsset.status }}</dd>
            </div>
            <div class="space-y-2">
              <dt class="font-medium text-text-primary">Descrição</dt>
              <dd class="text-text-secondary">{{ selectedAsset.description }}</dd>
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

      <ConfirmModal
        v-model="showConfirmation"
        :title="confirmationAction === 'delete-lab'
          ? 'Excluir laboratório'
          : confirmationAction === 'save-lab' ? 'Salvar laboratório' : 'Salvar ativo'"
        :message="confirmationAction === 'delete-lab'
          ? 'Tem certeza que deseja excluir este laboratório? Essa ação não pode ser revertida.'
          : confirmationAction === 'save-lab'
            ? 'Tem certeza que deseja salvar as alterações deste laboratório?'
            : 'Tem certeza que deseja salvar as alterações deste ativo?'"
        :confirm-text="confirmationAction === 'delete-lab' ? 'Excluir' : 'Salvar'"
        @confirm="confirmAction"
      />
    </section>
  </main>
</template>
