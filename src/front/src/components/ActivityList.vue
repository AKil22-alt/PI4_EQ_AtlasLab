<script setup>
const props = defineProps({
    title: {
        type: String,
        default: 'Últimas atividades'
    },
    activities: {
        type: Array,
        default: () => []
    }
})
</script>

<template>
    <article class="h-full min-h-0 rounded-lg bg-white px-4 py-4 xl:px-5 xl:py-5">
        <h2 class="text-lg font-semibold text-text-primary">{{ props.title }}</h2>

        <div class="relative mt-5 space-y-4 before:absolute before:bottom-5 before:left-4 before:top-4 before:w-px before:bg-red-primary/20">
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
