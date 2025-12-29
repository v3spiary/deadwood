<script setup lang="ts">
import { SearchIcon } from "lucide-vue-next"
import {
  Empty,
  EmptyContent,
  EmptyDescription,
  EmptyHeader,
  EmptyTitle,
} from "@/components/ui/empty"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupInput,
} from "@/components/ui/input-group"
import { Kbd } from "@/components/ui/kbd"
</script>

<template>
  <Empty class="min-h-screen flex items-center justify-center">
    <EmptyHeader class="flex flex-col justify-center h-full">
      <EmptyTitle>404 - Not Found</EmptyTitle>
      <EmptyDescription>
        The page you&apos;re looking for doesn&apos;t exist.
      </EmptyDescription>
    </EmptyHeader>
    <EmptyContent class="flex flex-col justify-center h-full">
      <EmptyDescription>
        <a href="javascript:history.back()">Go back</a>
      </EmptyDescription>
    </EmptyContent>
  </Empty>
</template>
