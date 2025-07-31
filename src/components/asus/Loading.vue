<template>
  <div id="Loading" class="popup_bg" v-show="isLoading">
    <div class="loading-overlay">
      <div class="loading-spinner"></div>
    </div>
  </div>
</template>

<script lang="ts">
  import { defineComponent, ref, inject, watch, type Ref } from 'vue';

  export default defineComponent({
    name: 'Loading',
    setup() {
      const isLoading = ref(false);
      const uiResponse = inject<Ref<{ loading?: boolean }>>('uiResponse');

      // Watch for loading state changes
      watch(
        () => uiResponse?.value?.loading,
        (newLoading) => {
          isLoading.value = newLoading || false;
        },
        { immediate: true }
      );

      return {
        isLoading
      };
    }
  });
</script>

<style scoped>
  .popup_bg {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.5);
    z-index: 9999;
  }
</style>