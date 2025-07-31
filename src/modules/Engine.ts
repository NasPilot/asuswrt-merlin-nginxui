import axios from 'axios';
import { ref } from 'vue';

export enum SubmitActions {
  applyConfig = 'apply_config',
  checkStatus = 'check_status',
  startService = 'start_service',
  stopService = 'stop_service',
  restartService = 'restart_service',
  reloadService = 'reload_service',
  testConfig = 'test_config',
  getLogs = 'get_logs',
  clearLog = 'clear_log',
  generateConfig = 'generate_config',
  backupConfig = 'backup_config',
  restoreConfig = 'restore_config'
}

interface EngineResponse {
  success: boolean;
  message?: string;
  data?: any;
  nginxui_status?: {
    running: boolean;
    version: string;
    pid?: number;
  };
  nginxui_config_test?: {
    valid: boolean;
    message: string;
  };
  nginxui_logs?: {
    content: string;
    lines: number;
  };
}

class Engine {
  private baseUrl = '/start_apply.htm';
  private isSubmitting = ref(false);

  async submit(
    action: SubmitActions,
    config: any,
    timeout: number = 10
  ): Promise<EngineResponse | null> {
    if (this.isSubmitting.value) {
      console.warn('Engine is already submitting, please wait...');
      return null;
    }

    try {
      this.isSubmitting.value = true;

      const formData = new FormData();
      formData.append('current_page', 'nginxui.asp');
      formData.append('next_page', 'nginxui.asp');
      formData.append('group_id', '');
      formData.append('modified', '0');
      formData.append('action_mode', 'apply');
      formData.append('action_wait', timeout.toString());
      formData.append('first_time', '');
      formData.append('action_script', 'nginxui');
      formData.append('amng_custom', action);
      
      // Add config data
      if (config) {
        formData.append('nginxui_config', JSON.stringify(config));
      }

      const response = await axios.post(this.baseUrl, formData, {
        timeout: (timeout + 5) * 1000,
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });

      // Parse response
      if (response.data) {
        try {
          // Try to parse as JSON first
          const jsonResponse = JSON.parse(response.data);
          return jsonResponse;
        } catch {
          // If not JSON, look for specific patterns in HTML response
          return this.parseHtmlResponse(response.data, action);
        }
      }

      return { success: true };
    } catch (error) {
      console.error('Engine submit error:', error);
      return {
        success: false,
        message: error instanceof Error ? error.message : 'Unknown error'
      };
    } finally {
      this.isSubmitting.value = false;
    }
  }

  private parseHtmlResponse(html: string, action: SubmitActions): EngineResponse {
    const response: EngineResponse = { success: false };

    try {
      // Look for JSON data in script tags or hidden elements
      const jsonMatch = html.match(/nginxui_response\s*=\s*({.*?});/s);
      if (jsonMatch) {
        const data = JSON.parse(jsonMatch[1]);
        return { success: true, ...data };
      }

      // Look for specific status indicators
      if (action === SubmitActions.checkStatus) {
        const runningMatch = html.match(/nginx_status\s*=\s*["']([^"']*)["']/);
        const versionMatch = html.match(/nginx_version\s*=\s*["']([^"']*)["']/);
        
        if (runningMatch || versionMatch) {
          response.success = true;
          response.nginxui_status = {
            running: runningMatch?.[1] === 'running',
            version: versionMatch?.[1] || 'Unknown'
          };
        }
      }

      // Look for config test results
      if (action === SubmitActions.testConfig) {
        const testMatch = html.match(/config_test\s*=\s*["']([^"']*)["']/);
        const messageMatch = html.match(/config_message\s*=\s*["']([^"']*)["']/);
        
        if (testMatch) {
          response.success = true;
          response.nginxui_config_test = {
            valid: testMatch[1] === 'valid',
            message: messageMatch?.[1] || ''
          };
        }
      }

      // Look for log content
      if (action === SubmitActions.getLogs) {
        const logMatch = html.match(/<pre[^>]*id=["']log_content["'][^>]*>([\s\S]*?)<\/pre>/);
        if (logMatch) {
          response.success = true;
          response.nginxui_logs = {
            content: logMatch[1].trim(),
            lines: logMatch[1].split('\n').length
          };
        }
      }

      // Check for success/error messages
      const successMatch = html.match(/alert\(["']([^"']*success[^"']*)["']\)/);
      const errorMatch = html.match(/alert\(["']([^"']*error[^"']*)["']\)/);
      
      if (successMatch) {
        response.success = true;
        response.message = successMatch[1];
      } else if (errorMatch) {
        response.success = false;
        response.message = errorMatch[1];
      }

      // Default success if no errors found
      if (!response.success && !errorMatch) {
        response.success = true;
      }

    } catch (error) {
      console.error('Error parsing HTML response:', error);
      response.success = false;
      response.message = 'Failed to parse response';
    }

    return response;
  }

  get submitting() {
    return this.isSubmitting.value;
  }

  // Utility method to wait for a condition
  async waitFor(condition: () => boolean, timeout: number = 10000): Promise<boolean> {
    const start = Date.now();
    while (Date.now() - start < timeout) {
      if (condition()) {
        return true;
      }
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    return false;
  }

  // Method to check if the backend is responsive
  async ping(): Promise<boolean> {
    try {
      const response = await this.submit(SubmitActions.checkStatus, null, 3);
      return response?.success || false;
    } catch {
      return false;
    }
  }
}

const engine = new Engine();
export default engine;

// Export types for use in components
export type { EngineResponse };