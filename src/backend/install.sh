#!/bin/sh
# NginxUI Installation and Management Module
# Handles installation, uninstallation, and system integration

# Import required modules
. "$NGINXUI_SCRIPT_DIR/_globals.sh"
. "$NGINXUI_SCRIPT_DIR/_helper.sh"

# Installation functions
install_nginxui() {
    log_info "Starting NginxUI installation..."
    
    # Check prerequisites
    check_prerequisites || {
        log_error "Prerequisites check failed"
        return 1
    }
    
    # Update package list
    update_package_list || {
        log_error "Failed to update package list"
        return 1
    }
    
    # Install required packages
    install_packages || {
        log_error "Failed to install packages"
        return 1
    }
    
    # Setup directories
    setup_directories || {
        log_error "Failed to setup directories"
        return 1
    }
    
    # Install script files
    install_script_files || {
        log_error "Failed to install script files"
        return 1
    }
    
    # Setup system integration
    setup_system_integration || {
        log_error "Failed to setup system integration"
        return 1
    }
    
    # Initialize configuration
    initialize_configuration || {
        log_error "Failed to initialize configuration"
        return 1
    }
    
    # Setup web application
    setup_web_application || {
        log_error "Failed to setup web application"
        return 1
    }
    
    # Setup logrotate
    setup_logrotate || {
        log_warn "Failed to setup logrotate (non-critical)"
    }
    
    # Setup cron jobs
    setup_cron_jobs || {
        log_warn "Failed to setup cron jobs (non-critical)"
    }
    
    log_info "NginxUI installation completed successfully"
    log_info "You can access the web interface at: http://$(nvram get lan_ipaddr):8088"
    
    return 0
}

uninstall_nginxui() {
    log_info "Starting NginxUI uninstallation..."
    
    # Stop all services
    stop_all_services || {
        log_warn "Failed to stop some services"
    }
    
    # Remove system integration
    remove_system_integration || {
        log_warn "Failed to remove system integration"
    }
    
    # Remove cron jobs
    remove_cron_jobs || {
        log_warn "Failed to remove cron jobs"
    }
    
    # Remove logrotate configuration
    remove_logrotate || {
        log_warn "Failed to remove logrotate configuration"
    }
    
    # Remove script files
    remove_script_files || {
        log_warn "Failed to remove script files"
    }
    
    # Remove directories (optional)
    if [ "$1" = "--purge" ]; then
        remove_directories || {
            log_warn "Failed to remove directories"
        }
    else
        log_info "Configuration and logs preserved. Use --purge to remove everything."
    fi
    
    log_info "NginxUI uninstallation completed"
    
    return 0
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running on ASUSWRT-Merlin
    if ! check_merlin_firmware; then
        log_error "This script requires ASUSWRT-Merlin firmware"
        return 1
    fi
    
    # Check JFFS partition
    if ! check_jffs_enabled; then
        log_error "JFFS custom scripts and configs must be enabled"
        log_error "Please enable it in Administration -> System -> Enable JFFS custom scripts and configs"
        return 1
    fi
    
    # Check if custom scripts are enabled
    if ! check_custom_scripts_enabled; then
        log_error "Custom scripts must be enabled"
        return 1
    }
    
    # Check Entware
    if ! check_entware_installed; then
        log_error "Entware is required but not installed"
        log_error "Please install Entware first: https://github.com/RMerl/asuswrt-merlin.ng/wiki/Entware"
        return 1
    fi
    
    # Check available space
    if ! check_disk_space; then
        log_error "Insufficient disk space"
        return 1
    }
    
    # Check for conflicting installations
    if check_conflicting_installations; then
        log_error "Conflicting installations detected"
        return 1
    fi
    
    log_info "Prerequisites check passed"
    return 0
}

update_package_list() {
    log_info "Updating package list..."
    
    if ! opkg update; then
        log_error "Failed to update package list"
        return 1
    fi
    
    log_info "Package list updated successfully"
    return 0
}

install_packages() {
    log_info "Installing required packages..."
    
    local packages="nginx lighttpd jq"
    local nginx_modules="nginx-mod-http-ssl nginx-mod-http-gzip nginx-mod-http-realip nginx-mod-http-stub-status"
    
    # Install base packages
    for package in $packages; do
        if ! opkg list-installed | grep -q "^$package "; then
            log_info "Installing $package..."
            if ! opkg install "$package"; then
                log_error "Failed to install $package"
                return 1
            fi
        else
            log_info "$package is already installed"
        fi
    done
    
    # Install Nginx modules
    for module in $nginx_modules; do
        if ! opkg list-installed | grep -q "^$module "; then
            log_info "Installing $module..."
            if ! opkg install "$module"; then
                log_warn "Failed to install $module (non-critical)"
            fi
        else
            log_info "$module is already installed"
        fi
    done
    
    log_info "Package installation completed"
    return 0
}

setup_directories() {
    log_info "Setting up directories..."
    
    # Create main directories
    local dirs="
        $NGINXUI_SCRIPT_DIR
        $NGINXUI_CONFIG_DIR
        $NGINXUI_LOG_DIR
        $NGINXUI_SHARED_DIR
        $NGINXUI_WEB_DIR
        $NGINXUI_BACKUP_DIR
    "
    
    for dir in $dirs; do
        if ! create_directory "$dir"; then
            log_error "Failed to create directory: $dir"
            return 1
        fi
    done
    
    # Create Nginx directories
    local nginx_dirs="
        $NGINX_CONFIG_DIR
        $NGINX_LOG_DIR
        /opt/var/lib/nginx
        /opt/var/lib/nginx/tmp
    "
    
    for dir in $nginx_dirs; do
        if ! create_directory "$dir"; then
            log_error "Failed to create Nginx directory: $dir"
            return 1
        fi
    done
    
    # Set proper permissions
    chmod 755 "$NGINXUI_SCRIPT_DIR"
    chmod 755 "$NGINXUI_CONFIG_DIR"
    chmod 755 "$NGINXUI_LOG_DIR"
    chmod 755 "$NGINXUI_SHARED_DIR"
    chmod 755 "$NGINXUI_WEB_DIR"
    chmod 755 "$NGINXUI_BACKUP_DIR"
    
    log_info "Directories setup completed"
    return 0
}

install_script_files() {
    log_info "Installing script files..."
    
    # Copy all backend scripts
    local script_files="
        _globals.sh
        _helper.sh
        nginxui.sh
        install.sh
        mount.sh
        service.sh
        config.sh
        webapp.sh
    "
    
    for script in $script_files; do
        if [ -f "$(dirname "$0")/$script" ]; then
            cp "$(dirname "$0")/$script" "$NGINXUI_SCRIPT_DIR/"
            chmod +x "$NGINXUI_SCRIPT_DIR/$script"
            log_info "Installed: $script"
        else
            log_warn "Script file not found: $script"
        fi
    done
    
    # Create main executable
    if [ ! -f "/opt/bin/nginxui" ]; then
        cat > "/opt/bin/nginxui" << EOF
#!/bin/sh
# NginxUI Main Executable
export NGINXUI_SCRIPT_DIR="$NGINXUI_SCRIPT_DIR"
exec "\$NGINXUI_SCRIPT_DIR/nginxui.sh" "\$@"
EOF
        chmod +x "/opt/bin/nginxui"
        log_info "Created main executable: /opt/bin/nginxui"
    fi
    
    log_info "Script files installation completed"
    return 0
}

setup_system_integration() {
    log_info "Setting up system integration..."
    
    # Setup services-start integration
    setup_services_start || {
        log_error "Failed to setup services-start integration"
        return 1
    }
    
    # Setup firewall-start integration
    setup_firewall_start || {
        log_error "Failed to setup firewall-start integration"
        return 1
    }
    
    # Setup post-mount integration
    setup_post_mount || {
        log_error "Failed to setup post-mount integration"
        return 1
    }
    
    # Setup unmount integration
    setup_unmount || {
        log_error "Failed to setup unmount integration"
        return 1
    }
    
    log_info "System integration setup completed"
    return 0
}

setup_services_start() {
    log_info "Setting up services-start integration..."
    
    local services_start="/jffs/scripts/services-start"
    local nginxui_marker="# NginxUI Auto-Start"
    local nginxui_command="$NGINXUI_SCRIPT_DIR/nginxui.sh start"
    
    # Create services-start if it doesn't exist
    if [ ! -f "$services_start" ]; then
        cat > "$services_start" << 'EOF'
#!/bin/sh
# ASUSWRT-Merlin Services Start Script
EOF
        chmod +x "$services_start"
    fi
    
    # Add NginxUI auto-start if not already present
    if ! grep -q "$nginxui_marker" "$services_start"; then
        cat >> "$services_start" << EOF

$nginxui_marker
if [ -f "$nginxui_command" ]; then
    "$nginxui_command" &
fi
EOF
        log_info "Added NginxUI auto-start to services-start"
    else
        log_info "NginxUI auto-start already configured in services-start"
    fi
    
    return 0
}

setup_firewall_start() {
    log_info "Setting up firewall-start integration..."
    
    local firewall_start="/jffs/scripts/firewall-start"
    local nginxui_marker="# NginxUI Firewall Rules"
    local nginxui_command="$NGINXUI_SCRIPT_DIR/nginxui.sh firewall"
    
    # Create firewall-start if it doesn't exist
    if [ ! -f "$firewall_start" ]; then
        cat > "$firewall_start" << 'EOF'
#!/bin/sh
# ASUSWRT-Merlin Firewall Start Script
EOF
        chmod +x "$firewall_start"
    fi
    
    # Add NginxUI firewall rules if not already present
    if ! grep -q "$nginxui_marker" "$firewall_start"; then
        cat >> "$firewall_start" << EOF

$nginxui_marker
if [ -f "$nginxui_command" ]; then
    "$nginxui_command"
fi
EOF
        log_info "Added NginxUI firewall rules to firewall-start"
    else
        log_info "NginxUI firewall rules already configured in firewall-start"
    fi
    
    return 0
}

setup_post_mount() {
    log_info "Setting up post-mount integration..."
    
    local post_mount="/jffs/scripts/post-mount"
    local nginxui_marker="# NginxUI Post-Mount"
    local nginxui_command="$NGINXUI_SCRIPT_DIR/nginxui.sh mount"
    
    # Create post-mount if it doesn't exist
    if [ ! -f "$post_mount" ]; then
        cat > "$post_mount" << 'EOF'
#!/bin/sh
# ASUSWRT-Merlin Post-Mount Script
EOF
        chmod +x "$post_mount"
    fi
    
    # Add NginxUI mount if not already present
    if ! grep -q "$nginxui_marker" "$post_mount"; then
        cat >> "$post_mount" << EOF

$nginxui_marker
if [ -f "$nginxui_command" ]; then
    "$nginxui_command"
fi
EOF
        log_info "Added NginxUI mount to post-mount"
    else
        log_info "NginxUI mount already configured in post-mount"
    fi
    
    return 0
}

setup_unmount() {
    log_info "Setting up unmount integration..."
    
    local unmount="/jffs/scripts/unmount"
    local nginxui_marker="# NginxUI Unmount"
    local nginxui_command="$NGINXUI_SCRIPT_DIR/nginxui.sh unmount"
    
    # Create unmount if it doesn't exist
    if [ ! -f "$unmount" ]; then
        cat > "$unmount" << 'EOF'
#!/bin/sh
# ASUSWRT-Merlin Unmount Script
EOF
        chmod +x "$unmount"
    fi
    
    # Add NginxUI unmount if not already present
    if ! grep -q "$nginxui_marker" "$unmount"; then
        cat >> "$unmount" << EOF

$nginxui_marker
if [ -f "$nginxui_command" ]; then
    "$nginxui_command"
fi
EOF
        log_info "Added NginxUI unmount to unmount"
    else
        log_info "NginxUI unmount already configured in unmount"
    fi
    
    return 0
}

initialize_configuration() {
    log_info "Initializing configuration..."
    
    # Create default settings
    am_settings_set nginxui_enabled "1"
    am_settings_set nginxui_web_port "8088"
    am_settings_set nginxui_web_interface "0.0.0.0"
    am_settings_set nginxui_auto_start "1"
    am_settings_set nginx_enabled "1"
    am_settings_set nginx_port "80"
    am_settings_set nginx_ssl_port "443"
    am_settings_set nginx_worker_processes "auto"
    am_settings_set nginx_worker_connections "1024"
    am_settings_set nginx_keepalive_timeout "65"
    am_settings_set nginx_client_max_body_size "1m"
    
    # Generate initial Nginx configuration
    . "$NGINXUI_SCRIPT_DIR/config.sh"
    generate_nginx_config || {
        log_error "Failed to generate initial Nginx configuration"
        return 1
    }
    
    log_info "Configuration initialization completed"
    return 0
}

setup_web_application() {
    log_info "Setting up web application..."
    
    # Initialize web application
    . "$NGINXUI_SCRIPT_DIR/webapp.sh"
    init_webapp || {
        log_error "Failed to initialize web application"
        return 1
    }
    
    log_info "Web application setup completed"
    return 0
}

setup_logrotate() {
    log_info "Setting up logrotate..."
    
    local logrotate_conf="/opt/etc/logrotate.d/nginxui"
    
    # Create logrotate configuration
    cat > "$logrotate_conf" << EOF
# NginxUI Log Rotation Configuration
$NGINXUI_LOG_FILE {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        # Signal processes to reopen log files if needed
    endscript
}

$NGINX_ACCESS_LOG {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        if [ -f $NGINX_PID_FILE ]; then
            kill -USR1 \$(cat $NGINX_PID_FILE)
        fi
    endscript
}

$NGINX_ERROR_LOG {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        if [ -f $NGINX_PID_FILE ]; then
            kill -USR1 \$(cat $NGINX_PID_FILE)
        fi
    endscript
}
EOF
    
    log_info "Logrotate setup completed"
    return 0
}

setup_cron_jobs() {
    log_info "Setting up cron jobs..."
    
    local cron_file="/opt/etc/cron.d/nginxui"
    
    # Create cron job for health checks and maintenance
    cat > "$cron_file" << EOF
# NginxUI Cron Jobs
# Health check every 5 minutes
*/5 * * * * root $NGINXUI_SCRIPT_DIR/nginxui.sh health >/dev/null 2>&1

# Log rotation daily at 2 AM
0 2 * * * root /opt/sbin/logrotate /opt/etc/logrotate.d/nginxui >/dev/null 2>&1

# Cleanup old files weekly on Sunday at 3 AM
0 3 * * 0 root $NGINXUI_SCRIPT_DIR/nginxui.sh cleanup >/dev/null 2>&1
EOF
    
    # Restart cron service
    if command -v crond >/dev/null 2>&1; then
        /opt/etc/init.d/S10cron restart >/dev/null 2>&1
    fi
    
    log_info "Cron jobs setup completed"
    return 0
}

# Uninstallation functions
stop_all_services() {
    log_info "Stopping all NginxUI services..."
    
    # Stop web application
    if [ -f "$NGINXUI_SCRIPT_DIR/webapp.sh" ]; then
        . "$NGINXUI_SCRIPT_DIR/webapp.sh"
        stop_webapp
    fi
    
    # Stop Nginx service
    if [ -f "$NGINXUI_SCRIPT_DIR/service.sh" ]; then
        . "$NGINXUI_SCRIPT_DIR/service.sh"
        stop_service
    fi
    
    # Unmount web interface
    if [ -f "$NGINXUI_SCRIPT_DIR/mount.sh" ]; then
        . "$NGINXUI_SCRIPT_DIR/mount.sh"
        unmount_web_interface
    fi
    
    return 0
}

remove_system_integration() {
    log_info "Removing system integration..."
    
    local scripts="
        /jffs/scripts/services-start
        /jffs/scripts/firewall-start
        /jffs/scripts/post-mount
        /jffs/scripts/unmount
    "
    
    local nginxui_marker="# NginxUI"
    
    for script in $scripts; do
        if [ -f "$script" ]; then
            # Remove NginxUI related lines
            sed -i "/$nginxui_marker/,+3d" "$script"
            log_info "Removed NginxUI integration from $script"
        fi
    done
    
    return 0
}

remove_cron_jobs() {
    log_info "Removing cron jobs..."
    
    local cron_file="/opt/etc/cron.d/nginxui"
    
    if [ -f "$cron_file" ]; then
        rm -f "$cron_file"
        log_info "Removed cron configuration"
        
        # Restart cron service
        if command -v crond >/dev/null 2>&1; then
            /opt/etc/init.d/S10cron restart >/dev/null 2>&1
        fi
    fi
    
    return 0
}

remove_logrotate() {
    log_info "Removing logrotate configuration..."
    
    local logrotate_conf="/opt/etc/logrotate.d/nginxui"
    
    if [ -f "$logrotate_conf" ]; then
        rm -f "$logrotate_conf"
        log_info "Removed logrotate configuration"
    fi
    
    return 0
}

remove_script_files() {
    log_info "Removing script files..."
    
    # Remove main executable
    if [ -f "/opt/bin/nginxui" ]; then
        rm -f "/opt/bin/nginxui"
        log_info "Removed main executable"
    fi
    
    # Remove script directory
    if [ -d "$NGINXUI_SCRIPT_DIR" ]; then
        rm -rf "$NGINXUI_SCRIPT_DIR"
        log_info "Removed script directory"
    fi
    
    return 0
}

remove_directories() {
    log_info "Removing directories..."
    
    local dirs="
        $NGINXUI_CONFIG_DIR
        $NGINXUI_LOG_DIR
        $NGINXUI_SHARED_DIR
        $NGINXUI_WEB_DIR
        $NGINXUI_BACKUP_DIR
    "
    
    for dir in $dirs; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            log_info "Removed directory: $dir"
        fi
    done
    
    return 0
}

# Utility functions for prerequisite checks
check_merlin_firmware() {
    if [ -f "/usr/sbin/helper.sh" ] || [ -f "/jffs/scripts/services-start" ] || nvram get buildno | grep -q "Merlin"; then
        return 0
    fi
    return 1
}

check_jffs_enabled() {
    local jffs_enabled=$(nvram get jffs2_enable)
    local jffs_scripts=$(nvram get jffs2_scripts)
    
    if [ "$jffs_enabled" = "1" ] && [ "$jffs_scripts" = "1" ]; then
        return 0
    fi
    return 1
}

check_custom_scripts_enabled() {
    if [ -d "/jffs/scripts" ]; then
        return 0
    fi
    return 1
}

check_entware_installed() {
    if command -v opkg >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

check_disk_space() {
    local required_space=50  # MB
    local available_space
    
    available_space=$(df /jffs | awk 'NR==2 {print int($4/1024)}')
    
    if [ "$available_space" -ge "$required_space" ]; then
        return 0
    fi
    
    log_error "Insufficient disk space. Required: ${required_space}MB, Available: ${available_space}MB"
    return 1
}

check_conflicting_installations() {
    # Check for other Nginx management tools
    local conflicts="
        /opt/bin/nginx-ui
        /jffs/scripts/nginx-manager
        /opt/share/nginx-admin
    "
    
    for conflict in $conflicts; do
        if [ -e "$conflict" ]; then
            log_error "Conflicting installation detected: $conflict"
            return 0  # Found conflict
        fi
    done
    
    return 1  # No conflicts
}

# Upgrade function
upgrade_nginxui() {
    log_info "Starting NginxUI upgrade..."
    
    # Backup current configuration
    backup_configuration || {
        log_error "Failed to backup configuration"
        return 1
    }
    
    # Stop services
    stop_all_services
    
    # Install new version
    install_script_files || {
        log_error "Failed to install new script files"
        return 1
    }
    
    # Restore configuration
    restore_configuration || {
        log_error "Failed to restore configuration"
        return 1
    }
    
    # Restart services
    . "$NGINXUI_SCRIPT_DIR/nginxui.sh"
    start_nginxui || {
        log_error "Failed to start NginxUI after upgrade"
        return 1
    }
    
    log_info "NginxUI upgrade completed successfully"
    return 0
}

backup_configuration() {
    log_info "Backing up configuration..."
    
    local backup_file="$NGINXUI_BACKUP_DIR/config_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    # Create backup directory
    mkdir -p "$NGINXUI_BACKUP_DIR"
    
    # Backup configuration files
    tar -czf "$backup_file" -C "$NGINXUI_CONFIG_DIR" . 2>/dev/null || {
        log_error "Failed to create configuration backup"
        return 1
    }
    
    log_info "Configuration backed up to: $backup_file"
    return 0
}

restore_configuration() {
    log_info "Restoring configuration..."
    
    # Find latest backup
    local latest_backup
    latest_backup=$(find "$NGINXUI_BACKUP_DIR" -name "config_*.tar.gz" -type f | sort -r | head -n 1)
    
    if [ -n "$latest_backup" ] && [ -f "$latest_backup" ]; then
        tar -xzf "$latest_backup" -C "$NGINXUI_CONFIG_DIR" 2>/dev/null || {
            log_error "Failed to restore configuration from backup"
            return 1
        }
        log_info "Configuration restored from: $latest_backup"
    else
        log_warn "No configuration backup found, using defaults"
        initialize_configuration
    fi
    
    return 0
}