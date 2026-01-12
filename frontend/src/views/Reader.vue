<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '@/lib/api'

const router = useRouter()
const input = ref('')
const sending = ref(false)

</script>

<template>
  <div>

    <h3 class="uk-margin-middle-bottom">Reader Diary</h3>

    <div class="uk-child-width-1-4@m uk-grid-small" uk-grid="masonry: pack">

        <div>
            <div class="uk-card uk-card-default uk-card-hover">
                <div class="uk-card-media-top">
                    <img src="" width="600px" height="400px" alt="">
                </div>
                <div class="uk-card-body">
                    <div class="uk-card-badge uk-label">Брошено</div>
                    <div class="uk-width-expand">
                        <h3 class="uk-card-title uk-margin-remove-bottom">Мир на Земле</h3>
                        <p class="uk-text-meta uk-margin-remove-top">Фантастика</p>
                    </div>
                    <p>Автор: С. Лем</p>
                    <a href="#" class="uk-button uk-button-text">Открыть</a>
                </div>
            </div>
        </div>

    </div>

  </div>
</template>
