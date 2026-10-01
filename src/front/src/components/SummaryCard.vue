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
    active: {
        type: Boolean,
        default: false
    }
})
</script>
<template>
    <article :class="[
        'flex min-h-[107px] flex-1 items-start justify-between rounded-lg p-4',
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
    </article>
</template>