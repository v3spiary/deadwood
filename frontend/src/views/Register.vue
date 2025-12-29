<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

const router = useRouter()
const authStore = useAuthStore()

const form = ref({
  username: '',
  email: '',
  first_name: '',
  last_name: '',
  password: ''
})

const handleRegister = async () => {
  const result = await authStore.register(form.value)
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
  <div class="min-h-screen flex items-center justify-center">
    <div class="w-full max-w-md">
      
      <Card>
        <CardHeader class="space-y-1 pb-6">
          <CardTitle class="text-2xl text-center">
            Create Account
          </CardTitle>
          <CardDescription class="text-center">
            Enter your information to create an account
          </CardDescription>
        </CardHeader>
        <CardContent class="space-y-4">
          <form @submit.prevent="handleRegister" class="space-y-4">
            <div class="grid grid-cols-2 gap-4">
              <div class="space-y-2">
                <Label for="first_name">First name</Label>
                <Input
                  id="first_name"
                  v-model="form.first_name"
                  type="text"
                  placeholder="John"
                  :disabled="authStore.isLoading"
                  class="h-11"
                />
              </div>
              <div class="space-y-2">
                <Label for="last_name">Last name</Label>
                <Input
                  id="last_name"
                  v-model="form.last_name"
                  type="text"
                  placeholder="Doe"
                  :disabled="authStore.isLoading"
                  class="h-11"
                />
              </div>
            </div>
            
            <div class="space-y-2">
              <Label for="username">Username</Label>
              <Input
                id="username"
                v-model="form.username"
                type="text"
                placeholder="Enter your username"
                autocomplete="username"
                required
                :disabled="authStore.isLoading"
                class="h-11"
              />
            </div>
            
            <div class="space-y-2">
              <Label for="email">Email</Label>
              <Input
                id="email"
                v-model="form.email"
                type="email"
                placeholder="Enter your email"
                autocomplete="email"
                required
                :disabled="authStore.isLoading"
                class="h-11"
              />
            </div>
            
            <div class="space-y-2">
              <Label for="password">Password</Label>
              <Input
                id="password"
                v-model="form.password"
                type="password"
                placeholder="Enter your password"
                autocomplete="new-password"
                required
                :disabled="authStore.isLoading"
                class="h-11"
              />
            </div>
            
            <div v-if="authStore.error" class="p-3 text-sm text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-md">
              {{ authStore.error }}
            </div>
          </form>
        </CardContent>
        <CardFooter class="pt-4">
          <Button 
            class="w-full h-11 text-base font-medium" 
            type="submit"
            @click="handleRegister"
            :disabled="authStore.isLoading"
          >
            <span v-if="authStore.isLoading" class="flex items-center justify-center">
              <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Creating account...
            </span>
            <span v-else>Create Account</span>
          </Button>
        </CardFooter>
      </Card>
      
      <div class="mt-6 text-center">
        <p class="text-sm text-slate-600 dark:text-slate-400">
          Already have an account? 
          <router-link to="/auth/login">
            Sign in
          </router-link>
        </p>
      </div>
    </div>
  </div>
</template>
