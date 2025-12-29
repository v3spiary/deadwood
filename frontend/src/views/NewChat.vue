<!-- NewChat.vue -->
<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '@/lib/api'
import { ArrowUpIcon, PlusIcon } from "lucide-vue-next"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { InputGroup, InputGroupAddon, InputGroupButton, InputGroupTextarea, InputGroupText } from "@/components/ui/input-group"
import { Separator } from "@/components/ui/separator"

const router = useRouter()
const input = ref('')
const sending = ref(false)

async function send() {
  if (!input.value.trim() || sending.value) return
  sending.value = true
  try {
    const res = await api.post('/chatbot/chats/start_chat/', { message: input.value })
    console.log('Chat created:', res.data)
    router.push(`/service/chat/${res.data.chat_id}`)
  } catch (e) {
    console.error(e)
  } finally {
    sending.value = false
  }
}
</script>

<template>
  <div class="min-h-[80vh] flex items-center justify-center p-6">
    <div class="w-full max-w-4xl mx-auto">
      <div class="text-center mb-8">
        <h1 class="text-3xl font-bold text-primary mb-2">HisMind</h1>
        <p class="text-lg text-muted-foreground">Your digital psychologist is here to help</p>
        <div class="flex justify-center items-center gap-2 mt-4 text-sm text-muted-foreground">
          <div class="flex items-center gap-1">
            <div class="w-2 h-2 bg-green-500 rounded-full"></div>
            <span>Online</span>
          </div>
          <span>•</span>
          <span>Ready to listen</span>
        </div>
      </div>
      <InputGroup class="w-full">
        <InputGroupTextarea
          v-model="input"
          :disabled="sending"
          placeholder="Ask, Search or Chat..."
          @keydown.enter.exact.prevent="send"
        />
        <InputGroupAddon align="block-end">
          <InputGroupButton variant="outline" class="rounded-full" size="icon-xs">
            <PlusIcon class="size-4" />
          </InputGroupButton>
          <DropdownMenu>
            <DropdownMenuTrigger as-child>
              <InputGroupButton variant="ghost">Auto</InputGroupButton>
            </DropdownMenuTrigger>
            <DropdownMenuContent side="top" align="start" class="[--radius:0.95rem]">
              <DropdownMenuItem>Auto</DropdownMenuItem>
              <DropdownMenuItem>Agent</DropdownMenuItem>
              <DropdownMenuItem>Manual</DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
          <InputGroupText class="ml-auto">52% used</InputGroupText>
          <Separator orientation="vertical" class="!h-4" />
          <InputGroupButton
            variant="default"
            class="rounded-full"
            size="icon-xs"
            :disabled="sending || !input.trim()"
            @click="send"
          >
            <ArrowUpIcon class="size-4" />
            <span class="sr-only">Send</span>
          </InputGroupButton>
        </InputGroupAddon>
      </InputGroup>
    </div>
  </div>
</template>