<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { api } from '@/lib/api'

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
  const wsUrl = import.meta.env.VITE_WS_BASE_URL + `chat/${chatId}/`
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
  const container = document.querySelector('.messages-container')
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
      socket.send(JSON.stringify({ message: userMessage }))
    } else {
      isWaiting.value = false
    }
    newMessage.value = ''
  }
}

// Функция для отправки при нажатии Enter (без Shift)
function handleKeyDown(e: KeyboardEvent) {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault()
    sendMessage()
  }
}
</script>

<template>
  <div class="uk-flex uk-flex-column uk-height-viewport uk-padding-remove">
    <!-- Messages area -->
    <div class="messages-container uk-flex-1 uk-overflow-auto uk-padding">
      <div class="uk-grid-small" uk-grid>
        <div 
          v-for="msg in messages" 
          :key="msg.id" 
          class="uk-width-1-1 uk-margin-small-bottom"
        >
          <div 
            class="uk-card uk-card-default uk-card-body uk-card-small"
            :class="{ 
              'uk-background-primary uk-light': msg.sender,
              'uk-background-muted': !msg.sender 
            }"
            style="border-radius: 12px;"
          >
            <div class="uk-flex uk-flex-between uk-flex-middle uk-margin-small-bottom">
              <div class="uk-text-bold">
                {{ msg.sender ? 'Вы' : 'Нейросеть' }}
              </div>
              <div 
                v-if="msg.created_at" 
                class="uk-text-meta uk-text-small"
              >
                {{ new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) }}
              </div>
            </div>
            <div class="uk-text-break" style="white-space: pre-wrap;">
              {{ msg.content }}
            </div>
          </div>
        </div>
        
        <!-- Индикатор загрузки -->
        <div 
          v-if="isWaiting && !pendingAIMessage.content" 
          class="uk-width-1-1"
        >
          <div class="uk-card uk-card-default uk-card-body uk-card-small uk-background-muted">
            <div class="uk-flex uk-flex-middle">
              <div class="uk-margin-small-right" uk-spinner="ratio: 0.6"></div>
              <div>Нейросеть печатает...</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Input panel -->
    <div class="uk-padding uk-background-default uk-box-shadow-medium">
      <form @submit.prevent="sendMessage" class="uk-form-stacked">
        <div class="uk-grid-small" uk-grid>
          <!-- Текстовое поле -->
          <div class="uk-width-expand">
            <div class="uk-inline uk-width-1-1">
              <textarea
                v-model="newMessage"
                @keydown="handleKeyDown"
                :disabled="isWaiting"
                class="uk-textarea uk-border-rounded"
                placeholder="Ask, Search or Chat..."
                rows="2"
                style="resize: none;"
              ></textarea>
            </div>
          </div>
          
          <!-- Кнопки управления -->
          <div class="uk-width-auto">
            <div class="uk-flex uk-flex-column uk-flex-between uk-height-1-1">
              <div class="uk-flex uk-flex-wrap uk-flex-right">
                <!-- Кнопка отправки -->
                <button
                  type="submit"
                  :disabled="isWaiting || !newMessage.trim()"
                  class="uk-button uk-button-primary uk-border-rounded"
                  style="padding: 12px 20px;"
                >
                  <span uk-icon="arrow-up"></span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>
