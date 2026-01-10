<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth'

interface Chat {
    id: string;
    name: string;
    is_pinned?: boolean;
    deleted?: boolean;
    created_at?: string;
    latest_messages: any[];
}

const route = useRoute();
const currentTitle = computed(() => route.meta.title as string | undefined);

const authStore = useAuthStore()

const currentChat = ref<Chat | null>(null);


// Получаем ID чата из URL
const getChatIdFromPath = (path: string): string | null => {
  if (path.startsWith('/service/chat/')) {
    const parts = path.split('/');
    const id = parts[parts.length - 1];
    return id || null;
  }
  return null;
};

// Загружаем информацию о чате
const fetchChat = async (chatId: string) => {
  try {
    const response = await api.get(`/chatbot/chats/${chatId}/`);
    currentChat.value = response.data;
  } catch (e) {
    console.error('Error fetching chat:', e);
    currentChat.value = null;
  }
};

// Следим за изменением маршрута и загружаем чат если нужно
watch(() => route.path, (newPath) => {
  const chatId = getChatIdFromPath(newPath);
  if (chatId) {
    fetchChat(chatId);
  } else {
    currentChat.value = null;
  }
}, { immediate: true });
</script>

<template>
  <div class="uk-flex uk-flex-column" style="min-height: 100vh;">
    <!-- Верхняя навигационная панель -->
    <nav class="uk-navbar-container uk-box-shadow-small" uk-navbar>
      <div class="uk-navbar-left">
        <a class="uk-navbar-item uk-logo" href="/">DEADWOOD</a>
      </div>
      
      <div class="uk-navbar-center">
        <ul class="uk-breadcrumb uk-margin-remove">
          <li v-if="currentChat">
            <a href="/service/chat">Chat</a>
          </li>
          <li v-if="currentChat">
            <span>{{ currentChat.name }}</span>
          </li>
          <li v-else>
            <span>{{ currentTitle || 'Dashboard' }}</span>
          </li>
        </ul>
      </div>
      
      <div class="uk-navbar-right">
        <ul class="uk-navbar-nav">
          <li><a href="" @click="authStore.logout">Logout</a></li>
        </ul>
      </div>
    </nav>

    <!-- Основное содержимое -->
    <main class="uk-flex-1 uk-padding">
      <router-view />
    </main>
  </div>
</template>
