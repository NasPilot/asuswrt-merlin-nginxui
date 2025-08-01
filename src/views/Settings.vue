<template>
  <div class="settings">
    <div class="settings-header">
      <h1>Settings</h1>
      <p class="subtitle">Configure NginxUI preferences and system settings</p>
    </div>
    
    <div class="settings-content">
      <div class="settings-grid">
        <!-- General Settings -->
        <div class="card">
          <div class="card-header">
            <h3>General Settings</h3>
          </div>
          <div class="card-content">
            <div class="setting-item">
              <label class="setting-label">Language</label>
              <select class="setting-input">
                <option value="en">English</option>
                <option value="zh">中文</option>
              </select>
            </div>
            <div class="setting-item">
              <label class="setting-label">Theme</label>
              <select class="setting-input">
                <option value="light">Light</option>
                <option value="dark">Dark</option>
                <option value="auto">Auto</option>
              </select>
            </div>
            <div class="setting-item">
              <label class="setting-label">Auto-refresh Interval</label>
              <select class="setting-input">
                <option value="5">5 seconds</option>
                <option value="10">10 seconds</option>
                <option value="30">30 seconds</option>
                <option value="0">Disabled</option>
              </select>
            </div>
          </div>
        </div>
        
        <!-- Security Settings -->
        <div class="card">
          <div class="card-header">
            <h3>Security Settings</h3>
          </div>
          <div class="card-content">
            <div class="setting-item">
              <label class="setting-label">Enable HTTPS</label>
              <label class="switch">
                <input type="checkbox" checked>
                <span class="slider"></span>
              </label>
            </div>
            <div class="setting-item">
              <label class="setting-label">Auto-backup Configuration</label>
              <label class="switch">
                <input type="checkbox" checked>
                <span class="slider"></span>
              </label>
            </div>
            <div class="setting-item">
              <label class="setting-label">Session Timeout (minutes)</label>
              <input type="number" class="setting-input" value="30" min="5" max="1440">
            </div>
          </div>
        </div>
        
        <!-- System Settings -->
        <div class="card full-width">
          <div class="card-header">
            <h3>System Settings</h3>
          </div>
          <div class="card-content">
            <div class="settings-row">
              <div class="setting-item">
                <label class="setting-label">Log Level</label>
                <select class="setting-input">
                  <option value="error">Error</option>
                  <option value="warn">Warning</option>
                  <option value="info" selected>Info</option>
                  <option value="debug">Debug</option>
                </select>
              </div>
              <div class="setting-item">
                <label class="setting-label">Max Log Size (MB)</label>
                <input type="number" class="setting-input" value="10" min="1" max="100">
              </div>
            </div>
            <div class="settings-row">
              <div class="setting-item">
                <label class="setting-label">Enable Log Rotation</label>
                <label class="switch">
                  <input type="checkbox" checked>
                  <span class="slider"></span>
                </label>
              </div>
              <div class="setting-item">
                <label class="setting-label">Health Check Interval (seconds)</label>
                <input type="number" class="setting-input" value="60" min="10" max="3600">
              </div>
            </div>
          </div>
        </div>
        
        <!-- Actions -->
        <div class="card full-width">
          <div class="card-header">
            <h3>Actions</h3>
          </div>
          <div class="card-content">
            <div class="action-buttons">
              <button class="btn btn-primary">Save Settings</button>
              <button class="btn btn-secondary">Reset to Defaults</button>
              <button class="btn btn-warning">Export Configuration</button>
              <button class="btn btn-info">Import Configuration</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
// Settings component logic will be added here
</script>

<style scoped>
.settings {
  padding: 20px;
}

.settings-header {
  margin-bottom: 30px;
}

.settings-header h1 {
  margin: 0 0 5px 0;
  color: #333;
}

.subtitle {
  color: #666;
  margin: 0;
}

.settings-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  overflow: hidden;
}

.card.full-width {
  grid-column: 1 / -1;
}

.card-header {
  background: #f8f9fa;
  padding: 15px 20px;
  border-bottom: 1px solid #e9ecef;
}

.card-header h3 {
  margin: 0;
  color: #333;
  font-size: 16px;
}

.card-content {
  padding: 20px;
}

.settings-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
  margin-bottom: 20px;
}

.settings-row:last-child {
  margin-bottom: 0;
}

.setting-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.setting-item:last-child {
  margin-bottom: 0;
}

.setting-label {
  font-weight: 500;
  color: #333;
  margin-right: 15px;
}

.setting-input {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 14px;
  min-width: 120px;
}

.setting-input:focus {
  outline: none;
  border-color: #2196F3;
  box-shadow: 0 0 0 2px rgba(33, 150, 243, 0.2);
}

/* Switch styles */
.switch {
  position: relative;
  display: inline-block;
  width: 50px;
  height: 24px;
}

.switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #ccc;
  transition: .4s;
  border-radius: 24px;
}

.slider:before {
  position: absolute;
  content: "";
  height: 18px;
  width: 18px;
  left: 3px;
  bottom: 3px;
  background-color: white;
  transition: .4s;
  border-radius: 50%;
}

input:checked + .slider {
  background-color: #2196F3;
}

input:checked + .slider:before {
  transform: translateX(26px);
}

.action-buttons {
  display: flex;
  gap: 15px;
  flex-wrap: wrap;
}

.btn {
  padding: 10px 20px;
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
  background: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background: #5a6268;
}

.btn-warning {
  background: #ffc107;
  color: #212529;
}

.btn-warning:hover {
  background: #e0a800;
}

.btn-info {
  background: #17a2b8;
  color: white;
}

.btn-info:hover {
  background: #138496;
}

@media (max-width: 768px) {
  .settings {
    padding: 10px;
  }
  
  .settings-grid {
    grid-template-columns: 1fr;
  }
  
  .settings-row {
    grid-template-columns: 1fr;
  }
  
  .action-buttons {
    flex-direction: column;
  }
  
  .setting-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }
  
  .setting-input {
    width: 100%;
  }
}
</style>