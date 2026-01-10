<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import type { HTMLAttributes } from "vue"

const props = defineProps<{
  class?: HTMLAttributes["class"]
}>()

const router = useRouter()
const authStore = useAuthStore()

const form = ref({
  username: '',
  password: ''
})

const handleLogin = async () => {
  console.log('Form data before login:', form.value)
  console.log('Form data keys:', Object.keys(form.value))
  console.log('Username value:', form.value.username)
  console.log('Password value:', form.value.password)
  
  const result = await authStore.login(form.value)
  if (result.success) {
    router.push('/service/chat')
  }
}

onMounted(() => {
  // Redirect if already authenticated
  if (authStore.isAuthenticated) {
    router.push('/service/chat')
  }
})
</script>

<template>
  <div class="uk-flex uk-flex-center uk-flex-middle" :class="props.class" style="min-height: 100vh;">
    <div class="uk-width-large uk-card uk-card-default uk-card-body uk-box-shadow-medium">
      <div class="uk-text-center uk-margin-medium-bottom">
        <h1 class="uk-card-title uk-margin-remove">Login to your account</h1>
      </div>

      <form @submit.prevent="handleLogin">
        <div class="uk-margin">
          <div class="uk-form-controls">
            <input
              id="username"
              v-model="form.username"
              class="uk-input"
              type="text"
              placeholder="Enter your username"
              autocomplete="username"
              required
              :disabled="authStore.isLoading"
            >
          </div>
        </div>

        <div class="uk-margin">
          <div class="uk-form-controls">
            <input
              id="password"
              v-model="form.password"
              class="uk-input"
              type="password"
              placeholder="Enter your password"
              autocomplete="current-password"
              required
              :disabled="authStore.isLoading"
            >
          </div>
        </div>

        <div class="uk-margin">
          <button
            type="submit"
            class="uk-button uk-button-primary uk-width-1-1"
            :disabled="authStore.isLoading"
          >
            <span v-if="authStore.isLoading" class="uk-margin-small-right" uk-spinner="ratio: 0.8"></span>
            Login
          </button>
        </div>

        <div
          v-if="authStore.error"
          class="uk-alert uk-alert-danger uk-margin-top"
          uk-alert
        >
          <p>{{ authStore.error }}</p>
        </div>
      </form>
    </div>
  </div>
</template>
