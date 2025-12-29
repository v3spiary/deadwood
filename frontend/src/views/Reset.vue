<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Input } from '@/components/ui/input'

const router = useRouter()
const authStore = useAuthStore()
const form = ref({ email: '' })
const success = ref(false)

const handleRequest = async () => {
  success.value = false
  const result = await authStore.requestPasswordReset(form.value.email)
  if (result.success) success.value = true
}

onMounted(() => {
  if (authStore.isAuthenticated) router.push('/service/chat')
})
</script>

<template>
  <div class="min-h-screen flex items-center justify-center">
    <Card class="w-full max-w-sm">
      <CardHeader>
        <CardTitle class="text-2xl">Forgot Password</CardTitle>
        <CardDescription>
          Enter your email to receive a password reset link
        </CardDescription>
      </CardHeader>
      <CardContent class="grid gap-4">
        <form @submit.prevent="handleRequest" class="grid gap-4">
          <div class="grid gap-2">
            <Label for="email">Email</Label>
            <Input
              id="email"
              v-model="form.email"
              type="email"
              placeholder="your@email.com"
              autocomplete="email"
              required
              :disabled="authStore.isLoading"
              class="h-11"
            />
          </div>

          <div v-if="authStore.error" class="p-3 text-sm text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-md">
            {{ authStore.error }}
          </div>

          <div v-if="success" class="p-3 text-sm text-green-600 dark:text-green-400 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-md">
            Check your email for the reset link.
          </div>
        </form>
      </CardContent>
      <CardFooter>
        <Button
          class="w-full"
          type="submit"
          @click="handleRequest"
          :disabled="authStore.isLoading"
        >
          Send Reset Link
        </Button>
      </CardFooter>
    </Card>
  </div>
</template>
