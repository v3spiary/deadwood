<script setup lang="ts">
const goBack = () => {
  window.history.back()
}
</script>

<template>
  <div class="uk-flex uk-flex-center uk-flex-middle" style="min-height: 100vh;">
    <div class="uk-text-center uk-width-large">
      <div class="uk-margin-large-bottom">
        <h1 class="uk-heading-xlarge uk-text-bold uk-margin-remove">404</h1>
        <h2 class="uk-heading-medium uk-margin-small-top">Not Found</h2>
      </div>
      
      <div class="uk-margin-medium-bottom">
        <p class="uk-text-large uk-text-muted">
          The page you're looking for doesn't exist.
        </p>
      </div>
      
      <div class="uk-margin">
        <a 
          href="javascript:void(0)" 
          @click="goBack"
          class="uk-button uk-button-primary uk-button-large"
        >
          Go back
        </a>
      </div>
    </div>
  </div>
</template>
