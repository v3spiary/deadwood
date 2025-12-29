<script setup lang="ts">
import type { SidebarProps } from '@/components/ui/sidebar'

import {
  BookOpen,
  Bot,
  Command,
  Frame,
  LifeBuoy,
  Map,
  PieChart,
  Send,
  Settings2,
  SquareTerminal,
  Pin,
  History
} from "lucide-vue-next"
import NavMain from '@/components/NavMain.vue'
import NavSecondary from '@/components/NavSecondary.vue'
import NavUser from '@/components/NavUser.vue'
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from '@/components/ui/sidebar'
import { Plus } from "lucide-vue-next"
import { useRouter, useRoute } from "vue-router"
import { ref, onMounted, computed, watch } from 'vue'
import { api } from '@/lib/api'

const props = withDefaults(defineProps<SidebarProps>(), {
  variant: "inset",
})

interface Chat {
  id: string;
  name: string;
  is_pinned?: boolean;
  deleted?: boolean;
  created_at?: string;
  latest_messages: any[];
}

const router = useRouter()
const route = useRoute()
const chats = ref<Chat[]>([])
const loading = ref(false)

const currentChatId = computed(() => {
  const path = route.path
  if (path.startsWith('/service/chat/')) {
    const parts = path.split('/')
    return parts[parts.length - 1]
  }
  return null
})

const currentChat = computed(() => {
  if (!currentChatId.value) return null
  return chats.value.find(chat => chat.id === currentChatId.value)
})

async function fetchChats() {
  try {
    loading.value = true
    const response = await api.get('/chatbot/chats/')
    chats.value = response.data.results || []
    console.log('Loaded chats:', chats.value)
  } catch (e) {
    console.error('Error fetching chats:', e)
  } finally {
    loading.value = false
  }
}

const pinnedChats = computed(() => 
  chats.value.filter(chat => chat.is_pinned).map(chat => ({
    title: chat.name,
    url: `/service/chat/${chat.id}`,
    isActive: currentChatId.value === chat.id
  }))
)

const historyChats = computed(() => 
  chats.value.filter(chat => !chat.is_pinned).map(chat => ({
    title: chat.name,
    url: `/service/chat/${chat.id}`,
    isActive: currentChatId.value === chat.id
  }))
)

const expandedSections = computed(() => {
  const sections = {
    pinned: true,
    history: true
  }
  
  if (!currentChat.value) return sections
  
  if (currentChat.value.is_pinned) {
    sections.pinned = true
  }
  sections.history = true
  
  return sections
})

const user = {
  name: "shadcn",
  email: "m@example.com",
  avatar: "/avatars/shadcn.jpg",
}

const navMain = computed(() => [
  {
    title: "New Chat",
    url: "/service/chat",
    icon: Plus,
    isActive: route.path === '/service/chat',
    items: []
  },
  {
    title: "Pinned",
    url: "#",
    icon: Pin,
    isExpanded: true,
    items: pinnedChats.value
  },
  {
    title: "History",
    url: "#",
    icon: History,
    isExpanded: true,
    items: historyChats.value
  }
])

const navSecondary = [
  {
    title: "Support",
    url: "#",
    icon: LifeBuoy,
  },
  {
    title: "Feedback",
    url: "#",
    icon: Send,
  },
]

onMounted(async () => {
  await fetchChats()
})

watch(() => route.path, async () => {
  await fetchChats()
})
</script>

<template>
  <Sidebar v-bind="props">
    <SidebarHeader>
      <SidebarMenu>
        <SidebarMenuItem>
          <SidebarMenuButton size="lg" as-child>
            <a href="/">
              <div class="flex aspect-square size-8 items-center justify-center rounded-lg bg-sidebar-primary text-sidebar-primary-foreground">
                <Command class="size-4" />
              </div>
              <div class="grid flex-1 text-left text-sm leading-tight">
                <span class="truncate font-medium">Builer Platform</span>
                <span class="truncate text-xs">Pilot version</span>
              </div>
            </a>
          </SidebarMenuButton>
        </SidebarMenuItem>
      </SidebarMenu>
    </SidebarHeader>
    <SidebarContent>
      <NavMain :items="navMain" />
      <NavSecondary :items="navSecondary" class="mt-auto" />
    </SidebarContent>
    <SidebarFooter>
      <NavUser :user="user" />
    </SidebarFooter>
  </Sidebar>
</template>