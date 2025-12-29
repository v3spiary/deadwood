<script setup lang="ts">
import { Button } from '@/components/ui/button'
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { api } from '@/lib/api'
import { ArrowUpIcon, PlusIcon } from "lucide-vue-next"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { InputGroup, InputGroupAddon, InputGroupButton, InputGroupTextarea, InputGroupText } from "@/components/ui/input-group"
import { Separator } from "@/components/ui/separator"

const authStore = useAuthStore()
const route = useRoute()
const chatId = route.params.id as string

const messages = ref<Message[]>([])
const newMessage = ref('')
const isWaiting = ref(false)
const pendingAIMessage = ref({ id: '', content: '' as string })
let socket: WebSocket | null = null

interface Message {
  id: string;
  content: string;
  sender: any | null;
  message_type?: string;
  is_edited?: boolean;
  created_at?: string;
}

onMounted(async () => {
  await loadChat()
  setupWebSocket()
})

onUnmounted(() => {
  if (socket) socket.close()
})

async function loadChat() {
  try {
    const response = await api.get(`/chatbot/chats/${chatId}/messages/`)
    messages.value = response.data.results || []
  } catch (e) {
    console.error('Error loading chat:', e)
  }
}

function setupWebSocket() {
  if (socket) socket.close()
  if (!authStore.token) return
  const wsUrl = import.meta.env.VITE_WS_BASE_URL + `/chat/${chatId}/`
  socket = new WebSocket(wsUrl, [authStore.token])

  socket.onmessage = (e) => {
    const data = JSON.parse(e.data)

    // === USER MESSAGE (эхо) ===
    if (data.type === 'user_message') {
      const msg = messages.value.find(m => m.id === pendingAIMessage.value.id || m.id === Date.now().toString())
      if (msg) {
        msg.id = data.message_id
      }
    }

    // === AI CHUNK ===
    if (data.type === 'ai_chunk') {
      if (!pendingAIMessage.value.id) {
        const newId = Date.now().toString()
        pendingAIMessage.value.id = newId
        pendingAIMessage.value.content = ''
        addMessageToHistory({ id: newId, content: '', sender: null })
      }

      pendingAIMessage.value.content += data.chunk
      const last = messages.value[messages.value.length - 1]
      if (last?.id === pendingAIMessage.value.id) {
        last.content = pendingAIMessage.value.content
      }

      nextTick(scrollToBottom)
    }

    // === AI COMPLETE ===
    if (data.type === 'ai_complete') {
      const last = messages.value[messages.value.length - 1]
      if (last?.id === pendingAIMessage.value.id) {
        last.id = data.message_id
      }
      pendingAIMessage.value = { id: '', content: '' }
      isWaiting.value = false
    }
  }

  socket.onclose = () => { isWaiting.value = false }
  socket.onerror = () => { isWaiting.value = false }
}

function addMessageToHistory(message: Message) {
  messages.value.push(message)
  messages.value = [...messages.value]
  nextTick(scrollToBottom)
}

function scrollToBottom() {
  const container = document.querySelector('.flex-1.overflow-auto')
  if (container) container.scrollTop = container.scrollHeight
}

function sendMessage() {
  if (newMessage.value.trim() && !isWaiting.value) {
    isWaiting.value = true
    const userMessage = newMessage.value

    // Временный ID
    const tempId = Date.now().toString()
    addMessageToHistory({
      id: tempId,
      content: userMessage,
      sender: authStore.user
    })

    if (socket && socket.readyState === WebSocket.OPEN) {
      socket.send(JSON.stringify({ message: userMessage }))  // ← БЕЗ chat_id
    } else {
      isWaiting.value = false
    }
    newMessage.value = ''
  }
}
</script>

<template>
  <div class="flex min-h-[90vh] flex-col bg-background">
    <!-- Messages area -->
    <div class="flex-1 overflow-auto p-4 space-y-4">
      <div v-for="msg in messages" :key="msg.id" class="flex space-x-3">
        <div class="flex-1">

          <div class="font-medium">{{ msg.sender ? 'Вы' : 'Нейросеть' }}</div>
          <div class="mt-1 text-sm">{{ msg.content }}</div>

        </div>
      </div>
    </div>
    <!-- Input panel -->
    <div class="p-4">
      <InputGroup class="w-full">
        <InputGroupTextarea
          v-model="newMessage"
          :disabled="isWaiting"
          placeholder="Ask, Search or Chat..."
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
            :disabled="isWaiting || !newMessage.trim()"
            @click="sendMessage"
          >
            <ArrowUpIcon class="size-4" />
            <span class="sr-only">Send</span>
          </InputGroupButton>
        </InputGroupAddon>
      </InputGroup>
    </div>
  </div>
</template>
