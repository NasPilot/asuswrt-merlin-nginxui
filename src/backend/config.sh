#!/bin/sh
# NginxUI Configuration Management Module
# Handles Nginx configuration generation, validation, and management

# Import required modules
. "$NGINXUI_SCRIPT_DIR/_globals.sh"
. "$NGINXUI_SCRIPT_DIR/_helper.sh"

# Configuration management functions
generate_config() {
    local config_type="$1"
    
    log_info "Generating Nginx configuration: $config_type"
    
    case "$config_type" in
    "basic")
        generate_basic_config
        ;;
    "ssl")
        generate_ssl_config
        ;;
    "proxy")
        generate_proxy_config
        ;;
    "static")
        generate_static_config
        ;;
    *)
        log_error "Unknown configuration type: $config_type"
        return 1
        ;;
    esac
}

generate_basic_config() {
    log_info "Generating basic Nginx configuration..."
    
    local http_port
    local server_name
    local document_root
    
    http_port=$(am_settings_get nginxui_http_port "80")
    server_name=$(am_settings_get nginxui_server_name "_")
    document_root=$(am_settings_get nginxui_document_root "/opt/share/nginx/html")
    
    # Ensure directories exist
    mkdir -p "$(dirname "$NGINX_CONFIG_FILE")"
    mkdir -p "$NGINX_CONFIG_DIR/conf.d"
    mkdir -p "$document_root"
    
    # Generate main configuration
    cat > "$NGINX_CONFIG_FILE" << EOF
# NginxUI Basic Configuration
# Generated on: $(date)

user nobody;
worker_processes ${NGINX_WORKER_PROCESSES:-auto};
error_log ${NGINX_ERROR_LOG} warn;
pid ${NGINX_PID_FILE};

events {
    worker_connections ${NGINX_WORKER_CONNECTIONS:-1024};
    use epoll;
}

http {
    include /opt/etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log ${NGINX_ACCESS_LOG} main;
    
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout ${NGINX_KEEPALIVE_TIMEOUT:-65};
    types_hash_max_size 2048;
    client_max_body_size ${NGINX_CLIENT_MAX_BODY_SIZE:-1m};
    
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
    
    # Basic server block
    server {
        listen $http_port default_server;
        listen [::]:$http_port default_server;
        server_name $server_name;
        
        root $document_root;
        index index.html index.htm;
        
        location / {
            try_files \$uri \$uri/ =404;
        }
        
        # Status page
        location /nginx_status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            allow ::1;
            deny all;
        }
        
        # Error pages
        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root $document_root;
        }
    }
    
    # Include additional configurations
    include ${NGINX_CONFIG_DIR}/conf.d/*.conf;
}
EOF
    
    log_info "Basic configuration generated successfully"
}

generate_ssl_config() {
    log_info "Generating SSL Nginx configuration..."
    
    local http_port
    local https_port
    local server_name
    local document_root
    local ssl_cert
    local ssl_key
    
    http_port=$(am_settings_get nginxui_http_port "80")
    https_port=$(am_settings_get nginxui_https_port "443")
    server_name=$(am_settings_get nginxui_server_name "_")
    document_root=$(am_settings_get nginxui_document_root "/opt/share/nginx/html")
    ssl_cert=$(am_settings_get nginxui_ssl_cert "/opt/etc/nginx/ssl/server.crt")
    ssl_key=$(am_settings_get nginxui_ssl_key "/opt/etc/nginx/ssl/server.key")
    
    # Generate SSL certificates if they don't exist
    if [ ! -f "$ssl_cert" ] || [ ! -f "$ssl_key" ]; then
        generate_self_signed_cert "$ssl_cert" "$ssl_key"
    fi
    
    # Ensure directories exist
    mkdir -p "$(dirname "$NGINX_CONFIG_FILE")"
    mkdir -p "$NGINX_CONFIG_DIR/conf.d"
    mkdir -p "$document_root"
    
    # Generate SSL configuration
    cat > "$NGINX_CONFIG_FILE" << EOF
# NginxUI SSL Configuration
# Generated on: $(date)

user nobody;
worker_processes ${NGINX_WORKER_PROCESSES:-auto};
error_log ${NGINX_ERROR_LOG} warn;
pid ${NGINX_PID_FILE};

events {
    worker_connections ${NGINX_WORKER_CONNECTIONS:-1024};
    use epoll;
}

http {
    include /opt/etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log ${NGINX_ACCESS_LOG} main;
    
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout ${NGINX_KEEPALIVE_TIMEOUT:-65};
    types_hash_max_size 2048;
    client_max_body_size ${NGINX_CLIENT_MAX_BODY_SIZE:-1m};
    
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
    
    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ${NGINX_SSL_CIPHERS};
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # HTTP server (redirect to HTTPS)
    server {
        listen $http_port default_server;
        listen [::]:$http_port default_server;
        server_name $server_name;
        
        # Redirect all HTTP traffic to HTTPS
        return 301 https://\$server_name:\$request_uri;
    }
    
    # HTTPS server
    server {
        listen $https_port ssl default_server;
        listen [::]:$https_port ssl default_server;
        server_name $server_name;
        
        # SSL configuration
        ssl_certificate $ssl_cert;
        ssl_certificate_key $ssl_key;
        
        root $document_root;
        index index.html index.htm;
        
        location / {
            try_files \$uri \$uri/ =404;
        }
        
        # Status page
        location /nginx_status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            allow ::1;
            deny all;
        }
        
        # Error pages
        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root $document_root;
        }
    }
    
    # Include additional configurations
    include ${NGINX_CONFIG_DIR}/conf.d/*.conf;
}
EOF
    
    log_info "SSL configuration generated successfully"
}

generate_proxy_config() {
    log_info "Generating proxy Nginx configuration..."
    
    local http_port
    local server_name
    local upstream_host
    local upstream_port
    
    http_port=$(am_settings_get nginxui_http_port "80")
    server_name=$(am_settings_get nginxui_server_name "_")
    upstream_host=$(am_settings_get nginxui_upstream_host "127.0.0.1")
    upstream_port=$(am_settings_get nginxui_upstream_port "8080")
    
    # Ensure directories exist
    mkdir -p "$(dirname "$NGINX_CONFIG_FILE")"
    mkdir -p "$NGINX_CONFIG_DIR/conf.d"
    
    # Generate proxy configuration
    cat > "$NGINX_CONFIG_FILE" << EOF
# NginxUI Proxy Configuration
# Generated on: $(date)

user nobody;
worker_processes ${NGINX_WORKER_PROCESSES:-auto};
error_log ${NGINX_ERROR_LOG} warn;
pid ${NGINX_PID_FILE};

events {
    worker_connections ${NGINX_WORKER_CONNECTIONS:-1024};
    use epoll;
}

http {
    include /opt/etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log ${NGINX_ACCESS_LOG} main;
    
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout ${NGINX_KEEPALIVE_TIMEOUT:-65};
    types_hash_max_size 2048;
    client_max_body_size ${NGINX_CLIENT_MAX_BODY_SIZE:-1m};
    
    # Proxy settings
    proxy_connect_timeout 30s;
    proxy_send_timeout 30s;
    proxy_read_timeout 30s;
    proxy_buffer_size 4k;
    proxy_buffers 8 4k;
    proxy_busy_buffers_size 8k;
    
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
    
    # Upstream definition
    upstream backend {
        server $upstream_host:$upstream_port;
    }
    
    # Proxy server
    server {
        listen $http_port default_server;
        listen [::]:$http_port default_server;
        server_name $server_name;
        
        location / {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
        
        # Status page
        location /nginx_status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            allow ::1;
            deny all;
        }
    }
    
    # Include additional configurations
    include ${NGINX_CONFIG_DIR}/conf.d/*.conf;
}
EOF
    
    log_info "Proxy configuration generated successfully"
}

generate_static_config() {
    log_info "Generating static file serving Nginx configuration..."
    
    local http_port
    local server_name
    local document_root
    local enable_autoindex
    
    http_port=$(am_settings_get nginxui_http_port "80")
    server_name=$(am_settings_get nginxui_server_name "_")
    document_root=$(am_settings_get nginxui_document_root "/opt/share/nginx/html")
    enable_autoindex=$(am_settings_get nginxui_autoindex "off")
    
    # Ensure directories exist
    mkdir -p "$(dirname "$NGINX_CONFIG_FILE")"
    mkdir -p "$NGINX_CONFIG_DIR/conf.d"
    mkdir -p "$document_root"
    
    # Generate static file configuration
    cat > "$NGINX_CONFIG_FILE" << EOF
# NginxUI Static File Configuration
# Generated on: $(date)

user nobody;
worker_processes ${NGINX_WORKER_PROCESSES:-auto};
error_log ${NGINX_ERROR_LOG} warn;
pid ${NGINX_PID_FILE};

events {
    worker_connections ${NGINX_WORKER_CONNECTIONS:-1024};
    use epoll;
}

http {
    include /opt/etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log ${NGINX_ACCESS_LOG} main;
    
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout ${NGINX_KEEPALIVE_TIMEOUT:-65};
    types_hash_max_size 2048;
    client_max_body_size ${NGINX_CLIENT_MAX_BODY_SIZE:-1m};
    
    # Static file optimization
    open_file_cache max=1000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
    
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
    
    # Static file server
    server {
        listen $http_port default_server;
        listen [::]:$http_port default_server;
        server_name $server_name;
        
        root $document_root;
        index index.html index.htm;
        autoindex $enable_autoindex;
        
        # Static file handling
        location / {
            try_files \$uri \$uri/ =404;
            
            # Cache static files
            location ~* \.(jpg|jpeg|png|gif|ico|css|js)\$ {
                expires 1y;
                add_header Cache-Control "public, immutable";
            }
        }
        
        # Status page
        location /nginx_status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            allow ::1;
            deny all;
        }
        
        # Error pages
        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
            root $document_root;
        }
    }
    
    # Include additional configurations
    include ${NGINX_CONFIG_DIR}/conf.d/*.conf;
}
EOF
    
    log_info "Static file configuration generated successfully"
}

generate_self_signed_cert() {
    local cert_file="$1"
    local key_file="$2"
    
    log_info "Generating self-signed SSL certificate..."
    
    # Ensure SSL directory exists
    mkdir -p "$(dirname "$cert_file")"
    mkdir -p "$(dirname "$key_file")"
    
    # Generate private key
    openssl genrsa -out "$key_file" 2048 || {
        log_error "Failed to generate private key"
        return 1
    }
    
    # Generate certificate
    openssl req -new -x509 -key "$key_file" -out "$cert_file" -days 365 \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" || {
        log_error "Failed to generate certificate"
        return 1
    }
    
    # Set proper permissions
    chmod 600 "$key_file"
    chmod 644 "$cert_file"
    
    log_info "Self-signed SSL certificate generated successfully"
}

backup_config() {
    log_info "Backing up Nginx configuration..."
    
    local backup_dir="$NGINXUI_BACKUP_DIR/$(date +%Y%m%d_%H%M%S)"
    
    mkdir -p "$backup_dir"
    
    # Backup main configuration
    if [ -f "$NGINX_CONFIG_FILE" ]; then
        cp "$NGINX_CONFIG_FILE" "$backup_dir/nginx.conf" || {
            log_error "Failed to backup main configuration"
            return 1
        }
    fi
    
    # Backup configuration directory
    if [ -d "$NGINX_CONFIG_DIR" ]; then
        cp -r "$NGINX_CONFIG_DIR" "$backup_dir/" || {
            log_error "Failed to backup configuration directory"
            return 1
        }
    fi
    
    # Backup NginxUI settings
    if [ -f "$NGINXUI_CONFIG_FILE" ]; then
        cp "$NGINXUI_CONFIG_FILE" "$backup_dir/nginxui.conf" || {
            log_warn "Failed to backup NginxUI settings"
        }
    fi
    
    log_info "Configuration backup completed: $backup_dir"
    echo "$backup_dir"
}

restore_config() {
    local backup_dir="$1"
    
    if [ ! -d "$backup_dir" ]; then
        log_error "Backup directory not found: $backup_dir"
        return 1
    fi
    
    log_info "Restoring Nginx configuration from: $backup_dir"
    
    # Stop Nginx before restoring
    if is_nginx_running; then
        log_info "Stopping Nginx for configuration restore..."
        stop_service
    fi
    
    # Restore main configuration
    if [ -f "$backup_dir/nginx.conf" ]; then
        cp "$backup_dir/nginx.conf" "$NGINX_CONFIG_FILE" || {
            log_error "Failed to restore main configuration"
            return 1
        }
    fi
    
    # Restore configuration directory
    if [ -d "$backup_dir/nginx" ]; then
        rm -rf "$NGINX_CONFIG_DIR"
        cp -r "$backup_dir/nginx" "$NGINX_CONFIG_DIR" || {
            log_error "Failed to restore configuration directory"
            return 1
        }
    fi
    
    # Restore NginxUI settings
    if [ -f "$backup_dir/nginxui.conf" ]; then
        cp "$backup_dir/nginxui.conf" "$NGINXUI_CONFIG_FILE" || {
            log_warn "Failed to restore NginxUI settings"
        }
    fi
    
    # Validate restored configuration
    if ! validate_nginx_config; then
        log_error "Restored configuration is invalid"
        return 1
    fi
    
    log_info "Configuration restore completed successfully"
}

list_backups() {
    log_info "Listing available configuration backups..."
    
    if [ ! -d "$NGINXUI_BACKUP_DIR" ]; then
        log_info "No backups found"
        return 0
    fi
    
    find "$NGINXUI_BACKUP_DIR" -maxdepth 1 -type d -name "[0-9]*" | sort -r | while read -r backup_dir; do
        local backup_name
        backup_name=$(basename "$backup_dir")
        local backup_date
        backup_date=$(echo "$backup_name" | sed 's/_/ /')
        
        echo "$backup_name - $backup_date"
    done
}

cleanup_old_backups() {
    local keep_count="${1:-5}"
    
    log_info "Cleaning up old configuration backups (keeping $keep_count)..."
    
    if [ ! -d "$NGINXUI_BACKUP_DIR" ]; then
        log_debug "No backup directory found"
        return 0
    fi
    
    # Remove old backups, keeping only the specified number
    find "$NGINXUI_BACKUP_DIR" -maxdepth 1 -type d -name "[0-9]*" | sort -r | tail -n +$((keep_count + 1)) | while read -r backup_dir; do
        log_debug "Removing old backup: $(basename "$backup_dir")"
        rm -rf "$backup_dir"
    done
    
    log_info "Old backup cleanup completed"
}

# Configuration validation functions
validate_config_syntax() {
    log_info "Validating Nginx configuration syntax..."
    
    "$NGINX_BIN" -t -c "$NGINX_CONFIG_FILE" 2>&1 | while read -r line; do
        echo "$line"
    done
}

test_config() {
    log_info "Testing Nginx configuration..."
    
    if validate_nginx_config; then
        log_info "Configuration test passed"
        return 0
    else
        log_error "Configuration test failed"
        return 1
    fi
}

# Configuration export/import functions
export_config() {
    local export_file="$1"
    
    if [ -z "$export_file" ]; then
        export_file="$NGINXUI_SHARED_DIR/nginx_config_export_$(date +%Y%m%d_%H%M%S).tar.gz"
    fi
    
    log_info "Exporting Nginx configuration to: $export_file"
    
    # Create temporary directory for export
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Copy configuration files
    mkdir -p "$temp_dir/nginx"
    cp "$NGINX_CONFIG_FILE" "$temp_dir/nginx.conf" 2>/dev/null || true
    cp -r "$NGINX_CONFIG_DIR"/* "$temp_dir/nginx/" 2>/dev/null || true
    cp "$NGINXUI_CONFIG_FILE" "$temp_dir/nginxui.conf" 2>/dev/null || true
    
    # Create archive
    tar -czf "$export_file" -C "$temp_dir" . || {
        log_error "Failed to create configuration export"
        rm -rf "$temp_dir"
        return 1
    }
    
    # Cleanup
    rm -rf "$temp_dir"
    
    log_info "Configuration export completed: $export_file"
    echo "$export_file"
}

import_config() {
    local import_file="$1"
    
    if [ ! -f "$import_file" ]; then
        log_error "Import file not found: $import_file"
        return 1
    fi
    
    log_info "Importing Nginx configuration from: $import_file"
    
    # Create backup before import
    local backup_dir
    backup_dir=$(backup_config)
    
    # Create temporary directory for import
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Extract archive
    tar -xzf "$import_file" -C "$temp_dir" || {
        log_error "Failed to extract configuration import"
        rm -rf "$temp_dir"
        return 1
    }
    
    # Stop Nginx before import
    if is_nginx_running; then
        log_info "Stopping Nginx for configuration import..."
        stop_service
    fi
    
    # Import configuration files
    if [ -f "$temp_dir/nginx.conf" ]; then
        cp "$temp_dir/nginx.conf" "$NGINX_CONFIG_FILE" || {
            log_error "Failed to import main configuration"
            restore_config "$backup_dir"
            rm -rf "$temp_dir"
            return 1
        }
    fi
    
    if [ -d "$temp_dir/nginx" ]; then
        rm -rf "$NGINX_CONFIG_DIR"
        cp -r "$temp_dir/nginx" "$NGINX_CONFIG_DIR" || {
            log_error "Failed to import configuration directory"
            restore_config "$backup_dir"
            rm -rf "$temp_dir"
            return 1
        }
    fi
    
    if [ -f "$temp_dir/nginxui.conf" ]; then
        cp "$temp_dir/nginxui.conf" "$NGINXUI_CONFIG_FILE" || {
            log_warn "Failed to import NginxUI settings"
        }
    fi
    
    # Validate imported configuration
    if ! validate_nginx_config; then
        log_error "Imported configuration is invalid, restoring backup"
        restore_config "$backup_dir"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    log_info "Configuration import completed successfully"
}