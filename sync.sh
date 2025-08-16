#!/bin/bash

# NginxUI Sync Script - Based on XrayUI successful pattern
# This script syncs built files to the router

set -euo pipefail

# Configuration
ROUTER_IP="${ROUTER_IP:-192.168.1.1}"
ROUTER_USER="${ROUTER_USER:-admin}"
ROUTER_PATH="${ROUTER_PATH:-/jffs/addons/nginxui}"
LOCAL_DIST="./dist"
SSH_KEY="${SSH_KEY:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v scp >/dev/null 2>&1; then
        log_error "scp is required but not installed"
        exit 1
    fi
    
    if ! command -v ssh >/dev/null 2>&1; then
        log_error "ssh is required but not installed"
        exit 1
    fi
    
    if [ ! -d "$LOCAL_DIST" ]; then
        log_error "Build directory $LOCAL_DIST not found. Please run 'npm run build' first"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Test router connection
test_connection() {
    log_info "Testing connection to router..."
    
    local ssh_opts="-o ConnectTimeout=10 -o BatchMode=yes"
    if [ -n "$SSH_KEY" ]; then
        ssh_opts="$ssh_opts -i $SSH_KEY"
    fi
    
    if ssh $ssh_opts "$ROUTER_USER@$ROUTER_IP" "echo 'Connection test successful'" >/dev/null 2>&1; then
        log_success "Router connection successful"
    else
        log_error "Cannot connect to router at $ROUTER_IP"
        log_info "Please check:"
        log_info "  - Router IP: $ROUTER_IP"
        log_info "  - Router User: $ROUTER_USER"
        log_info "  - SSH access is enabled"
        log_info "  - SSH key is configured (if using key auth)"
        exit 1
    fi
}

# Create remote directory structure
setup_remote_dirs() {
    log_info "Setting up remote directory structure..."
    
    local ssh_opts="-o ConnectTimeout=10"
    if [ -n "$SSH_KEY" ]; then
        ssh_opts="$ssh_opts -i $SSH_KEY"
    fi
    
    ssh $ssh_opts "$ROUTER_USER@$ROUTER_IP" "
        mkdir -p $ROUTER_PATH/www
        mkdir -p $ROUTER_PATH/backend
        mkdir -p $ROUTER_PATH/logs
    " || {
        log_error "Failed to create remote directories"
        exit 1
    }
    
    log_success "Remote directories created"
}

# Sync files to router
sync_files() {
    log_info "Syncing files to router..."
    
    local scp_opts="-r -o ConnectTimeout=30"
    if [ -n "$SSH_KEY" ]; then
        scp_opts="$scp_opts -i $SSH_KEY"
    fi
    
    # Sync web files
    log_info "Syncing web files..."
    scp $scp_opts "$LOCAL_DIST/"* "$ROUTER_USER@$ROUTER_IP:$ROUTER_PATH/www/" || {
        log_error "Failed to sync web files"
        exit 1
    }
    
    # Sync backend scripts
    if [ -d "src/backend" ]; then
        log_info "Syncing backend scripts..."
        scp $scp_opts src/backend/*.sh "$ROUTER_USER@$ROUTER_IP:$ROUTER_PATH/backend/" || {
            log_error "Failed to sync backend scripts"
            exit 1
        }
        
        # Make scripts executable
        ssh $ssh_opts "$ROUTER_USER@$ROUTER_IP" "
            chmod +x $ROUTER_PATH/backend/*.sh
        " || {
            log_warning "Failed to make scripts executable"
        }
    fi
    
    log_success "Files synced successfully"
}

# Restart service on router
restart_service() {
    log_info "Restarting NginxUI service on router..."
    
    local ssh_opts="-o ConnectTimeout=10"
    if [ -n "$SSH_KEY" ]; then
        ssh_opts="$ssh_opts -i $SSH_KEY"
    fi
    
    ssh $ssh_opts "$ROUTER_USER@$ROUTER_IP" "
        if [ -f $ROUTER_PATH/backend/nginxui.sh ]; then
            $ROUTER_PATH/backend/nginxui.sh stop 2>/dev/null || true
            sleep 2
            $ROUTER_PATH/backend/nginxui.sh start
        else
            echo 'NginxUI script not found, skipping service restart'
        fi
    " || {
        log_warning "Failed to restart service"
    }
    
    log_success "Service restart completed"
}

# Show usage
show_usage() {
    cat << EOF
NginxUI Sync Script

Usage: $0 [OPTIONS] [COMMAND]

Commands:
  sync      Sync files to router (default)
  test      Test router connection only
  setup     Setup remote directories only
  restart   Restart service only
  help      Show this help

Options:
  -h, --host HOST     Router IP address (default: 192.168.1.1)
  -u, --user USER     Router username (default: admin)
  -p, --path PATH     Remote path (default: /jffs/addons/nginxui)
  -k, --key KEY       SSH private key file
  --help              Show this help

Environment Variables:
  ROUTER_IP           Router IP address
  ROUTER_USER         Router username
  ROUTER_PATH         Remote installation path
  SSH_KEY             SSH private key file path

Examples:
  $0                                    # Sync with default settings
  $0 -h 192.168.50.1 -u root sync     # Sync to custom router
  $0 test                              # Test connection only
  ROUTER_IP=192.168.1.1 $0 sync       # Use environment variable

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--host)
                ROUTER_IP="$2"
                shift 2
                ;;
            -u|--user)
                ROUTER_USER="$2"
                shift 2
                ;;
            -p|--path)
                ROUTER_PATH="$2"
                shift 2
                ;;
            -k|--key)
                SSH_KEY="$2"
                shift 2
                ;;
            --help)
                show_usage
                exit 0
                ;;
            test|setup|restart|sync|help)
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

# Main function
main() {
    local COMMAND="${1:-sync}"
    
    parse_args "$@"
    
    case "$COMMAND" in
        test)
            check_prerequisites
            test_connection
            ;;
        setup)
            check_prerequisites
            test_connection
            setup_remote_dirs
            ;;
        restart)
            test_connection
            restart_service
            ;;
        sync)
            check_prerequisites
            test_connection
            setup_remote_dirs
            sync_files
            restart_service
            log_success "NginxUI sync completed successfully!"
            log_info "Access your NginxUI at: http://$ROUTER_IP/nginxui.asp"
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