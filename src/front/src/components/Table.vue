<script setup>
import { Eye, Pencil, Trash2 } from 'lucide-vue-next';
import { ref } from 'vue';
import ConfirmModal from './ConfirmModal.vue';

const props = defineProps({
    columns: {
        type: Array,
        required: true
    },
    rows: {
        type: Array,
        default: () => []
    },
    rowKey: {
        type: String,
        default: 'id'
    },
    actions: {
        type: Array,
        default: () => ['view', 'edit', 'delete']
    }
})

const emit = defineEmits(['row-action'])

const showConfirmation = ref(false)
const pendingAction = ref(null)

const confirmationCopy = {
    delete: {
        title: 'Confirmar exclusão',
        message: 'Tem certeza que deseja excluir este item? Essa ação não pode ser revertida.',
        confirmText: 'Excluir'
    }
}

function handleAction(action, row) {
    if (action !== 'delete') {
        emit('row-action', { action, row })
        return
    }

    pendingAction.value = { action, row }
    showConfirmation.value = true
}

function confirmAction() {
    if (!pendingAction.value) return

    emit('row-action', pendingAction.value)
    pendingAction.value = null
}

</script>
<template>
    <div class="overflow-hidden rounded-xl bg-bg-red">
        <table class="w-full table-fixed text-left text-xs">
            <thead class="bg-red-1 text-white">
                <tr>
                    <th
                        v-for="column in columns"
                        :key="column.key"
                        class="px-3 py-2 font-semibold"
                        :style="{ width: column.width }"
                    >
                        {{ column.label }}
                    </th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="row in rows" :key="row[rowKey]">
                    <td
                        v-for="column in columns"
                        :key="column.key"
                        class="px-3 py-3 text-text-secondary"
                        :style="{ width: column.width }"
                    >
                        <div v-if="column.type === 'actions' || column.key === 'actions'" class="flex items-center gap-1">
                            <button
                                v-if="props.actions.includes('view')"
                                type="button"
                                aria-label="Visualizar item"
                                title="Visualizar item"
                                class="flex h-8 w-8 items-center justify-center rounded-lg bg-white text-red-1 transition hover:bg-red-2"
                                @click="emit('row-action', { action: 'view', row })"
                            >
                                <Eye :size="16" />
                            </button>

                            <button
                                v-if="props.actions.includes('edit')"
                                type="button"
                                aria-label="Editar item"
                                title="Editar item"
                                class="flex h-8 w-8 items-center justify-center rounded-lg bg-white text-red-1 transition hover:bg-red-2"
                                @click="handleAction('edit', row)"
                            >
                                <Pencil :size="16" />
                            </button>

                            <button
                                v-if="props.actions.includes('delete')"
                                type="button"
                                aria-label="Excluir item"
                                title="Excluir item"
                                class="flex h-8 w-8 items-center justify-center rounded-lg bg-white text-red-1 transition hover:bg-red-2"
                                @click="handleAction('delete', row)"
                            >
                                <Trash2 :size="16" />
                            </button>
                        </div>

                        <span
                            v-else-if="column.type === 'status'"
                            class="inline-flex rounded-full bg-emerald-50 px-3 py-1 text-[10px] font-medium text-emerald-600"
                        >
                            {{ row[column.key] }}
                        </span>
                        <span v-else>{{ row[column.key] }}</span>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <ConfirmModal
        v-model="showConfirmation"
        :title="pendingAction ? confirmationCopy[pendingAction.action].title : ''"
        :message="pendingAction ? confirmationCopy[pendingAction.action].message : ''"
        :confirm-text="pendingAction ? confirmationCopy[pendingAction.action].confirmText : 'Confirmar'"
        @confirm="confirmAction"
    />
</template>