// Cria a aplicação Vue e registra os recursos globais antes da montagem.
import { createApp } from 'vue'
import { createPinia } from 'pinia'

// Carrega o Tailwind, as variáveis de tema e os estilos globais.
import './assets/styles/main.css'

import App from './App.vue'
import router from './router'

// O router fica disponível em todos os componentes depois do use(router).
createApp(App)
    .use(createPinia())
    .use(router)
    .mount('#app')
