<template>
  <div class="ssl-config">
    <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
      <thead>
        <tr>
          <td colspan="2">{{ $t('labels.ssl_configuration') }}</td>
        </tr>
      </thead>
      <tbody>
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
        <template v-if="localConfig.ssl_enable === '1'">
          <tr>
            <th>{{ $t('labels.ssl_protocols') }}</th>
            <td>
              <div class="checkbox-group">
                <label v-for="protocol in sslProtocols" :key="protocol">
                  <input 
                    type="checkbox" 
                    :value="protocol" 
                    v-model="selectedProtocols"
                    class="input"
                  />
                  {{ protocol }}
                </label>
              </div>
              <span class="hint">{{ $t('hints.ssl_protocols') }}</span>
            </td>
          </tr>
          <tr>
            <th>{{ $t('labels.ssl_ciphers') }}</th>
            <td>
              <select v-model="localConfig.ssl_ciphers_preset" class="input_option">
                <option value="modern">{{ $t('labels.modern') }}</option>
                <option value="intermediate">{{ $t('labels.intermediate') }}</option>
                <option value="old">{{ $t('labels.old') }}</option>
                <option value="custom">{{ $t('labels.custom') }}</option>
              </select>
              <span class="hint">{{ $t('hints.ssl_ciphers') }}</span>
            </td>
          </tr>
          <tr v-if="localConfig.ssl_ciphers_preset === 'custom'">
            <th>{{ $t('labels.custom_ciphers') }}</th>
            <td>
              <textarea 
                v-model="localConfig.ssl_ciphers_custom" 
                class="input_option" 
                rows="3"
                placeholder="ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256"
              ></textarea>
            </td>
          </tr>
          <tr>
            <th>{{ $t('labels.ssl_certificate') }}</th>
            <td>
              <input 
                type="text" 
                v-model="localConfig.ssl_certificate" 
                class="input_32_table" 
                placeholder="/opt/etc/nginx/ssl/server.crt"
              />
              <span class="hint">{{ $t('hints.ssl_certificate') }}</span>
            </td>
          </tr>
          <tr>
            <th>{{ $t('labels.ssl_private_key') }}</th>
            <td>
              <input 
                type="text" 
                v-model="localConfig.ssl_private_key" 
                class="input_32_table" 
                placeholder="/opt/etc/nginx/ssl/server.key"
              />
              <span class="hint">{{ $t('hints.ssl_private_key') }}</span>
            </td>
          </tr>
          <tr>
            <th>{{ $t('labels.ssl_dhparam') }}</th>
            <td>
              <input 
                type="text" 
                v-model="localConfig.ssl_dhparam" 
                class="input_32_table" 
                placeholder="/opt/etc/nginx/ssl/dhparam.pem"
              />
              <span class="hint">{{ $t('hints.ssl_dhparam') }}</span>
            </td>
          </tr>
          <tr>
            <th>{{ $t('labels.ssl_session_cache') }}</th>
            <td>
              <input 
                type="text" 
                v-model="localConfig.ssl_session_cache" 
                class="input_25_table" 
                placeholder="shared:SSL:10m"
              />
              <span class="hint">{{ $t('hints.ssl_session_cache') }}</span>
            </td>
          </tr>
          <tr>
            <th>{{ $t('labels.ssl_session_timeout') }}</th>
            <td>
              <input 
                type="text" 
                v-model="localConfig.ssl_session_timeout" 
                class="input_15_table" 
                placeholder="10m"
              />
              <span class="hint">{{ $t('hints.ssl_session_timeout') }}</span>
            </td>
          </tr>
          <tr>
            <th>{{ $t('labels.ssl_stapling') }}</th>
            <td>
              <input 
                type="radio" 
                name="ssl_stapling" 
                value="1" 
                v-model="localConfig.ssl_stapling"
                class="input"
              />
              <label>{{ $t('labels.yes') }}</label>
              <input 
                type="radio" 
                name="ssl_stapling" 
                value="0" 
                v-model="localConfig.ssl_stapling"
                class="input"
                style="margin-left: 10px;"
              />
              <label>{{ $t('labels.no') }}</label>
              <span class="hint">{{ $t('hints.ssl_stapling') }}</span>
            </td>
          </tr>
          <tr>
            <th>{{ $t('labels.hsts') }}</th>
            <td>
              <input 
                type="radio" 
                name="hsts_enable" 
                value="1" 
                v-model="localConfig.hsts_enable"
                class="input"
              />
              <label>{{ $t('labels.yes') }}</label>
              <input 
                type="radio" 
                name="hsts_enable" 
                value="0" 
                v-model="localConfig.hsts_enable"
                class="input"
                style="margin-left: 10px;"
              />
              <label>{{ $t('labels.no') }}</label>
              <span class="hint">{{ $t('hints.hsts') }}</span>
            </td>
          </tr>
          <tr v-if="localConfig.hsts_enable === '1'">
            <th>{{ $t('labels.hsts_max_age') }}</th>
            <td>
              <input 
                type="text" 
                v-model="localConfig.hsts_max_age" 
                class="input_15_table" 
                placeholder="31536000"
              />
              <span class="hint">{{ $t('hints.hsts_max_age') }}</span>
            </td>
          </tr>
          <tr>
            <th>{{ $t('labels.redirect_http_to_https') }}</th>
            <td>
              <input 
                type="radio" 
                name="redirect_http" 
                value="1" 
                v-model="localConfig.redirect_http"
                class="input"
              />
              <label>{{ $t('labels.yes') }}</label>
              <input 
                type="radio" 
                name="redirect_http" 
                value="0" 
                v-model="localConfig.redirect_http"
                class="input"
                style="margin-left: 10px;"
              />
              <label>{{ $t('labels.no') }}</label>
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  </div>
</template>

<script lang="ts">
  import { defineComponent, ref, watch, inject, computed, type Ref } from 'vue';

  export default defineComponent({
    name: 'SslConfig',
    setup() {
      const config = inject<Ref<{ ssl?: any }>>('nginxConfig');
      
      const sslProtocols = ['TLSv1.2', 'TLSv1.3'];
      
      const localConfig = ref({
        ssl_enable: '0',
        ssl_protocols: 'TLSv1.2 TLSv1.3',
        ssl_ciphers_preset: 'intermediate',
        ssl_ciphers_custom: '',
        ssl_certificate: '/opt/etc/nginx/ssl/server.crt',
        ssl_private_key: '/opt/etc/nginx/ssl/server.key',
        ssl_dhparam: '/opt/etc/nginx/ssl/dhparam.pem',
        ssl_session_cache: 'shared:SSL:10m',
        ssl_session_timeout: '10m',
        ssl_stapling: '1',
        hsts_enable: '1',
        hsts_max_age: '31536000',
        redirect_http: '1'
      });

      const selectedProtocols = computed({
        get: () => localConfig.value.ssl_protocols.split(' ').filter(p => p),
        set: (value: string[]) => {
          localConfig.value.ssl_protocols = value.join(' ');
        }
      });

      // Watch for changes in config and update local config
      watch(
        () => config?.value,
        (newConfig) => {
          if (newConfig?.ssl) {
            Object.assign(localConfig.value, newConfig.ssl);
          }
        },
        { immediate: true, deep: true }
      );

      // Watch for changes in local config and update main config
      watch(
        localConfig,
        (newLocalConfig) => {
          if (config?.value) {
            config.value.ssl = { ...newLocalConfig };
          }
        },
        { deep: true }
      );

      return {
        localConfig,
        sslProtocols,
        selectedProtocols
      };
    }
  });
</script>

<style scoped>
  .ssl-config {
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

  .checkbox-group {
    display: flex;
    flex-wrap: wrap;
    gap: 15px;
  }

  .checkbox-group label {
    display: flex;
    align-items: center;
    margin: 0;
  }

  .checkbox-group input[type="checkbox"] {
    margin-right: 5px;
  }
</style>