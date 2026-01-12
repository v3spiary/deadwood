<script setup lang="ts">
import LoginForm from "@/components/LoginForm.vue"
import DarkVeil from "@/components/DarkVeil.vue";
</script>
<template>
  <div style="width: 100%; height: 100vh; position: relative">
    <DarkVeil
      :hue-shift="249"
      :noise-intensity="0"
      :scanline-intensity="3.1"
      :speed="1.5"
      :scanline-frequency="0"
      :warp-amount="5"
      :resolution-scale="1"
    />
  </div>
  <div class="grid min-h-svh lg:grid-cols-2 uk-light">
    <div class="flex flex-col gap-4 p-6 md:p-10">
      <div class="flex flex-1 items-center justify-center">
        <div class="w-full max-w-xs">
          <LoginForm />
        </div>
      </div>
    </div>
  </div>
</template>
