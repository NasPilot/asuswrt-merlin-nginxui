<template>
  <div class="basic-mode">
    <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
      <thead>
        <tr>
          <td colspan="2">{{ $t('labels.basic_settings') }}</td>
        </tr>
      </thead>
      <tbody>
        <tr>
          <th>{{ $t('labels.enable_nginx') }}</th>
          <td>
            <input
              type="radio"
              name="nginx_enable"
              value="1"
              v-model="localConfig.enable"
              class="input"
            />
            <label>{{ $t('labels.yes') }}</label>
            <input
              type="radio"
              name="nginx_enable"
              value="0"
              v-model="localConfig.enable"
              class="input"
              style="margin-left: 10px;"
            />
            <label>{{ $t('labels.no') }}</label>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.listen_port') }}</th>
          <td>
            <input
              type="text"
              v-model="localConfig.port"
              class="input_15_table"
              maxlength="5"
              placeholder="80"
            />
            <span class="hint">{{ $t('hints.listen_port') }}</span>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.ssl_port') }}</th>
          <td>
            <input
              type="text"
              v-model="localConfig.ssl_port"
              class="input_15_table"
              maxlength="5"
              placeholder="443"
            />
            <span class="hint">{{ $t('hints.ssl_port') }}</span>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.server_name') }}</th>
          <td>
            <input
              type="text"
              v-model="localConfig.server_name"
              class="input_32_table"
              placeholder="example.com"
            />
            <span class="hint">{{ $t('hints.server_name') }}</span>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.document_root') }}</th>
          <td>
            <input
              type="text"
              v-model="localConfig.document_root"
              class="input_32_table"
              placeholder="/opt/share/www"
            />
            <span class="hint">{{ $t('hints.document_root') }}</span>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.index_files') }}</th>
          <td>
            <input
              type="text"
              v-model="localConfig.index_files"
              class="input_32_table"
              placeholder="index.html index.htm"
            />
            <span class="hint">{{ $t('hints.index_files') }}</span>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.enable_ssl') }}</th>
          <td>
            <input
              type="radio"
              name="ssl_enable"
              value="1"
              v-model="localConfig.ssl_enable"
              class="input"
            />
            <label>{{ $t('labels.yes') }}</label>
            <input
              type="radio"
              name="ssl_enable"
              value="0"
              v-model="localConfig.ssl_enable"
              class="input"
              style="margin-left: 10px;"
            />
            <label>{{ $t('labels.no') }}</label>
          </td>
        </tr>
        <tr v-if="localConfig.ssl_enable === '1'">
          <th>{{ $t('labels.ssl_certificate') }}</th>
          <td>
            <input
              type="text"
              v-model="localConfig.ssl_cert"
              class="input_32_table"
              placeholder="/opt/etc/nginx/ssl/server.crt"
            />
            <span class="hint">{{ $t('hints.ssl_certificate') }}</span>
          </td>
        </tr>
        <tr v-if="localConfig.ssl_enable === '1'">
          <th>{{ $t('labels.ssl_private_key') }}</th>
          <td>
            <input
              type="text"
              v-model="localConfig.ssl_key"
              class="input_32_table"
              placeholder="/opt/etc/nginx/ssl/server.key"
            />
            <span class="hint">{{ $t('hints.ssl_private_key') }}</span>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.access_log') }}</th>
          <td>
            <input
              type="radio"
              name="access_log_enable"
              value="1"
              v-model="localConfig.access_log_enable"
              class="input"
            />
            <label>{{ $t('labels.yes') }}</label>
            <input
              type="radio"
              name="access_log_enable"
              value="0"
              v-model="localConfig.access_log_enable"
              class="input"
              style="margin-left: 10px;"
            />
            <label>{{ $t('labels.no') }}</label>
          </td>
        </tr>
        <tr v-if="localConfig.access_log_enable === '1'">
          <th>{{ $t('labels.access_log_path') }}</th>
          <td>
            <input
              type="text"
              v-model="localConfig.access_log_path"
              class="input_32_table"
              placeholder="/opt/var/log/nginx/access.log"
            />
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.error_log') }}</th>
          <td>
            <input
              type="radio"
              name="error_log_enable"
              value="1"
              v-model="localConfig.error_log_enable"
              class="input"
            />
            <label>{{ $t('labels.yes') }}</label>
            <input
              type="radio"
              name="error_log_enable"
              value="0"
              v-model="localConfig.error_log_enable"
              class="input"
              style="margin-left: 10px;"
            />
            <label>{{ $t('labels.no') }}</label>
          </td>
        </tr>
        <tr v-if="localConfig.error_log_enable === '1'">
          <th>{{ $t('labels.error_log_path') }}</th>
          <td>
            <input
              type="text"
              v-model="localConfig.error_log_path"
              class="input_32_table"
              placeholder="/opt/var/log/nginx/error.log"
            />
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script lang="ts">
  import { defineComponent, ref, watch, inject, type Ref } from 'vue';

  export default defineComponent({
    name: 'BasicMode',
    setup() {
      const config = inject<Ref<{ basic?: any }>>('nginxConfig');

      const localConfig = ref({
        enable: '1',
        port: '80',
        ssl_port: '443',
        server_name: '_',
        document_root: '/opt/share/www',
        index_files: 'index.html index.htm',
        ssl_enable: '0',
        ssl_cert: '/opt/etc/nginx/ssl/server.crt',
        ssl_key: '/opt/etc/nginx/ssl/server.key',
        access_log_enable: '1',
        access_log_path: '/opt/var/log/nginx/access.log',
        error_log_enable: '1',
        error_log_path: '/opt/var/log/nginx/error.log'
      });

      // Watch for changes in config and update local config
      watch(
        () => config?.value,
        (newConfig) => {
          if (newConfig?.basic) {
            Object.assign(localConfig.value, newConfig.basic);
          }
        },
        { immediate: true, deep: true }
      );

      // Watch for changes in local config and update main config
      watch(
        localConfig,
        (newLocalConfig) => {
          if (config?.value) {
            config.value.basic = { ...newLocalConfig };
          }
        },
        { deep: true }
      );

      return {
        localConfig
      };
    }
  });
</script>

<style scoped>
  .basic-mode {
    margin-bottom: 20px;
  }

  .hint {
    color: #999;
    font-size: 11px;
    margin-left: 10px;
  }

  label {
    margin-left: 5px;
    margin-right: 10px;
  }
</style>
