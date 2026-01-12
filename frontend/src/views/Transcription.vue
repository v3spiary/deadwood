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
    <h3 class="uk-margin-middle-bottom">Audio to Text Transcriptions</h3>

    <table class="uk-table uk-table-justify uk-table-divider">
        <thead>
            <tr>
                <th class="uk-width-small">Название</th>
                <th>Описание</th>
                <th class="uk-width-small">Статус</th>
                <th class="uk-width-small">Формат</th>
                <th>Теги</th>
                <th class="uk-width-small">Продолжительность</th>
                <th class="uk-width-small">Дата и время загрузки</th>
                <th class="uk-width-small">Открыть расшифровку</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td class="uk-text-bolder">Лекция 2</td>
                <td>Лекция по теме N, обсуждалось то-то и т.д.</td>
                <td class="uk-text-muted">
                  <div><span class="uk-label uk-label-warning">В обработке</span></div>
                </td>
                <td>MP4 (видео)</td>
                <td>
                    <div><span class="uk-label">ВШЭ</span></div>
                    <div><span class="uk-label">Лекция</span></div>
                    <div><span class="uk-label">Правовой аудит</span></div>
                </td>
                <td>2:31:23</td>
                <td class="uk-text-muted">09-09-2025 14:30:25</td>
                <td><button class="uk-button uk-button-default" type="button" disabled>Открыть</button></td>
            </tr>

            <tr>
                <td class="uk-text-bolder">Лекция 2</td>
                <td>Лекция по теме N, обсуждалось то-то и т.д.</td>
                <td class="uk-text-muted">
                  <div><span class="uk-label uk-label-success">Готово</span></div>
                </td>
                <td>MP4 (видео)</td>
                <td>
                    <div><span class="uk-label">ВШЭ</span></div>
                    <div><span class="uk-label">Лекция</span></div>
                    <div><span class="uk-label">Правовой аудит</span></div>
                </td>
                <td>2:31:23</td>
                <td class="uk-text-muted">09-09-2025 14:30:25</td>
                <td><button class="uk-button uk-button-default" type="button">Открыть</button></td>
            </tr>
            
        </tbody>
    </table>
  </div>
</template>
