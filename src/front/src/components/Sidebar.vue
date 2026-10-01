<script setup>
// Ícones usados nos links de navegação da aplicação.
import {
    LayoutDashboard,
    FlaskConical,
    ClipboardList,
    Users,
    LogOut
} from 'lucide-vue-next'

// O App envia open para controlar a largura e a animação da Sidebar.
// Exemplo: <Sidebar :open="sidebarOpen" />
defineProps({
    open: Boolean
})
</script>

<template>
    <!-- Mantém uma rail compacta quando fechada para preservar os ícones de navegação. -->
    <aside :class="[
        'sticky top-0 flex h-screen max-h-screen shrink-0 self-start flex-col overflow-hidden text-white transition-all duration-300',
    ]" :style="{
        width: open ? '280px' : '72px',
        minWidth: open ? '280px' : '72px',
        maxWidth: open ? '280px' : '72px',
        background: 'var(--gradient-primary)'
    }">
        <!-- Identidade visual da aplicação no topo da Sidebar. -->
        <div :class="open ? 'px-6 py-8' : 'px-3 py-8'">
            <div :class="['flex items-center', open ? 'gap-3' : 'justify-center']">
                <FlaskConical :size="38" />
                <span v-if="open" class="text-2xl font-semibold">AtlasLab</span>
            </div>
        </div>

        <!-- Cada RouterLink altera a rota sem recarregar a aplicação. -->
        <nav :class="['flex flex-col gap-2', open ? 'px-4' : 'px-2']">
            <RouterLink to="/" exact-active-class="bg-white text-red-primary"
                :class="['flex items-center rounded-full py-3 font-medium transition-colors hover:bg-white/15 hover:text-white', open ? 'gap-4 px-4' : 'justify-center px-2']"
                title="Dashboard">
                <LayoutDashboard :size="22" />
                <span v-if="open">Dashboard</span>
            </RouterLink>

            <RouterLink to="/orders" active-class="bg-white text-red-primary"
                :class="['flex items-center rounded-full py-3 font-medium transition-colors hover:bg-white/15 hover:text-white', open ? 'gap-4 px-4' : 'justify-center px-2']"
                title="Ordem de serviço">
                <ClipboardList :size="22" />
                <span v-if="open">Ordem de serviço</span>
            </RouterLink>

            <RouterLink to="/labs" active-class="bg-white text-red-primary"
                :class="['flex items-center rounded-full py-3 font-medium transition-colors hover:bg-white/15 hover:text-white', open ? 'gap-4 px-4' : 'justify-center px-2']"
                title="Laboratórios e ativos">
                <FlaskConical :size="22" />
                <span v-if="open">Laboratórios e ativos</span>
            </RouterLink>

            <RouterLink to="/users" active-class="bg-white text-red-primary"
                :class="['flex items-center rounded-full py-3 font-medium transition-colors hover:bg-white/15 hover:text-white', open ? 'gap-4 px-4' : 'justify-center px-2']"
                title="Usuários">
                <Users :size="22" />
                <span v-if="open">Usuários</span>
            </RouterLink>
        </nav>

        <!-- mt-auto empurra o botão de saída para a parte inferior. -->
        <button type="button"
            :class="['mt-auto flex items-center py-8 font-medium transition-colors hover:text-red-200', open ? 'gap-4 px-8' : 'justify-center px-2']"
            title="Sair">
            <LogOut :size="22" />
            <span v-if="open">Sair</span>
        </button>
    </aside>
</template>