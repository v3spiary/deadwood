<!-- ServiceChat.vue -->
<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, computed, watch, reactive } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { api } from '@/lib/api'
import { Plus, Pin, Sun, History, Calendar, Archive, Wifi, WifiOff, AlertCircle } from 'lucide-vue-next'
import DOMPurify from 'dompurify'
import { v4 as uuidv4 } from 'uuid'
import { marked } from 'marked'

// Типы
interface Chat {
  id: string
  name: string
  is_pinned?: boolean
  deleted?: boolean
  created_at?: string
  updated_at?: string
  latest_messages?: any[]
}

interface Message {
  id: string
  content: string
  sender: any | null
  message_type?: string
  is_edited?: boolean
  created_at?: string
  timestamp?: string
}

interface WebSocketMessage {
  type: string
  [key: string]: any
}

// Константы
const MAX_RECONNECT_ATTEMPTS = 5
const RECONNECT_BASE_DELAY = 1000 // 1 секунда
const MAX_MESSAGE_LENGTH = 10000
const STREAM_UPDATE_THROTTLE = 100 // мс между обновлениями UI при стриминге

// Хранилища и роутер
const authStore = useAuthStore()
const router = useRouter()
const route = useRoute()
const chatId = route.params.id as string

// Состояние
const messages = ref<Message[]>([])
const newMessage = ref('')
const isWaiting = ref(false)
const connectionStatus = ref<'connecting' | 'connected' | 'disconnected' | 'reconnecting'>('connecting')
const lastError = ref<string | null>(null)

// Трекер для AI сообщений
const pendingAIMessage = reactive({
  id: '',
  content: '',
  isStreaming: false,
  streamUpdateTimer: null as NodeJS.Timeout | null
})

// WebSocket
let socket: WebSocket | null = null
let reconnectAttempts = 0
let reconnectTimeout: NodeJS.Timeout | null = null

// Список чатов
const chats = ref<Chat[]>([])
const chatsLoading = ref(false)
const chatsError = ref<string | null>(null)

// UI состояния
const isHistoryExpanded = ref(true)
const inputRef = ref<HTMLTextAreaElement | null>(null)

// -------------------------------------------------------------
// Хуки жизненного цикла
// -------------------------------------------------------------

onMounted(async () => {
  console.log('Компонент чата монтирован')
  
  try {
    await Promise.all([
      loadChat(),
      fetchChats()
    ])
  } catch (error) {
    console.error('Ошибка при загрузке чата:', error)
    lastError.value = 'Не удалось загрузить чат'
  }
  
  setupWebSocket()
})

onUnmounted(() => {
  console.log('Компонент чата размонтирован')
  cleanupWebSocket()
  cleanupTimers()
})

// -------------------------------------------------------------
// WebSocket методы
// -------------------------------------------------------------

function setupWebSocket() {
  cleanupWebSocket()
  
  if (!authStore.token) {
    console.error('Нет токена аутентификации')
    lastError.value = 'Требуется аутентификация'
    connectionStatus.value = 'disconnected'
    return
  }
  
  // Формируем URL WebSocket
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
  const host = import.meta.env.VITE_WS_BASE_URL || `${window.location.host}`
  const wsUrl = `${protocol}//${host}/ws/chat/${chatId}/`
  
  console.log('Подключение к WebSocket:', wsUrl)
  connectionStatus.value = 'connecting'
  
  try {
    socket = new WebSocket(wsUrl, [authStore.token])
    setupSocketHandlers()
  } catch (error) {
    console.error('Ошибка создания WebSocket:', error)
    lastError.value = 'Ошибка подключения'
    attemptReconnect()
  }
}

function setupSocketHandlers() {
  if (!socket) return
  
  socket.onopen = handleSocketOpen
  socket.onmessage = handleSocketMessage
  socket.onclose = handleSocketClose
  socket.onerror = handleSocketError
}

function handleSocketOpen() {
  console.log('WebSocket подключен')
  connectionStatus.value = 'connected'
  reconnectAttempts = 0
  lastError.value = null
}

function handleSocketMessage(event: MessageEvent) {
  try {
    const data: WebSocketMessage = JSON.parse(event.data)
    console.debug('Получено WebSocket сообщение:', data.type, data)
    
    switch (data.type) {
      case 'connection_established':
        handleConnectionEstablished(data)
        break
      case 'user_message':
        handleUserMessage(data)
        break
      case 'ai_chunk':
        handleAIChunk(data)
        break
      case 'ai_complete':
        handleAIComplete(data)
        break
      case 'error':
        handleErrorMessage(data)
        break
      case 'broadcast':
        handleBroadcastMessage(data)
        break
      default:
        console.warn('Неизвестный тип сообщения:', data.type)
    }
  } catch (error) {
    console.error('Ошибка обработки WebSocket сообщения:', error, event.data)
  }
}

function handleSocketClose(event: CloseEvent) {
  console.log(`WebSocket закрыт. Код: ${event.code}, Причина: ${event.reason}`)
  connectionStatus.value = 'disconnected'
  isWaiting.value = false
  
  // Очищаем стриминг
  cleanupAIMessage()
  
  // Если закрыто не чисто или таймаут - пытаемся переподключиться
  if (!event.wasClean || event.code === 1006) {
    attemptReconnect()
  }
}

function handleSocketError(error: Event) {
  console.error('WebSocket ошибка:', error)
  connectionStatus.value = 'disconnected'
  lastError.value = 'Ошибка соединения'
  isWaiting.value = false
  cleanupAIMessage()
}

function attemptReconnect() {
  if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
    console.error('Достигнут лимит попыток переподключения')
    lastError.value = 'Не удалось восстановить соединение. Обновите страницу.'
    return
  }
  
  const delay = RECONNECT_BASE_DELAY * Math.pow(2, reconnectAttempts)
  console.log(`Попытка переподключения ${reconnectAttempts + 1} через ${delay}мс`)
  
  connectionStatus.value = 'reconnecting'
  
  reconnectTimeout = setTimeout(() => {
    reconnectAttempts++
    setupWebSocket()
  }, delay)
}

function cleanupWebSocket() {
  if (socket) {
    socket.onopen = null
    socket.onmessage = null
    socket.onclose = null
    socket.onerror = null
    
    if (socket.readyState === WebSocket.OPEN) {
      socket.close(1000, 'Компонент размонтирован')
    }
    
    socket = null
  }
}

function cleanupTimers() {
  if (reconnectTimeout) {
    clearTimeout(reconnectTimeout)
    reconnectTimeout = null
  }
  
  if (pendingAIMessage.streamUpdateTimer) {
    clearTimeout(pendingAIMessage.streamUpdateTimer)
    pendingAIMessage.streamUpdateTimer = null
  }
}

// -------------------------------------------------------------
// Обработчики WebSocket сообщений
// -------------------------------------------------------------

function handleConnectionEstablished(data: WebSocketMessage) {
  console.log('Соединение установлено:', data.message)
  // Можно обновить состояние или показать уведомление
}

function handleUserMessage(data: WebSocketMessage) {
  // Обновляем ID временного сообщения пользователя на постоянный
  const tempId = pendingAIMessage.id || findTemporaryUserMessageId(data.content)
  
  if (tempId) {
    const messageIndex = messages.value.findIndex(m => m.id === tempId)
    if (messageIndex !== -1) {
      messages.value[messageIndex].id = data.message_id
      messages.value[messageIndex].timestamp = data.timestamp
    }
  }
}

function handleAIChunk(data: WebSocketMessage) {
  // Инициализируем AI сообщение если его нет
  if (!pendingAIMessage.id) {
    const newId = `ai_temp_${uuidv4()}`
    pendingAIMessage.id = newId
    pendingAIMessage.content = ''
    pendingAIMessage.isStreaming = true
    
    addMessageToHistory({
      id: newId,
      content: '',
      sender: null,
      message_type: 'text'
    })
  }
  
  // Добавляем чанк к контенту
  if (data.chunk) {
    pendingAIMessage.content += data.chunk
  }
  
  // Троттлинг обновлений UI для производительности
  if (!pendingAIMessage.streamUpdateTimer) {
    pendingAIMessage.streamUpdateTimer = setTimeout(() => {
      updateAIMessageContent()
      pendingAIMessage.streamUpdateTimer = null
    }, STREAM_UPDATE_THROTTLE)
  }
}

function handleAIComplete(data: WebSocketMessage) {
  // Останавливаем стриминг
  pendingAIMessage.isStreaming = false
  
  if (pendingAIMessage.streamUpdateTimer) {
    clearTimeout(pendingAIMessage.streamUpdateTimer)
    pendingAIMessage.streamUpdateTimer = null
  }
  
  // Обновляем финальное содержание
  updateAIMessageContent()
  
  // Обрабатываем результат
  const messageId = data.message_id
  const error = data.error
  
  if (error) {
    // Если есть ошибка - заменяем содержимое сообщения на ошибку
    const lastMessage = messages.value[messages.value.length - 1]
    if (lastMessage && lastMessage.id === pendingAIMessage.id) {
      lastMessage.content = `❌ Ошибка: ${getErrorMessage(error)}`
    }
  } else if (messageId && messageId !== 'error') {
    // Успешное завершение - обновляем ID временного сообщения
    const lastMessage = messages.value[messages.value.length - 1]
    if (lastMessage && lastMessage.id === pendingAIMessage.id) {
      lastMessage.id = messageId
    }
  }
  
  // Сбрасываем состояние
  cleanupAIMessage()
  isWaiting.value = false
  
  // Скроллим вниз
  nextTick(scrollToBottom)
}

function handleErrorMessage(data: WebSocketMessage) {
  console.error('Ошибка от сервера:', data.message)
  lastError.value = data.message || 'Неизвестная ошибка сервера'
  isWaiting.value = false
  
  // Показываем ошибку пользователю
  if (data.message) {
    addMessageToHistory({
      id: uuidv4(),
      content: `⚠️ ${data.message}`,
      sender: null,
      message_type: 'error'
    })
  }
}

function handleBroadcastMessage(data: WebSocketMessage) {
  console.log('Broadcast сообщение:', data.message)
  // Можно показать системное уведомление
}

// -------------------------------------------------------------
// Вспомогательные методы AI
// -------------------------------------------------------------

function findTemporaryUserMessageId(content: string): string | null {
  // Ищем последнее сообщение пользователя с таким контентом
  for (let i = messages.value.length - 1; i >= 0; i--) {
    const msg = messages.value[i]
    if (msg.sender && msg.content === content) {
      return msg.id
    }
  }
  return null
}

function updateAIMessageContent() {
  const lastMessage = messages.value[messages.value.length - 1]
  if (lastMessage && lastMessage.id === pendingAIMessage.id) {
    lastMessage.content = pendingAIMessage.content
    nextTick(scrollToBottom)
  }
}

function cleanupAIMessage() {
  pendingAIMessage.id = ''
  pendingAIMessage.content = ''
  pendingAIMessage.isStreaming = false
  
  if (pendingAIMessage.streamUpdateTimer) {
    clearTimeout(pendingAIMessage.streamUpdateTimer)
    pendingAIMessage.streamUpdateTimer = null
  }
}

function getErrorMessage(error: string): string {
  const errorMap: Record<string, string> = {
    'connection_error': 'Модель временно недоступна',
    'timeout_error': 'Превышено время ожидания ответа',
    'internal_error': 'Внутренняя ошибка сервера',
    'db_error': 'Ошибка сохранения сообщения',
    'empty_response': 'Пустой ответ от модели'
  }
  
  return errorMap[error] || error || 'Неизвестная ошибка'
}

// -------------------------------------------------------------
// Методы чата
// -------------------------------------------------------------

async function loadChat() {
  try {
    console.log('Загрузка сообщений чата:', chatId)
    const response = await api.get(`/chatbot/chats/${chatId}/messages/`)
    
    if (response.data && response.data.results) {
      messages.value = response.data.results.map((msg: any) => ({
        ...msg,
        sender: msg.sender || null
      }))
      
      console.log(`Загружено ${messages.value.length} сообщений`)
      nextTick(scrollToBottom)
    } else if (Array.isArray(response.data)) {
      messages.value = response.data
      nextTick(scrollToBottom)
    }
  } catch (error: any) {
    console.error('Ошибка загрузки чата:', error)
    lastError.value = 'Не удалось загрузить историю сообщений'
    
    if (error.response?.status === 404) {
      lastError.value = 'Чат не найден'
      router.push('/service/chat')
    }
  }
}

async function fetchChats() {
  try {
    chatsLoading.value = true
    chatsError.value = null
    
    console.log('Загрузка списка чатов...')
    const response = await api.get('/chatbot/chats/')
    
    if (response.data && response.data.results) {
      chats.value = response.data.results
      console.log(`Загружено ${chats.value.length} чатов`)
    } else if (Array.isArray(response.data)) {
      chats.value = response.data
    } else {
      console.warn('Неожиданная структура ответа:', response.data)
      chats.value = []
    }
  } catch (error: any) {
    console.error('Ошибка загрузки чатов:', error)
    chatsError.value = error.response?.data?.message || 'Не удалось загрузить список чатов'
  } finally {
    chatsLoading.value = false
  }
}

function sendMessage() {
  const content = newMessage.value.trim()
  
  if (!content) {
    console.warn('Попытка отправить пустое сообщение')
    return
  }
  
  if (content.length > MAX_MESSAGE_LENGTH) {
    lastError.value = `Сообщение слишком длинное (максимум ${MAX_MESSAGE_LENGTH} символов)`
    return
  }
  
  if (!socket || socket.readyState !== WebSocket.OPEN) {
    lastError.value = 'Соединение не установлено'
    return
  }
  
  if (isWaiting.value) {
    console.warn('Уже ожидается ответ от AI')
    return
  }
  
  // Подготавливаем состояние
  isWaiting.value = true
  const tempId = `user_temp_${uuidv4()}`
  
  // Добавляем сообщение пользователя в историю
  addMessageToHistory({
    id: tempId,
    content: content,
    sender: authStore.user,
    message_type: 'text'
  })
  
  try {
    // Отправляем через WebSocket
    socket.send(JSON.stringify({ 
      message: content,
      timestamp: new Date().toISOString()
    }))
    
    // Очищаем поле ввода
    newMessage.value = ''
    
    // Фокус остаётся на поле ввода
    nextTick(() => {
      if (inputRef.value) {
        inputRef.value.focus()
      }
    })
    
  } catch (error) {
    console.error('Ошибка отправки сообщения:', error)
    lastError.value = 'Не удалось отправить сообщение'
    isWaiting.value = false
    
    // Удаляем временное сообщение из истории
    const index = messages.value.findIndex(m => m.id === tempId)
    if (index !== -1) {
      messages.value.splice(index, 1)
    }
  }
}

function addMessageToHistory(message: Message) {
  messages.value.push(message)
  nextTick(scrollToBottom)
}

function scrollToBottom() {
  const container = document.querySelector('.messages-container')
  if (container) {
    container.scrollTop = container.scrollHeight
  }
}

function handleKeyDown(e: KeyboardEvent) {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault()
    sendMessage()
  }
  
  // Ctrl+Enter или Cmd+Enter для отправки
  if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) {
    e.preventDefault()
    sendMessage()
  }
}

// -------------------------------------------------------------
// Утилиты безопасности и форматирования
// -------------------------------------------------------------

function sanitizeHtml(html: string): string {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'code', 'pre', 'br', 'p', 'span', 'div'],
    ALLOWED_ATTR: ['class', 'style']
  })
}

function formatContent(content: string, isAI: boolean = false): string {
  if (!content) return ''
  
  // Для AI сообщений можно рендерить markdown
  if (isAI) {
    try {
      const rawHtml = marked.parse(content, {
        breaks: true,
        gfm: true
      })
      return sanitizeHtml(rawHtml)
    } catch (error) {
      console.warn('Ошибка парсинга markdown:', error)
      return sanitizeHtml(content)
    }
  }
  
  // Для пользовательских сообщений просто экранируем HTML
  return sanitizeHtml(content)
}

// -------------------------------------------------------------
// Утилиты для работы с датами
// -------------------------------------------------------------

function parseCustomDate(dateStr: string): Date {
  if (!dateStr) return new Date(0)
  
  try {
    // Пробуем ISO формат
    if (dateStr.includes('T')) {
      const date = new Date(dateStr)
      if (!isNaN(date.getTime())) return date
    }
    
    // Пробуем формат "DD.MM.YYYY HH:mm"
    if (dateStr.includes('.')) {
      const [datePart, timePart] = dateStr.split(' ')
      const [day, month, year] = datePart.split('.').map(Number)
      
      if (!year || !month || !day) {
        throw new Error('Invalid date format')
      }
      
      let hours = 0, minutes = 0
      if (timePart) {
        [hours, minutes] = timePart.split(':').map(Number)
      }
      
      const date = new Date(year, month - 1, day, hours, minutes)
      if (!isNaN(date.getTime())) return date
    }
    
    // Пробуем стандартный парсинг
    const parsed = Date.parse(dateStr)
    if (!isNaN(parsed)) {
      return new Date(parsed)
    }
    
    console.warn('Не удалось распарсить дату:', dateStr)
    return new Date(0)
  } catch (error) {
    console.warn('Ошибка парсинга даты:', error, dateStr)
    return new Date(0)
  }
}

// -------------------------------------------------------------
// Вычисляемые свойства
// -------------------------------------------------------------

const pinnedChats = computed(() => 
  chats.value.filter(chat => chat.is_pinned && !chat.deleted)
)

const historyChats = computed(() => 
  chats.value.filter(chat => !chat.is_pinned && !chat.deleted)
)

const currentChatId = computed(() => route.params.id as string)

const currentChat = computed(() => 
  chats.value.find(chat => chat.id === currentChatId.value)
)

const isCurrentChatPinned = computed(() => 
  currentChat.value?.is_pinned === true
)

const connectionStatusIcon = computed(() => {
  switch (connectionStatus.value) {
    case 'connected': return Wifi
    case 'connecting': return Wifi
    case 'reconnecting': return Wifi
    case 'disconnected': return WifiOff
    default: return AlertCircle
  }
})

const connectionStatusText = computed(() => {
  switch (connectionStatus.value) {
    case 'connected': return 'Подключено'
    case 'connecting': return 'Подключение...'
    case 'reconnecting': return 'Переподключение...'
    case 'disconnected': return 'Отключено'
    default: return 'Неизвестно'
  }
})

const connectionStatusClass = computed(() => {
  switch (connectionStatus.value) {
    case 'connected': return 'status-connected'
    case 'connecting': return 'status-connecting'
    case 'reconnecting': return 'status-reconnecting'
    case 'disconnected': return 'status-disconnected'
    default: return 'status-unknown'
  }
})

// Группировка чатов по датам
const groupedHistoryChats = computed(() => {
  const now = new Date()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const yesterday = new Date(today)
  yesterday.setDate(yesterday.getDate() - 1)
  const weekAgo = new Date(today)
  weekAgo.setDate(weekAgo.getDate() - 7)
  const monthAgo = new Date(today)
  monthAgo.setMonth(monthAgo.getMonth() - 1)
  const yearAgo = new Date(today)
  yearAgo.setFullYear(yearAgo.getFullYear() - 1)

  const groups: Record<string, Chat[]> = {
    today: [],
    yesterday: [],
    week: [],
    month: [],
    year: [],
    older: []
  }

  historyChats.value.forEach(chat => {
    if (!chat.created_at) {
      groups.older.push(chat)
      return
    }

    const chatDate = parseCustomDate(chat.created_at)
    const chatDay = new Date(chatDate.getFullYear(), chatDate.getMonth(), chatDate.getDate())

    if (chatDay.getTime() === today.getTime()) {
      groups.today.push(chat)
    } else if (chatDay.getTime() === yesterday.getTime()) {
      groups.yesterday.push(chat)
    } else if (chatDate >= weekAgo) {
      groups.week.push(chat)
    } else if (chatDate >= monthAgo) {
      groups.month.push(chat)
    } else if (chatDate >= yearAgo) {
      groups.year.push(chat)
    } else {
      groups.older.push(chat)
    }
  })

  // Сортируем чаты внутри групп (новые сверху)
  Object.keys(groups).forEach(key => {
    groups[key].sort((a, b) => {
      const dateA = a.created_at ? parseCustomDate(a.created_at).getTime() : 0
      const dateB = b.created_at ? parseCustomDate(b.created_at).getTime() : 0
      return dateB - dateA
    })
  })

  return groups
})

const visibleHistoryGroups = computed(() => {
  const groups = []
  if (groupedHistoryChats.value.today.length > 0) {
    groups.push({ label: 'Сегодня', key: 'today', icon: Sun })
  }
  if (groupedHistoryChats.value.yesterday.length > 0) {
    groups.push({ label: 'Вчера', key: 'yesterday', icon: History })
  }
  if (groupedHistoryChats.value.week.length > 0) {
    groups.push({ label: 'За неделю', key: 'week', icon: Calendar })
  }
  if (groupedHistoryChats.value.month.length > 0) {
    groups.push({ label: 'За месяц', key: 'month', icon: Calendar })
  }
  if (groupedHistoryChats.value.year.length > 0) {
    groups.push({ label: 'За год', key: 'year', icon: Calendar })
  }
  if (groupedHistoryChats.value.older.length > 0) {
    groups.push({ label: 'Больше года', key: 'older', icon: Archive })
  }
  return groups
})

// -------------------------------------------------------------
// Watchers
// -------------------------------------------------------------

watch(() => route.params.id, async (newChatId) => {
  if (newChatId) {
    console.log('Смена чата:', newChatId)
    
    // Очищаем текущее состояние
    messages.value = []
    cleanupAIMessage()
    isWaiting.value = false
    lastError.value = null
    
    // Загружаем новый чат
    await loadChat()
    
    // Переподключаем WebSocket к новому чату
    cleanupWebSocket()
    cleanupTimers()
    setupWebSocket()
  }
})

function formatTime(dateString: string): string {
  if (!dateString) return ''
  
  try {
    const date = new Date(dateString)
    if (isNaN(date.getTime())) return ''
    
    const now = new Date()
    const diffMs = now.getTime() - date.getTime()
    const diffMins = Math.floor(diffMs / 60000)
    
    // Если сегодня - показываем время
    if (date.toDateString() === now.toDateString()) {
      return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }
    
    // Если вчера
    const yesterday = new Date(now)
    yesterday.setDate(yesterday.getDate() - 1)
    if (date.toDateString() === yesterday.toDateString()) {
      return 'Вчера ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }
    
    // Если на этой неделе
    const weekAgo = new Date(now)
    weekAgo.setDate(weekAgo.getDate() - 7)
    if (date > weekAgo) {
      return date.toLocaleDateString([], { weekday: 'short', hour: '2-digit', minute: '2-digit' })
    }
    
    // Старые даты
    return date.toLocaleDateString([], { day: 'numeric', month: 'short' })
  } catch (error) {
    console.warn('Ошибка форматирования времени:', error)
    return ''
  }
}

// Автоматическое изменение высоты textarea
watch(newMessage, () => {
  nextTick(() => {
    const textarea = inputRef.value
    if (textarea) {
      textarea.style.height = 'auto'
      textarea.style.height = Math.min(textarea.scrollHeight, 200) + 'px'
    }
  })
})
</script>

<template>
  <div class="chat-container">
    <!-- Заголовок с индикатором статуса -->
    <div class="chat-header">
      <div class="header-left">
        <h2 class="chat-title">
          {{ currentChat?.name || 'Новый чат' }}
        </h2>
      </div>
      <div class="header-right">
        <div :class="['connection-status', connectionStatusClass]" :title="connectionStatusText">
          <component :is="connectionStatusIcon" :size="16" />
          <span class="status-text">{{ connectionStatusText }}</span>
        </div>
      </div>
    </div>

    <!-- Основной контент -->
    <div class="chat-content">
      <!-- Боковая панель с чатами -->
      <aside class="chat-sidebar" :class="{ 'sidebar-collapsed': !isHistoryExpanded }">
        <div class="sidebar-header">
          <button class="new-chat-btn" @click="router.push('/service/chat')">
            <Plus :size="18" />
            <span>Новый чат</span>
          </button>
          <button class="toggle-history-btn" @click="isHistoryExpanded = !isHistoryExpanded">
            <span uk-icon="chevron-left" v-if="isHistoryExpanded"></span>
            <span uk-icon="chevron-right" v-else></span>
          </button>
        </div>

        <div v-if="isHistoryExpanded" class="sidebar-content">
          <!-- Индикатор загрузки -->
          <div v-if="chatsLoading" class="loading-indicator">
            <div uk-spinner></div>
            <span>Загрузка чатов...</span>
          </div>

          <!-- Сообщение об ошибке -->
          <div v-if="chatsError" class="error-alert">
            <AlertCircle :size="16" />
            <span class="error-text">{{ chatsError }}</span>
          </div>

          <!-- Закрепленные чаты -->
          <div v-if="pinnedChats.length > 0" class="chat-section">
            <h3 class="section-title">
              <Pin :size="16" />
              <span>Закрепленные</span>
              <span class="section-count">{{ pinnedChats.length }}</span>
            </h3>
            <ul class="chat-list">
              <li v-for="chat in pinnedChats" :key="chat.id" 
                  :class="{ active: chat.id === currentChatId }">
                <a :href="`/service/chat/${chat.id}`" @click.prevent="router.push(`/service/chat/${chat.id}`)">
                  {{ chat.name?.length > 20 ? chat.name.substring(0, 18) + '...' : chat.name || `Чат ${chat.id.slice(0, 6)}` }}
                </a>
              </li>
            </ul>
          </div>

          <!-- История чатов по группам -->
          <template v-for="group in visibleHistoryGroups" :key="group.key">
            <div class="chat-section">
              <h3 class="section-title">
                <component :is="group.icon" :size="16" />
                <span>{{ group.label }}</span>
                <span class="section-count">{{ groupedHistoryChats[group.key].length }}</span>
              </h3>
              <ul class="chat-list">
                <li v-for="chat in groupedHistoryChats[group.key]" :key="chat.id"
                    :class="{ active: chat.id === currentChatId }">
                  <a :href="`/service/chat/${chat.id}`" 
                     @click.prevent="router.push(`/service/chat/${chat.id}`)">
                    {{ chat.name?.length > 20 ? chat.name.substring(0, 18) + '...' : chat.name || `Чат ${chat.id.slice(0, 6)}` }}
                  </a>
                </li>
              </ul>
            </div>
          </template>
        </div>
      </aside>

      <!-- Основная область чата -->
      <main class="chat-main">
        <!-- Область сообщений -->
        <div class="messages-container" ref="messagesContainer">
          <div v-if="messages.length === 0 && !isWaiting" class="empty-state">
            <div class="empty-icon">💬</div>
            <h3>Начните общение</h3>
            <p>Задайте вопрос или начните диалог с AI</p>
          </div>

          <div v-else class="messages-list">
            <div v-for="msg in messages" :key="msg.id" 
                 :class="['message', msg.sender ? 'message-user' : 'message-ai']">
              <div class="message-header">
                <span class="message-sender">
                  {{ msg.sender ? msg.sender.username || 'Вы' : 'AI' }}
                </span>
                <span v-if="msg.timestamp || msg.created_at" class="message-time">
                  {{ formatTime(msg.timestamp || msg.created_at) }}
                </span>
              </div>
              <div class="message-content" 
                   :class="{ 'ai-content': !msg.sender }"
                   v-html="formatContent(msg.content, !msg.sender)">
              </div>
            </div>

            <!-- Индикатор ожидания ответа AI -->
            <div v-if="isWaiting && !pendingAIMessage.content" class="typing-indicator">
              <div class="typing-dots">
                <span></span>
                <span></span>
                <span></span>
              </div>
              <span class="typing-text">AI печатает...</span>
            </div>
          </div>
        </div>

        <!-- Область ввода -->
        <div class="input-area">
          <!-- Показ ошибок -->
          <div v-if="lastError" class="error-message">
            <AlertCircle :size="16" />
            <span>{{ lastError }}</span>
            <button @click="lastError = null" class="close-error">×</button>
          </div>

          <form @submit.prevent="sendMessage" class="message-form">
            <div class="input-wrapper">
              <textarea
                ref="inputRef"
                v-model="newMessage"
                @keydown="handleKeyDown"
                :disabled="isWaiting || connectionStatus !== 'connected'"
                :placeholder="connectionStatus === 'connected' ? 'Введите сообщение...' : 'Подключение...'"
                rows="1"
                maxlength="MAX_MESSAGE_LENGTH"
                class="message-input"
              ></textarea>
              <div class="input-actions">
                <button
                  type="submit"
                  :disabled="isWaiting || !newMessage.trim() || connectionStatus !== 'connected'"
                  class="send-button"
                  :title="connectionStatus !== 'connected' ? 'Ожидание подключения' : 'Отправить (Ctrl+Enter)'"
                >
                  <span uk-icon="arrow-up"></span>
                </button>
              </div>
            </div>
            <div class="input-hints">
              <span class="char-counter">{{ newMessage.length }}/{{ MAX_MESSAGE_LENGTH }}</span>
              <span class="hint-text">Shift+Enter для новой строки, Ctrl+Enter для отправки</span>
            </div>
          </form>
        </div>
      </main>
    </div>
  </div>
</template>

<style scoped>
.chat-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: var(--bg-color, #f8f9fa);
}

.chat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 1.5rem;
  background: white;
  border-bottom: 1px solid var(--border-color, #e9ecef);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.chat-title {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--text-color, #212529);
}

.connection-status {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.25rem 0.75rem;
  border-radius: 1rem;
  font-size: 0.875rem;
  font-weight: 500;
}

.status-connected {
  background: var(--success-light, #d4edda);
  color: var(--success-dark, #155724);
}

.status-connecting,
.status-reconnecting {
  background: var(--warning-light, #fff3cd);
  color: var(--warning-dark, #856404);
}

.status-disconnected {
  background: var(--danger-light, #f8d7da);
  color: var(--danger-dark, #721c24);
}

.status-text {
  font-size: 0.75rem;
}

.chat-content {
  display: flex;
  flex: 1;
  overflow: hidden;
}

.chat-sidebar {
  width: 280px;
  background: white;
  border-right: 1px solid var(--border-color, #e9ecef);
  display: flex;
  flex-direction: column;
  transition: width 0.3s ease;
  overflow: hidden;
}

.sidebar-collapsed {
  width: 60px;
}

.sidebar-header {
  padding: 1rem;
  border-bottom: 1px solid var(--border-color, #e9ecef);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.new-chat-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: var(--primary-color, #007bff);
  color: white;
  border: none;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: background 0.2s;
  font-size: 0.875rem;
  font-weight: 500;
}

.new-chat-btn:hover {
  background: var(--primary-dark, #0056b3);
}

.toggle-history-btn {
  background: none;
  border: 1px solid var(--border-color, #e9ecef);
  border-radius: 0.25rem;
  padding: 0.25rem;
  cursor: pointer;
  color: var(--text-muted, #6c757d);
}

.sidebar-content {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
}

.loading-indicator {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem;
  color: var(--text-muted, #6c757d);
  font-size: 0.875rem;
}

.error-alert {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem;
  background: var(--danger-light, #f8d7da);
  color: var(--danger-dark, #721c24);
  border-radius: 0.5rem;
  font-size: 0.875rem;
  margin-bottom: 1rem;
}

.chat-section {
  margin-bottom: 1.5rem;
}

.section-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0 0 0.75rem 0;
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--text-muted, #6c757d);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.section-count {
  margin-left: auto;
  background: var(--light-color, #e9ecef);
  color: var(--text-color, #212529);
  padding: 0.125rem 0.5rem;
  border-radius: 1rem;
  font-size: 0.75rem;
  font-weight: 500;
}

.chat-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.chat-list li {
  margin-bottom: 0.25rem;
}

.chat-list li a {
  display: block;
  padding: 0.5rem 0.75rem;
  border-radius: 0.5rem;
  color: var(--text-color, #212529);
  text-decoration: none;
  font-size: 0.875rem;
  transition: background 0.2s;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.chat-list li a:hover {
  background: var(--light-color, #f8f9fa);
}

.chat-list li.active a {
  background: var(--primary-light, #e3f2fd);
  color: var(--primary-color, #007bff);
  font-weight: 500;
}

.chat-main {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.messages-container {
  flex: 1;
  overflow-y: auto;
  padding: 1.5rem;
  background: var(--bg-color, #f8f9fa);
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: var(--text-muted, #6c757d);
  text-align: center;
}

.empty-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.empty-state h3 {
  margin: 0 0 0.5rem 0;
  font-size: 1.25rem;
  font-weight: 600;
}

.empty-state p {
  margin: 0;
  font-size: 0.875rem;
}

.messages-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.message {
  max-width: 80%;
  padding: 1rem;
  border-radius: 1rem;
  animation: messageAppear 0.3s ease;
}

@keyframes messageAppear {
  from {
    opacity: 0;
    transform: translateY(0.5rem);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.message-user {
  align-self: flex-end;
  background: var(--primary-color, #007bff);
  color: white;
  border-bottom-right-radius: 0.25rem;
}

.message-ai {
  align-self: flex-start;
  background: white;
  color: var(--text-color, #212529);
  border: 1px solid var(--border-color, #e9ecef);
  border-bottom-left-radius: 0.25rem;
}

.message-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
  font-size: 0.75rem;
}

.message-sender {
  font-weight: 600;
  opacity: 0.9;
}

.message-time {
  opacity: 0.7;
}

.message-content {
  line-height: 1.5;
  word-wrap: break-word;
}

.message-content.ai-content {
  line-height: 1.6;
}

.message-content.ai-content :deep(pre) {
  background: var(--code-bg, #f8f9fa);
  padding: 0.75rem;
  border-radius: 0.5rem;
  overflow-x: auto;
  margin: 0.5rem 0;
}

.message-content.ai-content :deep(code) {
  background: var(--code-inline-bg, #e9ecef);
  padding: 0.125rem 0.25rem;
  border-radius: 0.25rem;
  font-family: 'Courier New', monospace;
}

.typing-indicator {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem;
  background: white;
  border: 1px solid var(--border-color, #e9ecef);
  border-radius: 1rem;
  border-bottom-left-radius: 0.25rem;
  align-self: flex-start;
  max-width: 200px;
}

.typing-dots {
  display: flex;
  gap: 0.25rem;
}

.typing-dots span {
  width: 0.5rem;
  height: 0.5rem;
  background: var(--primary-color, #007bff);
  border-radius: 50%;
  animation: typing 1.4s infinite ease-in-out;
}

.typing-dots span:nth-child(2) {
  animation-delay: 0.2s;
}

.typing-dots span:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes typing {
  0%, 60%, 100% {
    transform: translateY(0);
  }
  30% {
    transform: translateY(-0.25rem);
  }
}

.typing-text {
  font-size: 0.875rem;
  color: var(--text-muted, #6c757d);
}

.input-area {
  padding: 1rem 1.5rem;
  background: white;
  border-top: 1px solid var(--border-color, #e9ecef);
  box-shadow: 0 -1px 3px rgba(0, 0, 0, 0.05);
}

.error-message {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  background: var(--danger-light, #f8d7da);
  color: var(--danger-dark, #721c24);
  border-radius: 0.5rem;
  margin-bottom: 1rem;
  font-size: 0.875rem;
  animation: slideDown 0.3s ease;
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-0.5rem);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.close-error {
  margin-left: auto;
  background: none;
  border: none;
  color: inherit;
  font-size: 1.25rem;
  cursor: pointer;
  opacity: 0.7;
  padding: 0;
  width: 1.5rem;
  height: 1.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-error:hover {
  opacity: 1;
}

.message-form {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.input-wrapper {
  display: flex;
  gap: 0.75rem;
  align-items: flex-end;
}

.message-input {
  flex: 1;
  padding: 0.75rem 1rem;
  border: 1px solid var(--border-color, #ced4da);
  border-radius: 0.75rem;
  font-size: 0.875rem;
  line-height: 1.5;
  resize: none;
  max-height: 200px;
  transition: border-color 0.2s;
  font-family: inherit;
}

.message-input:focus {
  outline: none;
  border-color: var(--primary-color, #007bff);
  box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
}

.message-input:disabled {
  background: var(--light-color, #e9ecef);
  cursor: not-allowed;
}

.input-actions {
  margin-bottom: 0.5rem;
}

.send-button {
  width: 2.5rem;
  height: 2.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--primary-color, #007bff);
  color: white;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  transition: background 0.2s;
}

.send-button:hover:not(:disabled) {
  background: var(--primary-dark, #0056b3);
}

.send-button:disabled {
  background: var(--secondary-color, #6c757d);
  cursor: not-allowed;
  opacity: 0.5;
}

.input-hints {
  display: flex;
  justify-content: space-between;
  font-size: 0.75rem;
  color: var(--text-muted, #6c757d);
}

.char-counter {
  font-family: 'Courier New', monospace;
}

.hint-text {
  opacity: 0.8;
}

/* Адаптивность */
@media (max-width: 768px) {
  .chat-sidebar {
    position: fixed;
    top: 0;
    left: 0;
    bottom: 0;
    z-index: 1000;
    transform: translateX(-100%);
    transition: transform 0.3s ease;
  }
  
  .chat-sidebar.sidebar-visible {
    transform: translateX(0);
  }
  
  .sidebar-collapsed {
    width: 280px;
  }
  
  .message {
    max-width: 90%;
  }
}
</style>
