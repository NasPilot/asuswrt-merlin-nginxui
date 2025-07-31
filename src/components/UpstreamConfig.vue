<template>
  <div class="upstream-config">
    <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
      <thead>
        <tr>
          <td colspan="2">
            {{ $t('labels.upstream_configuration') }}
            <input 
              type="button" 
              class="button_gen" 
              :value="$t('labels.add_upstream')" 
              @click="addUpstream" 
              style="float: right;"
            />
          </td>
        </tr>
      </thead>
      <tbody>
        <tr v-if="localConfig.upstreams.length === 0">
          <td colspan="2" style="text-align: center; color: #999;">{{ $t('labels.no_upstreams') }}</td>
        </tr>
        <tr v-for="(upstream, index) in localConfig.upstreams" :key="index">
          <td colspan="2">
            <div class="upstream-block">
              <div class="upstream-header">
                <strong>{{ $t('labels.upstream') }} {{ index + 1 }}: {{ upstream.name }}</strong>
                <input 
                  type="button" 
                  class="button_gen" 
                  :value="$t('labels.remove')" 
                  @click="removeUpstream(index)" 
                  style="float: right;"
                />
              </div>
              <table class="upstream-table">
                <tr>
                  <th>{{ $t('labels.upstream_name') }}</th>
                  <td>
                    <input 
                      type="text" 
                      v-model="upstream.name" 
                      class="input_25_table" 
                      placeholder="backend"
                    />
                    <span class="hint">{{ $t('hints.upstream_name') }}</span>
                  </td>
                </tr>
                <tr>
                  <th>{{ $t('labels.load_balancing') }}</th>
                  <td>
                    <select v-model="upstream.method" class="input_option">
                      <option value="round_robin">{{ $t('labels.round_robin') }}</option>
                      <option value="least_conn">{{ $t('labels.least_conn') }}</option>
                      <option value="ip_hash">{{ $t('labels.ip_hash') }}</option>
                      <option value="hash">{{ $t('labels.hash') }}</option>
                    </select>
                    <span class="hint">{{ $t('hints.load_balancing') }}</span>
                  </td>
                </tr>
                <tr v-if="upstream.method === 'hash'">
                  <th>{{ $t('labels.hash_key') }}</th>
                  <td>
                    <input 
                      type="text" 
                      v-model="upstream.hash_key" 
                      class="input_25_table" 
                      placeholder="$remote_addr"
                    />
                    <span class="hint">{{ $t('hints.hash_key') }}</span>
                  </td>
                </tr>
                <tr>
                  <th>{{ $t('labels.servers') }}</th>
                  <td>
                    <div class="servers-container">
                      <div v-for="(server, serverIndex) in upstream.servers" :key="serverIndex" class="server-row">
                        <input 
                          type="text" 
                          v-model="server.address" 
                          class="input_25_table" 
                          placeholder="192.168.1.100:8080"
                        />
                        <input 
                          type="text" 
                          v-model="server.weight" 
                          class="input_6_table" 
                          placeholder="1"
                        />
                        <select v-model="server.status" class="input_option" style="width: 100px;">
                          <option value="">{{ $t('labels.active') }}</option>
                          <option value="backup">{{ $t('labels.backup') }}</option>
                          <option value="down">{{ $t('labels.down') }}</option>
                        </select>
                        <input 
                          type="button" 
                          class="button_gen" 
                          :value="$t('labels.remove')" 
                          @click="removeServer(index, serverIndex)" 
                        />
                      </div>
                      <div class="server-row">
                        <input 
                          type="button" 
                          class="button_gen" 
                          :value="$t('labels.add_server')" 
                          @click="addServer(index)" 
                        />
                      </div>
                    </div>
                  </td>
                </tr>
                <tr>
                  <th>{{ $t('labels.health_check') }}</th>
                  <td>
                    <input 
                      type="radio" 
                      :name="`health_check_${index}`" 
                      value="1" 
                      v-model="upstream.health_check"
                      class="input"
                    />
                    <label>{{ $t('labels.yes') }}</label>
                    <input 
                      type="radio" 
                      :name="`health_check_${index}`" 
                      value="0" 
                      v-model="upstream.health_check"
                      class="input"
                      style="margin-left: 10px;"
                    />
                    <label>{{ $t('labels.no') }}</label>
                  </td>
                </tr>
                <tr v-if="upstream.health_check === '1'">
                  <th>{{ $t('labels.health_check_path') }}</th>
                  <td>
                    <input 
                      type="text" 
                      v-model="upstream.health_check_path" 
                      class="input_25_table" 
                      placeholder="/health"
                    />
                    <span class="hint">{{ $t('hints.health_check_path') }}</span>
                  </td>
                </tr>
                <tr>
                  <th>{{ $t('labels.custom_config') }}</th>
                  <td>
                    <textarea 
                      v-model="upstream.custom_config" 
                      class="input_option" 
                      rows="3"
                      placeholder="# Custom upstream configuration"
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

  interface UpstreamServer {
    address: string;
    weight: string;
    status: string;
  }

  interface Upstream {
    name: string;
    method: string;
    hash_key: string;
    servers: UpstreamServer[];
    health_check: string;
    health_check_path: string;
    custom_config: string;
  }

  export default defineComponent({
    name: 'UpstreamConfig',
    setup() {
      const config = inject<Ref<{ upstream?: any }>>('nginxConfig');
      
      const localConfig = ref({
        upstreams: [] as Upstream[]
      });

      const addUpstream = () => {
        localConfig.value.upstreams.push({
          name: `backend_${localConfig.value.upstreams.length + 1}`,
          method: 'round_robin',
          hash_key: '$remote_addr',
          servers: [
            {
              address: '192.168.1.100:8080',
              weight: '1',
              status: ''
            }
          ],
          health_check: '0',
          health_check_path: '/health',
          custom_config: ''
        });
      };

      const removeUpstream = (index: number) => {
        localConfig.value.upstreams.splice(index, 1);
      };

      const addServer = (upstreamIndex: number) => {
        localConfig.value.upstreams[upstreamIndex].servers.push({
          address: '',
          weight: '1',
          status: ''
        });
      };

      const removeServer = (upstreamIndex: number, serverIndex: number) => {
        localConfig.value.upstreams[upstreamIndex].servers.splice(serverIndex, 1);
      };

      // Watch for changes in config and update local config
      watch(
        () => config?.value,
        (newConfig) => {
          if (newConfig?.upstream) {
            Object.assign(localConfig.value, newConfig.upstream);
          }
        },
        { immediate: true, deep: true }
      );

      // Watch for changes in local config and update main config
      watch(
        localConfig,
        (newLocalConfig) => {
          if (config?.value) {
            config.value.upstream = { ...newLocalConfig };
          }
        },
        { deep: true }
      );

      return {
        localConfig,
        addUpstream,
        removeUpstream,
        addServer,
        removeServer
      };
    }
  });
</script>

<style scoped>
  .upstream-config {
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

  .upstream-block {
    border: 1px solid #5a6a6f;
    border-radius: 3px;
    padding: 10px;
    margin: 5px 0;
    background-color: #2a3a3f;
  }

  .upstream-header {
    margin-bottom: 10px;
    padding-bottom: 5px;
    border-bottom: 1px solid #5a6a6f;
  }

  .upstream-table {
    width: 100%;
  }

  .upstream-table th {
    width: 150px;
    text-align: left;
    padding: 5px;
    background-color: #3a4a4f;
  }

  .upstream-table td {
    padding: 5px;
  }

  .servers-container {
    border: 1px solid #5a6a6f;
    border-radius: 3px;
    padding: 10px;
    background-color: #1a2a2f;
  }

  .server-row {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 5px;
  }

  .server-row:last-child {
    margin-bottom: 0;
  }
</style>