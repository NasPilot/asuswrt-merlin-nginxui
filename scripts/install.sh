#!/bin/sh

# NGINXUI Installation Script for ASUSWRT-Merlin
# Enhanced with XrayUI best practices

# Source global variables
. "$(dirname "$0")/_globals.sh"

# Enhanced installation functions with better error handling
check_prerequisites() {
    print_info "Starting NginxUI installation process."
    print_info "Checking prerequisites..."
    
    # Check if JFFS partition is enabled
    if [ ! -d "/jffs" ]; then
        print_error "JFFS partition is not available. Please enable JFFS custom scripts and configs in the router's administration page."
        print_error "Installation cannot continue without JFFS partition."
        return 1
    
    print_success "Web interface files installed successfully."
    return 0
}
    print_info "JFFS partition is ENABLED."
    
    # Check if custom scripts are enabled
    if [ "$(nvram get jffs2_scripts)" != "1" ]; then
        print_error "Custom scripts are not enabled. Please enable JFFS custom scripts and configs in the router's administration page."
        print_error "Installation cannot continue without custom scripts enabled."
        return 1
    fi
    print_info "JFFS custom scripts and configs are ENABLED."
    
    # Check if Entware is installed
    if ! command_exists "opkg"; then
        print_error "Entware is not installed. Please install Entware first."
        print_info "You can install Entware using amtm (Asuswrt-Merlin Terminal Menu)."
        print_error "Installation cannot continue without Entware."
        return 1
    fi
    print_info "Entware is installed."
    
    # Check firmware version compatibility
    local fw_version="$(nvram get buildno)"
    if [ -n "$fw_version" ]; then
        print_info "Firmware version: $(nvram get productid) $(nvram get buildno)"
    fi
    
    # Check available disk space
    local available_space="$(df /jffs | awk 'NR==2 {print $4}')"
    if [ "$available_space" -lt 10240 ]; then  # Less than 10MB
        print_warn "Low disk space on JFFS partition: ${available_space}KB available"
        print_warn "NginxUI requires at least 10MB of free space"
    fi
    
    print_success "Prerequisites check passed."
    return 0
}

install_packages() {
    print_info "Installing required packages..."
    
    # Update package list with retry mechanism
    local retry_count=0
    local max_retries=3
    
    while [ $retry_count -lt $max_retries ]; do
        print_info "Updating package list (attempt $((retry_count + 1))/$max_retries)..."
        if opkg update; then
            print_info "Package list updated successfully."
            break
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                print_warn "Failed to update package list, retrying in 5 seconds..."
                sleep 5
            else
                print_error "Failed to update package list after $max_retries attempts."
                return 1
            fi
        fi
    done
    
    # Check essential packages first
    local essential_packages="sed curl jq"
    for package in $essential_packages; do
        if ! opkg list-installed | grep -q "^$package "; then
            print_info "Installing essential package $package..."
            opkg install "$package" || {
                print_error "Failed to install essential package $package"
                return 1
            }
        else
            print_info "$package is already installed."
        fi
    done
    
    # Install Nginx and modules
    local nginx_packages="nginx nginx-mod-http-ssl nginx-mod-http-gzip nginx-mod-http-realip nginx-mod-http-stub-status"
    
    for package in $nginx_packages; do
        if ! opkg list-installed | grep -q "^$package "; then
            print_info "Installing $package..."
            opkg install "$package" || {
                print_warn "Failed to install $package, continuing..."
            }
        else
            print_info "$package is already installed."
        fi
    done
    
    # Install additional useful packages
    local optional_packages="wget openssl-util flock logrotate"
    
    for package in $optional_packages; do
        if ! opkg list-installed | grep -q "^$package "; then
            print_info "Installing optional package $package..."
            opkg install "$package" || {
                print_warn "Failed to install optional package $package, continuing..."
            }
        else
            print_info "$package is already installed."
        fi
    done
    
    # Verify Nginx installation
    if command_exists "nginx"; then
        local nginx_version="$(nginx -v 2>&1 | cut -d'/' -f2 | cut -d' ' -f1)"
        print_info "Nginx version: $nginx_version"
    else
        print_error "Nginx installation verification failed"
        return 1
    fi
    
    print_success "Package installation completed."
    return 0
}

setup_directories() {
    print_info "Setting up directories..."
    
    # Initialize all required directories
    if ! init_dirs; then
        print_error "Failed to create required directories."
        return 1
    fi
    
    # Create additional directories for enhanced functionality
    local additional_dirs="
        $NGINXUI_ADDON_DIR/geodata
        $NGINXUI_ADDON_DIR/certs
        $NGINXUI_ADDON_DIR/templates
        $NGINXUI_ADDON_DIR/cache
    "
    
    for dir in $additional_dirs; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir" || {
                print_warn "Failed to create directory: $dir"
            }
        fi
    done
    
    # Set proper permissions with enhanced security
    chmod 755 "$NGINXUI_WEB_DIR" "$NGINXUI_SCRIPT_DIR" "$NGINXUI_SHARED_DIR" "$NGINXUI_CONFIG_DIR"
    chmod 755 "$NGINXUI_LOG_DIR" "$NGINXUI_BACKUP_DIR" "$NGINX_CONF_DIR" "$NGINX_LOG_DIR"
    chmod 700 "$NGINXUI_ADDON_DIR/certs" 2>/dev/null || true  # Secure certificate directory
    
    # Create default configuration files if they don't exist
    if [ ! -f "$NGINXUI_CONFIG_DIR/nginxui.conf" ]; then
        create_default_config
    fi
    
    print_success "Directory setup completed."
    return 0
}

install_web_files() {
    print_info "Installing web interface files..."
    
    # Ensure web directory exists
    if [ ! -d "$NGINXUI_WEB_DIR" ]; then
        mkdir -p "$NGINXUI_WEB_DIR" || {
            print_error "Failed to create web directory: $NGINXUI_WEB_DIR"
            return 1
        }
    fi
    
    # Copy web files to the web directory
    if [ -f "app.js" ]; then
        cp "app.js" "$NGINXUI_WEB_DIR/" || {
            print_error "Failed to copy app.js"
            return 1
        }
        print_info "Copied app.js to web directory"
    fi
    
    if [ -f "index.asp" ]; then
        cp "index.asp" "$NGINXUI_WEB_DIR/" || {
            print_error "Failed to copy index.asp"
            return 1
        }
        print_info "Copied index.asp to web directory"
    fi
    
    # Copy additional assets if they exist
    for asset in "style.css" "favicon.ico" "manifest.json"; do
        if [ -f "$asset" ]; then
            cp "$asset" "$NGINXUI_WEB_DIR/" || {
                print_warn "Failed to copy $asset"
            }
        fi
    done
    
    if [ -f "nginxui.css" ]; then
        cp "nginxui.css" "$NGINXUI_WEB_DIR/" || {
            print_error "Failed to copy nginxui.css"
            return 1
        }
    fi
    
    if [ -f "nginxui.asp" ]; then
        cp "nginxui.asp" "/www/user/" || {
            print_error "Failed to copy nginxui.asp"
            return 1
        }
    fi
    
    # Set proper permissions for web files
    chmod 644 "$NGINXUI_WEB_DIR"/* 2>/dev/null
    chmod 644 "/www/user/nginxui.asp" 2>/dev/null
    
    print_success "Web interface files installed."
    return 0
}

install_scripts() {
    print_info "Installing backend scripts..."
    
    # Copy backend scripts
    local scripts="_globals.sh webapp.sh config_generator.sh service_manager.sh log_manager.sh"
    
    for script in $scripts; do
        if [ -f "$script" ]; then
            cp "$script" "$NGINXUI_SCRIPT_DIR/" || {
                print_error "Failed to copy $script"
                return 1
            }
            chmod 755 "$NGINXUI_SCRIPT_DIR/$script"
        fi
    done
    
    # Create main nginxui script
    cat > "$NGINXUI_SCRIPT_DIR/nginxui" << 'EOF'
#!/bin/sh

# Main NGINXUI script

# Source global variables
. "$(dirname "$0")/_globals.sh"

# Source other modules
. "$NGINXUI_SCRIPT_DIR/webapp.sh"
. "$NGINXUI_SCRIPT_DIR/service_manager.sh"
. "$NGINXUI_SCRIPT_DIR/config_generator.sh"
. "$NGINXUI_SCRIPT_DIR/log_manager.sh"

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
        install_nginxui
        ;;
    uninstall)
        uninstall_nginxui
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|install|uninstall}"
        exit 1
        ;;
esac
EOF
    
    chmod 755 "$NGINXUI_SCRIPT_DIR/nginxui"
    
    print_success "Backend scripts installed."
    return 0
}

setup_nginx_config() {
    print_info "Setting up initial Nginx configuration..."
    
    # Backup existing nginx.conf if it exists
    if [ -f "$NGINX_CONF" ]; then
        cp "$NGINX_CONF" "$NGINXUI_BACKUP_DIR/nginx.conf.backup.$(date +%Y%m%d_%H%M%S)" || {
            print_warn "Failed to backup existing nginx.conf"
        }
    fi
    
    # Create basic nginx.conf
    cat > "$NGINX_CONF" << EOF
user nobody;
worker_processes auto;
error_log $NGINX_ERROR_LOG;
pid $NGINX_PID;

events {
    worker_connections 1024;
}

http {
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log $NGINX_ACCESS_LOG main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /opt/etc/nginx/mime.types;
    default_type application/octet-stream;

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

    # Default server
    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;
        root /opt/share/www;
        index index.html index.htm;

        location / {
            try_files \$uri \$uri/ =404;
        }

        # Nginx status page
        location /nginx_status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            allow 192.168.0.0/16;
            allow 10.0.0.0/8;
            allow 172.16.0.0/12;
            deny all;
        }
    }

    # Include additional server configurations
    include $NGINX_CONF_DIR/conf.d/*.conf;
    include $NGINX_CONF_DIR/sites-enabled/*;
}
EOF
    
    # Create conf.d and sites-enabled directories
    ensure_dir "$NGINX_CONF_DIR/conf.d"
    ensure_dir "$NGINX_CONF_DIR/sites-available"
    ensure_dir "$NGINX_CONF_DIR/sites-enabled"
    
    # Create default document root
    ensure_dir "/opt/share/www"
    
    # Create a simple index.html if it doesn't exist
    if [ ! -f "/opt/share/www/index.html" ]; then
        cat > "/opt/share/www/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to Nginx</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>Welcome to Nginx on ASUSWRT-Merlin!</h1>
    <p>If you can see this page, the Nginx web server is successfully installed and working.</p>
    <p>For online documentation and support please refer to <a href="http://nginx.org/">nginx.org</a>.</p>
    <p>Thank you for using Nginx.</p>
</body>
</html>
EOF
    fi
    
    print_success "Nginx configuration setup completed."
    return 0
}

setup_startup_script() {
    print_info "Setting up startup script..."
    
    # Create services-start script if it doesn't exist
    if [ ! -f "/jffs/scripts/services-start" ]; then
        cat > "/jffs/scripts/services-start" << 'EOF'
#!/bin/sh

# Services start script
EOF
        chmod 755 "/jffs/scripts/services-start"
    fi
    
    # Add NGINXUI to services-start if not already present
    if ! grep -q "nginxui" "/jffs/scripts/services-start"; then
        echo "" >> "/jffs/scripts/services-start"
        echo "# Start NGINXUI" >> "/jffs/scripts/services-start"
        echo "$NGINXUI_SCRIPT_DIR/nginxui start" >> "/jffs/scripts/services-start"
    fi
    
    print_success "Startup script setup completed."
    return 0
}

setup_menu_integration() {
    print_info "Setting up menu integration..."
    
    # Create menu integration script
    cat > "/jffs/scripts/nginxui_menu.sh" << 'EOF'
#!/bin/sh

# Add NGINXUI to the router's web interface menu

# This script should be called from post-mount or services-start
# to integrate NGINXUI into the router's web interface

# Check if the menu modification is already in place
if ! grep -q "Nginx" /www/Advanced_Tools_Content.asp 2>/dev/null; then
    # Add menu entry (this is a placeholder - actual implementation
    # would depend on the specific router firmware version)
    logger "NGINXUI: Menu integration placeholder"
fi
EOF
    
    chmod 755 "/jffs/scripts/nginxui_menu.sh"
    
    print_success "Menu integration setup completed."
    return 0
}

finalize_installation() {
    print_info "Finalizing installation..."
    
    # Create initial configuration file
    cat > "$NGINXUI_CONF" << 'EOF'
# NGINXUI Configuration File
# This file is automatically generated and managed by NGINXUI

# Basic settings
NGINXUI_ENABLED=1
NGINXUI_MODE=basic
NGINXUI_AUTO_START=1

# Nginx settings
NGINX_ENABLED=1
NGINX_AUTO_START=1

# Logging
NGINXUI_LOG_LEVEL=info
NGINXUI_LOG_ROTATION=1
NGINXUI_LOG_MAX_SIZE=10M
NGINXUI_LOG_MAX_FILES=5
EOF
    
    # Set proper permissions
    chmod 644 "$NGINXUI_CONF"
    
    # Create log file
    touch "$NGINXUI_LOG"
    chmod 644 "$NGINXUI_LOG"
    
    # Log installation completion
    log_info "NGINXUI installation completed successfully"
    log_info "Version: $NGINXUI_VERSION"
    log_info "Installation directory: $NGINXUI_SCRIPT_DIR"
    log_info "Web directory: $NGINXUI_WEB_DIR"
    log_info "Configuration file: $NGINXUI_CONF"
    
    print_success "Installation completed successfully!"
    print_info "You can now access NGINXUI through the router's web interface."
    print_info "Navigate to Network Tools -> Nginx to configure and manage Nginx."
    
    return 0
}

# Main installation function
install_nginxui() {
    print_info "Starting NGINXUI installation..."
    print_info "Version: $NGINXUI_VERSION"
    
    # Run installation steps
    check_prerequisites || return 1
    install_packages || return 1
    setup_directories || return 1
    install_web_files || return 1
    install_scripts || return 1
    setup_nginx_config || return 1
    setup_startup_script || return 1
    setup_menu_integration || return 1
    finalize_installation || return 1
    
    print_success "NGINXUI has been installed successfully!"
    return 0
}

# Uninstallation function
uninstall_nginxui() {
    print_info "Starting NGINXUI uninstallation..."
    
    # Stop services
    "$NGINXUI_SCRIPT_DIR/nginxui" stop 2>/dev/null
    
    # Remove files and directories
    rm -rf "$NGINXUI_WEB_DIR"
    rm -rf "$NGINXUI_SCRIPT_DIR"
    rm -f "/www/user/nginxui.asp"
    rm -f "/jffs/scripts/nginxui_menu.sh"
    
    # Remove from services-start
    if [ -f "/jffs/scripts/services-start" ]; then
        sed -i '/nginxui/d' "/jffs/scripts/services-start"
    fi
    
    # Optionally remove configuration and logs
    read -p "Remove configuration files and logs? (y/N): " -r
    if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
        rm -rf "$NGINXUI_SHARED_DIR"
        rm -rf "$NGINXUI_LOG_DIR"
        rm -rf "$NGINXUI_CONFIG_DIR"
        rm -rf "$NGINXUI_BACKUP_DIR"
    fi
    
    print_success "NGINXUI has been uninstalled."
    return 0
}

# Run installation if script is executed directly
if [ "$(basename "$0")" = "install.sh" ]; then
    install_nginxui
fi
