#!/bin/sh

# NGINXUI Web Application Management Script

# Source global variables
. "$(dirname "$0")/_globals.sh"

# Web application functions
start_nginxui() {
    log_info "Starting NGINXUI web application..."
    
    # Check if already running
    if is_nginxui_running; then
        print_warn "NGINXUI is already running."
        return 0
    fi
    
    # Initialize directories
    if ! init_dirs; then
        log_error "Failed to initialize directories"
        return 1
    fi
    
    # Check if Nginx is installed
    if ! check_nginx_installed; then
        log_error "Nginx is not installed. Please install Nginx first."
        print_error "Nginx is not installed. Please run the installation script first."
        return 1
    fi
    
    # Start Nginx if enabled
    if [ "$(get_config_value 'NGINX_ENABLED' '1')" = "1" ]; then
        start_nginx_service
    fi
    
    # Create PID file
    echo "$$" > "$NGINXUI_PID"
    
    # Log startup
    log_info "NGINXUI web application started successfully"
    log_info "PID: $$"
    log_info "Version: $NGINXUI_VERSION"
    
    print_success "NGINXUI started successfully."
    return 0
}

stop_nginxui() {
    log_info "Stopping NGINXUI web application..."
    
    # Check if running
    if ! is_nginxui_running; then
        print_warn "NGINXUI is not running."
        return 0
    fi
    
    # Stop Nginx if it was started by NGINXUI
    if [ "$(get_config_value 'NGINX_AUTO_START' '1')" = "1" ]; then
        stop_nginx_service
    fi
    
    # Remove PID file
    rm -f "$NGINXUI_PID"
    
    # Log shutdown
    log_info "NGINXUI web application stopped"
    
    print_success "NGINXUI stopped successfully."
    return 0
}

restart_nginxui() {
    log_info "Restarting NGINXUI web application..."
    
    stop_nginxui
    sleep 2
    start_nginxui
    
    return $?
}

status_nginxui() {
    local status="stopped"
    local nginx_status="stopped"
    local nginx_version="unknown"
    
    # Check NGINXUI status
    if is_nginxui_running; then
        status="running"
    fi
    
    # Check Nginx status
    if is_nginx_running; then
        nginx_status="running"
        nginx_version=$(get_nginx_version)
    fi
    
    # Print status information
    echo "NGINXUI Status: $status"
    echo "NGINXUI Version: $NGINXUI_VERSION"
    echo "Nginx Status: $nginx_status"
    echo "Nginx Version: $nginx_version"
    
    if [ -f "$NGINXUI_PID" ]; then
        echo "NGINXUI PID: $(cat "$NGINXUI_PID")"
    fi
    
    if [ -f "$NGINX_PID" ]; then
        echo "Nginx PID: $(cat "$NGINX_PID")"
    fi
    
    # Log status check
    log_info "Status check - NGINXUI: $status, Nginx: $nginx_status"
    
    return 0
}

is_nginxui_running() {
    if [ -f "$NGINXUI_PID" ]; then
        local pid=$(cat "$NGINXUI_PID")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            # Remove stale PID file
            rm -f "$NGINXUI_PID"
        fi
    fi
    return 1
}

# Nginx service management functions
start_nginx_service() {
    log_info "Starting Nginx service..."
    
    if is_nginx_running; then
        log_info "Nginx is already running"
        return 0
    fi
    
    # Test configuration before starting
    if ! test_nginx_config; then
        log_error "Nginx configuration test failed"
        return 1
    fi
    
    # Start Nginx
    if nginx; then
        log_info "Nginx started successfully"
        return 0
    else
        log_error "Failed to start Nginx"
        return 1
    fi
}

stop_nginx_service() {
    log_info "Stopping Nginx service..."
    
    if ! is_nginx_running; then
        log_info "Nginx is not running"
        return 0
    fi
    
    # Stop Nginx gracefully
    if nginx -s quit; then
        log_info "Nginx stopped successfully"
        return 0
    else
        log_warn "Graceful stop failed, trying force stop"
        if nginx -s stop; then
            log_info "Nginx force stopped"
            return 0
        else
            log_error "Failed to stop Nginx"
            return 1
        fi
    fi
}

restart_nginx_service() {
    log_info "Restarting Nginx service..."
    
    if is_nginx_running; then
        stop_nginx_service
        sleep 2
    fi
    
    start_nginx_service
    return $?
}

reload_nginx_service() {
    log_info "Reloading Nginx configuration..."
    
    if ! is_nginx_running; then
        log_error "Nginx is not running"
        return 1
    fi
    
    # Test configuration before reloading
    if ! test_nginx_config; then
        log_error "Nginx configuration test failed"
        return 1
    fi
    
    # Reload Nginx
    if nginx -s reload; then
        log_info "Nginx configuration reloaded successfully"
        return 0
    else
        log_error "Failed to reload Nginx configuration"
        return 1
    fi
}

test_nginx_config() {
    log_info "Testing Nginx configuration..."
    
    if nginx -t 2>&1; then
        log_info "Nginx configuration test passed"
        return 0
    else
        log_error "Nginx configuration test failed"
        return 1
    fi
}

is_nginx_running() {
    if [ -f "$NGINX_PID" ]; then
        local pid=$(cat "$NGINX_PID")
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    
    # Alternative check using pgrep
    if pgrep -f "nginx: master process" >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Configuration management functions
get_config_value() {
    local key="$1"
    local default="$2"
    
    if [ -f "$NGINXUI_CONF" ]; then
        local value=$(grep "^$key=" "$NGINXUI_CONF" | cut -d'=' -f2- | tr -d '"')
        if [ -n "$value" ]; then
            echo "$value"
            return 0
        fi
    fi
    
    echo "$default"
    return 0
}

set_config_value() {
    local key="$1"
    local value="$2"
    
    # Ensure config file exists
    if [ ! -f "$NGINXUI_CONF" ]; then
        touch "$NGINXUI_CONF"
    fi
    
    # Update or add the configuration value
    if grep -q "^$key=" "$NGINXUI_CONF"; then
        sed -i "s|^$key=.*|$key=$value|" "$NGINXUI_CONF"
    else
        echo "$key=$value" >> "$NGINXUI_CONF"
    fi
    
    log_info "Configuration updated: $key=$value"
    return 0
}

# Health check functions
health_check() {
    local status=0
    
    log_info "Performing health check..."
    
    # Check if NGINXUI is enabled
    if [ "$(get_config_value 'NGINXUI_ENABLED' '1')" != "1" ]; then
        log_info "NGINXUI is disabled"
        return 0
    fi
    
    # Check if NGINXUI should be running
    if [ "$(get_config_value 'NGINXUI_AUTO_START' '1')" = "1" ]; then
        if ! is_nginxui_running; then
            log_warn "NGINXUI should be running but is not"
            status=1
        fi
    fi
    
    # Check if Nginx should be running
    if [ "$(get_config_value 'NGINX_ENABLED' '1')" = "1" ]; then
        if ! is_nginx_running; then
            log_warn "Nginx should be running but is not"
            status=1
        fi
    fi
    
    # Check configuration validity
    if ! test_nginx_config >/dev/null 2>&1; then
        log_error "Nginx configuration is invalid"
        status=1
    fi
    
    # Check disk space
    local disk_usage=$(df "$NGINXUI_SHARED_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        log_warn "Disk usage is high: ${disk_usage}%"
        status=1
    fi
    
    # Check log file sizes
    if [ -f "$NGINXUI_LOG" ]; then
        local log_size=$(stat -c%s "$NGINXUI_LOG" 2>/dev/null || echo 0)
        if [ "$log_size" -gt 10485760 ]; then  # 10MB
            log_warn "NGINXUI log file is large: $(($log_size / 1024 / 1024))MB"
        fi
    fi
    
    if [ "$status" -eq 0 ]; then
        log_info "Health check passed"
    else
        log_warn "Health check found issues"
    fi
    
    return $status
}

# Maintenance functions
rotate_logs() {
    log_info "Rotating logs..."
    
    local max_size=$(get_config_value 'NGINXUI_LOG_MAX_SIZE' '10M')
    local max_files=$(get_config_value 'NGINXUI_LOG_MAX_FILES' '5')
    
    # Convert size to bytes
    local max_bytes
    case "$max_size" in
        *K|*k) max_bytes=$((${max_size%[Kk]} * 1024)) ;;
        *M|*m) max_bytes=$((${max_size%[Mm]} * 1024 * 1024)) ;;
        *G|*g) max_bytes=$((${max_size%[Gg]} * 1024 * 1024 * 1024)) ;;
        *) max_bytes="$max_size" ;;
    esac
    
    # Rotate NGINXUI log
    if [ -f "$NGINXUI_LOG" ]; then
        local log_size=$(stat -c%s "$NGINXUI_LOG" 2>/dev/null || echo 0)
        if [ "$log_size" -gt "$max_bytes" ]; then
            # Rotate log files
            local i="$max_files"
            while [ "$i" -gt 1 ]; do
                local prev=$((i - 1))
                if [ -f "${NGINXUI_LOG}.$prev" ]; then
                    mv "${NGINXUI_LOG}.$prev" "${NGINXUI_LOG}.$i"
                fi
                i="$prev"
            done
            
            mv "$NGINXUI_LOG" "${NGINXUI_LOG}.1"
            touch "$NGINXUI_LOG"
            chmod 644 "$NGINXUI_LOG"
            
            log_info "NGINXUI log rotated"
        fi
    fi
    
    # Signal Nginx to rotate its logs if running
    if is_nginx_running; then
        nginx -s reopen
        log_info "Nginx logs rotated"
    fi
    
    return 0
}

cleanup_old_files() {
    log_info "Cleaning up old files..."
    
    # Clean up old backup files (keep last 10)
    if [ -d "$NGINXUI_BACKUP_DIR" ]; then
        find "$NGINXUI_BACKUP_DIR" -name "*.backup.*" -type f | sort -r | tail -n +11 | xargs rm -f
    fi
    
    # Clean up old log files
    local max_files=$(get_config_value 'NGINXUI_LOG_MAX_FILES' '5')
    if [ -d "$NGINXUI_LOG_DIR" ]; then
        find "$NGINXUI_LOG_DIR" -name "*.log.*" -type f | sort -r | tail -n +$((max_files + 1)) | xargs rm -f
    fi
    
    log_info "Cleanup completed"
    return 0
}

# Auto-start function for services-start script
auto_start() {
    # Check if auto-start is enabled
    if [ "$(get_config_value 'NGINXUI_AUTO_START' '1')" != "1" ]; then
        log_info "NGINXUI auto-start is disabled"
        return 0
    fi
    
    # Wait for system to be ready
    sleep 10
    
    # Start NGINXUI
    start_nginxui
    
    return $?
}

# Monitoring function
monitor() {
    while true; do
        # Perform health check
        if ! health_check; then
            log_warn "Health check failed, attempting recovery..."
            
            # Try to restart if auto-start is enabled
            if [ "$(get_config_value 'NGINXUI_AUTO_START' '1')" = "1" ]; then
                restart_nginxui
            fi
        fi
        
        # Rotate logs if needed
        if [ "$(get_config_value 'NGINXUI_LOG_ROTATION' '1')" = "1" ]; then
            rotate_logs
        fi
        
        # Sleep for monitoring interval (default 5 minutes)
        local interval=$(get_config_value 'NGINXUI_MONITOR_INTERVAL' '300')
        sleep "$interval"
    done
}

# Main script entry point
if [ "$#" -gt 0 ]; then
    case "$1" in
        start)
            start_nginxui
            ;;
        stop)
            stop_nginxui
            ;;
        restart)
            restart_nginxui
            ;;
        status)
            status_nginxui
            ;;
        install)
            # Source and run installation script
            if [ -f "$(dirname "$0")/install.sh" ]; then
                . "$(dirname "$0")/install.sh"
                install_nginxui
            else
                print_error "Installation script not found"
                exit 1
            fi
            ;;
        uninstall)
            # Source and run uninstallation
            if [ -f "$(dirname "$0")/install.sh" ]; then
                . "$(dirname "$0")/install.sh"
                uninstall_nginxui
            else
                print_error "Installation script not found"
                exit 1
            fi
            ;;
        monitor)
            monitor
            ;;
        health)
            health_check
            ;;
        rotate-logs)
            rotate_logs
            ;;
        cleanup)
            cleanup_old_files
            ;;
        auto-start)
            auto_start
            ;;
        *)
            echo "Usage: $0 {start|stop|restart|status|install|uninstall|monitor|health|rotate-logs|cleanup|auto-start}"
            exit 1
            ;;
    esac
fi

# Export functions for use by other scripts
export -f start_nginxui stop_nginxui restart_nginxui status_nginxui
export -f start_nginx_service stop_nginx_service restart_nginx_service reload_nginx_service
export -f test_nginx_config is_nginx_running is_nginxui_running
export -f get_config_value set_config_value health_check
export -f rotate_logs cleanup_old_files auto_start monitor