<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import type { HTMLAttributes } from "vue"
import { cn } from '@/lib/utils'
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
  <div :class="cn('flex flex-col gap-6', props.class)">
    <Card>
      <CardHeader>
        <CardTitle>Login to your account</CardTitle>
        <CardDescription>
          Enter your email below to login to your account
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form  @submit.prevent="handleLogin">
          <div class="flex flex-col gap-6">
            <div class="grid gap-3">
              <Label for="username">Username</Label>
              <Input 
              id="username" 
              v-model="form.username"
              type="text" 
              placeholder="Enter your username" 
              autocomplete="username"
              required 
              :disabled="authStore.isLoading"
              class="h-11 "
              />
            </div>
            <div class="grid gap-3">
              <div class="flex items-center">
                <Label for="password">Password</Label>
                <RouterLink
                  to="/auth/reset-password"
                  class="ml-auto inline-block text-sm underline-offset-4 hover:underline"
                >
                  Forgot your password?
                </RouterLink>
              </div>
              <Input 
              id="password" 
              v-model="form.password"
              type="password" 
              placeholder="Enter your password"
              autocomplete="current-password"
              required 
              :disabled="authStore.isLoading"
              class="h-11 "
              />
            </div>
            <div class="flex flex-col gap-3">
              <Button type="submit" class="w-full">
                Login
              </Button>
              <Button variant="outline" class="w-full">
                Login with Google
              </Button>
            </div>
          </div>
          <div class="mt-4 text-center text-sm">
            Don't have an account?
            <RouterLink to="/auth/register" class="underline underline-offset-4">
              Sign up
            </RouterLink>
          </div>
          <div v-if="authStore.error" class="p-3 text-sm text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-md ">
            {{ authStore.error }}
          </div>
        </form>
      </CardContent>
    </Card>
  </div>
</template>
