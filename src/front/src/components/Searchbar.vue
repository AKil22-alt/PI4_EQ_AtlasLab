<script setup>
import { Search, X } from 'lucide-vue-next';

// defineModel conecta o texto deste input ao v-model usado pelo componente pai.
// Exemplo: <Searchbar v-model="searchText" />
const searchText = defineModel({ default : '' })
</script>

<template>
    <!-- O componente é reutilizável em Navbar ou em qualquer página que precise pesquisar. -->
    <div class="flex w-full max-w-md items-center gap-3 rounded-full bg-white px-4 py-2 border-2 border-gray-300 focus-within:border-[var(--color-red-4)] transition-colors">
        <Search class="text-gray-500" :size="20"/>

        <label for="search" class="sr-only">
            Pesquisar
        </label>

        <!-- v-model mantém o texto digitado sincronizado com searchText. -->
        <input
            id="search" 
            v-model="searchText" 
            type="text" 
            placeholder="Pesquisar" 
            class="min-w-0 flex-1 bg-transparent focus:outline-none"
        />

        <!-- O botão só aparece quando existe texto e limpa o campo ao ser clicado. -->
        <button
            v-if="searchText"
            type="button"
            aria-label="Limpar pesquisa"
            title="Limpar pesquisa"
            @click="searchText = ''"
        >
            <X :size="18"/>
        </button>

    </div>
</template>