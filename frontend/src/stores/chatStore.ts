// stores/chatStore.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { api } from '@/lib/api'
import type { Chat } from '@/types/chat'

export const useChatStore = defineStore('chat', () => {
  const chats = ref<Chat[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)
  const currentChatId = ref<string | null>(null)
  
  const currentChat = computed(() => {
    return chats.value.find(chat => chat.id === currentChatId.value)
  })
  
  const pinnedChats = computed(() => {
    return chats.value.filter(chat => chat.is_pinned && !chat.deleted)
  })
  
  const historyChats = computed(() => {
    return chats.value.filter(chat => !chat.is_pinned && !chat.deleted)
  })
  
  async function fetchChats() {
    loading.value = true
    error.value = null
    
    try {
      const response = await api.get('/chatbot/chats/')
      
      if (response.data?.results) {
        chats.value = response.data.results
      } else if (Array.isArray(response.data)) {
        chats.value = response.data
      } else {
        chats.value = []
      }
    } catch (err: any) {
      error.value = err.message || 'Failed to load chats'
      console.error('Error fetching chats:', err)
    } finally {
      loading.value = false
    }
  }
  
  async function createChat(name?: string) {
    try {
      const response = await api.post('/chatbot/chats/', { name })
      chats.value.unshift(response.data)
      return response.data
    } catch (err) {
      console.error('Error creating chat:', err)
      throw err
    }
  }
  
  async function updateChat(chatId: string, updates: Partial<Chat>) {
    try {
      const response = await api.patch(`/chatbot/chats/${chatId}/`, updates)
      const index = chats.value.findIndex(c => c.id === chatId)
      if (index !== -1) {
        chats.value[index] = { ...chats.value[index], ...response.data }
      }
      return response.data
    } catch (err) {
      console.error('Error updating chat:', err)
      throw err
    }
  }
  
  function setCurrentChat(chatId: string | null) {
    currentChatId.value = chatId
  }
  
  return {
    chats,
    loading,
    error,
    currentChatId,
    currentChat,
    pinnedChats,
    historyChats,
    fetchChats,
    createChat,
    updateChat,
    setCurrentChat
  }
})