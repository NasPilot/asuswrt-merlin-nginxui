#!/bin/sh
# NginxUI Web Application Management Module
# Handles the web interface server and API endpoints

# Import required modules
. "$NGINXUI_SCRIPT_DIR/_globals.sh"
. "$NGINXUI_SCRIPT_DIR/_helper.sh"

# Web application management functions
start_webapp() {
    log_info "Starting NginxUI web application..."
    
    # Check if webapp is already running
    if is_webapp_running; then
        log_warn "NginxUI web application is already running (PID: $(cat "$NGINXUI_WEB_PID_FILE" 2>/dev/null))"
        return 0
    fi
    
    # Ensure web directory exists
    mkdir -p "$NGINXUI_WEB_DIR"
    
    # Generate lighttpd configuration
    generate_lighttpd_config || {
        log_error "Failed to generate lighttpd configuration"
        return 1
    }
    
    # Start lighttpd web server
    lighttpd -f "$NGINXUI_WEB_DIR/lighttpd.conf" -D &
    local webapp_pid=$!
    
    # Save PID
    echo "$webapp_pid" > "$NGINXUI_WEB_PID_FILE"
    
    # Wait for web server to start
    local timeout=10
    local count=0
    while [ $count -lt $timeout ]; do
        if is_webapp_running; then
            log_info "NginxUI web application started successfully (PID: $webapp_pid)"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    
    log_error "NginxUI web application failed to start within $timeout seconds"
    return 1
}

stop_webapp() {
    log_info "Stopping NginxUI web application..."
    
    if ! is_webapp_running; then
        log_warn "NginxUI web application is not running"
        return 0
    fi
    
    local pid
    pid=$(cat "$NGINXUI_WEB_PID_FILE" 2>/dev/null)
    
    if [ -n "$pid" ]; then
        log_info "Stopping web application (PID: $pid)..."
        kill "$pid" 2>/dev/null || {
            log_warn "Failed to send TERM signal, trying KILL signal..."
            kill -KILL "$pid" 2>/dev/null
        }
        
        # Wait for process to stop
        local timeout=10
        local count=0
        while [ $count -lt $timeout ]; do
            if ! is_webapp_running; then
                log_info "NginxUI web application stopped successfully"
                rm -f "$NGINXUI_WEB_PID_FILE"
                return 0
            fi
            sleep 1
            count=$((count + 1))
        done
        
        log_error "NginxUI web application failed to stop within $timeout seconds"
        return 1
    else
        log_error "Could not read PID file: $NGINXUI_WEB_PID_FILE"
        return 1
    fi
}

restart_webapp() {
    log_info "Restarting NginxUI web application..."
    
    stop_webapp || {
        log_error "Failed to stop web application"
        return 1
    }
    
    # Wait a moment before starting
    sleep 2
    
    start_webapp || {
        log_error "Failed to start web application"
        return 1
    }
    
    log_info "NginxUI web application restarted successfully"
}

is_webapp_running() {
    if [ ! -f "$NGINXUI_WEB_PID_FILE" ]; then
        return 1
    fi
    
    local pid
    pid=$(cat "$NGINXUI_WEB_PID_FILE" 2>/dev/null)
    
    if [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
        return 0
    else
        rm -f "$NGINXUI_WEB_PID_FILE"
        return 1
    fi
}

generate_lighttpd_config() {
    log_info "Generating lighttpd configuration..."
    
    local web_port
    local web_interface
    local document_root
    
    web_port=$(am_settings_get nginxui_web_port "8088")
    web_interface=$(am_settings_get nginxui_web_interface "127.0.0.1")
    document_root="$NGINXUI_WEB_DIR"
    
    # Create lighttpd configuration
    cat > "$NGINXUI_WEB_DIR/lighttpd.conf" << EOF
# NginxUI Lighttpd Configuration
# Generated on: $(date)

server.modules = (
    "mod_access",
    "mod_alias",
    "mod_compress",
    "mod_redirect",
    "mod_cgi",
    "mod_setenv"
)

server.document-root = "$document_root"
server.upload-dirs = ( "/tmp" )
server.errorlog = "$NGINXUI_LOG_DIR/lighttpd_error.log"
server.pid-file = "$NGINXUI_WEB_PID_FILE"

server.bind = "$web_interface"
server.port = $web_port

# MIME types
mimetype.assign = (
    ".html" => "text/html",
    ".htm" => "text/html",
    ".css" => "text/css",
    ".js" => "application/javascript",
    ".json" => "application/json",
    ".png" => "image/png",
    ".jpg" => "image/jpeg",
    ".jpeg" => "image/jpeg",
    ".gif" => "image/gif",
    ".ico" => "image/x-icon",
    ".svg" => "image/svg+xml",
    ".txt" => "text/plain",
    ".log" => "text/plain",
    "" => "application/octet-stream"
)

# Index files
index-file.names = ( "index.html", "index.htm" )

# Compression
compress.cache-dir = "/tmp/lighttpd/compress/"
compress.filetype = ( "application/javascript", "text/css", "text/html", "text/plain" )

# CGI for API endpoints
cgi.assign = ( ".sh" => "/bin/sh" )

# API endpoints
alias.url += ( "/api/" => "$NGINXUI_SCRIPT_DIR/api/" )

# Static assets
alias.url += ( "/assets/" => "$document_root/assets/" )

# Access control
\$HTTP["url"] =~ "^/api/" {
    setenv.add-environment = (
        "NGINXUI_SCRIPT_DIR" => "$NGINXUI_SCRIPT_DIR",
        "NGINXUI_CONFIG_DIR" => "$NGINXUI_CONFIG_DIR",
        "NGINXUI_LOG_DIR" => "$NGINXUI_LOG_DIR",
        "NGINXUI_SHARED_DIR" => "$NGINXUI_SHARED_DIR"
    )
}

# Security headers
setenv.add-response-header = (
    "X-Frame-Options" => "SAMEORIGIN",
    "X-Content-Type-Options" => "nosniff",
    "X-XSS-Protection" => "1; mode=block"
)
EOF
    
    # Create compress cache directory
    mkdir -p "/tmp/lighttpd/compress"
    
    log_info "Lighttpd configuration generated successfully"
}

setup_api_endpoints() {
    log_info "Setting up API endpoints..."
    
    local api_dir="$NGINXUI_SCRIPT_DIR/api"
    
    mkdir -p "$api_dir"
    
    # Create status API endpoint
    cat > "$api_dir/status.sh" << 'EOF'
#!/bin/sh
echo "Content-Type: application/json"
echo ""

. "$NGINXUI_SCRIPT_DIR/_globals.sh"
. "$NGINXUI_SCRIPT_DIR/_helper.sh"
. "$NGINXUI_SCRIPT_DIR/service.sh"

get_service_status
EOF
    
    # Create config API endpoint
    cat > "$api_dir/config.sh" << 'EOF'
#!/bin/sh
echo "Content-Type: application/json"
echo ""

. "$NGINXUI_SCRIPT_DIR/_globals.sh"
. "$NGINXUI_SCRIPT_DIR/_helper.sh"

if [ "$REQUEST_METHOD" = "GET" ]; then
    # Return current configuration
    if [ -f "$NGINX_CONFIG_FILE" ]; then
        cat "$NGINX_CONFIG_FILE" | jq -Rs '{"config": .}'
    else
        echo '{"error": "Configuration file not found"}'
    fi
elif [ "$REQUEST_METHOD" = "POST" ]; then
    # Update configuration (placeholder)
    echo '{"message": "Configuration update not implemented yet"}'
else
    echo '{"error": "Method not allowed"}'
fi
EOF
    
    # Create service control API endpoint
    cat > "$api_dir/service.sh" << 'EOF'
#!/bin/sh
echo "Content-Type: application/json"
echo ""

. "$NGINXUI_SCRIPT_DIR/_globals.sh"
. "$NGINXUI_SCRIPT_DIR/_helper.sh"
. "$NGINXUI_SCRIPT_DIR/service.sh"

# Parse query string for action
action=$(echo "$QUERY_STRING" | sed -n 's/.*action=\([^&]*\).*/\1/p')

case "$action" in
"start")
    if start_service; then
        echo '{"success": true, "message": "Service started successfully"}'
    else
        echo '{"success": false, "message": "Failed to start service"}'
    fi
    ;;
"stop")
    if stop_service; then
        echo '{"success": true, "message": "Service stopped successfully"}'
    else
        echo '{"success": false, "message": "Failed to stop service"}'
    fi
    ;;
"restart")
    if restart_service; then
        echo '{"success": true, "message": "Service restarted successfully"}'
    else
        echo '{"success": false, "message": "Failed to restart service"}'
    fi
    ;;
"reload")
    if reload_service; then
        echo '{"success": true, "message": "Service reloaded successfully"}'
    else
        echo '{"success": false, "message": "Failed to reload service"}'
    fi
    ;;
*)
    echo '{"error": "Invalid action"}'
    ;;
esac
EOF
    
    # Create logs API endpoint
    cat > "$api_dir/logs.sh" << 'EOF'
#!/bin/sh
echo "Content-Type: application/json"
echo ""

. "$NGINXUI_SCRIPT_DIR/_globals.sh"
. "$NGINXUI_SCRIPT_DIR/_helper.sh"

# Parse query parameters
log_type=$(echo "$QUERY_STRING" | sed -n 's/.*type=\([^&]*\).*/\1/p')
lines=$(echo "$QUERY_STRING" | sed -n 's/.*lines=\([^&]*\).*/\1/p')

# Default values
lines=${lines:-100}

case "$log_type" in
"access")
    if [ -f "$NGINX_ACCESS_LOG" ]; then
        tail -n "$lines" "$NGINX_ACCESS_LOG" | jq -Rs '{"logs": .}'
    else
        echo '{"error": "Access log not found"}'
    fi
    ;;
"error")
    if [ -f "$NGINX_ERROR_LOG" ]; then
        tail -n "$lines" "$NGINX_ERROR_LOG" | jq -Rs '{"logs": .}'
    else
        echo '{"error": "Error log not found"}'
    fi
    ;;
"nginxui")
    if [ -f "$NGINXUI_LOG_FILE" ]; then
        tail -n "$lines" "$NGINXUI_LOG_FILE" | jq -Rs '{"logs": .}'
    else
        echo '{"error": "NginxUI log not found"}'
    fi
    ;;
*)
    echo '{"error": "Invalid log type"}'
    ;;
esac
EOF
    
    # Make API scripts executable
    chmod +x "$api_dir"/*.sh
    
    log_info "API endpoints setup completed"
}

setup_web_interface() {
    log_info "Setting up web interface files..."
    
    # Create main HTML file
    cat > "$NGINXUI_WEB_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NginxUI - Nginx Management Interface</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f5f5f5;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            background: #fff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        
        .header h1 {
            color: #2c3e50;
            margin-bottom: 10px;
        }
        
        .status-card {
            background: #fff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 8px;
        }
        
        .status-running {
            background: #27ae60;
        }
        
        .status-stopped {
            background: #e74c3c;
        }
        
        .btn {
            background: #3498db;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            margin-right: 10px;
            margin-bottom: 10px;
        }
        
        .btn:hover {
            background: #2980b9;
        }
        
        .btn-success {
            background: #27ae60;
        }
        
        .btn-success:hover {
            background: #229954;
        }
        
        .btn-danger {
            background: #e74c3c;
        }
        
        .btn-danger:hover {
            background: #c0392b;
        }
        
        .logs-container {
            background: #2c3e50;
            color: #ecf0f1;
            padding: 20px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            font-size: 12px;
            max-height: 400px;
            overflow-y: auto;
            white-space: pre-wrap;
        }
        
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>NginxUI</h1>
            <p>Nginx Management Interface for ASUSWRT-Merlin</p>
        </div>
        
        <div class="status-card">
            <h2>Service Status</h2>
            <div id="status-info">
                <span class="status-indicator status-stopped"></span>
                <span>Loading...</span>
            </div>
            <div style="margin-top: 15px;">
                <button class="btn btn-success" onclick="controlService('start')">Start</button>
                <button class="btn btn-danger" onclick="controlService('stop')">Stop</button>
                <button class="btn" onclick="controlService('restart')">Restart</button>
                <button class="btn" onclick="controlService('reload')">Reload</button>
                <button class="btn" onclick="refreshStatus()">Refresh</button>
            </div>
        </div>
        
        <div class="grid">
            <div class="status-card">
                <h3>Access Logs</h3>
                <div id="access-logs" class="logs-container">Loading...</div>
                <button class="btn" onclick="loadLogs('access')">Refresh</button>
            </div>
            
            <div class="status-card">
                <h3>Error Logs</h3>
                <div id="error-logs" class="logs-container">Loading...</div>
                <button class="btn" onclick="loadLogs('error')">Refresh</button>
            </div>
        </div>
    </div>
    
    <script>
        // Load status on page load
        document.addEventListener('DOMContentLoaded', function() {
            refreshStatus();
            loadLogs('access');
            loadLogs('error');
        });
        
        function refreshStatus() {
            fetch('/api/status.sh')
                .then(response => response.json())
                .then(data => {
                    const statusInfo = document.getElementById('status-info');
                    const indicator = statusInfo.querySelector('.status-indicator');
                    const text = statusInfo.querySelector('span:last-child');
                    
                    if (data.status === 'running') {
                        indicator.className = 'status-indicator status-running';
                        text.textContent = `Running (PID: ${data.pid || 'Unknown'})`;
                    } else {
                        indicator.className = 'status-indicator status-stopped';
                        text.textContent = 'Stopped';
                    }
                })
                .catch(error => {
                    console.error('Error fetching status:', error);
                });
        }
        
        function controlService(action) {
            fetch(`/api/service.sh?action=${action}`, { method: 'POST' })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert(data.message);
                        setTimeout(refreshStatus, 1000);
                    } else {
                        alert('Error: ' + data.message);
                    }
                })
                .catch(error => {
                    console.error('Error controlling service:', error);
                    alert('Error controlling service');
                });
        }
        
        function loadLogs(type) {
            fetch(`/api/logs.sh?type=${type}&lines=50`)
                .then(response => response.json())
                .then(data => {
                    const container = document.getElementById(`${type}-logs`);
                    if (data.logs) {
                        container.textContent = data.logs;
                        container.scrollTop = container.scrollHeight;
                    } else {
                        container.textContent = data.error || 'No logs available';
                    }
                })
                .catch(error => {
                    console.error('Error loading logs:', error);
                    document.getElementById(`${type}-logs`).textContent = 'Error loading logs';
                });
        }
        
        // Auto-refresh status every 30 seconds
        setInterval(refreshStatus, 30000);
    </script>
</body>
</html>
EOF
    
    log_info "Web interface files setup completed"
}

cleanup_webapp() {
    log_info "Cleaning up web application..."
    
    # Stop web application
    stop_webapp
    
    # Remove web files
    if [ -d "$NGINXUI_WEB_DIR" ]; then
        rm -rf "$NGINXUI_WEB_DIR"
    fi
    
    # Remove API directory
    if [ -d "$NGINXUI_SCRIPT_DIR/api" ]; then
        rm -rf "$NGINXUI_SCRIPT_DIR/api"
    fi
    
    log_info "Web application cleanup completed"
}

# Initialize web application
init_webapp() {
    log_info "Initializing NginxUI web application..."
    
    # Setup API endpoints
    setup_api_endpoints || {
        log_error "Failed to setup API endpoints"
        return 1
    }
    
    # Setup web interface
    setup_web_interface || {
        log_error "Failed to setup web interface"
        return 1
    }
    
    log_info "NginxUI web application initialized successfully"
}