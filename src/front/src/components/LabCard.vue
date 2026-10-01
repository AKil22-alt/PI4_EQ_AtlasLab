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
    }
});

const emit = defineEmits(['view-assets', 'view-details', 'edit', 'delete']);
</script>

<template>
    <article class="flex min-h-44 flex-col rounded-3xl border-t-8 border-red-4 bg-red-2 p-8">
        <div class="flex items-start justify-between gap-4">
            <strong class="text-3xl font-bold text-black">
                {{ props.acronym }}
            </strong>

            <div class="flex items-center gap-2">
                <button type="button" aria-label="Visualizar ativos" title="Visualizar ativos"
                    class="flex h-8 w-8 items-center justify-center rounded-lg bg-white text-red-1 shadow-sm ring-1 ring-gray-200 transition hover:bg-red-2"
                    @click="emit('view-details')">
                    <Eye :size="16" />
                </button>
                <button type="button" aria-label="Editar laboratório" title="Editar laboratório"
                    class="flex h-8 w-8 items-center justify-center rounded-lg bg-white text-red-1 shadow-sm ring-1 ring-gray-200 transition hover:bg-red-2"
                    @click="emit('edit')">
                    <Pencil :size="16" />
                </button>
                <button type="button" aria-label="Excluir laboratório" title="Excluir laboratório"
                    class="flex h-8 w-8 items-center justify-center rounded-lg bg-white text-red-1 shadow-sm ring-1 ring-gray-200 transition hover:bg-red-2"
                    @click="emit('delete')">
                    <Trash2 :size="16" />
                </button>
            </div>
        </div>

        <h2 class="mt-3 text-base text-text-primary">
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