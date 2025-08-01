#!/bin/sh
# shellcheck disable=SC2034  # codacy:Unused variables

# Web UI mounting functions for NGINXUI

mount_ui() {
    check_lock
    create_lock
    
    log_info "Starting NGINXUI web interface mounting..."
    
    # Pre-mount validation
    if ! validate_mount_prerequisites; then
        log_error "Mount prerequisites validation failed"
        clear_lock
        exit 1
    fi
    
    # Check if firmware supports addons
    if ! nvram get rc_support | grep -q am_addons; then
        log_error "This firmware does not support addons!"
        clear_lock
        exit 5
    fi
    
    # Check if already mounted
    if is_web_interface_mounted; then
        log_warn "Web interface is already mounted"
        clear_lock
        return 0
    fi
    
    # Get available user page
    get_webui_page true
    
    if [ "$NGINXUI_USER_PAGE" = "none" ]; then
        log_error "Unable to install NGINXUI - no user pages available"
        clear_lock
        exit 5
    fi
    
    log_info "Mounting NGINXUI as $NGINXUI_USER_PAGE"
    
    # Ensure directories exist with proper permissions
    log_info "Creating addon directories..."
    ensure_directories
    
    # Create web directory if it doesn't exist
    if [ ! -d "$NGINXUI_WEB_DIR" ]; then
        mkdir -p "$NGINXUI_WEB_DIR" || {
            log_error "Failed to create web directory: $NGINXUI_WEB_DIR"
            clear_lock
            exit 1
        }
        chmod 755 "$NGINXUI_WEB_DIR"
    fi
    
    # Create additional required directories
    for dir in "$NGINXUI_SCRIPT_DIR/assets" "$NGINXUI_SCRIPT_DIR/api"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir" && chmod 755 "$dir" || {
                log_warn "Failed to create directory: $dir"
            }
        fi
    done
    
    # Backup existing user page if it exists
    local index_target="/www/user/$NGINXUI_USER_PAGE"
    if [ -f "$index_target" ] && [ ! -L "$index_target" ]; then
        log_info "Backing up existing user page: $NGINXUI_USER_PAGE"
        mv "$index_target" "${index_target}.backup.$(date +%s)" || {
            log_warn "Failed to backup existing user page"
        }
    fi
    
    # Create symlink for the main page
    log_info "Creating web interface symlink..."
    if [ -L "$index_target" ]; then
        rm -f "$index_target"
    fi
    
    ln -sf "$NGINXUI_SCRIPT_DIR/index.asp" "$index_target" || {
        log_error "Failed to create symlink for $NGINXUI_USER_PAGE"
        clear_lock
        exit 1
    }
    
    # Verify symlink creation
    if [ ! -L "$index_target" ]; then
        log_error "Symlink verification failed for $NGINXUI_USER_PAGE"
        clear_lock
        exit 1
    fi
    
    # Create title file with version info
    local base_user_page="$(echo "$NGINXUI_USER_PAGE" | cut -f1 -d'.')"
    log_info "Creating title file..."
    echo "NginxUI v${NGINXUI_VERSION:-1.0}" > "/www/user/$base_user_page.title" || {
        log_error "Failed to create title file"
        clear_lock
        exit 1
    }
    
    # Create version info file
    cat > "$NGINXUI_SCRIPT_DIR/version" << EOF
NGINXUI_VERSION=${NGINXUI_VERSION:-1.0}
NGINXUI_BUILD_DATE=${NGINXUI_BUILD_DATE:-$(date '+%Y-%m-%d')}
NGINXUI_INSTALL_DATE=$(date '+%Y-%m-%d %H:%M:%S')
EOF
    
    # Handle menuTree.js modification
    setup_menu_integration
    
    # Create symlinks for web assets
    setup_web_assets
    
    # Create symlink for main script
    log_info "Creating command line interface..."
    if [ -L "/opt/bin/nginxui" ]; then
        rm -f "/opt/bin/nginxui"
    fi
    
    ln -sf "$NGINXUI_SCRIPT_DIR/nginxui.sh" "/opt/bin/nginxui" || {
        log_error "Failed to create symlink for nginxui command"
    }
    
    # Set up API endpoints
    setup_api_endpoints || {
        log_warn "Failed to set up API endpoints"
    }
    
    # Store the user page in settings
    am_settings_set nginxui_user_page "$NGINXUI_USER_PAGE"
    
    # Verify mount success
    if verify_mount_success "$NGINXUI_USER_PAGE"; then
        clear_lock
        log_info "NGINXUI mounted successfully as $NGINXUI_USER_PAGE"
        log_info "Access URL: http://$(nvram get lan_ipaddr)/$NGINXUI_USER_PAGE"
    else
        log_error "Mount verification failed"
        clear_lock
        exit 1
    fi
}

unmount_ui() {
    check_lock
    create_lock
    
    log_info "Starting NGINXUI web interface unmounting..."
    
    # Check if firmware supports addons
    if ! nvram get rc_support | grep -q am_addons; then
        log_error "This firmware does not support addons!"
        clear_lock
        exit 5
    fi
    
    # Get current user page from settings
    NGINXUI_USER_PAGE=$(am_settings_get nginxui_user_page)
    
    if [ -z "$NGINXUI_USER_PAGE" ] || [ "$NGINXUI_USER_PAGE" = "none" ]; then
        log_warn "No NGINXUI page found to unmount. Checking for orphaned mounts..."
        cleanup_orphaned_mounts
    else
        log_info "Unmounting NGINXUI $NGINXUI_USER_PAGE"
        
        # Check if actually mounted
        if ! is_web_interface_mounted; then
            log_warn "Web interface is not currently mounted"
        fi
        
        # Remove page symlink
        local index_target="/www/user/$NGINXUI_USER_PAGE"
        log_info "Removing web interface symlink..."
        if [ -L "$index_target" ]; then
            rm -f "$index_target" || {
                log_warn "Failed to remove symlink: $index_target"
            }
        fi
        
        # Restore backup if exists
        local backup_file="$(ls "${index_target}.backup."* 2>/dev/null | head -1)"
        if [ -n "$backup_file" ] && [ -f "$backup_file" ]; then
            log_info "Restoring backup user page..."
            mv "$backup_file" "$index_target" || {
                log_warn "Failed to restore backup user page"
            }
        fi
        
        # Remove title file
        local base_user_page="$(echo "$NGINXUI_USER_PAGE" | cut -f1 -d'.')"
        rm -f "/www/user/$base_user_page.title"
    fi
    
    # Remove menu integration
    cleanup_menu_integration
    
    # Remove web assets
    cleanup_web_assets
    
    # Clean up API endpoints
    cleanup_api_endpoints || {
        log_warn "Failed to clean up API endpoints"
    }
    
    # Remove command symlink
    log_info "Removing command line interface..."
    if [ -L "/opt/bin/nginxui" ]; then
        rm -f "/opt/bin/nginxui" || {
            log_warn "Failed to remove /opt/bin/nginxui symlink"
        }
    fi
    
    # Remove settings
    am_settings_del nginxui_user_page
    
    # Verify unmount success
    if ! is_web_interface_mounted; then
        log_info "NGINXUI unmounted successfully"
    else
        log_warn "Web interface may not be completely unmounted"
    fi
    
    clear_lock
}

remount_ui() {
    local skip_wait="$1"
    
    log_info "Remounting NGINXUI web interface..."
    
    # Unmount first
    unmount_ui
    
    # Wait a moment unless skip is requested
    if [ "$skip_wait" != "skipwait" ]; then
        sleep 2
    fi
    
    # Mount again
    mount_ui
}

setup_menu_integration() {
    log_info "Setting up menu integration..."
    
    # Create backup of menuTree.js if not exists
    if [ ! -f "/tmp/menuTree.js" ]; then
        cp "/www/require/modules/menuTree.js" "/tmp/" || {
            log_error "Failed to backup menuTree.js"
            return 1
        }
        mount -o bind "/tmp/menuTree.js" "/www/require/modules/menuTree.js" || {
            log_error "Failed to bind mount menuTree.js"
            return 1
        }
    fi
    
    # Add NGINXUI entry to VPN menu
    local menu_entry="{ url: \"$NGINXUI_USER_PAGE\", tabName: \"NginxUI\" },"
    
    # Check if entry already exists
    if grep -q "tabName: \"NginxUI\"" "/tmp/menuTree.js"; then
        log_debug "NginxUI menu entry already exists"
        return 0
    fi
    
    # Insert the menu entry in VPN section
    sed -i '/index: "menu_VPN"/,/index:/ {
        /url:\s*"NULL",\s*tabName:\s*"__INHERIT__"/ i \
            '"$menu_entry"'
    }' "/tmp/menuTree.js" || {
        log_error "Failed to add NginxUI menu entry"
        return 1
    }
    
    # Remount the modified menuTree.js
    umount "/www/require/modules/menuTree.js" 2>/dev/null
    mount -o bind "/tmp/menuTree.js" "/www/require/modules/menuTree.js" || {
        log_error "Failed to remount menuTree.js"
        return 1
    }
    
    log_info "Menu integration completed successfully"
}

cleanup_menu_integration() {
    log_info "Cleaning up menu integration..."
    
    if [ ! -f "/tmp/menuTree.js" ]; then
        log_warn "menuTree.js backup not found, skipping cleanup"
        return 0
    fi
    
    # Remove NginxUI entries from menuTree.js
    sed -i '/tabName: "NginxUI"/d' "/tmp/menuTree.js" || {
        log_warn "Failed to remove NginxUI menu entries"
    }
    
    # Remount the cleaned menuTree.js
    umount "/www/require/modules/menuTree.js" 2>/dev/null
    mount -o bind "/tmp/menuTree.js" "/www/require/modules/menuTree.js" || {
        log_warn "Failed to remount cleaned menuTree.js"
    }
    
    log_info "Menu integration cleanup completed"
}

setup_web_assets() {
    log_info "Setting up web assets..."
    
    # Create symlinks for web application files
    ln -sf "$NGINXUI_SCRIPT_DIR/app.js" "$NGINXUI_WEB_DIR/app.js" || {
        log_error "Failed to create symlink for app.js"
        return 1
    }
    
    # Create symlinks for configuration files (JSON format for web interface)
    ln -sf "$NGINXUI_CONFIG_DIR/nginx.json" "$NGINXUI_WEB_DIR/nginx-config.json" || {
        log_warn "Failed to create symlink for nginx-config.json"
    }
    
    # Create symlinks for status files
    ln -sf "$NGINXUI_SHARED_DIR/status.json" "$NGINXUI_WEB_DIR/status.json" || {
        log_warn "Failed to create symlink for status.json"
    }
    
    # Create symlinks for logs (if they exist)
    if [ -f "$NGINX_ACCESS_LOG" ]; then
        ln -sf "$NGINX_ACCESS_LOG" "$NGINXUI_WEB_DIR/access.log" || {
            log_warn "Failed to create symlink for access.log"
        }
    fi
    
    if [ -f "$NGINX_ERROR_LOG" ]; then
        ln -sf "$NGINX_ERROR_LOG" "$NGINXUI_WEB_DIR/error.log" || {
            log_warn "Failed to create symlink for error.log"
        }
    fi
    
    log_info "Web assets setup completed"
}

cleanup_web_assets() {
    log_info "Cleaning up web assets..."
    
    # Remove all symlinks in web directory
    if [ -d "$NGINXUI_WEB_DIR" ]; then
        find "$NGINXUI_WEB_DIR" -type l -delete 2>/dev/null || {
            log_warn "Failed to remove some web asset symlinks"
        }
        
        # Remove web directory if empty
        rmdir "$NGINXUI_WEB_DIR" 2>/dev/null || {
            log_debug "Web directory not empty or removal failed"
        }
    fi
    
    log_info "Web assets cleanup completed"
}

# Service event handlers
service_event_startup() {
    log_info "Handling startup service event..."
    
    # Wait for system to be ready
    sleep 10
    
    # Ensure NGINXUI is properly mounted
    if [ "$(am_settings_get nginxui_startup)" = "y" ]; then
        log_info "Auto-mounting NGINXUI on startup"
        mount_ui
        
        # Start services if configured
        if [ "$(am_settings_get nginxui_autostart)" = "y" ]; then
            log_info "Auto-starting Nginx service"
            start_service
        fi
    fi
}

service_event_firewall() {
    local action="$1"
    
    log_info "Handling firewall service event: $action"
    
    case "$action" in
    configure)
        # Configure firewall rules for Nginx if needed
        configure_firewall_rules
        ;;
    *)
        log_debug "Unknown firewall action: $action"
        ;;
    esac
}

configure_firewall_rules() {
    log_info "Configuring firewall rules for Nginx..."
    
    # Add any necessary iptables rules here
    # This is a placeholder for future firewall configuration
    
    log_debug "Firewall rules configuration completed"
}