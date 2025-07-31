<template>
  <div class="server-config">
    <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
      <thead>
        <tr>
          <td colspan="2">{{ $t('labels.server_configuration') }}</td>
        </tr>
      </thead>
      <tbody>
        <tr>
          <th>{{ $t('labels.worker_processes') }}</th>
          <td>
            <input
              type="text"
              v-model="localConfig.worker_processes"
              class="input_6_table"
              maxlength="2"
              placeholder="auto"
            />
            <span class="hint">{{ $t('hints.worker_processes') }}</span>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.worker_connections') }}</th>
          <td>
            <input
              type="text"
              v-model="localConfig.worker_connections"
              class="input_15_table"
              maxlength="5"
              placeholder="1024"
            />
            <span class="hint">{{ $t('hints.worker_connections') }}</span>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.keepalive_timeout') }}</th>
          <td>
            <input
              type="text"
              v-model="localConfig.keepalive_timeout"
              class="input_6_table"
              maxlength="3"
              placeholder="65"
            />
            <span class="hint">{{ $t('hints.keepalive_timeout') }}</span>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.client_max_body_size') }}</th>
          <td>
            <input
              type="text"
              v-model="localConfig.client_max_body_size"
              class="input_15_table"
              placeholder="1m"
            />
            <span class="hint">{{ $t('hints.client_max_body_size') }}</span>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.gzip_compression') }}</th>
          <td>
            <input
              type="radio"
              name="gzip_enable"
              value="1"
              v-model="localConfig.gzip_enable"
              class="input"
            />
            <label>{{ $t('labels.yes') }}</label>
            <input
              type="radio"
              name="gzip_enable"
              value="0"
              v-model="localConfig.gzip_enable"
              class="input"
              style="margin-left: 10px;"
            />
            <label>{{ $t('labels.no') }}</label>
          </td>
        </tr>
        <tr v-if="localConfig.gzip_enable === '1'">
          <th>{{ $t('labels.gzip_types') }}</th>
          <td>
            <textarea
              v-model="localConfig.gzip_types"
              class="input_option"
              rows="3"
              placeholder="text/plain text/css application/json application/javascript text/xml application/xml"
            ></textarea>
            <span class="hint">{{ $t('hints.gzip_types') }}</span>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.custom_directives') }}</th>
          <td>
            <textarea
              v-model="localConfig.custom_directives"
              class="input_option"
              rows="5"
              placeholder="# Add custom nginx directives here"
            ></textarea>
            <span class="hint">{{ $t('hints.custom_directives') }}</span>
          </td>
        </tr>
      </tbody>
    </table>

    <!-- Server Blocks -->
    <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="margin-top: 20px;">
      <thead>
        <tr>
          <td colspan="2">
            {{ $t('labels.server_blocks') }}
            <input
              type="button"
              class="button_gen"
              :value="$t('labels.add_server')"
              @click="addServer"
              style="float: right;"
            />
          </td>
        </tr>
      </thead>
      <tbody>
        <tr v-if="localConfig.servers.length === 0">
          <td colspan="2" style="text-align: center; color: #999;">{{ $t('labels.no_servers') }}</td>
        </tr>
        <tr v-for="(server, index) in localConfig.servers" :key="index">
          <td style="width: 90%;">
            <div class="server-block">
              <div class="server-header">
                <strong>{{ $t('labels.server') }} {{ index + 1 }}</strong>
                <input
                  type="button"
                  class="button_gen"
                  :value="$t('labels.remove')"
                  @click="removeServer(index)"
                  style="float: right;"
                />
              </div>
              <table class="server-table">
                <tr>
                  <th>{{ $t('labels.listen') }}</th>
                  <td>
                    <input
                      type="text"
                      v-model="server.listen"
                      class="input_15_table"
                      placeholder="80"
                    />
                  </td>
                </tr>
                <tr>
                  <th>{{ $t('labels.server_name') }}</th>
                  <td>
                    <input
                      type="text"
                      v-model="server.server_name"
                      class="input_32_table"
                      placeholder="example.com"
                    />
                  </td>
                </tr>
                <tr>
                  <th>{{ $t('labels.root') }}</th>
                  <td>
                    <input
                      type="text"
                      v-model="server.root"
                      class="input_32_table"
                      placeholder="/opt/share/www"
                    />
                  </td>
                </tr>
                <tr>
                  <th>{{ $t('labels.index') }}</th>
                  <td>
                    <input
                      type="text"
                      v-model="server.index"
                      class="input_32_table"
                      placeholder="index.html index.htm"
                    />
                  </td>
                </tr>
                <tr>
                  <th>{{ $t('labels.custom_config') }}</th>
                  <td>
                    <textarea
                      v-model="server.custom_config"
                      class="input_option"
                      rows="4"
                      placeholder="# Custom server configuration"
                    ></textarea>
                  </td>
                </tr>
              </table>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script lang="ts">
  import { defineComponent, ref, watch, inject, type Ref } from 'vue';

  interface ServerBlock {
    listen: string;
    server_name: string;
    root: string;
    index: string;
    custom_config: string;
  }

  export default defineComponent({
    name: 'ServerConfig',
    setup() {
      const config = inject<Ref<{ server?: any }>>('nginxConfig');

      const localConfig = ref({
        worker_processes: 'auto',
        worker_connections: '1024',
        keepalive_timeout: '65',
        client_max_body_size: '1m',
        gzip_enable: '1',
        gzip_types: 'text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript',
        custom_directives: '',
        servers: [] as ServerBlock[]
      });

      const addServer = () => {
        localConfig.value.servers.push({
          listen: '80',
          server_name: '_',
          root: '/opt/share/www',
          index: 'index.html index.htm',
          custom_config: ''
        });
      };

      const removeServer = (index: number) => {
        localConfig.value.servers.splice(index, 1);
      };

      // Watch for changes in config and update local config
      watch(
        () => config?.value,
        (newConfig) => {
          if (newConfig?.server) {
            Object.assign(localConfig.value, newConfig.server);
          }
        },
        { immediate: true, deep: true }
      );

      // Watch for changes in local config and update main config
      watch(
        localConfig,
        (newLocalConfig) => {
          if (config?.value) {
            config.value.server = { ...newLocalConfig };
          }
        },
        { deep: true }
      );

      return {
        localConfig,
        addServer,
        removeServer
      };
    }
  });
</script>

<style scoped>
  .server-config {
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

  .server-block {
    border: 1px solid #5a6a6f;
    border-radius: 3px;
    padding: 10px;
    margin: 5px 0;
    background-color: #2a3a3f;
  }

  .server-header {
    margin-bottom: 10px;
    padding-bottom: 5px;
    border-bottom: 1px solid #5a6a6f;
  }

  .server-table {
    width: 100%;
  }

  .server-table th {
    width: 150px;
    text-align: left;
    padding: 5px;
    background-color: #3a4a4f;
  }

  .server-table td {
    padding: 5px;
  }
</style>
