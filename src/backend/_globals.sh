#!/bin/sh

# Global variables and paths for NGINXUI

# Version
NGINXUI_VERSION="1.0.0"

# Paths
NGINXUI_WEB_DIR="/www/user/nginxui"
NGINXUI_SCRIPT_DIR="/jffs/addons/nginxui"
NGINXUI_SHARED_DIR="/jffs/shared/nginxui"
NGINXUI_LOG_DIR="/opt/var/log/nginxui"
NGINXUI_CONFIG_DIR="/opt/etc/nginxui"
NGINXUI_BACKUP_DIR="/opt/var/backups/nginxui"

# Files
NGINXUI_CONF="$NGINXUI_CONFIG_DIR/nginxui.conf"
NGINXUI_LOG="$NGINXUI_LOG_DIR/nginxui.log"
NGINXUI_PID="/opt/var/run/nginxui.pid"
NGINXUI_LOCK="/var/lock/nginxui.lock"

# Nginx paths
NGINX_BIN="/opt/sbin/nginx"
NGINX_CONF_DIR="/opt/etc/nginx"
NGINX_CONF="$NGINX_CONF_DIR/nginx.conf"
NGINX_PID="/opt/var/run/nginx.pid"
NGINX_LOG_DIR="/opt/var/log/nginx"
NGINX_ACCESS_LOG="$NGINX_LOG_DIR/access.log"
NGINX_ERROR_LOG="$NGINX_LOG_DIR/error.log"

# Default configuration
NGINXUI_DEFAULT_PORT="80"
NGINXUI_DEFAULT_SSL_PORT="443"
NGINXUI_DEFAULT_WORKER_PROCESSES="auto"
NGINXUI_DEFAULT_WORKER_CONNECTIONS="1024"
NGINXUI_DEFAULT_KEEPALIVE_TIMEOUT="65"
NGINXUI_DEFAULT_CLIENT_MAX_BODY_SIZE="1m"

# SSL cipher suites
NGINXUI_SSL_CIPHERS_MODERN="ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384"
NGINXUI_SSL_CIPHERS_INTERMEDIATE="ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS"
NGINXUI_SSL_CIPHERS_OLD="ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" | tee -a "$NGINXUI_LOG"
}

log_warn() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $1" | tee -a "$NGINXUI_LOG"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" | tee -a "$NGINXUI_LOG"
}

log_debug() {
    if [ "$NGINXUI_DEBUG" = "1" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $1" | tee -a "$NGINXUI_LOG"
    fi
}

# Utility functions
print_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

print_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if file exists and is readable
file_readable() {
    [ -f "$1" ] && [ -r "$1" ]
}

# Check if directory exists and is writable
dir_writable() {
    [ -d "$1" ] && [ -w "$1" ]
}

# Create directory if it doesn't exist
ensure_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1" 2>/dev/null || {
            log_error "Failed to create directory: $1"
            return 1
        }
    fi
    return 0
}

# Check if nginx is installed
check_nginx() {
    if ! command_exists "$NGINX_BIN"; then
        log_error "Nginx is not installed or not found at $NGINX_BIN"
        return 1
    fi
    return 0
}

# Check if nginx is running
nginx_running() {
    if [ -f "$NGINX_PID" ]; then
        local pid
        pid=$(cat "$NGINX_PID" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

# Get nginx version
get_nginx_version() {
    if check_nginx; then
        "$NGINX_BIN" -v 2>&1 | sed 's/.*nginx\///; s/ .*//' 2>/dev/null || echo "unknown"
    else
        echo "not installed"
    fi
}

# Validate port number
validate_port() {
    local port="$1"
    if [ -z "$port" ] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi
    return 0
}

# Validate IP address
validate_ip() {
    local ip="$1"
    echo "$ip" | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' >/dev/null 2>&1
}

# Validate domain name
validate_domain() {
    local domain="$1"
    echo "$domain" | grep -E '^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$' >/dev/null 2>&1
}

# Initialize directories
init_dirs() {
    ensure_dir "$NGINXUI_WEB_DIR" || return 1
    ensure_dir "$NGINXUI_SCRIPT_DIR" || return 1
    ensure_dir "$NGINXUI_SHARED_DIR" || return 1
    ensure_dir "$NGINXUI_LOG_DIR" || return 1
    ensure_dir "$NGINXUI_CONFIG_DIR" || return 1
    ensure_dir "$NGINXUI_BACKUP_DIR" || return 1
    ensure_dir "$NGINX_CONF_DIR" || return 1
    ensure_dir "$NGINX_LOG_DIR" || return 1
    return 0
}

# Export variables for use in other scripts
export NGINXUI_VERSION
export NGINXUI_WEB_DIR NGINXUI_SCRIPT_DIR NGINXUI_SHARED_DIR NGINXUI_LOG_DIR NGINXUI_CONFIG_DIR NGINXUI_BACKUP_DIR
export NGINXUI_CONF NGINXUI_LOG NGINXUI_PID NGINXUI_LOCK
export NGINX_BIN NGINX_CONF_DIR NGINX_CONF NGINX_PID NGINX_LOG_DIR NGINX_ACCESS_LOG NGINX_ERROR_LOG
export NGINXUI_DEFAULT_PORT NGINXUI_DEFAULT_SSL_PORT NGINXUI_DEFAULT_WORKER_PROCESSES NGINXUI_DEFAULT_WORKER_CONNECTIONS
export NGINXUI_DEFAULT_KEEPALIVE_TIMEOUT NGINXUI_DEFAULT_CLIENT_MAX_BODY_SIZE
export NGINXUI_SSL_CIPHERS_MODERN NGINXUI_SSL_CIPHERS_INTERMEDIATE NGINXUI_SSL_CIPHERS_OLD