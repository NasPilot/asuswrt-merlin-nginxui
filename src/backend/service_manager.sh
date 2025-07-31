#!/bin/sh

# NGINXUI Service Manager Script

# Source global variables
. "$(dirname "$0")/_globals.sh"

# Service management functions
handle_service_action() {
    local action="$1"
    local service="$2"
    local params="$3"
    
    log_info "Handling service action: $action for $service"
    
    case "$service" in
        "nginx")
            handle_nginx_action "$action" "$params"
            ;;
        "nginxui")
            handle_nginxui_action "$action" "$params"
            ;;
        *)
            log_error "Unknown service: $service"
            return 1
            ;;
    esac
}

handle_nginx_action() {
    local action="$1"
    local params="$2"
    
    case "$action" in
        "start")
            start_nginx_service
            ;;
        "stop")
            stop_nginx_service
            ;;
        "restart")
            restart_nginx_service
            ;;
        "reload")
            reload_nginx_service
            ;;
        "test")
            test_nginx_config
            ;;
        "status")
            get_nginx_status
            ;;
        "enable")
            enable_nginx_service
            ;;
        "disable")
            disable_nginx_service
            ;;
        *)
            log_error "Unknown nginx action: $action"
            return 1
            ;;
    esac
}

handle_nginxui_action() {
    local action="$1"
    local params="$2"
    
    case "$action" in
        "start")
            start_nginxui
            ;;
        "stop")
            stop_nginxui
            ;;
        "restart")
            restart_nginxui
            ;;
        "status")
            get_nginxui_status
            ;;
        "enable")
            enable_nginxui_service
            ;;
        "disable")
            disable_nginxui_service
            ;;
        *)
            log_error "Unknown nginxui action: $action"
            return 1
            ;;
    esac
}

# Nginx service functions
start_nginx_service() {
    log_info "Starting Nginx service..."
    
    if is_nginx_running; then
        log_info "Nginx is already running"
        echo '{"status":"success","message":"Nginx is already running","data":{"running":true}}'
        return 0
    fi
    
    # Check if Nginx is installed
    if ! check_nginx_installed; then
        log_error "Nginx is not installed"
        echo '{"status":"error","message":"Nginx is not installed","data":{"running":false}}'
        return 1
    fi
    
    # Test configuration before starting
    if ! test_nginx_config >/dev/null 2>&1; then
        log_error "Nginx configuration test failed"
        echo '{"status":"error","message":"Nginx configuration test failed","data":{"running":false}}'
        return 1
    fi
    
    # Start Nginx
    if nginx; then
        log_info "Nginx started successfully"
        echo '{"status":"success","message":"Nginx started successfully","data":{"running":true}}'
        return 0
    else
        log_error "Failed to start Nginx"
        echo '{"status":"error","message":"Failed to start Nginx","data":{"running":false}}'
        return 1
    fi
}

stop_nginx_service() {
    log_info "Stopping Nginx service..."
    
    if ! is_nginx_running; then
        log_info "Nginx is not running"
        echo '{"status":"success","message":"Nginx is not running","data":{"running":false}}'
        return 0
    fi
    
    # Stop Nginx gracefully
    if nginx -s quit; then
        # Wait for graceful shutdown
        local count=0
        while [ $count -lt 10 ] && is_nginx_running; do
            sleep 1
            count=$((count + 1))
        done
        
        if is_nginx_running; then
            log_warn "Graceful stop failed, forcing stop"
            nginx -s stop
            sleep 2
        fi
        
        if ! is_nginx_running; then
            log_info "Nginx stopped successfully"
            echo '{"status":"success","message":"Nginx stopped successfully","data":{"running":false}}'
            return 0
        else
            log_error "Failed to stop Nginx"
            echo '{"status":"error","message":"Failed to stop Nginx","data":{"running":true}}'
            return 1
        fi
    else
        log_error "Failed to send stop signal to Nginx"
        echo '{"status":"error","message":"Failed to send stop signal to Nginx","data":{"running":true}}'
        return 1
    fi
}

restart_nginx_service() {
    log_info "Restarting Nginx service..."
    
    # Stop first
    if is_nginx_running; then
        stop_nginx_service >/dev/null 2>&1
        sleep 2
    fi
    
    # Then start
    start_nginx_service
    return $?
}

reload_nginx_service() {
    log_info "Reloading Nginx configuration..."
    
    if ! is_nginx_running; then
        log_error "Nginx is not running"
        echo '{"status":"error","message":"Nginx is not running","data":{"running":false}}'
        return 1
    fi
    
    # Test configuration before reloading
    if ! test_nginx_config >/dev/null 2>&1; then
        log_error "Nginx configuration test failed"
        echo '{"status":"error","message":"Nginx configuration test failed","data":{"config_valid":false}}'
        return 1
    fi
    
    # Reload Nginx
    if nginx -s reload; then
        log_info "Nginx configuration reloaded successfully"
        echo '{"status":"success","message":"Nginx configuration reloaded successfully","data":{"config_valid":true}}'
        return 0
    else
        log_error "Failed to reload Nginx configuration"
        echo '{"status":"error","message":"Failed to reload Nginx configuration","data":{"config_valid":false}}'
        return 1
    fi
}

test_nginx_config() {
    log_info "Testing Nginx configuration..."
    
    local test_output=$(nginx -t 2>&1)
    local test_result=$?
    
    if [ $test_result -eq 0 ]; then
        log_info "Nginx configuration test passed"
        echo '{"status":"success","message":"Configuration test passed","data":{"config_valid":true,"output":"'$(echo "$test_output" | sed 's/"/\\"/'g)'"}'
        return 0
    else
        log_error "Nginx configuration test failed"
        echo '{"status":"error","message":"Configuration test failed","data":{"config_valid":false,"output":"'$(echo "$test_output" | sed 's/"/\\"/'g)'"}'
        return 1
    fi
}

get_nginx_status() {
    local running=false
    local version="unknown"
    local config_valid=false
    local uptime="unknown"
    local connections=0
    local requests=0
    
    # Check if Nginx is running
    if is_nginx_running; then
        running=true
        version=$(get_nginx_version)
        
        # Get uptime if PID file exists
        if [ -f "$NGINX_PID" ]; then
            local pid=$(cat "$NGINX_PID")
            if [ -n "$pid" ]; then
                local start_time=$(stat -c %Y "/proc/$pid" 2>/dev/null || echo 0)
                local current_time=$(date +%s)
                uptime=$((current_time - start_time))
            fi
        fi
        
        # Get connection statistics from status page
        local status_url="http://127.0.0.1/nginx_status"
        local status_data=$(curl -s "$status_url" 2>/dev/null || echo "")
        
        if [ -n "$status_data" ]; then
            connections=$(echo "$status_data" | grep "Active connections" | awk '{print $3}' || echo 0)
            requests=$(echo "$status_data" | awk 'NR==3 {print $3}' || echo 0)
        fi
    fi
    
    # Test configuration
    if test_nginx_config >/dev/null 2>&1; then
        config_valid=true
    fi
    
    # Generate status JSON
    cat << EOF
{
    "status": "success",
    "message": "Nginx status retrieved",
    "data": {
        "running": $running,
        "version": "$version",
        "config_valid": $config_valid,
        "uptime": $uptime,
        "connections": $connections,
        "requests": $requests,
        "pid_file": "$NGINX_PID",
        "config_file": "$NGINX_CONF"
    }
}
EOF
    
    return 0
}

enable_nginx_service() {
    log_info "Enabling Nginx service..."
    
    set_config_value "NGINX_ENABLED" "1"
    set_config_value "NGINX_AUTO_START" "1"
    
    log_info "Nginx service enabled"
    echo '{"status":"success","message":"Nginx service enabled","data":{"enabled":true}}'
    return 0
}

disable_nginx_service() {
    log_info "Disabling Nginx service..."
    
    set_config_value "NGINX_ENABLED" "0"
    set_config_value "NGINX_AUTO_START" "0"
    
    # Stop Nginx if running
    if is_nginx_running; then
        stop_nginx_service >/dev/null 2>&1
    fi
    
    log_info "Nginx service disabled"
    echo '{"status":"success","message":"Nginx service disabled","data":{"enabled":false}}'
    return 0
}

# NGINXUI service functions
get_nginxui_status() {
    local running=false
    local version="$NGINXUI_VERSION"
    local uptime="unknown"
    local enabled=true
    
    # Check if NGINXUI is running
    if is_nginxui_running; then
        running=true
        
        # Get uptime if PID file exists
        if [ -f "$NGINXUI_PID" ]; then
            local pid=$(cat "$NGINXUI_PID")
            if [ -n "$pid" ]; then
                local start_time=$(stat -c %Y "/proc/$pid" 2>/dev/null || echo 0)
                local current_time=$(date +%s)
                uptime=$((current_time - start_time))
            fi
        fi
    fi
    
    # Check if enabled
    if [ "$(get_config_value 'NGINXUI_ENABLED' '1')" != "1" ]; then
        enabled=false
    fi
    
    # Generate status JSON
    cat << EOF
{
    "status": "success",
    "message": "NGINXUI status retrieved",
    "data": {
        "running": $running,
        "enabled": $enabled,
        "version": "$version",
        "uptime": $uptime,
        "pid_file": "$NGINXUI_PID",
        "config_file": "$NGINXUI_CONF",
        "web_dir": "$NGINXUI_WEB_DIR",
        "script_dir": "$NGINXUI_SCRIPT_DIR"
    }
}
EOF
    
    return 0
}

enable_nginxui_service() {
    log_info "Enabling NGINXUI service..."
    
    set_config_value "NGINXUI_ENABLED" "1"
    set_config_value "NGINXUI_AUTO_START" "1"
    
    log_info "NGINXUI service enabled"
    echo '{"status":"success","message":"NGINXUI service enabled","data":{"enabled":true}}'
    return 0
}

disable_nginxui_service() {
    log_info "Disabling NGINXUI service..."
    
    set_config_value "NGINXUI_ENABLED" "0"
    set_config_value "NGINXUI_AUTO_START" "0"
    
    # Stop NGINXUI if running
    if is_nginxui_running; then
        stop_nginxui >/dev/null 2>&1
    fi
    
    log_info "NGINXUI service disabled"
    echo '{"status":"success","message":"NGINXUI service disabled","data":{"enabled":false}}'
    return 0
}

# Configuration management functions
apply_configuration() {
    local config_data="$1"
    
    log_info "Applying configuration..."
    
    # Parse configuration mode
    local mode=$(echo "$config_data" | jq -r '.mode // "basic"')
    
    # Source configuration generator
    . "$NGINXUI_SCRIPT_DIR/config_generator.sh"
    
    # Generate configuration
    if generate_nginx_config "$mode" "$config_data"; then
        log_info "Configuration applied successfully"
        
        # Reload Nginx if running
        if is_nginx_running; then
            reload_nginx_service >/dev/null 2>&1
        fi
        
        echo '{"status":"success","message":"Configuration applied successfully","data":{"mode":"'$mode'","applied":true}}'
        return 0
    else
        log_error "Failed to apply configuration"
        echo '{"status":"error","message":"Failed to apply configuration","data":{"mode":"'$mode'","applied":false}}'
        return 1
    fi
}

get_configuration() {
    log_info "Retrieving current configuration..."
    
    # Read current configuration file
    local config_json="{}"
    
    if [ -f "$NGINXUI_CONF" ]; then
        # Convert shell variables to JSON
        config_json=$(awk -F'=' '
            BEGIN { print "{" }
            /^[A-Z_]+=/ {
                gsub(/"/, "", $2)
                if (NR > 1) print ","
                printf "  \"%s\": \"%s\"", $1, $2
            }
            END { print "\n}" }
        ' "$NGINXUI_CONF" | tr -d '\n' | sed 's/,}/}/')
    fi
    
    # Get Nginx configuration info
    local nginx_info="{}"
    if [ -f "$NGINX_CONF" ]; then
        nginx_info=$(cat << EOF
{
    "config_file": "$NGINX_CONF",
    "config_test": $(test_nginx_config >/dev/null 2>&1 && echo "true" || echo "false"),
    "last_modified": "$(stat -c %Y "$NGINX_CONF" 2>/dev/null || echo 0)"
}
EOF
        )
    fi
    
    # Combine configuration data
    cat << EOF
{
    "status": "success",
    "message": "Configuration retrieved",
    "data": {
        "nginxui_config": $config_json,
        "nginx_info": $nginx_info
    }
}
EOF
    
    return 0
}

# System information functions
get_system_info() {
    log_info "Retrieving system information..."
    
    # Get system information
    local hostname=$(hostname 2>/dev/null || echo "unknown")
    local uptime=$(uptime | awk '{print $3,$4}' | sed 's/,//' 2>/dev/null || echo "unknown")
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//' 2>/dev/null || echo "unknown")
    local memory_info=$(free -m 2>/dev/null | awk 'NR==2{printf "%.1f/%.1fMB (%.1f%%)", $3,$2,$3*100/$2}' || echo "unknown")
    local disk_usage=$(df -h "$NGINXUI_SHARED_DIR" 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5")"}' || echo "unknown")
    
    # Get network information
    local ip_address=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo "unknown")
    
    # Get Entware information
    local entware_version="unknown"
    if command_exists "opkg"; then
        entware_version=$(opkg --version 2>/dev/null | head -n1 || echo "unknown")
    fi
    
    # Generate system info JSON
    cat << EOF
{
    "status": "success",
    "message": "System information retrieved",
    "data": {
        "hostname": "$hostname",
        "uptime": "$uptime",
        "load_average": "$load_avg",
        "memory": "$memory_info",
        "disk_usage": "$disk_usage",
        "ip_address": "$ip_address",
        "entware_version": "$entware_version",
        "nginxui_version": "$NGINXUI_VERSION",
        "timestamp": "$(date)"
    }
}
EOF
    
    return 0
}

# Process management functions
get_process_list() {
    log_info "Retrieving process list..."
    
    # Get Nginx processes
    local nginx_processes=$(ps aux | grep nginx | grep -v grep | awk '{
        printf "{\"pid\":%s,\"user\":\"%s\",\"cpu\":\"%s\",\"mem\":\"%s\",\"command\":\"%s\"},", $2, $1, $3, $4, $11
    }' | sed 's/,$//')
    
    if [ -z "$nginx_processes" ]; then
        nginx_processes=""
    else
        nginx_processes="[$nginx_processes]"
    fi
    
    # Get NGINXUI processes
    local nginxui_processes=$(ps aux | grep nginxui | grep -v grep | awk '{
        printf "{\"pid\":%s,\"user\":\"%s\",\"cpu\":\"%s\",\"mem\":\"%s\",\"command\":\"%s\"},", $2, $1, $3, $4, $11
    }' | sed 's/,$//')
    
    if [ -z "$nginxui_processes" ]; then
        nginxui_processes=""
    else
        nginxui_processes="[$nginxui_processes]"
    fi
    
    # Generate process list JSON
    cat << EOF
{
    "status": "success",
    "message": "Process list retrieved",
    "data": {
        "nginx_processes": $nginx_processes,
        "nginxui_processes": $nginxui_processes
    }
}
EOF
    
    return 0
}

# Backup and restore functions
create_backup() {
    local backup_name="$1"
    
    if [ -z "$backup_name" ]; then
        backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    log_info "Creating backup: $backup_name"
    
    local backup_dir="$NGINXUI_BACKUP_DIR/$backup_name"
    ensure_dir "$backup_dir"
    
    # Backup Nginx configuration
    if [ -f "$NGINX_CONF" ]; then
        cp "$NGINX_CONF" "$backup_dir/nginx.conf"
    fi
    
    # Backup conf.d directory
    if [ -d "$NGINX_CONF_DIR/conf.d" ]; then
        cp -r "$NGINX_CONF_DIR/conf.d" "$backup_dir/"
    fi
    
    # Backup sites-enabled directory
    if [ -d "$NGINX_CONF_DIR/sites-enabled" ]; then
        cp -r "$NGINX_CONF_DIR/sites-enabled" "$backup_dir/"
    fi
    
    # Backup NGINXUI configuration
    if [ -f "$NGINXUI_CONF" ]; then
        cp "$NGINXUI_CONF" "$backup_dir/nginxui.conf"
    fi
    
    # Create backup metadata
    cat > "$backup_dir/metadata.json" << EOF
{
    "name": "$backup_name",
    "created": "$(date)",
    "nginxui_version": "$NGINXUI_VERSION",
    "nginx_version": "$(get_nginx_version)"
}
EOF
    
    log_info "Backup created successfully: $backup_name"
    echo '{"status":"success","message":"Backup created successfully","data":{"backup_name":"'$backup_name'","backup_dir":"'$backup_dir'"}}'
    return 0
}

list_backups() {
    log_info "Listing available backups..."
    
    local backups="[]"
    
    if [ -d "$NGINXUI_BACKUP_DIR" ]; then
        local backup_list=""
        
        for backup_dir in "$NGINXUI_BACKUP_DIR"/*/; do
            if [ -d "$backup_dir" ]; then
                local backup_name=$(basename "$backup_dir")
                local metadata_file="$backup_dir/metadata.json"
                
                if [ -f "$metadata_file" ]; then
                    local metadata=$(cat "$metadata_file")
                    backup_list="$backup_list,$metadata"
                else
                    # Create basic metadata for old backups
                    local created=$(stat -c %y "$backup_dir" 2>/dev/null || date)
                    backup_list="$backup_list,{\"name\":\"$backup_name\",\"created\":\"$created\",\"nginxui_version\":\"unknown\",\"nginx_version\":\"unknown\"}"
                fi
            fi
        done
        
        if [ -n "$backup_list" ]; then
            backups="[${backup_list#,}]"
        fi
    fi
    
    cat << EOF
{
    "status": "success",
    "message": "Backup list retrieved",
    "data": {
        "backups": $backups
    }
}
EOF
    
    return 0
}

restore_backup() {
    local backup_name="$1"
    
    if [ -z "$backup_name" ]; then
        log_error "Backup name is required"
        echo '{"status":"error","message":"Backup name is required","data":{}}'
        return 1
    fi
    
    log_info "Restoring backup: $backup_name"
    
    local backup_dir="$NGINXUI_BACKUP_DIR/$backup_name"
    
    if [ ! -d "$backup_dir" ]; then
        log_error "Backup not found: $backup_name"
        echo '{"status":"error","message":"Backup not found","data":{"backup_name":"'$backup_name'"}}'
        return 1
    fi
    
    # Create a backup of current configuration before restoring
    create_backup "pre_restore_$(date +%Y%m%d_%H%M%S)" >/dev/null 2>&1
    
    # Restore Nginx configuration
    if [ -f "$backup_dir/nginx.conf" ]; then
        cp "$backup_dir/nginx.conf" "$NGINX_CONF"
    fi
    
    # Restore conf.d directory
    if [ -d "$backup_dir/conf.d" ]; then
        rm -rf "$NGINX_CONF_DIR/conf.d"
        cp -r "$backup_dir/conf.d" "$NGINX_CONF_DIR/"
    fi
    
    # Restore sites-enabled directory
    if [ -d "$backup_dir/sites-enabled" ]; then
        rm -rf "$NGINX_CONF_DIR/sites-enabled"
        cp -r "$backup_dir/sites-enabled" "$NGINX_CONF_DIR/"
    fi
    
    # Restore NGINXUI configuration
    if [ -f "$backup_dir/nginxui.conf" ]; then
        cp "$backup_dir/nginxui.conf" "$NGINXUI_CONF"
    fi
    
    # Test configuration
    if test_nginx_config >/dev/null 2>&1; then
        log_info "Backup restored successfully: $backup_name"
        
        # Reload Nginx if running
        if is_nginx_running; then
            reload_nginx_service >/dev/null 2>&1
        fi
        
        echo '{"status":"success","message":"Backup restored successfully","data":{"backup_name":"'$backup_name'"}}'
        return 0
    else
        log_error "Restored configuration is invalid"
        echo '{"status":"error","message":"Restored configuration is invalid","data":{"backup_name":"'$backup_name'"}}'
        return 1
    fi
}

# Export functions
export -f handle_service_action handle_nginx_action handle_nginxui_action
export -f start_nginx_service stop_nginx_service restart_nginx_service reload_nginx_service
export -f test_nginx_config get_nginx_status enable_nginx_service disable_nginx_service
export -f get_nginxui_status enable_nginxui_service disable_nginxui_service
export -f apply_configuration get_configuration get_system_info get_process_list
export -f create_backup list_backups restore_backup