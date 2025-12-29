
<script setup lang="ts">
import AppSidebar from "@/components/AppSidebar.vue"
import {
Breadcrumb,
BreadcrumbItem,
BreadcrumbLink,
BreadcrumbList,
BreadcrumbPage,
BreadcrumbSeparator,
} from "@/components/ui/breadcrumb"
import { Separator } from "@/components/ui/separator"
import {
SidebarInset,
SidebarProvider,
SidebarTrigger,
} from "@/components/ui/sidebar"
import { useRoute } from 'vue-router';

import { computed, ref, onMounted, watch } from 'vue';
import { api } from '@/lib/api';

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

const currentChat = ref<Chat | null>(null);

// Получаем ID чата из URL
const getChatIdFromPath = (path: string): string | null => {
  if (path.startsWith('/service/chat/')) {
    const parts = path.split('/');
    const id = parts[parts.length - 1];
    return id || null; // Явно возвращаем null если id пустой
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
    <SidebarProvider>
        <AppSidebar />
        <SidebarInset>
        <header class="flex h-16 shrink-0 items-center gap-2">
            <div class="flex items-center gap-2 px-4">
            <SidebarTrigger class="-ml-1" />
            <Separator orientation="vertical" class="mr-2 h-4" />
            <Breadcrumb>
                <BreadcrumbList>
                <BreadcrumbItem class="hidden md:block">
                    <BreadcrumbLink href="/">
                    Builder Platform
                    </BreadcrumbLink>
                </BreadcrumbItem>
                <BreadcrumbSeparator class="hidden md:block" />
                  <BreadcrumbItem v-if="currentChat">
                    <BreadcrumbLink href="/service/chat">
                      Chat
                    </BreadcrumbLink>
                  </BreadcrumbItem>
                  <BreadcrumbSeparator v-if="currentChat" class="hidden md:block" />
                  <BreadcrumbItem v-if="currentChat">
                    <BreadcrumbPage>{{ currentChat.name }}</BreadcrumbPage>
                  </BreadcrumbItem>
                  <BreadcrumbItem v-else>
                    <BreadcrumbPage>{{ currentTitle }}</BreadcrumbPage>
                  </BreadcrumbItem>
                </BreadcrumbList>
            </Breadcrumb>
            </div>
        </header>
        <div class="flex flex-1 flex-col gap-4 p-4 pt-0">
            <router-view />
        </div>
        </SidebarInset>
    </SidebarProvider>
</template>
