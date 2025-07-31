<template>
  <div class="logs-viewer">
    <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
      <thead>
        <tr>
          <td colspan="2">{{ $t('labels.logs_viewer') }}</td>
        </tr>
      </thead>
      <tbody>
        <tr>
          <th>{{ $t('labels.log_type') }}</th>
          <td>
            <select v-model="selectedLogType" class="input_option" @change="loadLogs">
              <option value="access">{{ $t('labels.access_log') }}</option>
              <option value="error">{{ $t('labels.error_log') }}</option>
              <option value="nginx">{{ $t('labels.nginx_log') }}</option>
            </select>
            <input 
              type="button" 
              class="button_gen" 
              :value="$t('labels.refresh')" 
              @click="loadLogs" 
              :disabled="isLoading"
            />
            <input 
              type="button" 
              class="button_gen" 
              :value="$t('labels.clear_log')" 
              @click="clearLog" 
              :disabled="isLoading"
            />
            <input 
              type="button" 
              class="button_gen" 
              :value="$t('labels.download')" 
              @click="downloadLog" 
              :disabled="isLoading || !logContent"
            />
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.log_lines') }}</th>
          <td>
            <select v-model="logLines" class="input_option" @change="loadLogs">
              <option value="50">50</option>
              <option value="100">100</option>
              <option value="200">200</option>
              <option value="500">500</option>
              <option value="1000">1000</option>
            </select>
            <span class="hint">{{ $t('hints.log_lines') }}</span>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.auto_refresh') }}</th>
          <td>
            <input 
              type="radio" 
              name="auto_refresh" 
              value="1" 
              v-model="autoRefresh"
              class="input"
              @change="toggleAutoRefresh"
            />
            <label>{{ $t('labels.yes') }}</label>
            <input 
              type="radio" 
              name="auto_refresh" 
              value="0" 
              v-model="autoRefresh"
              class="input"
              style="margin-left: 10px;"
              @change="toggleAutoRefresh"
            />
            <label>{{ $t('labels.no') }}</label>
            <select v-model="refreshInterval" class="input_option" style="margin-left: 10px;" :disabled="autoRefresh === '0'">
              <option value="5">5s</option>
              <option value="10">10s</option>
              <option value="30">30s</option>
              <option value="60">60s</option>
            </select>
          </td>
        </tr>
        <tr>
          <th>{{ $t('labels.search_filter') }}</th>
          <td>
            <input 
              type="text" 
              v-model="searchFilter" 
              class="input_32_table" 
              :placeholder="$t('hints.search_filter')"
              @input="filterLogs"
            />
            <input 
              type="button" 
              class="button_gen" 
              :value="$t('labels.clear_filter')" 
              @click="clearFilter"
            />
          </td>
        </tr>
        <tr>
          <td colspan="2">
            <div class="log-container">
              <div v-if="isLoading" class="log-loading">
                {{ $t('labels.loading') }}...
              </div>
              <div v-else-if="!logContent" class="log-empty">
                {{ $t('labels.no_logs') }}
              </div>
              <div v-else class="log-content">
                <div class="log-header">
                  <span class="log-info">
                    {{ $t('labels.showing') }} {{ filteredLines.length }} {{ $t('labels.of') }} {{ totalLines }} {{ $t('labels.lines') }}
                    <span v-if="searchFilter"> ({{ $t('labels.filtered') }})</span>
                  </span>
                  <span class="log-timestamp">
                    {{ $t('labels.last_updated') }}: {{ lastUpdated }}
                  </span>
                </div>
                <pre class="log-text" ref="logTextRef">{{ displayContent }}</pre>
              </div>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script lang="ts">
  import { defineComponent, ref, computed, watch, onMounted, onUnmounted, nextTick } from 'vue';
  import { useI18n } from 'vue-i18n';
  import engine, { SubmitActions } from '@modules/Engine';

  export default defineComponent({
    name: 'LogsViewer',
    setup() {
      const { t } = useI18n();
      
      const selectedLogType = ref('access');
      const logLines = ref('100');
      const autoRefresh = ref('0');
      const refreshInterval = ref('10');
      const searchFilter = ref('');
      const logContent = ref('');
      const isLoading = ref(false);
      const lastUpdated = ref('');
      const totalLines = ref(0);
      const logTextRef = ref<HTMLElement>();
      
      let refreshTimer: NodeJS.Timeout | null = null;

      const allLines = computed(() => {
        if (!logContent.value) return [];
        return logContent.value.split('\n').filter(line => line.trim());
      });

      const filteredLines = computed(() => {
        const lines = allLines.value;
        
        if (!searchFilter.value) return lines;
        
        const filter = searchFilter.value.toLowerCase();
        return lines.filter(line => line.toLowerCase().includes(filter));
      });

      // Watch for changes to update totalLines
      watch(allLines, (lines) => {
        totalLines.value = lines.length;
      }, { immediate: true });

      const displayContent = computed(() => {
        return filteredLines.value.join('\n');
      });

      const loadLogs = async () => {
        try {
          isLoading.value = true;
          const response = await engine.submit(SubmitActions.getLogs, {
            log_type: selectedLogType.value,
            lines: parseInt(logLines.value)
          }, 5);
          
          if (response?.nginxui_logs) {
            logContent.value = response.nginxui_logs.content || '';
            lastUpdated.value = new Date().toLocaleString();
            
            // Auto scroll to bottom
            await nextTick();
            if (logTextRef.value) {
              logTextRef.value.scrollTop = logTextRef.value.scrollHeight;
            }
          }
        } catch (error) {
          console.error('Error loading logs:', error);
          logContent.value = `Error loading logs: ${error}`;
        } finally {
          isLoading.value = false;
        }
      };

      const clearLog = async () => {
        if (!confirm(t('messages.confirm_clear_log'))) return;
        
        try {
          isLoading.value = true;
          await engine.submit(SubmitActions.clearLog, {
            log_type: selectedLogType.value
          }, 3);
          
          logContent.value = '';
          lastUpdated.value = new Date().toLocaleString();
        } catch (error) {
          console.error('Error clearing log:', error);
        } finally {
          isLoading.value = false;
        }
      };

      const downloadLog = () => {
        if (!logContent.value) return;
        
        const blob = new Blob([logContent.value], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `nginx_${selectedLogType.value}_${new Date().toISOString().slice(0, 10)}.log`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      };

      const filterLogs = () => {
        // Filtering is handled by computed property
      };

      const clearFilter = () => {
        searchFilter.value = '';
      };

      const toggleAutoRefresh = () => {
        if (refreshTimer) {
          clearInterval(refreshTimer);
          refreshTimer = null;
        }
        
        if (autoRefresh.value === '1') {
          refreshTimer = setInterval(() => {
            loadLogs();
          }, parseInt(refreshInterval.value) * 1000);
        }
      };

      onMounted(() => {
        loadLogs();
      });

      onUnmounted(() => {
        if (refreshTimer) {
          clearInterval(refreshTimer);
        }
      });

      return {
        selectedLogType,
        logLines,
        autoRefresh,
        refreshInterval,
        searchFilter,
        logContent,
        isLoading,
        lastUpdated,
        totalLines,
        filteredLines,
        displayContent,
        logTextRef,
        loadLogs,
        clearLog,
        downloadLog,
        filterLogs,
        clearFilter,
        toggleAutoRefresh
      };
    }
  });
</script>

<style scoped>
  .logs-viewer {
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

  .log-container {
    border: 1px solid #5a6a6f;
    border-radius: 3px;
    background-color: #1a1a1a;
    min-height: 400px;
    max-height: 600px;
    overflow: hidden;
  }

  .log-loading,
  .log-empty {
    display: flex;
    align-items: center;
    justify-content: center;
    height: 400px;
    color: #999;
    font-style: italic;
  }

  .log-content {
    height: 100%;
    display: flex;
    flex-direction: column;
  }

  .log-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 8px 12px;
    background-color: #2a2a2a;
    border-bottom: 1px solid #5a6a6f;
    font-size: 11px;
    color: #ccc;
  }

  .log-text {
    flex: 1;
    margin: 0;
    padding: 12px;
    background-color: #1a1a1a;
    color: #e0e0e0;
    font-family: 'Courier New', Consolas, monospace;
    font-size: 11px;
    line-height: 1.4;
    overflow-y: auto;
    white-space: pre-wrap;
    word-wrap: break-word;
  }

  .log-text::-webkit-scrollbar {
    width: 8px;
  }

  .log-text::-webkit-scrollbar-track {
    background: #2a2a2a;
  }

  .log-text::-webkit-scrollbar-thumb {
    background: #5a6a6f;
    border-radius: 4px;
  }

  .log-text::-webkit-scrollbar-thumb:hover {
    background: #6a7a7f;
  }
</style>