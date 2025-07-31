<template>
  <top-banner />
  <loading />
  <main-form />
  <asus-footer />
</template>

<script lang="ts">
  import { defineComponent, ref, onMounted, provide } from 'vue';
  import TopBanner from './components/asus/TopBanner.vue';
  import Loading from './components/asus/Loading.vue';
  import AsusFooter from './components/asus/Footer.vue';
  import MainForm from './components/MainForm.vue';

  import engine, { SubmitActions } from '@modules/Engine';

  declare global {
    interface Window {
      show_menu?: () => void;
    }
  }

  export default defineComponent({
    name: 'App',
    components: {
      TopBanner,
      Loading,
      MainForm,
      AsusFooter
    },
    setup() {
      const uiResponse = ref({});
      window.scrollTo = () => {};

      const nginxConfig = ref({});
      provide('nginxConfig', nginxConfig);

      onMounted(async () => {
        try {
          // Ensure window.show_menu exists before calling
          if (typeof window.show_menu === 'function') {
            window.show_menu();
          }
          await engine.submit(SubmitActions.checkStatus, null, 0);
          // Simple delay using setTimeout
          await new Promise(resolve => setTimeout(resolve, 1000));
        } catch (error) {
          console.error('Error during initialization:', error);
        }
      });

      provide('uiResponse', uiResponse);

      return {
        uiResponse
      };
    }
  });
</script>

<style lang="scss">
  @import './App.globals.scss';
</style>
