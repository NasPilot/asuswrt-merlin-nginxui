<template>
  <div class="status">
    <div class="status-header">
      <h1>Status</h1>
      <p class="subtitle">Monitor system status and performance</p>
    </div>
    
    <div class="status-content">
      <div class="status-grid">
        <!-- Service Status -->
        <div class="card">
          <div class="card-header">
            <h3>Service Status</h3>
          </div>
          <div class="card-content">
            <div class="service-item">
              <div class="service-info">
                <span class="service-name">NginxUI</span>
                <span class="service-description">Web Management Interface</span>
              </div>
              <span class="status-badge running">Running</span>
            </div>
            <div class="service-item">
              <div class="service-info">
                <span class="service-name">Nginx</span>
                <span class="service-description">Web Server</span>
              </div>
              <span class="status-badge running">Running</span>
            </div>
          </div>
        </div>
        
        <!-- System Resources -->
        <div class="card">
          <div class="card-header">
            <h3>System Resources</h3>
          </div>
          <div class="card-content">
            <div class="resource-item">
              <div class="resource-label">CPU Usage</div>
              <div class="resource-bar">
                <div class="resource-fill" style="width: 25%"></div>
              </div>
              <div class="resource-value">25%</div>
            </div>
            <div class="resource-item">
              <div class="resource-label">Memory</div>
              <div class="resource-bar">
                <div class="resource-fill" style="width: 45%"></div>
              </div>
              <div class="resource-value">45.2 MB</div>
            </div>
            <div class="resource-item">
              <div class="resource-label">Disk Space</div>
              <div class="resource-bar">
                <div class="resource-fill" style="width: 60%"></div>
              </div>
              <div class="resource-value">60%</div>
            </div>
          </div>
        </div>
        
        <!-- Network Stats -->
        <div class="card full-width">
          <div class="card-header">
            <h3>Network Statistics</h3>
          </div>
          <div class="card-content">
            <div class="stats-grid">
              <div class="stat-item">
                <div class="stat-value">1,234</div>
                <div class="stat-label">Total Requests</div>
              </div>
              <div class="stat-item">
                <div class="stat-value">45</div>
                <div class="stat-label">Active Connections</div>
              </div>
              <div class="stat-item">
                <div class="stat-value">2.5 MB/s</div>
                <div class="stat-label">Bandwidth</div>
              </div>
              <div class="stat-item">
                <div class="stat-value">99.9%</div>
                <div class="stat-label">Uptime</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
// Status component logic will be added here
</script>

<style scoped>
.status {
  padding: 20px;
}

.status-header {
  margin-bottom: 30px;
}

.status-header h1 {
  margin: 0 0 5px 0;
  color: #333;
}

.subtitle {
  color: #666;
  margin: 0;
}

.status-grid {
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

.service-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.service-item:last-child {
  margin-bottom: 0;
}

.service-info {
  display: flex;
  flex-direction: column;
}

.service-name {
  font-weight: 600;
  color: #333;
}

.service-description {
  font-size: 12px;
  color: #666;
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

.resource-item {
  display: flex;
  align-items: center;
  gap: 15px;
  margin-bottom: 15px;
}

.resource-item:last-child {
  margin-bottom: 0;
}

.resource-label {
  min-width: 80px;
  font-size: 14px;
  color: #333;
}

.resource-bar {
  flex: 1;
  height: 8px;
  background: #e9ecef;
  border-radius: 4px;
  overflow: hidden;
}

.resource-fill {
  height: 100%;
  background: linear-gradient(90deg, #2196F3, #21CBF3);
  transition: width 0.3s ease;
}

.resource-value {
  min-width: 60px;
  text-align: right;
  font-size: 14px;
  font-weight: 600;
  color: #333;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 20px;
}

.stat-item {
  text-align: center;
}

.stat-value {
  font-size: 24px;
  font-weight: 700;
  color: #2196F3;
  margin-bottom: 5px;
}

.stat-label {
  font-size: 12px;
  color: #666;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

@media (max-width: 768px) {
  .status {
    padding: 10px;
  }
  
  .status-grid {
    grid-template-columns: 1fr;
  }
  
  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>