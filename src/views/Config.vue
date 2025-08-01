<template>
  <div class="config">
    <div class="config-header">
      <h1>Configuration</h1>
      <p class="subtitle">Manage Nginx configuration files</p>
    </div>
    
    <div class="config-content">
      <div class="card">
        <div class="card-header">
          <h3>Nginx Configuration</h3>
          <div class="card-actions">
            <button class="btn btn-secondary">Backup</button>
            <button class="btn btn-primary">Save</button>
          </div>
        </div>
        <div class="card-content">
          <textarea 
            class="config-editor" 
            placeholder="Nginx configuration will be loaded here..."
            rows="20"
          ></textarea>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
// Config component logic will be added here
</script>

<style scoped>
.config {
  padding: 20px;
}

.config-header {
  margin-bottom: 30px;
}

.config-header h1 {
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

.config-editor {
  width: 100%;
  border: none;
  padding: 20px;
  font-family: 'Monaco', 'Menlo', monospace;
  font-size: 14px;
  line-height: 1.5;
  resize: vertical;
  outline: none;
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