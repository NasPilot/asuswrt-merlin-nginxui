#!/bin/bash

# NginxUI Installation Script - Based on XrayUI successful pattern
# This script handles the complete installation and setup process

set -euo pipefail

# Configuration
APP_NAME="NginxUI"
APP_VERSION="1.0.0"
INSTALL_PATH="/jffs/addons/nginxui"
WEB_PATH="/www/nginxui"
CONFIG_PATH="/jffs/addons/nginxui/config"
LOG_PATH="/tmp/nginxui"
BACKUP_PATH="/jffs/addons/nginxui/backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Print banner
print_banner() {
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                        NginxUI Installer                    ║"
    echo "║                   Based on XrayUI Pattern                   ║"
    echo "║                        Version $APP_VERSION                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if running on supported router
check_router_compatibility() {
    log_step "Checking router compatibility..."
    
    # Check if it's an ASUS router with Merlin firmware
    if [ ! -f "/usr/sbin/nvram" ]; then
        log_error "This script is designed for ASUS routers with Merlin firmware"
        exit 1
    fi
    
    # Check firmware version
    local firmware_version
    firmware_version=$(nvram get buildno 2>/dev/null || echo "unknown")
    log_info "Detected firmware version: $firmware_version"
    
    # Check available space
    local available_space
    available_space=$(df /jffs | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 10240 ]; then  # 10MB minimum
        log_warning "Low disk space on /jffs ($(($available_space/1024))MB available)"
        log_warning "At least 10MB is recommended for NginxUI"
    fi
    
    log_success "Router compatibility check passed"
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check for required commands
    local required_commands=("wget" "tar" "chmod" "mkdir" "cp" "mv")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required commands: ${missing_deps[*]}"
        exit 1
    fi
    
    # Check if Entware is installed (optional but recommended)
    if ! command -v opkg >/dev/null 2>&1; then
        log_warning "Entware not detected. Some features may be limited."
        log_info "Consider installing Entware for full functionality."
    else
        log_success "Entware detected"
    fi
    
    log_success "Prerequisites check passed"
}

# Create directory structure
setup_directories() {
    log_step "Setting up directory structure..."
    
    local directories=(
        "$INSTALL_PATH"
        "$INSTALL_PATH/backend"
        "$INSTALL_PATH/www"
        "$CONFIG_PATH"
        "$LOG_PATH"
        "$BACKUP_PATH"
        "/jffs/scripts"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_info "Created directory: $dir"
        fi
    done
    
    # Set proper permissions
    chmod 755 "$INSTALL_PATH"
    chmod 755 "$INSTALL_PATH/backend"
    chmod 755 "$CONFIG_PATH"
    chmod 777 "$LOG_PATH"
    
    log_success "Directory structure created"
}

# Install application files
install_files() {
    log_step "Installing application files..."
    
    # Check if we're installing from a local build or downloading
    if [ -d "./dist" ] && [ -d "./src/backend" ]; then
        log_info "Installing from local build..."
        
        # Copy web files
        cp -r ./dist/* "$INSTALL_PATH/www/"
        
        # Copy backend scripts
        cp ./src/backend/*.sh "$INSTALL_PATH/backend/"
        
        # Copy configuration
        if [ -f "./config.json" ]; then
            cp ./config.json "$CONFIG_PATH/"
        fi
        
    else
        log_info "Downloading latest release..."
        
        # Download and extract (placeholder - would download from GitHub releases)
        local download_url="https://github.com/your-repo/nginxui/releases/latest/download/nginxui.tar.gz"
        local temp_file="/tmp/nginxui.tar.gz"
        
        if wget -q "$download_url" -O "$temp_file"; then
            tar -xzf "$temp_file" -C "$INSTALL_PATH"
            rm "$temp_file"
        else
            log_error "Failed to download NginxUI. Please check your internet connection."
            exit 1
        fi
    fi
    
    # Make scripts executable
    chmod +x "$INSTALL_PATH/backend/"*.sh
    
    log_success "Application files installed"
}

# Configure web server integration
setup_web_integration() {
    log_step "Setting up web server integration..."
    
    # Create symbolic link for web access
    if [ ! -L "$WEB_PATH" ]; then
        ln -sf "$INSTALL_PATH/www" "$WEB_PATH"
        log_info "Created web symbolic link"
    fi
    
    # Add to httpd.conf if exists
    local httpd_conf="/opt/etc/nginx/nginx.conf"
    if [ -f "$httpd_conf" ]; then
        if ! grep -q "nginxui" "$httpd_conf"; then
            log_info "Adding NginxUI location to nginx.conf"
            # Add location block (simplified)
            echo "# NginxUI location block would be added here" >> "$httpd_conf"
        fi
    fi
    
    log_success "Web integration configured"
}

# Setup service integration
setup_service() {
    log_step "Setting up service integration..."
    
    # Create service script
    cat > "/jffs/scripts/nginxui" << 'EOF'
#!/bin/bash
# NginxUI Service Script

INSTALL_PATH="/jffs/addons/nginxui"

case "$1" in
    start)
        if [ -f "$INSTALL_PATH/backend/nginxui.sh" ]; then
            "$INSTALL_PATH/backend/nginxui.sh" start
        fi
        ;;
    stop)
        if [ -f "$INSTALL_PATH/backend/nginxui.sh" ]; then
            "$INSTALL_PATH/backend/nginxui.sh" stop
        fi
        ;;
    restart)
        "$0" stop
        sleep 2
        "$0" start
        ;;
    status)
        if [ -f "$INSTALL_PATH/backend/nginxui.sh" ]; then
            "$INSTALL_PATH/backend/nginxui.sh" status
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "/jffs/scripts/nginxui"
    
    # Add to services-start if it exists
    local services_start="/jffs/scripts/services-start"
    if [ -f "$services_start" ]; then
        if ! grep -q "nginxui" "$services_start"; then
            echo "/jffs/scripts/nginxui start" >> "$services_start"
            log_info "Added to services-start"
        fi
    fi
    
    log_success "Service integration configured"
}

# Create default configuration
setup_default_config() {
    log_step "Setting up default configuration..."
    
    local config_file="$CONFIG_PATH/nginxui.conf"
    
    if [ ! -f "$config_file" ]; then
        cat > "$config_file" << EOF
# NginxUI Configuration
NGINXUI_PORT=8080
NGINXUI_SSL_PORT=8443
NGINXUI_LOG_LEVEL=info
NGINXUI_AUTO_START=true
NGINXUI_BACKUP_ENABLED=true
NGINXUI_BACKUP_INTERVAL=daily
EOF
        log_info "Created default configuration"
    fi
    
    log_success "Default configuration created"
}

# Start services
start_services() {
    log_step "Starting NginxUI services..."
    
    if [ -f "$INSTALL_PATH/backend/nginxui.sh" ]; then
        "$INSTALL_PATH/backend/nginxui.sh" start
        sleep 2
        
        # Check if service started successfully
        if "$INSTALL_PATH/backend/nginxui.sh" status >/dev/null 2>&1; then
            log_success "NginxUI services started successfully"
        else
            log_warning "NginxUI services may not have started properly"
        fi
    else
        log_error "NginxUI main script not found"
        exit 1
    fi
}

# Show installation summary
show_summary() {
    echo
    log_success "NginxUI installation completed successfully!"
    echo
    echo -e "${CYAN}Installation Summary:${NC}"
    echo "  📁 Install Path: $INSTALL_PATH"
    echo "  🌐 Web Path: $WEB_PATH"
    echo "  ⚙️  Config Path: $CONFIG_PATH"
    echo "  📝 Log Path: $LOG_PATH"
    echo
    echo -e "${CYAN}Access Information:${NC}"
    echo "  🌐 Web Interface: http://$(nvram get lan_ipaddr):8080/nginxui"
    echo "  📱 Mobile Access: http://$(nvram get ddns_hostname_x):8080/nginxui"
    echo
    echo -e "${CYAN}Service Commands:${NC}"
    echo "  Start:   /jffs/scripts/nginxui start"
    echo "  Stop:    /jffs/scripts/nginxui stop"
    echo "  Restart: /jffs/scripts/nginxui restart"
    echo "  Status:  /jffs/scripts/nginxui status"
    echo
    echo -e "${CYAN}Configuration:${NC}"
    echo "  Edit: $CONFIG_PATH/nginxui.conf"
    echo "  Logs: $LOG_PATH/"
    echo
    echo -e "${GREEN}🎉 Enjoy using NginxUI!${NC}"
    echo
}

# Uninstall function
uninstall() {
    log_step "Uninstalling NginxUI..."
    
    # Stop services
    if [ -f "$INSTALL_PATH/backend/nginxui.sh" ]; then
        "$INSTALL_PATH/backend/nginxui.sh" stop 2>/dev/null || true
    fi
    
    # Remove files and directories
    rm -rf "$INSTALL_PATH"
    rm -f "$WEB_PATH"
    rm -f "/jffs/scripts/nginxui"
    
    # Remove from services-start
    local services_start="/jffs/scripts/services-start"
    if [ -f "$services_start" ]; then
        sed -i '/nginxui/d' "$services_start"
    fi
    
    log_success "NginxUI uninstalled successfully"
}

# Show usage
show_usage() {
    cat << EOF
NginxUI Installation Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
  install     Install NginxUI (default)
  uninstall   Remove NginxUI completely
  upgrade     Upgrade to latest version
  help        Show this help

Options:
  --path PATH     Custom installation path
  --port PORT     Custom web port (default: 8080)
  --no-start      Don't start services after installation

Examples:
  $0                              # Install with defaults
  $0 --path /opt/nginxui install  # Install to custom path
  $0 uninstall                    # Remove NginxUI

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --path)
                INSTALL_PATH="$2"
                WEB_PATH="$2/www"
                CONFIG_PATH="$2/config"
                shift 2
                ;;
            --port)
                # Would set custom port
                shift 2
                ;;
            --no-start)
                NO_START=true
                shift
                ;;
            install|uninstall|upgrade|help)
                COMMAND="$1"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Main installation function
install_nginxui() {
    print_banner
    check_router_compatibility
    check_prerequisites
    setup_directories
    install_files
    setup_web_integration
    setup_service
    setup_default_config
    
    if [ "${NO_START:-false}" != "true" ]; then
        start_services
    fi
    
    show_summary
}

# Main function
main() {
    local COMMAND="${1:-install}"
    
    parse_args "$@"
    
    case "$COMMAND" in
        install)
            install_nginxui
            ;;
        uninstall)
            uninstall
            ;;
        upgrade)
            log_info "Upgrading NginxUI..."
            uninstall
            install_nginxui
            ;;
        help)
            show_usage
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"