<script setup>
import { Eye, Pencil, Trash2 } from 'lucide-vue-next';
import { computed } from 'vue';

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

const dataColumns = computed(() => props.columns.filter((column) => column.type !== 'actions' && column.key !== 'actions'))
const hasActionColumn = computed(() => props.columns.some((column) => column.type === 'actions' || column.key === 'actions'))
const actionButtons = [
    { action: 'view', label: 'Visualizar item', icon: Eye },
    { action: 'edit', label: 'Editar item', icon: Pencil },
    { action: 'delete', label: 'Excluir item', icon: Trash2 }
]

function handleAction(action, row) {
    emit('row-action', { action, row })
}

</script>
<template>
    <div class="hidden min-w-0 overflow-hidden rounded-xl bg-bg-red md:block">
        <table class="w-full min-w-0 table-fixed text-left text-xs">
            <thead class="bg-red-1 text-white">
                <tr>
                    <th
                        v-for="column in columns"
                        :key="column.key"
                        class="min-w-0 break-words px-3 py-2 font-semibold"
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
                        class="min-w-0 break-words px-2 py-3 text-text-secondary"
                        :style="{ width: column.width }"
                    >
                        <div v-if="column.type === 'actions' || column.key === 'actions'" class="flex min-w-0 flex-nowrap items-center gap-1">
                            <button
                                v-for="button in actionButtons"
                                v-show="props.actions.includes(button.action)"
                                :key="button.action"
                                type="button"
                                :aria-label="button.label"
                                :title="button.label"
                                class="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-white text-red-1 transition hover:bg-red-2"
                                @click="handleAction(button.action, row)"
                            >
                                <component :is="button.icon" :size="16" />
                            </button>
                        </div>

                        <span
                            v-else-if="column.type === 'status'"
                            class="inline-flex min-w-0 max-w-full break-words rounded-full bg-emerald-50 px-3 py-1 text-[10px] font-medium text-emerald-600"
                        >
                            {{ row[column.key] }}
                        </span>
                        <span v-else class="min-w-0 break-words">{{ row[column.key] }}</span>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <div class="space-y-3 rounded-xl bg-bg-red p-3 md:hidden">
        <article
            v-for="row in rows"
            :key="row[rowKey]"
            class="space-y-3 rounded-lg bg-white p-3 text-xs"
        >
            <dl class="space-y-2">
                <div v-for="column in dataColumns" :key="column.key" class="grid grid-cols-[minmax(0,1fr)_minmax(0,1.5fr)] gap-3">
                    <dt class="font-semibold text-text-primary">{{ column.label }}</dt>
                    <dd class="min-w-0 break-words text-right text-text-secondary">
                        <span
                            v-if="column.type === 'status'"
                            class="inline-flex min-w-0 max-w-full break-words rounded-full bg-emerald-50 px-3 py-1 text-[10px] font-medium text-emerald-600"
                        >
                            {{ row[column.key] }}
                        </span>
                        <span v-else class="min-w-0 break-words">{{ row[column.key] }}</span>
                    </dd>
                </div>
            </dl>

            <div v-if="hasActionColumn" class="flex flex-wrap justify-end gap-2 border-t border-red-1/10 pt-3">
                <button
                    v-for="button in actionButtons"
                    v-show="props.actions.includes(button.action)"
                    :key="button.action"
                    type="button"
                    :aria-label="button.label"
                    :title="button.label"
                    class="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-bg-red text-red-1 transition hover:bg-red-2"
                    @click="handleAction(button.action, row)"
                >
                    <component :is="button.icon" :size="16" />
                </button>
            </div>
        </article>
    </div>

</template>