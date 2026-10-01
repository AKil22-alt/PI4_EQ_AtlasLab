<script setup>
import { X } from 'lucide-vue-next';

// modelValue permite usar o componente com v-model no componente pai.
// Exemplo: <Modal v-model="showModal" title="Criar Ativo">...</Modal>
const props = defineProps({
    modelValue: {
        type: Boolean,
        default: false
    },
    title: {
        type: String,
        default: ''
    },
    size: {
        type: String,
        default: 'md'
    },
    closable: {
        type: Boolean,
        default: true
    }
})

  // O Modal emite update:modelValue para abrir ou fechar o estado controlado pelo pai.
const emit = defineEmits(['update:modelValue'])

  // Fecha o modal quando o X ou o fundo externo é acionado.
function close() {
    emit('update:modelValue', false)
}
</script>

<template>
  <!-- v-if remove o modal do DOM enquanto ele estiver fechado. -->
    <div
    v-if="modelValue"
    class="fixed inset-y-0 right-0 z-50 flex items-center justify-center bg-black/40 px-4"
    :style="{ left: 'var(--sidebar-width, 0px)' }"
    @click.self="close"
  >
    <section
      class="w-full rounded-3xl bg-white p-8 shadow-xl"
      :class="{
        'max-w-md': size === 'sm',
        'max-w-2xl': size === 'md',
        'max-w-4xl': size === 'lg'
      }"
      role="dialog"
      aria-modal="true"
    >
      <!-- Cabeçalho fixo: título via prop e botão de fechar opcional. -->
      <header class="flex items-start justify-between">
        <h2 class="text-2xl font-semibold">{{ title }}</h2>

        <button
          v-if="closable"
          type="button"
          aria-label="Fechar modal"
          title="Fechar modal"
          @click="close"
        >
            <X :size="20" />
        </button>
      </header>

      <!-- Slot padrão: recebe o conteúdo principal, como texto, formulário ou detalhes. -->
      <div class="mt-6">
        <slot />
      </div>

      <!-- Slot footer é opcional; sem ele o modal não cria uma área de botões. -->
      <footer
        v-if="$slots.footer"
        class="mt-8 flex items-center justify-between"
      >
        <slot name="footer" />
      </footer>
    </section>
  </div>
</template>