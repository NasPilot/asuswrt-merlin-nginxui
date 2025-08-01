#!/bin/sh
# NginxUI Service Management Module
# Handles Nginx service operations including start, stop, restart, and status

# Import required modules
. "$NGINXUI_SCRIPT_DIR/_globals.sh"
. "$NGINXUI_SCRIPT_DIR/_helper.sh"

# Service management functions
start_service() {
    log_info "Starting Nginx service..."
    
    # Check if Nginx is already running
    if is_nginx_running; then
        log_warn "Nginx is already running (PID: $(cat "$NGINX_PID_FILE" 2>/dev/null))"
        return 0
    fi
    
    # Pre-start checks
    if ! pre_start_checks; then
        log_error "Pre-start checks failed"
        return 1
    fi
    
    # Validate configuration before starting
    log_info "Validating Nginx configuration..."
    if ! validate_nginx_config; then
        log_error "Nginx configuration validation failed"
        return 1
    fi
    
    # Create necessary directories
    create_required_directories || {
        log_error "Failed to create required directories"
        return 1
    }
    
    # Generate configuration if needed
    if [ ! -f "$NGINX_CONFIG_FILE" ]; then
        log_info "Generating default Nginx configuration..."
        generate_default_config || {
            log_error "Failed to generate default configuration"
            return 1
        }
    fi
    
    # Set up log rotation
    setup_log_rotation || {
        log_warn "Failed to set up log rotation"
    }
    
    # Start Nginx with enhanced error handling
    log_info "Starting Nginx daemon..."
    "$NGINX_BIN" -c "$NGINX_CONFIG_FILE" 2>&1 | while read -r line; do
        log_info "nginx: $line"
    done
    local start_result=$?
    
    if [ $start_result -ne 0 ]; then
        log_error "Failed to start Nginx (exit code: $start_result)"
        update_service_status "failed"
        return 1
    fi
    
    # Wait for service to start
    local timeout=10
    local count=0
    while [ $count -lt $timeout ]; do
        if is_nginx_running; then
            log_info "Nginx started successfully (PID: $(cat "$NGINX_PID_FILE" 2>/dev/null))"
            
            # Post-start verification
            if verify_service_health; then
                log_info "Nginx service health check passed"
            else
                log_warn "Nginx service health check failed"
            fi
            
            update_service_status "running"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    
    log_error "Nginx failed to start within $timeout seconds"
    update_service_status "failed"
    return 1
}

stop_service() {
    log_info "Stopping Nginx service..."
    
    if ! is_nginx_running; then
        log_warn "Nginx is not running"
        update_service_status "stopped"
        return 0
    fi
    
    local pid
    pid=$(cat "$NGINX_PID_FILE" 2>/dev/null)
    
    if [ -n "$pid" ]; then
        log_info "Stopping Nginx (PID: $pid)..."
        
        # Try graceful shutdown first
        log_info "Attempting graceful shutdown..."
        kill -QUIT "$pid" 2>/dev/null
        local quit_result=$?
        
        # Wait for graceful shutdown
        local timeout=15
        local count=0
        while [ $count -lt $timeout ] && is_nginx_running; do
            sleep 1
            count=$((count + 1))
        done
        
        # Force stop if graceful shutdown failed
        if is_nginx_running; then
            log_warn "Graceful shutdown timed out, forcing stop..."
            
            # Try SIGTERM first
            kill -TERM "$pid" 2>/dev/null
            sleep 3
            
            # Force kill if still running
            if is_nginx_running; then
                log_warn "Using SIGKILL to force stop..."
                kill -KILL "$pid" 2>/dev/null
                sleep 2
            fi
        fi
        
        # Clean up runtime files
        cleanup_runtime_files
        
        # Final verification
        if ! is_nginx_running; then
            log_info "Nginx stopped successfully"
            update_service_status "stopped"
            return 0
        else
            log_error "Failed to stop Nginx service"
            return 1
        fi
    else
        log_error "Could not read PID file: $NGINX_PID_FILE"
        return 1
    fi
}

restart_service() {
    log_info "Restarting Nginx service..."
    
    local was_running=false
    if is_nginx_running; then
        was_running=true
    fi
    
    # Stop if running
    if [ "$was_running" = "true" ]; then
        stop_service || {
            log_error "Failed to stop Nginx service during restart"
            return 1
        }
    fi
    
    # Wait for complete shutdown
    local wait_count=0
    while [ $wait_count -lt 5 ] && is_nginx_running; do
        sleep 1
        wait_count=$((wait_count + 1))
    done
    
    if [ $wait_count -eq 5 ]; then
        log_warn "Timeout waiting for complete shutdown, proceeding with restart"
    fi
    
    # Start again
    start_service || {
        log_error "Failed to start Nginx service during restart"
        return 1
    }
    
    log_info "Nginx service restarted successfully"
}

reload_service() {
    log_info "Reloading Nginx configuration..."
    
    if ! is_nginx_running; then
        log_error "Nginx is not running, cannot reload"
        return 1
    fi
    
    # Validate configuration before reloading
    if ! validate_nginx_config; then
        log_error "Configuration validation failed, reload aborted"
        return 1
    fi
    
    local pid
    pid=$(cat "$NGINX_PID_FILE" 2>/dev/null)
    
    if [ -n "$pid" ]; then
        log_info "Sending HUP signal to Nginx (PID: $pid)..."
        kill -HUP "$pid" || {
            log_error "Failed to reload Nginx configuration"
            return 1
        }
        
        log_info "Nginx configuration reloaded successfully"
        return 0
    else
        log_error "Could not read PID file: $NGINX_PID_FILE"
        return 1
    fi
}

get_service_status() {
    local status="stopped"
    local pid=""
    local uptime=""
    local memory=""
    local connections=""
    
    if is_nginx_running; then
        status="running"
        pid=$(cat "$NGINX_PID_FILE" 2>/dev/null)
        
        # Get process uptime
        if [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
            local start_time
            start_time=$(stat -c %Y "/proc/$pid" 2>/dev/null)
            if [ -n "$start_time" ]; then
                local current_time
                current_time=$(date +%s)
                uptime=$((current_time - start_time))
            fi
            
            # Get memory usage
            memory=$(ps -o rss= -p "$pid" 2>/dev/null | tr -d ' ')
        fi
        
        # Get connection count from stub_status if available
        connections=$(get_nginx_connections)
    fi
    
    # Create status JSON
    cat > "$NGINXUI_SHARED_DIR/status.json" << EOF
{
    "status": "$status",
    "pid": "$pid",
    "uptime": "$uptime",
    "memory": "$memory",
    "connections": "$connections",
    "config_file": "$NGINX_CONFIG_FILE",
    "last_updated": "$(date -Iseconds)"
}
EOF
    
    echo "$status"
}

get_nginx_connections() {
    # Try to get connection count from stub_status module
    local stub_status_url="http://127.0.0.1:${NGINX_STATUS_PORT:-8080}/nginx_status"
    
    if command -v curl >/dev/null 2>&1; then
        curl -s "$stub_status_url" 2>/dev/null | grep "Active connections" | awk '{print $3}'
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$stub_status_url" 2>/dev/null | grep "Active connections" | awk '{print $3}'
    else
        echo "0"
    fi
}

validate_nginx_config() {
    log_debug "Validating Nginx configuration..."
    
    if [ ! -f "$NGINX_CONFIG_FILE" ]; then
        log_error "Nginx configuration file not found: $NGINX_CONFIG_FILE"
        return 1
    fi
    
    "$NGINX_BIN" -t -c "$NGINX_CONFIG_FILE" 2>/dev/null || {
        log_error "Nginx configuration validation failed"
        "$NGINX_BIN" -t -c "$NGINX_CONFIG_FILE" 2>&1 | while read -r line; do
            log_error "  $line"
        done
        return 1
    }
    
    log_debug "Nginx configuration is valid"
    return 0
}

generate_default_config() {
    log_info "Generating default Nginx configuration..."
    
    # Ensure config directory exists
    mkdir -p "$(dirname "$NGINX_CONFIG_FILE")"
    
    # Generate basic nginx.conf
    cat > "$NGINX_CONFIG_FILE" << EOF
# NginxUI Generated Configuration
# Generated on: $(date)

user nobody;
worker_processes ${NGINX_WORKER_PROCESSES:-auto};
error_log ${NGINX_ERROR_LOG} warn;
pid ${NGINX_PID_FILE};

events {
    worker_connections ${NGINX_WORKER_CONNECTIONS:-1024};
    use epoll;
}

http {
    include /opt/etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log ${NGINX_ACCESS_LOG} main;
    
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout ${NGINX_KEEPALIVE_TIMEOUT:-65};
    types_hash_max_size 2048;
    client_max_body_size ${NGINX_CLIENT_MAX_BODY_SIZE:-1m};
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ${NGINX_SSL_CIPHERS};
    ssl_prefer_server_ciphers off;
    
    # Default server block
    server {
        listen ${NGINX_HTTP_PORT:-80} default_server;
        listen [::]:${NGINX_HTTP_PORT:-80} default_server;
        server_name _;
        
        root /opt/share/nginx/html;
        index index.html index.htm;
        
        location / {
            try_files \$uri \$uri/ =404;
        }
        
        # Status page for monitoring
        location /nginx_status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            allow ::1;
            deny all;
        }
        
        # Error pages
        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root /opt/share/nginx/html;
        }
    }
    
    # Include additional configuration files
    include ${NGINX_CONFIG_DIR}/conf.d/*.conf;
    include ${NGINX_CONFIG_DIR}/sites-enabled/*;
}
EOF
    
    # Create conf.d directory
    mkdir -p "$NGINX_CONFIG_DIR/conf.d"
    mkdir -p "$NGINX_CONFIG_DIR/sites-available"
    mkdir -p "$NGINX_CONFIG_DIR/sites-enabled"
    
    # Create default HTML files
    create_default_html_files
    
    log_info "Default Nginx configuration generated successfully"
}

create_default_html_files() {
    local html_dir="/opt/share/nginx/html"
    
    mkdir -p "$html_dir"
    
    # Create index.html
    cat > "$html_dir/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to nginx!</title>
    <style>
        body {
            width: 35em;
            margin: 0 auto;
            font-family: Tahoma, Verdana, Arial, sans-serif;
        }
    </style>
</head>
<body>
    <h1>Welcome to nginx!</h1>
    <p>If you see this page, the nginx web server is successfully installed and
    working. Further configuration is required.</p>
    
    <p>For online documentation and support please refer to
    <a href="http://nginx.org/">nginx.org</a>.<br/>
    Commercial support is available at
    <a href="http://nginx.com/">nginx.com</a>.</p>
    
    <p><em>Thank you for using nginx.</em></p>
</body>
</html>
EOF
    
    # Create 50x.html
    cat > "$html_dir/50x.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Error</title>
    <style>
        body {
            width: 35em;
            margin: 0 auto;
            font-family: Tahoma, Verdana, Arial, sans-serif;
        }
    </style>
</head>
<body>
    <h1>An error occurred.</h1>
    <p>Sorry, the page you are looking for is currently unavailable.<br/>
    Please try again later.</p>
    
    <p>If you are the system administrator of this resource then you should check
    the error log for details.</p>
    
    <p><em>Faithfully yours, nginx.</em></p>
</body>
</html>
EOF
}

update_service_status() {
    local status="$1"
    
    # Update status file
    mkdir -p "$NGINXUI_SHARED_DIR"
    echo "$status" > "$NGINXUI_SHARED_DIR/service_status"
    
    # Update detailed status
    get_service_status >/dev/null
}

# Service monitoring functions
monitor_service() {
    log_info "Starting Nginx service monitoring..."
    
    while true; do
        if ! is_nginx_running; then
            log_warn "Nginx service is not running, attempting restart..."
            start_service || {
                log_error "Failed to restart Nginx service"
                sleep 30
                continue
            }
        fi
        
        # Update status
        get_service_status >/dev/null
        
        # Sleep for monitoring interval
        sleep "${NGINX_MONITOR_INTERVAL:-60}"
    done
}

# Log management functions
rotate_logs() {
    log_info "Rotating Nginx logs..."
    
    if ! is_nginx_running; then
        log_warn "Nginx is not running, skipping log rotation"
        return 0
    fi
    
    # Rotate access log
    if [ -f "$NGINX_ACCESS_LOG" ]; then
        mv "$NGINX_ACCESS_LOG" "${NGINX_ACCESS_LOG}.old"
        touch "$NGINX_ACCESS_LOG"
        chmod 644 "$NGINX_ACCESS_LOG"
    fi
    
    # Rotate error log
    if [ -f "$NGINX_ERROR_LOG" ]; then
        mv "$NGINX_ERROR_LOG" "${NGINX_ERROR_LOG}.old"
        touch "$NGINX_ERROR_LOG"
        chmod 644 "$NGINX_ERROR_LOG"
    fi
    
    # Send USR1 signal to reopen log files
    local pid
    pid=$(cat "$NGINX_PID_FILE" 2>/dev/null)
    if [ -n "$pid" ]; then
        kill -USR1 "$pid" || {
            log_error "Failed to send USR1 signal for log rotation"
            return 1
        }
    fi
    
    log_info "Log rotation completed successfully"
}

cleanup_old_logs() {
    log_info "Cleaning up old log files..."
    
    # Remove old log files (older than 7 days)
    find "$(dirname "$NGINX_ACCESS_LOG")" -name "*.log.old" -mtime +7 -delete 2>/dev/null || true
    find "$(dirname "$NGINX_ERROR_LOG")" -name "*.log.old" -mtime +7 -delete 2>/dev/null || true
    
    log_info "Old log cleanup completed"
}

# Pre-start system checks
pre_start_checks() {
    # Check if Nginx binary exists and is executable
    if [ ! -x "$NGINX_BIN" ]; then
        log_error "Nginx binary not found or not executable: $NGINX_BIN"
        return 1
    fi
    
    # Check if configuration file exists
    if [ ! -f "$NGINX_CONFIG_FILE" ]; then
        log_warn "Nginx configuration file not found: $NGINX_CONFIG_FILE"
    fi
    
    # Check for port conflicts
    if [ -f "$NGINX_CONFIG_FILE" ]; then
        local listen_ports="$(awk '/listen/ {print $2}' "$NGINX_CONFIG_FILE" 2>/dev/null | sed 's/;//g' | sort -u)"
        for port in $listen_ports; do
            if [ "$port" != "80" ] && [ "$port" != "443" ] && is_port_in_use "$port"; then
                log_warn "Port $port is already in use"
            fi
        done
    fi
    
    return 0
}

# Setup log rotation
setup_log_rotation() {
    local logrotate_conf="/opt/etc/logrotate.d/nginx"
    
    if [ ! -f "$logrotate_conf" ] && command -v logrotate >/dev/null 2>&1; then
        mkdir -p "$(dirname "$logrotate_conf")"
        cat > "$logrotate_conf" << 'EOF'
/var/log/nginx/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 nobody nobody
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}
EOF
    fi
    
    return 0
}

# Verify service health
verify_service_health() {
    # Check if process is running
    if ! is_nginx_running; then
        return 1
    fi
    
    # Try to connect to default port
    if command -v nc >/dev/null 2>&1; then
        if nc -z 127.0.0.1 "${NGINX_HTTP_PORT:-80}" 2>/dev/null; then
            return 0
        fi
    fi
    
    # If nc is not available, assume healthy if process is running
    return 0
}

# Clean up runtime files
cleanup_runtime_files() {
    # Remove PID file if it exists
    if [ -f "$NGINX_PID_FILE" ]; then
        rm -f "$NGINX_PID_FILE" 2>/dev/null
    fi
    
    # Clean up temporary files
    rm -f /tmp/nginx_* 2>/dev/null || true
    
    return 0
}

# Check if port is in use
is_port_in_use() {
    local port="$1"
    if command -v netstat >/dev/null 2>&1; then
        netstat -ln | grep ":$port " >/dev/null 2>&1
    elif command -v ss >/dev/null 2>&1; then
        ss -ln | grep ":$port " >/dev/null 2>&1
    else
        return 1
    fi
}