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
    <h3 class="uk-margin-middle-bottom">Startup Platform</h3>

    <div class="uk-child-width-1-4@m uk-grid-small" uk-grid="masonry: pack">

        <div>
            <div class="uk-card uk-card-default uk-card-hover">
                <div class="uk-card-body">
                    <div class="uk-card-badge uk-label uk-label-success">B2B</div>
                    <h3 class="uk-card-title">Название проекта</h3>

                    <ul class="uk-subnav uk-subnav-pill" uk-switcher>
                        <li><a href="#">Идея</a></li>
                        <li><a href="#">ЦА</a></li>
                        <li><a href="#">Показатели</a></li>
                    </ul>

                    <div class="uk-switcher uk-margin">

                        <div>
                          <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
                        </div>

                        <div>


                                <div>
                                    <div uk-grid>
                                        <div class="uk-width-auto@m uk-flex-last@m">
                                            <ul class="uk-tab-right" uk-tab="connect: #component-tab-right; animation: uk-animation-fade">
                                                <li><a href="#">WHAT</a></li>
                                                <li><a href="#">WHO</a></li>
                                                <li><a href="#">WHY</a></li>
                                                <li><a href="#">WHEN</a></li>
                                                <li><a href="#">WHERE</a></li>
                                            </ul>
                                        </div>
                                        <div class="uk-width-expand@m">
                                            <div id="component-tab-right" class="uk-switcher">

                                                <div>
                                                    <p>Что продаем?</p>
                                                </div>

                                                <div>
                                                    <p>Кто купит?</p>
                                                </div>

                                                <div>
                                                    <p>Зачем это ему?</p>
                                                </div>

                                                <div>
                                                    <p>Когда купит?</p>
                                                </div>

                                                <div>
                                                    <p>Где купит?</p>
                                                </div>

                                            </div>
                                        </div>
                                    </div>
                                </div>


                        </div>

                        <div>
                          <div class="uk-grid-small" uk-grid>
                              <div class="uk-width-expand" uk-leader>NPV</div>
                              <div class="uk-text-success">2.000.000</div>
                          </div>
                          <div class="uk-grid-small" uk-grid>
                              <div class="uk-width-expand" uk-leader>FPV</div>
                              <div class="uk-text-success">1,5 года</div>
                          </div>
                          <div class="uk-grid-small" uk-grid>
                              <div class="uk-width-expand" uk-leader>FSB</div>
                              <div class="uk-text-warning">32%</div>
                          </div>
                          <div class="uk-grid-small" uk-grid>
                              <div class="uk-width-expand" uk-leader>ABC</div>
                              <div class="uk-text-danger">4.2</div>
                          </div>
                          <div class="uk-grid-small" uk-grid>
                              <div class="uk-width-expand" uk-leader>ETC</div>
                              <div class="uk-text-warning">1</div>
                          </div>
                        </div>

                    </div>

                </div>
                <div class="uk-card-footer">
                    <a href="#" class="uk-button uk-button-text">Открыть</a>
                </div>
            </div>
        </div>

    </div>

  </div>
</template>
