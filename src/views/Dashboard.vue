<template>
  <div class="dashboard">
    <div class="dashboard-header">
      <h1>{{ $t('nav.dashboard') }}</h1>
      <p class="subtitle">{{ $t('app.subtitle') }}</p>
    </div>
    
    <div class="dashboard-grid">
      <!-- Service Status Card -->
      <div class="card">
        <div class="card-header">
          <h3>Service Status</h3>
        </div>
        <div class="card-content">
          <div class="status-item">
            <span class="status-label">NginxUI:</span>
            <span class="status-badge running">{{ $t('status.running') }}</span>
          </div>
          <div class="status-item">
            <span class="status-label">Nginx:</span>
            <span class="status-badge running">{{ $t('status.running') }}</span>
          </div>
        </div>
      </div>
      
      <!-- Quick Actions Card -->
      <div class="card">
        <div class="card-header">
          <h3>Quick Actions</h3>
        </div>
        <div class="card-content">
          <div class="action-buttons">
            <button class="btn btn-primary">{{ $t('actions.restart') }} Nginx</button>
            <button class="btn btn-secondary">View Logs</button>
            <button class="btn btn-secondary">Edit Config</button>
          </div>
        </div>
      </div>
      
      <!-- System Info Card -->
      <div class="card">
        <div class="card-header">
          <h3>System Information</h3>
        </div>
        <div class="card-content">
          <div class="info-item">
            <span class="info-label">Version:</span>
            <span class="info-value">1.0.0</span>
          </div>
          <div class="info-item">
            <span class="info-label">Uptime:</span>
            <span class="info-value">2h 15m</span>
          </div>
          <div class="info-item">
            <span class="info-label">Memory:</span>
            <span class="info-value">45.2 MB</span>
          </div>
        </div>
      </div>
      
      <!-- Recent Logs Card -->
      <div class="card full-width">
        <div class="card-header">
          <h3>Recent Logs</h3>
        </div>
        <div class="card-content">
          <div class="log-entries">
            <div class="log-entry">
              <span class="log-time">13:45:23</span>
              <span class="log-level info">INFO</span>
              <span class="log-message">Nginx configuration reloaded successfully</span>
            </div>
            <div class="log-entry">
              <span class="log-time">13:44:15</span>
              <span class="log-level info">INFO</span>
              <span class="log-message">NginxUI service started</span>
            </div>
            <div class="log-entry">
              <span class="log-time">13:43:02</span>
              <span class="log-level warn">WARN</span>
              <span class="log-message">Configuration backup created</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
// Dashboard component logic will be added here
</script>

<style scoped>
.dashboard {
  padding: 20px;
}

.dashboard-header {
  margin-bottom: 30px;
}

.dashboard-header h1 {
  margin: 0 0 5px 0;
  color: #333;
}

.subtitle {
  color: #666;
  margin: 0;
}

.dashboard-grid {
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

.status-item, .info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.status-item:last-child, .info-item:last-child {
  margin-bottom: 0;
}

.status-badge {
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
}

.status-badge.running {
  background: #d4edda;
  color: #155724;
}

.action-buttons {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.btn {
  padding: 10px 16px;
  border: none;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
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

.log-entries {
  max-height: 200px;
  overflow-y: auto;
}

.log-entry {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
  font-family: monospace;
  font-size: 13px;
}

.log-entry:last-child {
  border-bottom: none;
}

.log-time {
  color: #666;
  min-width: 70px;
}

.log-level {
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: 600;
  min-width: 40px;
  text-align: center;
}

.log-level.info {
  background: #d1ecf1;
  color: #0c5460;
}

.log-level.warn {
  background: #fff3cd;
  color: #856404;
}

.log-message {
  flex: 1;
  color: #333;
}

@media (max-width: 768px) {
  .dashboard {
    padding: 10px;
  }
  
  .dashboard-grid {
    grid-template-columns: 1fr;
  }
  
  .action-buttons {
    flex-direction: column;
  }
}
</style>