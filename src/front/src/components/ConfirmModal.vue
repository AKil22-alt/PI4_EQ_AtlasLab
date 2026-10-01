<script setup>
import { computed } from 'vue'
import Button from './Button.vue'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  title: {
    type: String,
    default: 'Confirmar ação'
  },
  message: {
    type: String,
    default: 'Essa ação não pode ser revertida.'
  },
  confirmText: {
    type: String,
    default: 'Confirmar'
  },
  cancelText: {
    type: String,
    default: 'Cancelar'
  }
})

const emit = defineEmits(['update:modelValue', 'confirm'])

const confirmationTitle = computed(() => props.title || 'Confirmar ação')

function close() {
  emit('update:modelValue', false)
}

function confirm() {
  emit('confirm')
  close()
}
</script>

<template>
  <div
    v-if="modelValue"
    class="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 px-4"
    :style="{ paddingLeft: 'var(--sidebar-width, 0px)' }"
    @click.self="close"
  >
    <div class="w-full max-w-md">
      <section class="rounded-3xl bg-white px-8 py-7 shadow-xl" role="dialog" aria-modal="true" :aria-label="confirmationTitle">
        <h2 class="text-lg font-semibold leading-tight text-text-primary">{{ message }}</h2>

        <footer class="mt-8 flex items-center justify-between">
      <Button variant="outline" size="sm" @click="close">
        {{ cancelText }}
      </Button>
      <Button variant="primary" size="sm" @click="confirm">
        {{ confirmText }}
      </Button>
        </footer>
      </section>
    </div>
  </div>
</template>
