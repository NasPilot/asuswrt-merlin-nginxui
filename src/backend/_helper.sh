#!/bin/sh
# shellcheck disable=SC2034  # codacy:Unused variables

# Helper functions for NGINXUI
# Enhanced with XrayUI best practices for robust system integration

# Module import function (based on XrayUI pattern)
import() {
    local module="$1"
    local module_path="$NGINXUI_SCRIPT_DIR/$module.sh"
    
    if [ -f "$module_path" ]; then
        . "$module_path"
        log_debug "Imported module: $module"
    else
        log_error "Module $module not found at $module_path"
        return 1
    fi
}

# Batch import modules
import_modules() {
    for module in "$@"; do
        import "$module" || return 1
    done
}

# Enhanced error handling setup
setup_error_handling() {
    set -e
    trap 'handle_error $? $LINENO' ERR
}

# Error handler
handle_error() {
    local exit_code=$1
    local line_number=$2
    log_error "Script failed with exit code $exit_code at line $line_number"
    cleanup_on_error
    exit $exit_code
}

# Cleanup on error
cleanup_on_error() {
    # Remove lock files
    rm -f "$NGINXUI_LOCK" 2>/dev/null || true
    # Kill any background processes
    jobs -p | xargs -r kill 2>/dev/null || true
}

# Setup logging system
setup_logging() {
    # Ensure log directory exists
    mkdir -p "$(dirname "$NGINXUI_LOG")"
    
    # Setup log rotation if needed
    if [ -f "$NGINXUI_LOG" ] && [ "$(stat -f%z "$NGINXUI_LOG" 2>/dev/null || stat -c%s "$NGINXUI_LOG" 2>/dev/null)" -gt 1048576 ]; then
        mv "$NGINXUI_LOG" "$NGINXUI_LOG.old"
    fi
    
    # Initialize log file
    touch "$NGINXUI_LOG"
}

# Check if a process is running by name
is_process_running() {
    local process_name="$1"
    [ -n "$process_name" ] && pgrep -f "$process_name" >/dev/null 2>&1
}

# Enhanced port checking with multiple methods
is_port_in_use() {
    local port="$1"
    if [ -z "$port" ]; then
        return 1
    fi
    
    # Try netstat first
    if command -v netstat >/dev/null 2>&1; then
        netstat -ln 2>/dev/null | grep -q ":$port "
        return $?
    fi
    
    # Fallback to ss if available
    if command -v ss >/dev/null 2>&1; then
        ss -ln 2>/dev/null | grep -q ":$port "
        return $?
    fi
    
    # Last resort: try to bind to the port
    if command -v nc >/dev/null 2>&1; then
        ! nc -z 127.0.0.1 "$port" 2>/dev/null
        return $?
    fi
    
    return 1
}

# Get the router's LAN IP address with fallback
get_lan_ip() {
    local lan_ip="$(nvram get lan_ipaddr 2>/dev/null)"
    if [ -z "$lan_ip" ] || [ "$lan_ip" = "0.0.0.0" ]; then
        # Fallback methods
        lan_ip="$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1)"
        if [ -z "$lan_ip" ]; then
            lan_ip="$(ifconfig br0 2>/dev/null | awk '/inet addr/{print substr($2,6)}')"
        fi
        if [ -z "$lan_ip" ]; then
            lan_ip="192.168.1.1"  # Default fallback
        fi
    fi
    echo "$lan_ip"
}

# Enhanced Entware checking
is_entware_installed() {
    [ -f "/opt/bin/opkg" ] && [ -d "/opt/etc" ] && [ -f "/opt/etc/opkg.conf" ]
}

# Enhanced JFFS partition checking
is_jffs_enabled() {
    local jffs_enable="$(nvram get jffs2_enable 2>/dev/null)"
    local jffs_scripts="$(nvram get jffs2_scripts 2>/dev/null)"
    
    [ "$jffs_enable" = "1" ] && [ "$jffs_scripts" = "1" ] && [ -d "/jffs" ] && [ -w "/jffs" ]
}

# Enhanced custom scripts checking
are_custom_scripts_enabled() {
    [ "$(nvram get jffs2_scripts 2>/dev/null)" = "1" ] && [ -d "/jffs/scripts" ]
}

# Enhanced user page finding with conflict detection
find_available_user_page() {
    for i in 1 2 3; do
        local page="user$i.asp"
        local page_path="/www/user/$page"
        
        if [ ! -f "$page_path" ] && [ ! -L "$page_path" ]; then
            echo "$page"
            return 0
        elif [ -L "$page_path" ]; then
            # Check if it's our symlink
            local target="$(readlink "$page_path" 2>/dev/null)"
            if echo "$target" | grep -q "nginxui"; then
                echo "$page"
                return 0
            fi
        fi
    done
    return 1
}

# Check if web interface is currently mounted
is_web_interface_mounted() {
    local user_page="$(am_settings_get nginxui_user_page)"
    if [ -n "$user_page" ] && [ -L "/www/user/$user_page" ]; then
        local target="$(readlink "/www/user/$user_page" 2>/dev/null)"
        echo "$target" | grep -q "nginxui"
        return $?
    fi
    return 1
}

# Enhanced firmware addon support checking
check_firmware_addon_support() {
    local rc_support="$(nvram get rc_support 2>/dev/null)"
    echo "$rc_support" | grep -q "am_addons" && [ -d "/www/user" ]
}

# Enhanced permission validation
validate_permissions() {
    local file="$1"
    local expected_perms="$2"
    
    if [ ! -e "$file" ]; then
        return 1
    fi
    
    # Try different stat formats for compatibility
    local actual_perms
    if command -v stat >/dev/null 2>&1; then
        actual_perms="$(stat -c '%a' "$file" 2>/dev/null)"
        if [ -z "$actual_perms" ]; then
            # BSD stat format (macOS)
            actual_perms="$(stat -f '%A' "$file" 2>/dev/null)"
        fi
    fi
    
    [ "$actual_perms" = "$expected_perms" ]
}

# System requirements validation
check_system_requirements() {
    log_info "Checking system requirements..."
    
    # Check JFFS
    if ! is_jffs_enabled; then
        log_error "JFFS partition is not enabled"
        return 1
    fi
    
    # Check custom scripts
    if ! are_custom_scripts_enabled; then
        log_error "Custom scripts are not enabled"
        return 1
    fi
    
    # Check Entware
    if ! is_entware_installed; then
        log_error "Entware is not installed"
        return 1
    fi
    
    # Check available disk space (minimum 50MB)
    local available_space="$(df /jffs 2>/dev/null | awk 'NR==2 {print $4}')"
    if [ -n "$available_space" ] && [ "$available_space" -lt 51200 ]; then
        log_warn "Low disk space on JFFS partition: ${available_space}KB available"
    fi
    
    # Check firmware version compatibility
    local fw_version="$(nvram get buildno 2>/dev/null)"
    if [ -n "$fw_version" ]; then
        log_info "Firmware version: $fw_version"
        # Add version-specific checks if needed
    fi
    
    return 0
}

# Mount prerequisites validation
validate_mount_prerequisites() {
    # Check if /www/user directory exists and is writable
    if [ ! -d "/www/user" ]; then
        log_error "/www/user directory does not exist"
        return 1
    fi
    
    if [ ! -w "/www/user" ]; then
        log_error "/www/user directory is not writable"
        return 1
    fi
    
    # Check if required directories exist
    for dir in "$NGINXUI_ADDON_DIR" "$NGINXUI_WEB_DIR"; do
        if [ -n "$dir" ] && [ ! -d "$(dirname "$dir")" ]; then
            log_error "Parent directory for $dir does not exist"
            return 1
        fi
    done
    
    return 0
}

# Verify mount success
verify_mount_success() {
    local user_page="$1"
    
    # Check symlink exists and points to correct target
    local index_target="/www/user/$user_page"
    if [ ! -L "$index_target" ]; then
        log_error "Symlink not found: $index_target"
        return 1
    fi
    
    local target="$(readlink "$index_target" 2>/dev/null)"
    if ! echo "$target" | grep -q "nginxui"; then
        log_error "Symlink points to wrong target: $target"
        return 1
    fi
    
    # Check if target file exists
    if [ ! -f "$target" ]; then
        log_error "Target file does not exist: $target"
        return 1
    fi
    
    return 0
}

# Verify startup success
verify_startup() {
    local max_attempts=10
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if is_webapp_running && is_service_running; then
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    
    return 1
}

# Enhanced cleanup functions
cleanup_temp_files() {
    log_info "Cleaning up temporary files..."
    
    # Remove any temporary files in /tmp
    rm -f /tmp/nginxui_* 2>/dev/null
    rm -f /tmp/.nginxui_* 2>/dev/null
    
    # Clean up any stale lock files
    find /var/run -name "nginxui*.lock" -type f -delete 2>/dev/null
    
    # Clean up old log files (keep last 5)
    if [ -d "$NGINXUI_LOG_DIR" ]; then
        find "$NGINXUI_LOG_DIR" -name "*.log.*" -type f | sort -r | tail -n +6 | xargs rm -f 2>/dev/null
    fi
    
    return 0
}

# Clean up orphaned mounts
cleanup_orphaned_mounts() {
    log_info "Checking for orphaned mounts..."
    
    for i in 1 2 3; do
        local page="user$i.asp"
        local page_path="/www/user/$page"
        
        if [ -L "$page_path" ]; then
            local target="$(readlink "$page_path" 2>/dev/null)"
            if echo "$target" | grep -q "nginxui" && [ ! -f "$target" ]; then
                log_info "Removing orphaned symlink: $page_path"
                rm -f "$page_path"
                
                # Remove associated title file
                rm -f "/www/user/user$i.title" 2>/dev/null
            fi
        fi
    done
}

# Setup API endpoints
setup_api_endpoints() {
    log_info "Setting up API endpoints..."
    
    # Create API directory if it doesn't exist
    local api_dir="$NGINXUI_ADDON_DIR/api"
    mkdir -p "$api_dir"
    
    # Create basic API endpoints
    cat > "$api_dir/status.asp" << 'EOF'
<%
response.setHeader("Content-Type", "application/json");
response.write('{"status":"ok","service":"nginxui"}');
%>
EOF
    
    return 0
}

# Cleanup API endpoints
cleanup_api_endpoints() {
    local api_dir="$NGINXUI_ADDON_DIR/api"
    if [ -d "$api_dir" ]; then
        rm -rf "$api_dir"
    fi
    return 0
}

# Cleanup firewall rules
cleanup_firewall_rules() {
    # Remove any custom iptables rules added by NginxUI
    # This is a placeholder - implement based on actual firewall integration
    return 0
}

# Legacy import function (deprecated - use import() instead)
legacy_import() {
    local script_path="$1"
    local script_dir="$(dirname "$0")"
    
    # Handle relative paths
    if [ "${script_path#./}" != "$script_path" ]; then
        script_path="$script_dir/$script_path"
    fi
    
    if [ -f "$script_path" ]; then
        . "$script_path"
    else
        log_error "Failed to import script: $script_path"
        exit 1
    fi
}

# Enhanced import with module validation
import_with_validation() {
    local module="$1"
    local required_functions="$2"
    
    if import "$module"; then
        # Validate required functions exist
        if [ -n "$required_functions" ]; then
            for func in $required_functions; do
                if ! command -v "$func" >/dev/null 2>&1; then
                    log_error "Required function $func not found in module $module"
                    return 1
                fi
            done
        fi
        return 0
    else
        return 1
    fi
}

# Lock management functions
check_lock() {
    if [ -f "$NGINXUI_LOCK" ]; then
        local lock_pid=$(cat "$NGINXUI_LOCK" 2>/dev/null)
        if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
            log_error "Another NGINXUI process is running (PID: $lock_pid)"
            exit 1
        else
            log_warn "Removing stale lock file"
            rm -f "$NGINXUI_LOCK"
        fi
    fi
}

create_lock() {
    echo $$ > "$NGINXUI_LOCK"
}

clear_lock() {
    rm -f "$NGINXUI_LOCK"
}

# Progress update function
update_loading_progress() {
    local message="$1"
    log_info "$message"
    # Could be extended to update a progress file for UI
    echo "$message" > "/tmp/nginxui_progress.txt" 2>/dev/null || true
}

# Package installation helper
install_opkg_package() {
    local package="$1"
    local required="${2:-true}"
    
    if opkg list-installed | grep -q "^$package "; then
        log_debug "$package is already installed."
        return 0
    fi
    
    log_info "Installing $package..."
    if opkg install "$package"; then
        log_info "$package installed successfully."
        return 0
    else
        if [ "$required" = "true" ]; then
            log_error "Failed to install required package: $package"
            exit 1
        else
            log_warn "Failed to install optional package: $package"
            return 1
        fi
    fi
}

# Script file setup helper
setup_script_file() {
    local script_file="$1"
    local script_content="$2"
    local script_dir="$(dirname "$script_file")"
    
    # Create directory if it doesn't exist
    if [ ! -d "$script_dir" ]; then
        mkdir -p "$script_dir" || {
            log_error "Failed to create directory: $script_dir"
            return 1
        }
    fi
    
    # Create script file if it doesn't exist
    if [ ! -f "$script_file" ]; then
        cat > "$script_file" << 'EOF'
#!/bin/sh
EOF
        chmod +x "$script_file"
        log_info "Created script file: $script_file"
    fi
    
    # Check if content already exists
    if grep -q "#nginxui" "$script_file"; then
        log_debug "NGINXUI entry already exists in $script_file"
        return 0
    fi
    
    # Add content to script
    echo "" >> "$script_file"
    echo "$script_content" >> "$script_file"
    log_info "Added NGINXUI entry to $script_file"
}

# Clear script entries
clear_script_entries() {
    local scripts="/jffs/scripts/nat-start /jffs/scripts/post-mount /jffs/scripts/service-event"
    
    for script in $scripts; do
        if [ -f "$script" ]; then
            log_info "Removing NGINXUI entries from $script"
            sed -i '/#nginxui/d' "$script"
        fi
    done
}

# Settings management
am_settings_get() {
    local key="$1"
    grep "^$key=" /jffs/addons/custom_settings.txt 2>/dev/null | cut -d'=' -f2- | sed 's/^"\|"$//g'
}

am_settings_set() {
    local key="$1"
    local value="$2"
    local settings_file="/jffs/addons/custom_settings.txt"
    
    # Create settings file if it doesn't exist
    if [ ! -f "$settings_file" ]; then
        touch "$settings_file"
    fi
    
    # Remove existing entry
    sed -i "/^$key=/d" "$settings_file"
    
    # Add new entry
    echo "$key=\"$value\"" >> "$settings_file"
}

am_settings_del() {
    local key="$1"
    local settings_file="/jffs/addons/custom_settings.txt"
    
    if [ -f "$settings_file" ]; then
        sed -i "/^$key=/d" "$settings_file"
    fi
}

# Web UI page detection
get_webui_page() {
    local skip_wait="$1"
    
    # Check for available user pages
    for i in 1 2 3; do
        if [ ! -f "/www/user/user$i.asp" ]; then
            NGINXUI_USER_PAGE="user$i.asp"
            return 0
        fi
    done
    
    # If no pages available, wait and retry (unless skip_wait is set)
    if [ "$skip_wait" != "true" ]; then
        log_warn "No user pages available, waiting 30 seconds..."
        sleep 30
        get_webui_page true
    else
        NGINXUI_USER_PAGE="none"
        log_error "No user pages available for NGINXUI"
        return 1
    fi
}

# Nginx service management helpers
nginx_is_running() {
    if [ -f "$NGINX_PID" ]; then
        local pid=$(cat "$NGINX_PID" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

nginx_start() {
    if nginx_is_running; then
        log_info "Nginx is already running"
        return 0
    fi
    
    log_info "Starting Nginx..."
    if "$NGINX_BIN" -t && "$NGINX_BIN"; then
        log_info "Nginx started successfully"
        return 0
    else
        log_error "Failed to start Nginx"
        return 1
    fi
}

nginx_stop() {
    if ! nginx_is_running; then
        log_info "Nginx is not running"
        return 0
    fi
    
    log_info "Stopping Nginx..."
    if "$NGINX_BIN" -s quit; then
        log_info "Nginx stopped successfully"
        return 0
    else
        log_error "Failed to stop Nginx gracefully, trying force stop"
        if [ -f "$NGINX_PID" ]; then
            local pid=$(cat "$NGINX_PID" 2>/dev/null)
            if [ -n "$pid" ]; then
                kill "$pid" 2>/dev/null
                sleep 2
                if kill -0 "$pid" 2>/dev/null; then
                    kill -9 "$pid" 2>/dev/null
                fi
            fi
        fi
        rm -f "$NGINX_PID"
        log_info "Nginx force stopped"
        return 0
    fi
}

nginx_reload() {
    if ! nginx_is_running; then
        log_warn "Nginx is not running, starting instead"
        nginx_start
        return $?
    fi
    
    log_info "Reloading Nginx configuration..."
    if "$NGINX_BIN" -t && "$NGINX_BIN" -s reload; then
        log_info "Nginx configuration reloaded successfully"
        return 0
    else
        log_error "Failed to reload Nginx configuration"
        return 1
    fi
}

# Directory creation helper
ensure_directories() {
    local dirs="$NGINXUI_CONFIG_DIR $NGINXUI_LOG_DIR $NGINXUI_BACKUP_DIR $NGINXUI_SHARED_DIR $NGINX_CONF_DIR $NGINX_LOG_DIR"
    
    for dir in $dirs; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir" || {
                log_error "Failed to create directory: $dir"
                return 1
            }
            log_debug "Created directory: $dir"
        fi
    done
    
    return 0
}

# Configuration validation
validate_nginx_config() {
    log_info "Validating Nginx configuration..."
    if "$NGINX_BIN" -t; then
        log_info "Nginx configuration is valid"
        return 0
    else
        log_error "Nginx configuration is invalid"
        return 1
    fi
}

# Backup functions
backup_config() {
    local backup_name="nginxui_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    local backup_path="$NGINXUI_BACKUP_DIR/$backup_name"
    
    log_info "Creating configuration backup: $backup_name"
    
    if tar -czf "$backup_path" -C "$NGINXUI_CONFIG_DIR" . 2>/dev/null; then
        log_info "Backup created successfully: $backup_path"
        return 0
    else
        log_error "Failed to create backup"
        return 1
    fi
}

restore_config() {
    local backup_file="$1"
    
    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    log_info "Restoring configuration from: $backup_file"
    
    # Create backup of current config
    backup_config
    
    # Restore from backup
    if tar -xzf "$backup_file" -C "$NGINXUI_CONFIG_DIR"; then
        log_info "Configuration restored successfully"
        return 0
    else
        log_error "Failed to restore configuration"
        return 1
    fi
}