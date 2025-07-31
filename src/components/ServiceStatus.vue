<template>
  <div class="service-status">
    <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
      <thead>
        <tr>
          <td colspan="2">{{ $t('labels.service_status') }}</td>
        </tr>
      </thead>
      <tbody>
        <tr>
          <th>{{ $t('labels.nginx_status') }}</th>
          <td>
            <div class="status-container">
              <span :class="statusClass">{{ statusText }}</span>
              <div class="status-actions">
                <input
                  type="button"
                  class="button_gen"
                  :value="$t('labels.start')"
                  @click="startService"
                  :disabled="isRunning || isLoading"
                />
                <input
                  type="button"
                  class="button_gen"
                  :value="$t('labels.stop')"
                  @click="stopService"
                  :disabled="!isRunning || isLoading"
                />
                <input
                  type="button"
                  class="button_gen"
                  :value="$t('labels.restart')"
                  @click="restartService"
                  :disabled="isLoading"
                />
                <input
                  type="button"
                  class="button_gen"
                  :value="$t('labels.reload')"
                  @click="reloadService"
                  :disabled="!isRunning || isLoading"
                />
              </div>
            </div>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.version') }}</th>
          <td>{{ nginxVersion || 'N/A' }}</td>
        </tr>
        <tr>
          <th>{{ $t('labels.config_test') }}</th>
          <td>
            <div class="config-test">
              <span :class="configTestClass">{{ configTestText }}</span>
              <input
                type="button"
                class="button_gen"
                :value="$t('labels.test_config')"
                @click="testConfig"
                :disabled="isLoading"
              />
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script lang="ts">
  import { defineComponent, ref, computed, onMounted, type PropType } from 'vue';
  import { useI18n } from 'vue-i18n';
  import engine, { SubmitActions } from '@modules/Engine';

  interface Props {
    config: Record<string, any>;
  }

  export default defineComponent({
    name: 'ServiceStatus',
    props: {
      config: {
        type: Object as PropType<Record<string, any>>,
        required: true
      }
    },
    emits: ['update:config'],
    setup(props: Props) {
      const { t } = useI18n();

      const isRunning = ref(false);
      const isLoading = ref(false);
      const nginxVersion = ref('');
      const configTestResult = ref('');
      const configTestStatus = ref('unknown');

      const statusClass = computed(() => ({
        'status-running': isRunning.value,
        'status-stopped': !isRunning.value
      }));

      const statusText = computed(() =>
        isRunning.value ? t('labels.running') : t('labels.stopped')
      );

      const configTestClass = computed(() => ({
        'config-valid': configTestStatus.value === 'valid',
        'config-invalid': configTestStatus.value === 'invalid',
        'config-unknown': configTestStatus.value === 'unknown'
      }));

      const configTestText = computed(() => {
        switch (configTestStatus.value) {
          case 'valid': return t('labels.config_valid');
          case 'invalid': return t('labels.config_invalid');
          default: return t('labels.config_unknown');
        }
      });

      const checkStatus = async () => {
        try {
          isLoading.value = true;
          const response = await engine.submit(SubmitActions.checkStatus, props.config, 3);
          if (response?.nginxui_status) {
            isRunning.value = response.nginxui_status.running || false;
            nginxVersion.value = response.nginxui_status.version || '';
          }
        } catch (error) {
          console.error('Error checking status:', error);
        } finally {
          isLoading.value = false;
        }
      };

      const startService = async () => {
        try {
          isLoading.value = true;
          await engine.submit(SubmitActions.startService, props.config, 5);
          await checkStatus();
        } catch (error) {
          console.error('Error starting service:', error);
        } finally {
          isLoading.value = false;
        }
      };

      const stopService = async () => {
        try {
          isLoading.value = true;
          await engine.submit(SubmitActions.stopService, props.config, 5);
          await checkStatus();
        } catch (error) {
          console.error('Error stopping service:', error);
        } finally {
          isLoading.value = false;
        }
      };

      const restartService = async () => {
        try {
          isLoading.value = true;
          await engine.submit(SubmitActions.restartService, props.config, 5);
          await checkStatus();
        } catch (error) {
          console.error('Error restarting service:', error);
        } finally {
          isLoading.value = false;
        }
      };

      const reloadService = async () => {
        try {
          isLoading.value = true;
          await engine.submit(SubmitActions.reloadService, props.config, 3);
          await checkStatus();
        } catch (error) {
          console.error('Error reloading service:', error);
        } finally {
          isLoading.value = false;
        }
      };

      const testConfig = async () => {
        try {
          isLoading.value = true;
          const response = await engine.submit(SubmitActions.testConfig, props.config, 3);
          if (response?.nginxui_config_test) {
            configTestStatus.value = response.nginxui_config_test.valid ? 'valid' : 'invalid';
            configTestResult.value = response.nginxui_config_test.message || '';
          }
        } catch (error) {
          console.error('Error testing config:', error);
          configTestStatus.value = 'invalid';
        } finally {
          isLoading.value = false;
        }
      };

      onMounted(() => {
        checkStatus();
      });

      return {
        isRunning,
        isLoading,
        nginxVersion,
        configTestResult,
        configTestStatus,
        statusClass,
        statusText,
        configTestClass,
        configTestText,
        startService,
        stopService,
        restartService,
        reloadService,
        testConfig
      };
    }
  });
</script>

<style scoped>
  .service-status {
    margin-bottom: 20px;
  }

  .status-container {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .status-actions {
    display: flex;
    gap: 5px;
  }

  .status-running {
    color: #00ff00;
    font-weight: bold;
  }

  .status-stopped {
    color: #ff6666;
    font-weight: bold;
  }

  .config-test {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .config-valid {
    color: #00ff00;
    font-weight: bold;
  }

  .config-invalid {
    color: #ff6666;
    font-weight: bold;
  }

  .config-unknown {
    color: #cccccc;
  }
</style>
