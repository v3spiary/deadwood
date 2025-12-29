<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
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
const route = useRoute()
const authStore = useAuthStore()

const uid = route.params.uid as string
const token = route.params.token as string

const form = ref({
  new_password: '',
  re_new_password: ''
})

const handleConfirm = async () => {
  if (form.value.new_password !== form.value.re_new_password) return
  const result = await authStore.confirmPasswordReset({
    uid,
    token,
    new_password: form.value.new_password,
    re_new_password: form.value.re_new_password
  })
  if (result.success) router.push('/auth/login')
}

onMounted(() => {
  if (authStore.isAuthenticated) router.push('/service/chat')
})
</script>

<template>
  <div class="min-h-screen flex items-center justify-center">
    <Card class="w-full max-w-sm">
      <CardHeader>
        <CardTitle class="text-2xl">Set New Password</CardTitle>
        <CardDescription>
          Enter your new password twice
        </CardDescription>
      </CardHeader>
      <CardContent class="grid gap-4">
        <form @submit.prevent="handleConfirm" class="grid gap-4">
          <div class="grid gap-2">
            <Label for="new_password">New Password</Label>
            <Input
              id="new_password"
              v-model="form.new_password"
              type="password"
              placeholder="••••••••"
              autocomplete="new-password"
              required
              :disabled="authStore.isLoading"
              class="h-11"
            />
          </div>
          <div class="grid gap-2">
            <Label for="re_new_password">Confirm Password</Label>
            <Input
              id="re_new_password"
              v-model="form.re_new_password"
              type="password"
              placeholder="••••••••"
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
      <CardFooter>
        <Button
          class="w-full"
          type="submit"
          @click="handleConfirm"
          :disabled="authStore.isLoading || form.new_password !== form.re_new_password"
        >
          Change Password
        </Button>
      </CardFooter>
    </Card>
  </div>
</template>
