<script setup>
import Button from './Button.vue';
import { Eye, Pencil, Trash2 } from 'lucide-vue-next';

const props = defineProps({
    acronym: {
        type: String,
        required: true
    },
    title: {
        type: String,
        required: true
    },
    responsible: {
        type: String,
        required: true
    },
    canManage: {
        type: Boolean,
        default: false
    }
});

const emit = defineEmits(['view-assets', 'view-details', 'edit', 'delete']);
</script>

<template>
    <article class="flex min-h-44 min-w-0 flex-col overflow-hidden rounded-3xl border-t-8 border-red-4 bg-red-2 p-5 sm:p-8">
        <div class="flex min-w-0 items-start justify-between gap-3">
            <strong class="min-w-0 break-words text-2xl font-bold leading-tight text-black sm:text-3xl">
                {{ props.acronym }}
            </strong>

            <div class="flex shrink-0 items-center gap-1.5 sm:gap-2">
                <button type="button" aria-label="Visualizar ativos" title="Visualizar ativos"
                    class="flex h-8 w-8 items-center justify-center rounded-lg bg-white text-red-1 shadow-sm ring-1 ring-gray-200 transition hover:bg-red-2"
                    @click="emit('view-details')">
                    <Eye :size="16" />
                </button>
                <button v-if="props.canManage" type="button" aria-label="Editar laboratório" title="Editar laboratório"
                    class="flex h-8 w-8 items-center justify-center rounded-lg bg-white text-red-1 shadow-sm ring-1 ring-gray-200 transition hover:bg-red-2"
                    @click="emit('edit')">
                    <Pencil :size="16" />
                </button>
                <button v-if="props.canManage" type="button" aria-label="Excluir laboratório" title="Excluir laboratório"
                    class="flex h-8 w-8 items-center justify-center rounded-lg bg-white text-red-1 shadow-sm ring-1 ring-gray-200 transition hover:bg-red-2"
                    @click="emit('delete')">
                    <Trash2 :size="16" />
                </button>
            </div>
        </div>

        <h2 class="mt-3 break-words text-base text-text-primary">
            {{ props.title }}
        </h2>

        <p class="mt-3 text-xs text-text-secondary">
            Responsável: {{ props.responsible }}
        </p>

        <div class="mt-auto pt-8">
            <Button class="w-full" variant="primary" size="sm" @click="emit('view-assets', props.acronym)">
                Ver Ativos
            </Button>
        </div>
    </article>
</template>