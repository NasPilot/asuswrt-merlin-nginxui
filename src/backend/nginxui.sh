#!/bin/sh
# NginxUI Main Control Script
# Enhanced with XrayUI best practices for better system integration
# Handles all NginxUI operations and module coordination

# Version information
NGINXUI_VERSION="1.0.0"
NGINXUI_BUILD_DATE="$(date '+%Y-%m-%d')"

# Set script directory if not already set
if [ -z "$NGINXUI_SCRIPT_DIR" ]; then
    export NGINXUI_SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# Enhanced error handling
set -e
trap 'log_error "Script failed at line $LINENO"' ERR

# Import required modules with error checking
for module in "_globals.sh" "_helper.sh" "mount.sh" "service.sh" "config.sh" "webapp.sh" "install.sh"; do
    if [ -f "$NGINXUI_SCRIPT_DIR/$module" ]; then
        . "$NGINXUI_SCRIPT_DIR/$module"
    else
        echo "ERROR: Required module $module not found in $NGINXUI_SCRIPT_DIR"
        exit 1
    fi
done

# Disable error exit for normal operations
set +e

# Enhanced NginxUI control functions with better error handling and logging
start_nginxui() {
    log_info "Starting NginxUI v$NGINXUI_VERSION..."
    
    # Check if already running
    if is_webapp_running && is_service_running; then
        log_warn "NginxUI is already running"
        return 0
    fi
    
    # Create lock file to prevent concurrent operations
    local lock_file="/var/run/nginxui.lock"
    if [ -f "$lock_file" ]; then
        local lock_pid="$(cat "$lock_file" 2>/dev/null)"
        if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
            log_error "Another NginxUI operation is in progress (PID: $lock_pid)"
            return 1
        else
            rm -f "$lock_file"
        fi
    fi
    echo $$ > "$lock_file"
    
    # Cleanup function
    cleanup_start() {
        rm -f "$lock_file"
    }
    trap cleanup_start EXIT
    
    # Pre-start checks
    log_info "Performing pre-start checks..."
    if ! check_system_requirements; then
        log_error "System requirements check failed"
        return 1
    fi
    
    # Mount web interface
    log_info "Mounting web interface..."
    mount_web_interface || {
        log_error "Failed to mount web interface"
        return 1
    }
    
    # Start web application
    log_info "Starting web application..."
    start_webapp || {
        log_error "Failed to start web application"
        return 1
    }
    
    # Start Nginx service if enabled
    if [ "$(am_settings_get nginx_enabled '1')" = "1" ]; then
        log_info "Starting Nginx service..."
        start_service || {
            log_error "Failed to start Nginx service"
            return 1
        }
    else
        log_info "Nginx service is disabled, skipping..."
    fi
    
    # Post-start verification
    sleep 2
    if verify_startup; then
        log_info "NginxUI started successfully"
        log_info "Web interface available at: http://$(nvram get lan_ipaddr)/$(am_settings_get nginxui_user_page 'user1.asp')"
    else
        log_error "NginxUI startup verification failed"
        return 1
    fi
    
    return 0
}

stop_nginxui() {
    log_info "Stopping NginxUI..."
    
    # Create lock file to prevent concurrent operations
    local lock_file="/var/run/nginxui.lock"
    if [ -f "$lock_file" ]; then
        local lock_pid="$(cat "$lock_file" 2>/dev/null)"
        if [ -n "$lock_pid" ] && [ "$lock_pid" != "$$" ] && kill -0 "$lock_pid" 2>/dev/null; then
            log_error "Another NginxUI operation is in progress (PID: $lock_pid)"
            return 1
        fi
    fi
    echo $$ > "$lock_file"
    
    # Cleanup function
    cleanup_stop() {
        rm -f "$lock_file"
    }
    trap cleanup_stop EXIT
    
    # Stop Nginx service gracefully
    log_info "Stopping Nginx service..."
    if is_service_running; then
        stop_service || {
            log_warn "Failed to gracefully stop Nginx service, attempting force stop..."
            killall nginx 2>/dev/null || true
            sleep 1
        }
    else
        log_info "Nginx service is not running"
    fi
    
    # Stop web application
    log_info "Stopping web application..."
    stop_webapp || {
        log_warn "Failed to stop web application"
    }
    
    # Clean up firewall rules
    log_info "Cleaning up firewall rules..."
    cleanup_firewall_rules || {
        log_warn "Failed to clean up firewall rules"
    }
    
    # Unmount web interface
    log_info "Unmounting web interface..."
    unmount_web_interface || {
        log_warn "Failed to unmount web interface"
    }
    
    # Clean up temporary files
    cleanup_temp_files
    
    log_info "NginxUI stopped successfully"
    return 0
}

restart_nginxui() {
    log_info "Restarting NginxUI..."
    
    # Check if currently running
    local was_running=false
    if is_webapp_running || is_service_running; then
        was_running=true
    fi
    
    # Stop if running
    if [ "$was_running" = "true" ]; then
        stop_nginxui || {
            log_error "Failed to stop NginxUI during restart"
            return 1
        }
    fi
    
    # Wait for complete shutdown
    log_info "Waiting for complete shutdown..."
    local wait_count=0
    while [ $wait_count -lt 10 ] && (is_webapp_running || is_service_running); do
        sleep 1
        wait_count=$((wait_count + 1))
    done
    
    if [ $wait_count -eq 10 ]; then
        log_warn "Timeout waiting for complete shutdown, proceeding with restart"
    fi
    
    # Start again
    start_nginxui || {
        log_error "Failed to start NginxUI during restart"
        return 1
    }
    
    log_info "NginxUI restarted successfully"
    return 0
}

status_nginxui() {
    log_info "Checking NginxUI status..."
    
    local webapp_status="stopped"
    local service_status="stopped"
    local mount_status="unmounted"
    local overall_status="stopped"
    
    # Check web application status
    if is_webapp_running; then
        webapp_status="running"
    fi
    
    # Check Nginx service status
    if is_service_running; then
        service_status="running"
    fi
    
    # Check mount status
    if is_web_interface_mounted; then
        mount_status="mounted"
    fi
    
    # Output status information
    echo "NginxUI Status Report:"
    echo "  Version: $NGINXUI_VERSION"
    echo "  Web Application: $webapp_status"
    echo "  Nginx Service: $service_status"
    echo "  Web Interface: $mount_status"
    
    if [ "$webapp_status" = "running" ]; then
        local web_port=$(am_settings_get nginxui_web_port "8088")
        local web_interface=$(am_settings_get nginxui_web_interface "0.0.0.0")
        echo "  Web URL: http://$(nvram get lan_ipaddr):$web_port"
    fi
    
    # Return 0 if everything is running, 1 otherwise
    if [ "$webapp_status" = "running" ] && [ "$service_status" = "running" ] && [ "$mount_status" = "mounted" ]; then
        return 0
    else
        return 1
    fi
}

# Health check function
health_check() {
    log_info "Performing health check..."
    
    local issues=0
    
    # Check if NginxUI is enabled
    if [ "$(am_settings_get nginxui_enabled '1')" != "1" ]; then
        log_info "NginxUI is disabled"
        return 0
    fi
    
    # Check web application
    if [ "$(am_settings_get nginxui_auto_start '1')" = "1" ]; then
        if ! is_webapp_running; then
            log_warn "Web application should be running but is not"
            start_webapp || issues=$((issues + 1))
        fi
    fi
    
    # Check Nginx service
    if [ "$(am_settings_get nginx_enabled '1')" = "1" ]; then
        if ! is_service_running; then
            log_warn "Nginx service should be running but is not"
            start_service || issues=$((issues + 1))
        fi
    fi
    
    # Check web interface mount
    if ! is_web_interface_mounted; then
        log_warn "Web interface should be mounted but is not"
        mount_web_interface || issues=$((issues + 1))
    fi
    
    # Check configuration validity
    if ! validate_nginx_config >/dev/null 2>&1; then
        log_error "Nginx configuration is invalid"
        issues=$((issues + 1))
    fi
    
    # Check disk space
    local disk_usage
    disk_usage=$(df "$NGINXUI_SHARED_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        log_warn "Disk usage is high: ${disk_usage}%"
        issues=$((issues + 1))
    fi
    
    if [ "$issues" -eq 0 ]; then
        log_info "Health check passed"
        return 0
    else
        log_warn "Health check found $issues issues"
        return 1
    fi
}

# Cleanup function
cleanup() {
    log_info "Performing cleanup..."
    
    # Clean up old backup files (keep last 10)
    if [ -d "$NGINXUI_BACKUP_DIR" ]; then
        find "$NGINXUI_BACKUP_DIR" -name "*.backup.*" -type f | sort -r | tail -n +11 | xargs rm -f 2>/dev/null
        log_info "Cleaned up old backup files"
    fi
    
    # Clean up old log files
    local max_files=$(am_settings_get nginxui_log_max_files "5")
    if [ -d "$NGINXUI_LOG_DIR" ]; then
        find "$NGINXUI_LOG_DIR" -name "*.log.*" -type f | sort -r | tail -n +$((max_files + 1)) | xargs rm -f 2>/dev/null
        log_info "Cleaned up old log files"
    fi
    
    # Clean up temporary files
    if [ -d "/tmp/nginxui" ]; then
        rm -rf "/tmp/nginxui"
        log_info "Cleaned up temporary files"
    fi
    
    log_info "Cleanup completed"
    return 0
}

# Firewall rules setup
setup_firewall() {
    log_info "Setting up firewall rules..."
    
    local web_port=$(am_settings_get nginxui_web_port "8088")
    local nginx_port=$(am_settings_get nginx_port "80")
    local nginx_ssl_port=$(am_settings_get nginx_ssl_port "443")
    
    # Allow access to NginxUI web interface from LAN
    iptables -I INPUT -p tcp --dport "$web_port" -s 192.168.0.0/16 -j ACCEPT 2>/dev/null
    iptables -I INPUT -p tcp --dport "$web_port" -s 10.0.0.0/8 -j ACCEPT 2>/dev/null
    iptables -I INPUT -p tcp --dport "$web_port" -s 172.16.0.0/12 -j ACCEPT 2>/dev/null
    
    # Allow access to Nginx ports if enabled
    if [ "$(am_settings_get nginx_enabled '1')" = "1" ]; then
        iptables -I INPUT -p tcp --dport "$nginx_port" -j ACCEPT 2>/dev/null
        iptables -I INPUT -p tcp --dport "$nginx_ssl_port" -j ACCEPT 2>/dev/null
    fi
    
    log_info "Firewall rules setup completed"
    return 0
}

# Command handlers
handle_config_command() {
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        "generate")
            generate_nginx_config "$@"
            ;;
        "validate")
            validate_nginx_config "$@"
            ;;
        "backup")
            backup_nginx_config "$@"
            ;;
        "restore")
            restore_nginx_config "$@"
            ;;
        "export")
            export_nginx_config "$@"
            ;;
        "import")
            import_nginx_config "$@"
            ;;
        *)
            log_error "Unknown config command: $subcommand"
            echo "Usage: nginxui config {generate|validate|backup|restore|export|import}"
            exit 1
            ;;
    esac
}

handle_service_command() {
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        "start")
            start_service "$@"
            ;;
        "stop")
            stop_service "$@"
            ;;
        "restart")
            restart_service "$@"
            ;;
        "reload")
            reload_service "$@"
            ;;
        "status")
            get_service_status "$@"
            ;;
        *)
            log_error "Unknown service command: $subcommand"
            echo "Usage: nginxui service {start|stop|restart|reload|status}"
            exit 1
            ;;
    esac
}

handle_webapp_command() {
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        "start")
            start_webapp "$@"
            ;;
        "stop")
            stop_webapp "$@"
            ;;
        "restart")
            restart_webapp "$@"
            ;;
        "status")
            if is_webapp_running; then
                echo "Web application is running"
                return 0
            else
                echo "Web application is stopped"
                return 1
            fi
            ;;
        "init")
            init_webapp "$@"
            ;;
        "cleanup")
            cleanup_webapp "$@"
            ;;
        *)
            log_error "Unknown webapp command: $subcommand"
            echo "Usage: nginxui webapp {start|stop|restart|status|init|cleanup}"
            exit 1
            ;;
    esac
}

# Help and version functions
show_help() {
    cat << EOF
NginxUI - Nginx Management Interface for ASUSWRT-Merlin

Usage: nginxui <command> [options]

Commands:
  start                 Start NginxUI (web app + service)
  stop                  Stop NginxUI
  restart               Restart NginxUI
  status                Show NginxUI status
  
  mount                 Mount web interface
  unmount               Unmount web interface
  
  install               Install NginxUI
  uninstall [--purge]   Uninstall NginxUI
  upgrade               Upgrade NginxUI
  
  config <subcommand>   Configuration management:
    generate              Generate Nginx configuration
    validate              Validate Nginx configuration
    backup                Backup Nginx configuration
    restore               Restore Nginx configuration
    export                Export configuration
    import                Import configuration
  
  service <subcommand>  Service management:
    start                 Start Nginx service
    stop                  Stop Nginx service
    restart               Restart Nginx service
    reload                Reload Nginx configuration
    status                Show service status
  
  webapp <subcommand>   Web application management:
    start                 Start web application
    stop                  Stop web application
    restart               Restart web application
    status                Show web app status
    init                  Initialize web application
    cleanup               Cleanup web application
  
  health                Perform health check
  cleanup               Clean up old files
  firewall              Setup firewall rules
  
  help, --help, -h      Show this help message
  version, --version, -v Show version information

Examples:
  nginxui start         Start NginxUI
  nginxui status        Check status
  nginxui config generate Generate default Nginx config
  nginxui service reload Reload Nginx configuration
  nginxui uninstall --purge Remove everything

For more information, visit: https://github.com/your-repo/nginxui
EOF
}

show_version() {
    echo "NginxUI version $NGINXUI_VERSION"
    echo "For ASUSWRT-Merlin firmware"
    echo "Copyright (c) 2024"
}

# Main command dispatcher
main() {
    local command="$1"
    shift
    
    case "$command" in
        "start")
            start_nginxui "$@"
            ;;
        "stop")
            stop_nginxui "$@"
            ;;
        "restart")
            restart_nginxui "$@"
            ;;
        "status")
            status_nginxui "$@"
            ;;
        "mount")
            mount_web_interface "$@"
            ;;
        "unmount")
            unmount_web_interface "$@"
            ;;
        "install")
            install_nginxui "$@"
            ;;
        "uninstall")
            uninstall_nginxui "$@"
            ;;
        "upgrade")
            upgrade_nginxui "$@"
            ;;
        "config")
            handle_config_command "$@"
            ;;
        "service")
            handle_service_command "$@"
            ;;
        "webapp")
            handle_webapp_command "$@"
            ;;
        "health")
            health_check "$@"
            ;;
        "cleanup")
            cleanup "$@"
            ;;
        "firewall")
            setup_firewall "$@"
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        "version"|"--version"|"-v")
            show_version
            ;;
        "")
            log_error "No command specified"
            show_help
            exit 1
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
exit $?