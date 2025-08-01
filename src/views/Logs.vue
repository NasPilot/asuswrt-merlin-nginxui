<template>
  <div class="logs">
    <div class="logs-header">
      <h1>Logs</h1>
      <p class="subtitle">View system and application logs</p>
    </div>
    
    <div class="logs-content">
      <div class="card">
        <div class="card-header">
          <h3>Live Logs</h3>
          <div class="card-actions">
            <button class="btn btn-secondary">Clear</button>
            <button class="btn btn-primary">Refresh</button>
          </div>
        </div>
        <div class="card-content">
          <div class="log-viewer">
            <div class="log-line">
              <span class="timestamp">2024-01-31 13:45:23</span>
              <span class="level info">INFO</span>
              <span class="message">Nginx configuration reloaded successfully</span>
            </div>
            <div class="log-line">
              <span class="timestamp">2024-01-31 13:44:15</span>
              <span class="level info">INFO</span>
              <span class="message">NginxUI service started</span>
            </div>
            <div class="log-line">
              <span class="timestamp">2024-01-31 13:43:02</span>
              <span class="level warn">WARN</span>
              <span class="message">Configuration backup created</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
// Logs component logic will be added here
</script>

<style scoped>
.logs {
  padding: 20px;
}

.logs-header {
  margin-bottom: 30px;
}

.logs-header h1 {
  margin: 0 0 5px 0;
  color: #333;
}

.subtitle {
  color: #666;
  margin: 0;
}

.card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  overflow: hidden;
}

.card-header {
  background: #f8f9fa;
  padding: 15px 20px;
  border-bottom: 1px solid #e9ecef;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-header h3 {
  margin: 0;
  color: #333;
  font-size: 16px;
}

.card-actions {
  display: flex;
  gap: 10px;
}

.card-content {
  padding: 0;
}

.log-viewer {
  height: 400px;
  overflow-y: auto;
  padding: 20px;
  background: #1e1e1e;
  color: #d4d4d4;
  font-family: 'Monaco', 'Menlo', monospace;
  font-size: 13px;
  line-height: 1.4;
}

.log-line {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 5px;
  padding: 2px 0;
}

.timestamp {
  color: #569cd6;
  min-width: 150px;
}

.level {
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 600;
  min-width: 40px;
  text-align: center;
  text-transform: uppercase;
}

.level.info {
  background: #0e639c;
  color: #ffffff;
}

.level.warn {
  background: #f59e0b;
  color: #ffffff;
}

.level.error {
  background: #dc2626;
  color: #ffffff;
}

.message {
  flex: 1;
  color: #d4d4d4;
}

.btn {
  padding: 8px 16px;
  border: none;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 14px;
}

.btn-primary {
  background: #2196F3;
  color: white;
}

.btn-primary:hover {
  background: #1976D2;
}

.btn-secondary {
  background: #f5f5f5;
  color: #333;
}

.btn-secondary:hover {
  background: #e0e0e0;
}
</style>