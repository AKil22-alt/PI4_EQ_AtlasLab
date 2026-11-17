<script setup>
const props = defineProps({
    title: {
        type: String,
        default: 'Últimas atividades'
    },
    activities: {
        type: Array,
        default: () => []
    },
    canClear: {
        type: Boolean,
        default: false
    },
    isClearing: {
        type: Boolean,
        default: false
    },
    clearError: {
        type: String,
        default: ''
    }
})

const emit = defineEmits(['clear'])
</script>

<template>
    <article class="h-full min-h-0 rounded-lg bg-white px-4 py-4 xl:px-5 xl:py-5">
        <header class="flex items-center justify-between gap-3">
            <h2 class="text-lg font-semibold text-text-primary">{{ props.title }}</h2>
            <button
                v-if="props.canClear"
                type="button"
                class="shrink-0 text-sm font-semibold text-red-primary hover:underline disabled:cursor-not-allowed disabled:opacity-50"
                :disabled="props.isClearing"
                @click="emit('clear')"
            >
                {{ props.isClearing ? 'Limpando...' : 'Limpar atividades' }}
            </button>
        </header>

        <p v-if="props.clearError" class="mt-3 text-sm text-red-primary" role="alert">
            {{ props.clearError }}
        </p>

        <p v-if="!props.activities.length" class="mt-5 text-sm text-text-secondary">
            Nenhuma atividade registrada hoje.
        </p>
        <div v-else class="relative mt-5 space-y-4 before:absolute before:bottom-5 before:left-4 before:top-4 before:w-px before:bg-red-primary/20">
            <div
                v-for="activity in props.activities"
                :key="activity.id"
                class="relative flex items-center gap-4"
            >
                <div class="z-10 flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-bg-red text-red-primary">
                    <component :is="activity.icon" :size="17" />
                </div>

                <div class="flex min-w-0 flex-1 items-center justify-between gap-3 rounded-lg bg-bg-red px-4 py-4">
                    <div class="min-w-0">
                        <p class="truncate text-sm font-semibold text-text-primary">{{ activity.title }}</p>
                        <p class="mt-1 text-xs text-text-secondary">{{ activity.time }}</p>
                    </div>
                    <RouterLink
                        v-if="activity.to"
                        :to="activity.to"
                        class="shrink-0 text-xl leading-none text-red-primary transition-transform hover:translate-x-1"
                        :aria-label="`Abrir atividade: ${activity.title}`"
                    >
                        &#8594;
                    </RouterLink>
                    <span v-else class="shrink-0 text-xl leading-none text-red-primary" aria-hidden="true">&#8594;</span>
                </div>
            </div>
        </div>
    </article>
</template>
