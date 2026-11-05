<script setup>
import { LoaderCircle } from 'lucide-vue-next'

defineProps({
  message: {
    type: String,
    default: 'Carregando...'
  }
})
</script>

<template>
  <div
    class="fixed inset-0 z-[100] flex items-center justify-center bg-dark-red/10 px-4 backdrop-blur-[2px]"
    role="status"
    aria-live="polite"
  >
    <div class="flex items-center gap-3 rounded-2xl bg-white px-5 py-4 text-sm font-semibold text-red-1 shadow-lg ring-1 ring-red-1/10">
      <LoaderCircle class="animate-spin" :size="22" aria-hidden="true" />
      <span>{{ message }}</span>
    </div>
  </div>
</template>
