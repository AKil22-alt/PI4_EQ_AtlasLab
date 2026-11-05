<script setup>
const props = defineProps({
    title: {
        type: String,
        required: true
    },
    value: {
        type: [Number, String],
        required: true
    },
    icon: {
        type: Object,
        required: false
    },
    to: {
        type: String,
        required: true
    },
    active: {
        type: Boolean,
        default: false
    }
})
</script>
<template>
    <RouterLink :to="props.to" :class="[
        'flex min-h-[107px] flex-1 items-start justify-between rounded-lg p-4 transition duration-200 ease-out hover:-translate-y-1 hover:shadow-lg focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-4',
        props.active
            ? 'bg-red-4 text-white'
            : 'bg-white text-black'
    ]">
        <div class="flex flex-col gap-3">
            <strong :class="[
                'text-3xl font-bold',
                props.active ? 'text-white' : 'text-black'
            ]">{{ props.value }}</strong>

            <span :class="[
                'text-sm',
                props.active ? 'text-white' : 'text-text-secondary'
            ]">{{ props.title }}</span>
        </div>

        <component :is="props.icon" :size="34" :class="props.active ? 'text-white' : 'text-red-4'" />
    </RouterLink>
</template>