#!/bin/sh

# NGINXUI Log Manager Script

# Source global variables
. "$(dirname "$0")/_globals.sh"

# Log management functions
get_logs() {
    local log_type="$1"
    local lines="$2"
    local search="$3"
    
    # Default values
    if [ -z "$lines" ] || [ "$lines" = "null" ]; then
        lines=100
    fi
    
    log_info "Retrieving $log_type logs (last $lines lines)"
    
    case "$log_type" in
        "access")
            get_access_logs "$lines" "$search"
            ;;
        "error")
            get_error_logs "$lines" "$search"
            ;;
        "nginxui")
            get_nginxui_logs "$lines" "$search"
            ;;
        "all")
            get_all_logs "$lines" "$search"
            ;;
        *)
            log_error "Unknown log type: $log_type"
            echo '{"status":"error","message":"Unknown log type","data":{}}'
            return 1
            ;;
    esac
}

get_access_logs() {
    local lines="$1"
    local search="$2"
    
    local log_file="$NGINX_ACCESS_LOG"
    local logs="[]"
    
    if [ -f "$log_file" ]; then
        local raw_logs
        
        if [ -n "$search" ] && [ "$search" != "null" ]; then
            raw_logs=$(grep -i "$search" "$log_file" | tail -n "$lines" 2>/dev/null || echo "")
        else
            raw_logs=$(tail -n "$lines" "$log_file" 2>/dev/null || echo "")
        fi
        
        if [ -n "$raw_logs" ]; then
            logs=$(echo "$raw_logs" | awk '{
                gsub(/"/, "\\\"")
                gsub(/\\/, "\\\\")
                printf "{\"line\":\"%s\"},", $0
            }' | sed 's/,$//')
            
            if [ -n "$logs" ]; then
                logs="[$logs]"
            else
                logs="[]"
            fi
        fi
    fi
    
    cat << EOF
{
    "status": "success",
    "message": "Access logs retrieved",
    "data": {
        "log_type": "access",
        "log_file": "$log_file",
        "lines_requested": $lines,
        "search_term": "$search",
        "logs": $logs
    }
}
EOF
    
    return 0
}

get_error_logs() {
    local lines="$1"
    local search="$2"
    
    local log_file="$NGINX_ERROR_LOG"
    local logs="[]"
    
    if [ -f "$log_file" ]; then
        local raw_logs
        
        if [ -n "$search" ] && [ "$search" != "null" ]; then
            raw_logs=$(grep -i "$search" "$log_file" | tail -n "$lines" 2>/dev/null || echo "")
        else
            raw_logs=$(tail -n "$lines" "$log_file" 2>/dev/null || echo "")
        fi
        
        if [ -n "$raw_logs" ]; then
            logs=$(echo "$raw_logs" | awk '{
                gsub(/"/, "\\\"")
                gsub(/\\/, "\\\\")
                printf "{\"line\":\"%s\"},", $0
            }' | sed 's/,$//')
            
            if [ -n "$logs" ]; then
                logs="[$logs]"
            else
                logs="[]"
            fi
        fi
    fi
    
    cat << EOF
{
    "status": "success",
    "message": "Error logs retrieved",
    "data": {
        "log_type": "error",
        "log_file": "$log_file",
        "lines_requested": $lines,
        "search_term": "$search",
        "logs": $logs
    }
}
EOF
    
    return 0
}

get_nginxui_logs() {
    local lines="$1"
    local search="$2"
    
    local log_file="$NGINXUI_LOG"
    local logs="[]"
    
    if [ -f "$log_file" ]; then
        local raw_logs
        
        if [ -n "$search" ] && [ "$search" != "null" ]; then
            raw_logs=$(grep -i "$search" "$log_file" | tail -n "$lines" 2>/dev/null || echo "")
        else
            raw_logs=$(tail -n "$lines" "$log_file" 2>/dev/null || echo "")
        fi
        
        if [ -n "$raw_logs" ]; then
            logs=$(echo "$raw_logs" | awk '{
                gsub(/"/, "\\\"")
                gsub(/\\/, "\\\\")
                printf "{\"line\":\"%s\"},", $0
            }' | sed 's/,$//')
            
            if [ -n "$logs" ]; then
                logs="[$logs]"
            else
                logs="[]"
            fi
        fi
    fi
    
    cat << EOF
{
    "status": "success",
    "message": "NGINXUI logs retrieved",
    "data": {
        "log_type": "nginxui",
        "log_file": "$log_file",
        "lines_requested": $lines,
        "search_term": "$search",
        "logs": $logs
    }
}
EOF
    
    return 0
}

get_all_logs() {
    local lines="$1"
    local search="$2"
    
    # Get logs from all sources
    local access_logs=$(get_access_logs "$lines" "$search" | jq -r '.data.logs')
    local error_logs=$(get_error_logs "$lines" "$search" | jq -r '.data.logs')
    local nginxui_logs=$(get_nginxui_logs "$lines" "$search" | jq -r '.data.logs')
    
    cat << EOF
{
    "status": "success",
    "message": "All logs retrieved",
    "data": {
        "log_type": "all",
        "lines_requested": $lines,
        "search_term": "$search",
        "access_logs": $access_logs,
        "error_logs": $error_logs,
        "nginxui_logs": $nginxui_logs
    }
}
EOF
    
    return 0
}

# Log file management functions
clear_logs() {
    local log_type="$1"
    
    log_info "Clearing $log_type logs"
    
    case "$log_type" in
        "access")
            clear_access_logs
            ;;
        "error")
            clear_error_logs
            ;;
        "nginxui")
            clear_nginxui_logs
            ;;
        "all")
            clear_all_logs
            ;;
        *)
            log_error "Unknown log type: $log_type"
            echo '{"status":"error","message":"Unknown log type","data":{}}'
            return 1
            ;;
    esac
}

clear_access_logs() {
    local log_file="$NGINX_ACCESS_LOG"
    
    if [ -f "$log_file" ]; then
        # Create backup before clearing
        local backup_file="${log_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$log_file" "$backup_file" 2>/dev/null
        
        # Clear the log file
        > "$log_file"
        
        # Signal Nginx to reopen log files
        if is_nginx_running; then
            nginx -s reopen 2>/dev/null
        fi
        
        log_info "Access logs cleared (backup: $backup_file)"
        echo '{"status":"success","message":"Access logs cleared","data":{"log_type":"access","backup_file":"'$backup_file'"}}'
    else
        echo '{"status":"success","message":"Access log file does not exist","data":{"log_type":"access"}}'
    fi
    
    return 0
}

clear_error_logs() {
    local log_file="$NGINX_ERROR_LOG"
    
    if [ -f "$log_file" ]; then
        # Create backup before clearing
        local backup_file="${log_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$log_file" "$backup_file" 2>/dev/null
        
        # Clear the log file
        > "$log_file"
        
        # Signal Nginx to reopen log files
        if is_nginx_running; then
            nginx -s reopen 2>/dev/null
        fi
        
        log_info "Error logs cleared (backup: $backup_file)"
        echo '{"status":"success","message":"Error logs cleared","data":{"log_type":"error","backup_file":"'$backup_file'"}}'
    else
        echo '{"status":"success","message":"Error log file does not exist","data":{"log_type":"error"}}'
    fi
    
    return 0
}

clear_nginxui_logs() {
    local log_file="$NGINXUI_LOG"
    
    if [ -f "$log_file" ]; then
        # Create backup before clearing
        local backup_file="${log_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$log_file" "$backup_file" 2>/dev/null
        
        # Clear the log file
        > "$log_file"
        
        log_info "NGINXUI logs cleared (backup: $backup_file)"
        echo '{"status":"success","message":"NGINXUI logs cleared","data":{"log_type":"nginxui","backup_file":"'$backup_file'"}}'
    else
        echo '{"status":"success","message":"NGINXUI log file does not exist","data":{"log_type":"nginxui"}}'
    fi
    
    return 0
}

clear_all_logs() {
    log_info "Clearing all logs"
    
    local results="[]"
    
    # Clear each log type and collect results
    local access_result=$(clear_access_logs | jq -c '.')
    local error_result=$(clear_error_logs | jq -c '.')
    local nginxui_result=$(clear_nginxui_logs | jq -c '.')
    
    results="[$access_result,$error_result,$nginxui_result]"
    
    cat << EOF
{
    "status": "success",
    "message": "All logs cleared",
    "data": {
        "log_type": "all",
        "results": $results
    }
}
EOF
    
    return 0
}

# Log download functions
download_logs() {
    local log_type="$1"
    local format="$2"
    
    if [ -z "$format" ] || [ "$format" = "null" ]; then
        format="txt"
    fi
    
    log_info "Preparing $log_type logs for download in $format format"
    
    case "$log_type" in
        "access")
            download_access_logs "$format"
            ;;
        "error")
            download_error_logs "$format"
            ;;
        "nginxui")
            download_nginxui_logs "$format"
            ;;
        "all")
            download_all_logs "$format"
            ;;
        *)
            log_error "Unknown log type: $log_type"
            echo '{"status":"error","message":"Unknown log type","data":{}}'
            return 1
            ;;
    esac
}

download_access_logs() {
    local format="$1"
    local log_file="$NGINX_ACCESS_LOG"
    local download_file="$NGINXUI_SHARED_DIR/downloads/nginx_access_$(date +%Y%m%d_%H%M%S).$format"
    
    # Ensure downloads directory exists
    ensure_dir "$NGINXUI_SHARED_DIR/downloads"
    
    if [ -f "$log_file" ]; then
        case "$format" in
            "txt")
                cp "$log_file" "$download_file"
                ;;
            "json")
                create_json_log_export "$log_file" "access" > "$download_file"
                ;;
            "csv")
                create_csv_log_export "$log_file" "access" > "$download_file"
                ;;
            *)
                cp "$log_file" "$download_file"
                ;;
        esac
        
        echo '{"status":"success","message":"Access logs prepared for download","data":{"download_file":"'$download_file'","format":"'$format'"}}'
    else
        echo '{"status":"error","message":"Access log file does not exist","data":{}}'
        return 1
    fi
    
    return 0
}

download_error_logs() {
    local format="$1"
    local log_file="$NGINX_ERROR_LOG"
    local download_file="$NGINXUI_SHARED_DIR/downloads/nginx_error_$(date +%Y%m%d_%H%M%S).$format"
    
    # Ensure downloads directory exists
    ensure_dir "$NGINXUI_SHARED_DIR/downloads"
    
    if [ -f "$log_file" ]; then
        case "$format" in
            "txt")
                cp "$log_file" "$download_file"
                ;;
            "json")
                create_json_log_export "$log_file" "error" > "$download_file"
                ;;
            "csv")
                create_csv_log_export "$log_file" "error" > "$download_file"
                ;;
            *)
                cp "$log_file" "$download_file"
                ;;
        esac
        
        echo '{"status":"success","message":"Error logs prepared for download","data":{"download_file":"'$download_file'","format":"'$format'"}}'
    else
        echo '{"status":"error","message":"Error log file does not exist","data":{}}'
        return 1
    fi
    
    return 0
}

download_nginxui_logs() {
    local format="$1"
    local log_file="$NGINXUI_LOG"
    local download_file="$NGINXUI_SHARED_DIR/downloads/nginxui_$(date +%Y%m%d_%H%M%S).$format"
    
    # Ensure downloads directory exists
    ensure_dir "$NGINXUI_SHARED_DIR/downloads"
    
    if [ -f "$log_file" ]; then
        case "$format" in
            "txt")
                cp "$log_file" "$download_file"
                ;;
            "json")
                create_json_log_export "$log_file" "nginxui" > "$download_file"
                ;;
            "csv")
                create_csv_log_export "$log_file" "nginxui" > "$download_file"
                ;;
            *)
                cp "$log_file" "$download_file"
                ;;
        esac
        
        echo '{"status":"success","message":"NGINXUI logs prepared for download","data":{"download_file":"'$download_file'","format":"'$format'"}}'
    else
        echo '{"status":"error","message":"NGINXUI log file does not exist","data":{}}'
        return 1
    fi
    
    return 0
}

download_all_logs() {
    local format="$1"
    local archive_file="$NGINXUI_SHARED_DIR/downloads/all_logs_$(date +%Y%m%d_%H%M%S).tar.gz"
    local temp_dir="$NGINXUI_SHARED_DIR/temp/logs_export_$$"
    
    # Ensure directories exist
    ensure_dir "$NGINXUI_SHARED_DIR/downloads"
    ensure_dir "$temp_dir"
    
    # Export each log type to temp directory
    if [ -f "$NGINX_ACCESS_LOG" ]; then
        case "$format" in
            "txt")
                cp "$NGINX_ACCESS_LOG" "$temp_dir/nginx_access.txt"
                ;;
            "json")
                create_json_log_export "$NGINX_ACCESS_LOG" "access" > "$temp_dir/nginx_access.json"
                ;;
            "csv")
                create_csv_log_export "$NGINX_ACCESS_LOG" "access" > "$temp_dir/nginx_access.csv"
                ;;
        esac
    fi
    
    if [ -f "$NGINX_ERROR_LOG" ]; then
        case "$format" in
            "txt")
                cp "$NGINX_ERROR_LOG" "$temp_dir/nginx_error.txt"
                ;;
            "json")
                create_json_log_export "$NGINX_ERROR_LOG" "error" > "$temp_dir/nginx_error.json"
                ;;
            "csv")
                create_csv_log_export "$NGINX_ERROR_LOG" "error" > "$temp_dir/nginx_error.csv"
                ;;
        esac
    fi
    
    if [ -f "$NGINXUI_LOG" ]; then
        case "$format" in
            "txt")
                cp "$NGINXUI_LOG" "$temp_dir/nginxui.txt"
                ;;
            "json")
                create_json_log_export "$NGINXUI_LOG" "nginxui" > "$temp_dir/nginxui.json"
                ;;
            "csv")
                create_csv_log_export "$NGINXUI_LOG" "nginxui" > "$temp_dir/nginxui.csv"
                ;;
        esac
    fi
    
    # Create archive
    if tar -czf "$archive_file" -C "$(dirname "$temp_dir")" "$(basename "$temp_dir")" 2>/dev/null; then
        # Clean up temp directory
        rm -rf "$temp_dir"
        
        echo '{"status":"success","message":"All logs prepared for download","data":{"download_file":"'$archive_file'","format":"archive"}}'
    else
        # Clean up temp directory
        rm -rf "$temp_dir"
        
        echo '{"status":"error","message":"Failed to create log archive","data":{}}'
        return 1
    fi
    
    return 0
}

# Log export format functions
create_json_log_export() {
    local log_file="$1"
    local log_type="$2"
    
    echo '{'
    echo '  "export_info": {'
    echo '    "log_type": "'$log_type'",'
    echo '    "log_file": "'$log_file'",'
    echo '    "exported_at": "'$(date)'",'
    echo '    "nginxui_version": "'$NGINXUI_VERSION'"'
    echo '  },'
    echo '  "logs": ['
    
    local first=true
    while IFS= read -r line; do
        if [ "$first" = true ]; then
            first=false
        else
            echo ','
        fi
        
        # Escape JSON special characters
        local escaped_line=$(echo "$line" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g; s/\n/\\n/g')
        echo -n '    {"timestamp": "'$(date)'", "line": "'$escaped_line'"}'
    done < "$log_file"
    
    echo ''
    echo '  ]'
    echo '}'
}

create_csv_log_export() {
    local log_file="$1"
    local log_type="$2"
    
    # CSV header
    echo "timestamp,log_type,line"
    
    # CSV data
    while IFS= read -r line; do
        # Escape CSV special characters
        local escaped_line=$(echo "$line" | sed 's/"/""/g')
        echo "$(date),$log_type,\"$escaped_line\""
    done < "$log_file"
}

# Log statistics functions
get_log_stats() {
    local log_type="$1"
    
    log_info "Retrieving log statistics for $log_type"
    
    case "$log_type" in
        "access")
            get_access_log_stats
            ;;
        "error")
            get_error_log_stats
            ;;
        "nginxui")
            get_nginxui_log_stats
            ;;
        "all")
            get_all_log_stats
            ;;
        *)
            log_error "Unknown log type: $log_type"
            echo '{"status":"error","message":"Unknown log type","data":{}}'
            return 1
            ;;
    esac
}

get_access_log_stats() {
    local log_file="$NGINX_ACCESS_LOG"
    local total_lines=0
    local file_size=0
    local last_modified="unknown"
    
    if [ -f "$log_file" ]; then
        total_lines=$(wc -l < "$log_file" 2>/dev/null || echo 0)
        file_size=$(stat -c%s "$log_file" 2>/dev/null || echo 0)
        last_modified=$(stat -c%y "$log_file" 2>/dev/null || echo "unknown")
        
        # Get some basic statistics from access log
        local status_200=$(grep " 200 " "$log_file" 2>/dev/null | wc -l || echo 0)
        local status_404=$(grep " 404 " "$log_file" 2>/dev/null | wc -l || echo 0)
        local status_500=$(grep " 50[0-9] " "$log_file" 2>/dev/null | wc -l || echo 0)
        
        cat << EOF
{
    "status": "success",
    "message": "Access log statistics retrieved",
    "data": {
        "log_type": "access",
        "log_file": "$log_file",
        "total_lines": $total_lines,
        "file_size": $file_size,
        "last_modified": "$last_modified",
        "statistics": {
            "status_200": $status_200,
            "status_404": $status_404,
            "status_500": $status_500
        }
    }
}
EOF
    else
        cat << EOF
{
    "status": "success",
    "message": "Access log file does not exist",
    "data": {
        "log_type": "access",
        "log_file": "$log_file",
        "total_lines": 0,
        "file_size": 0,
        "last_modified": "unknown",
        "statistics": {}
    }
}
EOF
    fi
    
    return 0
}

get_error_log_stats() {
    local log_file="$NGINX_ERROR_LOG"
    local total_lines=0
    local file_size=0
    local last_modified="unknown"
    
    if [ -f "$log_file" ]; then
        total_lines=$(wc -l < "$log_file" 2>/dev/null || echo 0)
        file_size=$(stat -c%s "$log_file" 2>/dev/null || echo 0)
        last_modified=$(stat -c%y "$log_file" 2>/dev/null || echo "unknown")
        
        # Get some basic statistics from error log
        local error_count=$(grep "\[error\]" "$log_file" 2>/dev/null | wc -l || echo 0)
        local warn_count=$(grep "\[warn\]" "$log_file" 2>/dev/null | wc -l || echo 0)
        local crit_count=$(grep "\[crit\]" "$log_file" 2>/dev/null | wc -l || echo 0)
        
        cat << EOF
{
    "status": "success",
    "message": "Error log statistics retrieved",
    "data": {
        "log_type": "error",
        "log_file": "$log_file",
        "total_lines": $total_lines,
        "file_size": $file_size,
        "last_modified": "$last_modified",
        "statistics": {
            "error_count": $error_count,
            "warn_count": $warn_count,
            "crit_count": $crit_count
        }
    }
}
EOF
    else
        cat << EOF
{
    "status": "success",
    "message": "Error log file does not exist",
    "data": {
        "log_type": "error",
        "log_file": "$log_file",
        "total_lines": 0,
        "file_size": 0,
        "last_modified": "unknown",
        "statistics": {}
    }
}
EOF
    fi
    
    return 0
}

get_nginxui_log_stats() {
    local log_file="$NGINXUI_LOG"
    local total_lines=0
    local file_size=0
    local last_modified="unknown"
    
    if [ -f "$log_file" ]; then
        total_lines=$(wc -l < "$log_file" 2>/dev/null || echo 0)
        file_size=$(stat -c%s "$log_file" 2>/dev/null || echo 0)
        last_modified=$(stat -c%y "$log_file" 2>/dev/null || echo "unknown")
        
        # Get some basic statistics from NGINXUI log
        local info_count=$(grep "\[INFO\]" "$log_file" 2>/dev/null | wc -l || echo 0)
        local warn_count=$(grep "\[WARN\]" "$log_file" 2>/dev/null | wc -l || echo 0)
        local error_count=$(grep "\[ERROR\]" "$log_file" 2>/dev/null | wc -l || echo 0)
        
        cat << EOF
{
    "status": "success",
    "message": "NGINXUI log statistics retrieved",
    "data": {
        "log_type": "nginxui",
        "log_file": "$log_file",
        "total_lines": $total_lines,
        "file_size": $file_size,
        "last_modified": "$last_modified",
        "statistics": {
            "info_count": $info_count,
            "warn_count": $warn_count,
            "error_count": $error_count
        }
    }
}
EOF
    else
        cat << EOF
{
    "status": "success",
    "message": "NGINXUI log file does not exist",
    "data": {
        "log_type": "nginxui",
        "log_file": "$log_file",
        "total_lines": 0,
        "file_size": 0,
        "last_modified": "unknown",
        "statistics": {}
    }
}
EOF
    fi
    
    return 0
}

get_all_log_stats() {
    # Get statistics for all log types
    local access_stats=$(get_access_log_stats | jq -c '.data')
    local error_stats=$(get_error_log_stats | jq -c '.data')
    local nginxui_stats=$(get_nginxui_log_stats | jq -c '.data')
    
    cat << EOF
{
    "status": "success",
    "message": "All log statistics retrieved",
    "data": {
        "log_type": "all",
        "access_stats": $access_stats,
        "error_stats": $error_stats,
        "nginxui_stats": $nginxui_stats
    }
}
EOF
    
    return 0
}

# Log rotation functions
rotate_log_files() {
    log_info "Rotating log files..."
    
    local max_size=$(get_config_value 'NGINXUI_LOG_MAX_SIZE' '10M')
    local max_files=$(get_config_value 'NGINXUI_LOG_MAX_FILES' '5')
    
    # Convert size to bytes
    local max_bytes
    case "$max_size" in
        *K|*k) max_bytes=$((${max_size%[Kk]} * 1024)) ;;
        *M|*m) max_bytes=$((${max_size%[Mm]} * 1024 * 1024)) ;;
        *G|*g) max_bytes=$((${max_size%[Gg]} * 1024 * 1024 * 1024)) ;;
        *) max_bytes="$max_size" ;;
    esac
    
    local rotated_files="[]"
    
    # Rotate each log file if needed
    for log_file in "$NGINX_ACCESS_LOG" "$NGINX_ERROR_LOG" "$NGINXUI_LOG"; do
        if [ -f "$log_file" ]; then
            local log_size=$(stat -c%s "$log_file" 2>/dev/null || echo 0)
            
            if [ "$log_size" -gt "$max_bytes" ]; then
                # Rotate this log file
                local base_name=$(basename "$log_file")
                local log_dir=$(dirname "$log_file")
                
                # Shift existing rotated files
                local i="$max_files"
                while [ "$i" -gt 1 ]; do
                    local prev=$((i - 1))
                    if [ -f "${log_file}.$prev" ]; then
                        mv "${log_file}.$prev" "${log_file}.$i"
                    fi
                    i="$prev"
                done
                
                # Move current log to .1
                mv "$log_file" "${log_file}.1"
                
                # Create new empty log file
                touch "$log_file"
                chmod 644 "$log_file"
                
                rotated_files=$(echo "$rotated_files" | jq '. + ["'$log_file'"]')
                
                log_info "Rotated log file: $log_file"
            fi
        fi
    done
    
    # Signal Nginx to reopen log files if running
    if is_nginx_running; then
        nginx -s reopen 2>/dev/null
    fi
    
    cat << EOF
{
    "status": "success",
    "message": "Log rotation completed",
    "data": {
        "max_size": "$max_size",
        "max_files": $max_files,
        "rotated_files": $rotated_files
    }
}
EOF
    
    return 0
}

# Export functions
export -f get_logs get_access_logs get_error_logs get_nginxui_logs get_all_logs
export -f clear_logs clear_access_logs clear_error_logs clear_nginxui_logs clear_all_logs
export -f download_logs download_access_logs download_error_logs download_nginxui_logs download_all_logs
export -f create_json_log_export create_csv_log_export
export -f get_log_stats get_access_log_stats get_error_log_stats get_nginxui_log_stats get_all_log_stats
export -f rotate_log_files