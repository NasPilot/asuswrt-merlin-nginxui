#!/bin/bash

# NginxUI Development Script - Based on XrayUI successful pattern
# This script provides development and debugging utilities

set -euo pipefail

# Configuration
CONFIG_FILE="./config.json"
PORT="${DEV_PORT:-3000}"
HOST="${DEV_HOST:-localhost}"
ROUTER_IP="${ROUTER_IP:-192.168.1.1}"

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

log_debug() {
    echo -e "${MAGENTA}[DEBUG]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log_info "Loading configuration from $CONFIG_FILE"
        # Extract values using basic JSON parsing
        if command -v jq >/dev/null 2>&1; then
            PORT=$(jq -r '.development.port // 3000' "$CONFIG_FILE")
            HOST=$(jq -r '.development.host // "localhost"' "$CONFIG_FILE")
            ROUTER_IP=$(jq -r '.router.defaultIP // "192.168.1.1"' "$CONFIG_FILE")
        else
            log_warning "jq not found, using default configuration"
        fi
    else
        log_warning "Configuration file not found, using defaults"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local missing_deps=()
    
    if ! command -v node >/dev/null 2>&1; then
        missing_deps+=("node")
    fi
    
    if ! command -v npm >/dev/null 2>&1; then
        missing_deps+=("npm")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi
    
    if [ ! -f "package.json" ]; then
        log_error "package.json not found. Are you in the project root?"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Install dependencies
install_deps() {
    log_step "Installing dependencies..."
    
    if [ ! -d "node_modules" ] || [ "package.json" -nt "node_modules" ]; then
        npm install
        log_success "Dependencies installed"
    else
        log_info "Dependencies are up to date"
    fi
}

# Start development server
start_dev_server() {
    log_step "Starting development server..."
    log_info "Server will be available at: http://$HOST:$PORT"
    log_info "Press Ctrl+C to stop the server"
    
    npm run dev
}

# Build project
build_project() {
    log_step "Building project..."
    
    npm run build
    
    if [ -d "dist" ]; then
        log_success "Build completed successfully"
        log_info "Build output: $(du -sh dist | cut -f1)"
    else
        log_error "Build failed - dist directory not found"
        exit 1
    fi
}

# Watch mode
watch_mode() {
    log_step "Starting watch mode..."
    log_info "Watching for file changes..."
    log_info "Press Ctrl+C to stop watching"
    
    npm run watch
}

# Preview built project
preview_build() {
    log_step "Starting preview server..."
    
    if [ ! -d "dist" ]; then
        log_warning "Build not found, building first..."
        build_project
    fi
    
    log_info "Preview server will be available at: http://$HOST:4173"
    npm run preview
}

# Test router connection
test_router() {
    log_step "Testing router connection..."
    
    if ping -c 1 "$ROUTER_IP" >/dev/null 2>&1; then
        log_success "Router is reachable at $ROUTER_IP"
        
        # Test HTTP connection
        if curl -s --connect-timeout 5 "http://$ROUTER_IP" >/dev/null 2>&1; then
            log_success "HTTP service is running on router"
        else
            log_warning "HTTP service may not be running on router"
        fi
        
        # Test SSH connection
        if nc -z "$ROUTER_IP" 22 2>/dev/null; then
            log_success "SSH service is available on router"
        else
            log_warning "SSH service may not be available on router"
        fi
    else
        log_error "Router is not reachable at $ROUTER_IP"
        log_info "Please check:"
        log_info "  - Router IP address: $ROUTER_IP"
        log_info "  - Network connectivity"
        log_info "  - Router is powered on"
    fi
}

# Analyze bundle
analyze_bundle() {
    log_step "Analyzing bundle..."
    
    npm run analyze
    
    if [ -f "dist/stats.html" ]; then
        log_success "Bundle analysis completed"
        log_info "Opening analysis report..."
        
        if command -v open >/dev/null 2>&1; then
            open "dist/stats.html"
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "dist/stats.html"
        else
            log_info "Please open dist/stats.html in your browser"
        fi
    else
        log_error "Bundle analysis failed"
    fi
}

# Clean project
clean_project() {
    log_step "Cleaning project..."
    
    local cleaned=()
    
    if [ -d "dist" ]; then
        rm -rf dist
        cleaned+=("dist")
    fi
    
    if [ -d "node_modules/.vite" ]; then
        rm -rf node_modules/.vite
        cleaned+=("vite cache")
    fi
    
    if [ -d "logs" ]; then
        rm -rf logs
        cleaned+=("logs")
    fi
    
    if [ ${#cleaned[@]} -gt 0 ]; then
        log_success "Cleaned: ${cleaned[*]}"
    else
        log_info "Nothing to clean"
    fi
}

# Show project status
show_status() {
    log_step "Project Status"
    
    echo
    echo "📁 Project Information:"
    echo "   Name: $(jq -r '.name // "NginxUI"' package.json 2>/dev/null || echo "NginxUI")"
    echo "   Version: $(jq -r '.version // "unknown"' package.json 2>/dev/null || echo "unknown")"
    echo "   Node: $(node --version 2>/dev/null || echo "not found")"
    echo "   NPM: $(npm --version 2>/dev/null || echo "not found")"
    
    echo
    echo "📦 Dependencies:"
    if [ -d "node_modules" ]; then
        echo "   Status: ✅ Installed"
        echo "   Size: $(du -sh node_modules 2>/dev/null | cut -f1 || echo "unknown")"
    else
        echo "   Status: ❌ Not installed"
    fi
    
    echo
    echo "🏗️  Build:"
    if [ -d "dist" ]; then
        echo "   Status: ✅ Built"
        echo "   Size: $(du -sh dist 2>/dev/null | cut -f1 || echo "unknown")"
        echo "   Files: $(find dist -type f | wc -l | tr -d ' ')"
    else
        echo "   Status: ❌ Not built"
    fi
    
    echo
    echo "🌐 Network:"
    echo "   Router IP: $ROUTER_IP"
    echo "   Dev Server: http://$HOST:$PORT"
    
    echo
}

# Show usage
show_usage() {
    cat << EOF
NginxUI Development Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
  dev         Start development server (default)
  build       Build project for production
  watch       Build project in watch mode
  preview     Preview built project
  test        Test router connection
  analyze     Analyze bundle size
  clean       Clean build artifacts
  status      Show project status
  install     Install dependencies
  help        Show this help

Options:
  --port PORT     Development server port (default: 3000)
  --host HOST     Development server host (default: localhost)
  --router IP     Router IP address (default: 192.168.1.1)

Environment Variables:
  DEV_PORT        Development server port
  DEV_HOST        Development server host
  ROUTER_IP       Router IP address

Examples:
  $0                          # Start development server
  $0 build                    # Build for production
  $0 --port 8080 dev         # Start dev server on port 8080
  $0 --router 192.168.50.1 test  # Test custom router IP
  ROUTER_IP=192.168.1.1 $0 test   # Use environment variable

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --port)
                PORT="$2"
                shift 2
                ;;
            --host)
                HOST="$2"
                shift 2
                ;;
            --router)
                ROUTER_IP="$2"
                shift 2
                ;;
            dev|build|watch|preview|test|analyze|clean|status|install|help)
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
    local COMMAND="${1:-dev}"
    
    parse_args "$@"
    load_config
    
    case "$COMMAND" in
        dev)
            check_prerequisites
            install_deps
            start_dev_server
            ;;
        build)
            check_prerequisites
            install_deps
            build_project
            ;;
        watch)
            check_prerequisites
            install_deps
            watch_mode
            ;;
        preview)
            check_prerequisites
            preview_build
            ;;
        test)
            test_router
            ;;
        analyze)
            check_prerequisites
            install_deps
            analyze_bundle
            ;;
        clean)
            clean_project
            ;;
        status)
            show_status
            ;;
        install)
            check_prerequisites
            install_deps
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