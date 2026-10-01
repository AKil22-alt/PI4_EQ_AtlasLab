<script setup>
import { ref } from 'vue'
import { Eye, EyeOff, LockKeyhole, Mail, UserRound } from 'lucide-vue-next'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../store/auth'
import backgroundLogin from '../assets/images/fundo-login.png'
import backgroundRegister from '../assets/images/fundo-cadastro.png'

const router = useRouter()
const authStore = useAuthStore()
const AUTH_MODE_KEY = 'atlaslab-auth-mode'
const isRegistering = ref(localStorage.getItem(AUTH_MODE_KEY) === 'register')
const name = ref('')
const email = ref('')
const senha = ref('')
const confirmSenha = ref('')
const showPassword = ref(false)
const showConfirmPassword = ref(false)
const message = ref('')
const error = ref('')

function clearFeedback() {
    message.value = ''
    error.value = ''
}

function toggleMode() {
    isRegistering.value = !isRegistering.value
    localStorage.setItem(AUTH_MODE_KEY, isRegistering.value ? 'register' : 'login')
    clearFeedback()
}

function login() {
    clearFeedback()
    const normalizedEmail = email.value.trim().toLowerCase()
    const isAdmin = normalizedEmail.includes('admin')

    if (!isAdmin && !authStore.isApproved(normalizedEmail)) {
        authStore.requestEntry({
            name: normalizedEmail.split('@')[0],
            email: normalizedEmail
        })
        message.value = 'Sua solicitação foi enviada para aprovação do administrador.'
        return
    }

    authStore.currentUser = { email: normalizedEmail, role: isAdmin ? 'admin' : 'user' }
    router.push('/users')
}

function register() {
    clearFeedback()

    if (senha.value !== confirmSenha.value) {
        error.value = 'As senhas não coincidem.'
        return
    }

    const wasCreated = authStore.requestEntry({
        name: name.value,
        email: email.value
    })

    message.value = wasCreated
        ? 'Cadastro enviado. Aguarde a aprovação do administrador.'
        : 'Este email já possui uma solicitação pendente.'
}
</script>

<template>
    <main class="auth-page" :class="{ 'auth-page--register': isRegistering }">
        <section
            class="auth-art"
            :style="{ backgroundImage: `url(${isRegistering ? backgroundRegister : backgroundLogin})` }"
            aria-hidden="true"
        ></section>

        <section class="auth-panel">
                        <Transition name="auth-content" mode="out-in">
                            <div :key="isRegistering ? 'register' : 'login'" class="auth-content">
                <h1>{{ isRegistering ? 'Cadastro' : 'Login' }}</h1>

                <form v-if="!isRegistering" class="auth-form" @submit.prevent="login">
                    <label for="login-email">Email</label>
                    <div class="auth-input-wrap">
                        <Mail :size="18" />
                        <input id="login-email" v-model="email" type="email" placeholder="Digite seu email" required />
                    </div>

                    <label for="login-password">Senha</label>
                    <div class="auth-input-wrap">
                        <LockKeyhole :size="18" />
                        <input id="login-password" v-model="senha" :type="showPassword ? 'text' : 'password'" placeholder="Digite sua senha" required />
                        <button type="button" class="password-toggle" aria-label="Mostrar senha" @click="showPassword = !showPassword">
                              <EyeOff v-if="showPassword" :size="18" />
                              <Eye v-else :size="18" />
                        </button>
                    </div>

                    <button class="forgot-password" type="button">
                        Esqueci minha senha
                    </button>

                    <button class="auth-submit" type="submit">Login</button>
                </form>

                <form v-else class="auth-form" @submit.prevent="register">
                    <label for="register-name">Nome</label>
                    <div class="auth-input-wrap">
                        <UserRound :size="18" />
                        <input id="register-name" v-model="name" type="text" placeholder="Digite seu nome" required />
                    </div>

                    <label for="register-email">Email</label>
                    <div class="auth-input-wrap">
                        <Mail :size="18" />
                        <input id="register-email" v-model="email" type="email" placeholder="Digite seu email" required />
                    </div>

                    <label for="register-password">Senha</label>
                    <div class="auth-input-wrap">
                        <LockKeyhole :size="18" />
                        <input id="register-password" v-model="senha" :type="showPassword ? 'text' : 'password'" placeholder="Digite sua senha" required />
                        <button type="button" class="password-toggle" aria-label="Mostrar senha" @click="showPassword = !showPassword">
                              <EyeOff v-if="showPassword" :size="18" />
                              <Eye v-else :size="18" />
                        </button>
                    </div>

                    <label for="register-confirm-password">Confirmar senha</label>
                    <div class="auth-input-wrap">
                        <LockKeyhole :size="18" />
                        <input id="register-confirm-password" v-model="confirmSenha" :type="showConfirmPassword ? 'text' : 'password'" placeholder="Confirme sua senha" required />
                        <button type="button" class="password-toggle" aria-label="Mostrar confirmação de senha" @click="showConfirmPassword = !showConfirmPassword">
                              <EyeOff v-if="showConfirmPassword" :size="18" />
                              <Eye v-else :size="18" />
                        </button>
                    </div>

                    <button class="auth-submit" type="submit">Cadastrar-se</button>
                </form>

                <p v-if="error" class="auth-feedback auth-feedback--error">{{ error }}</p>
                <p v-if="message" class="auth-feedback">{{ message }}</p>

                <button type="button" class="auth-switch" @click="toggleMode">
                    {{ isRegistering ? 'Já possui uma conta?' : 'Não possui uma conta?' }}
                    <span>{{ isRegistering ? 'Fazer Login' : 'Cadastre-se' }}</span>
                </button>
                            </div>
                        </Transition>
        </section>
    </main>
</template>

<style scoped>
.auth-page {
    --auth-red: #c40009;
    --auth-dark: #260708;
    min-height: 100vh;
    display: grid;
    grid-template-columns: minmax(0, 1.05fr) minmax(360px, 0.95fr);
    overflow: hidden;
    background: #fff;
}

.auth-art {
    position: relative;
    min-height: 100vh;
    overflow: hidden;
    background: var(--auth-dark);
    background-position: center;
    background-size: cover;
}

.auth-panel {
    position: relative;
    z-index: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #fff;
    padding: 48px 56px;
}

.auth-page--register .auth-art {
    grid-column: 2;
    grid-row: 1;
}

.auth-page--register .auth-panel {
    grid-column: 1;
    grid-row: 1;
}

.auth-content {
    position: relative;
    z-index: 1;
    width: min(100%, 480px);
}

.auth-content-enter-active,
.auth-content-leave-active {
    transition: opacity 0.28s ease, transform 0.28s ease;
}

.auth-content-enter-from {
    opacity: 0;
    transform: translateX(18px);
}

.auth-content-leave-to {
    opacity: 0;
    transform: translateX(-18px);
}

.auth-content h1 {
    display: inline-block;
    margin: 0;
    border-bottom: 3px solid var(--auth-red);
    padding-bottom: 7px;
    color: #3d3d3d;
    font-size: 34px;
    font-weight: 700;
    line-height: 1;
}

.auth-form {
    display: flex;
    flex-direction: column;
    gap: 7px;
    margin-top: 34px;
}

.auth-form label {
    margin-top: 9px;
    color: #171a21;
    font-size: 15px;
    font-weight: 700;
}

.auth-input-wrap {
    display: flex;
    align-items: center;
    gap: 6px;
    border-bottom: 1px solid #ed9da4;
    color: #aaa;
}

.auth-input-wrap input {
    min-width: 0;
    flex: 1;
    border: 0;
    outline: 0;
    background: transparent;
    padding: 7px 0;
    color: #171a21;
    font: inherit;
    font-size: 15px;
}

.auth-input-wrap input::placeholder {
    color: #aaa;
}

.password-toggle {
    display: flex;
    border: 0;
    background: transparent;
    padding: 2px;
    color: #aaa;
    cursor: pointer;
}

.auth-submit {
    align-self: flex-end;
    margin-top: 22px;
    border: 0;
    border-radius: 999px;
    background: var(--auth-red);
    padding: 11px 30px;
    color: white;
    font-size: 14px;
    font-weight: 700;
    cursor: pointer;
    transition: background 0.2s ease;
}

.forgot-password {
    align-self: flex-end;
    margin-top: 4px;
    border: 0;
    background: transparent;
    padding: 0;
    color: var(--auth-red);
    font-size: 14px;
    cursor: pointer;
}

.forgot-password:hover {
    text-decoration: underline;
}

.auth-submit:hover {
    background: #990007;
}

.auth-page--register .auth-submit {
    align-self: flex-start;
}

.auth-feedback {
    margin: 14px 0 0;
    color: #16804b;
    font-size: 13px;
    line-height: 1.4;
}

.auth-feedback--error {
    color: #b40001;
}

.auth-switch {
    display: block;
    margin: 9px 0 0 auto;
    border: 0;
    background: transparent;
    color: #aaa;
    font-size: 11px;
    cursor: pointer;
}

.auth-switch span {
    color: var(--auth-red);
    font-weight: 700;
}

.auth-page--register .auth-switch {
    margin-right: auto;
    margin-left: 0;
}

@media (max-width: 760px) {
    .auth-page {
        display: block;
    }

    .auth-art {
        min-height: 190px;
    }

    .auth-page--register .auth-art,
    .auth-page--register .auth-panel {
        grid-column: auto;
        grid-row: auto;
    }

    .auth-panel {
        min-height: calc(100vh - 190px);
        padding: 42px 28px;
    }
}
</style>