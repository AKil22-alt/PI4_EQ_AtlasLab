<script setup>
import { computed } from 'vue';

// Props permitem reutilizar o botão em diferentes contextos sem duplicar CSS.
// Exemplo: <Button variant="outline" size="sm">Cancelar</Button>
const props = defineProps({
    variant: {
        type: String,
        default: 'primary'
    },
    size: {
        type: String,
        default: 'md'
    },
    type: {
        type: String,
        default: 'button'
    },
    disabled: Boolean
})

const buttonClasses = computed(() => [
    // Classes comuns a todas as variantes: alinhamento, formato e acessibilidade visual.
    'inline-flex items-center justify-center gap-2 font-semibold',
    'transition-colors disabled:cursor-not-allowed disabled:opacity-50',

    // Cada variante define a aparência sem alterar a estrutura do componente.
    {
        'rounded-full bg-dark-red text-white hover:bg-red-4':
            props.variant === 'primary',

        'rounded-full border border-red-primary bg-white text-red-primary hover:bg-bg-red':
            props.variant === 'outline',

        'rounded-2xl border-2 border-gray-200 bg-white text-red-1 shadow-sm hover:border-red-1':
            props.variant === 'icon'
    },

    // O tamanho controla o padding interno e o tamanho do texto.
    {
        'px-4 py-2 text-sm': props.size === 'sm',
        'px-5 py-2 text-base': props.size === 'md',
        'px-7 py-3 text-lg': props.size === 'lg',
        'h-12 w-12 p-0': props.size === 'icon'
    }
])
</script>

<template>
    <!-- O slot permite usar somente texto, somente ícone ou os dois. -->
    <button :type="type" :disabled="disabled" :class="buttonClasses">
        <slot />
    </button>
</template>