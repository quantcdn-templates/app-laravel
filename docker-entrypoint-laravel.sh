#!/bin/bash
set -euo pipefail

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Function to apply environment variable mappings for Quant Cloud
apply_env_mapping() {
    log "Applying Quant Cloud environment variable mappings..."
    
    # Create/append to Apache environment file (need sudo since we run as www-data)
    sudo touch /etc/apache2/envvars
    
    # Map Quant Cloud DB variables to Laravel variables if they exist
    if [ -n "${DB_HOST:-}" ]; then
        if [ -n "${DB_PORT:-}" ] && [ "${DB_PORT}" != "3306" ]; then
            export DB_HOST="${DB_HOST}:${DB_PORT}"
            echo "export DB_HOST=\"${DB_HOST}:${DB_PORT}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        else
            echo "export DB_HOST=\"${DB_HOST}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        fi
        log "Mapped DB_HOST environment variable"
    fi
    
    if [ -n "${DB_DATABASE:-}" ]; then
        echo "export DB_DATABASE=\"${DB_DATABASE}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Mapped DB_DATABASE environment variable"
    fi
    
    if [ -n "${DB_USERNAME:-}" ]; then
        echo "export DB_USERNAME=\"${DB_USERNAME}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Mapped DB_USERNAME environment variable"
    fi
    
    if [ -n "${DB_PASSWORD:-}" ]; then
        echo "export DB_PASSWORD=\"${DB_PASSWORD}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Mapped DB_PASSWORD environment variable"
    fi
    
    # Map Laravel-specific variables
    if [ -n "${APP_KEY:-}" ]; then
        echo "export APP_KEY=\"${APP_KEY}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Mapped APP_KEY environment variable"
    fi
    
    if [ -n "${APP_ENV:-}" ]; then
        echo "export APP_ENV=\"${APP_ENV}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Mapped APP_ENV environment variable"
    fi
    
    if [ -n "${APP_DEBUG:-}" ]; then
        echo "export APP_DEBUG=\"${APP_DEBUG}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Mapped APP_DEBUG environment variable"
    fi
    
    if [ -n "${APP_URL:-}" ]; then
        echo "export APP_URL=\"${APP_URL}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Mapped APP_URL environment variable"
    fi
    
    # Map logging variables
    if [ -n "${LOG_CHANNEL:-}" ]; then
        echo "export LOG_CHANNEL=\"${LOG_CHANNEL}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Mapped LOG_CHANNEL environment variable"
    fi
    
    if [ -n "${LOG_LEVEL:-}" ]; then
        echo "export LOG_LEVEL=\"${LOG_LEVEL}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Mapped LOG_LEVEL environment variable"
    fi
    
    # Map cache/session variables
    if [ -n "${CACHE_DRIVER:-}" ]; then
        echo "export CACHE_DRIVER=\"${CACHE_DRIVER}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Mapped CACHE_DRIVER environment variable"
    fi
    
    if [ -n "${SESSION_DRIVER:-}" ]; then
        echo "export SESSION_DRIVER=\"${SESSION_DRIVER}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
        log "Mapped SESSION_DRIVER environment variable"
    fi
    
    # Map Quant-specific variables
    local quant_vars=(
        "QUANT_ENABLED" "QUANT_DISABLE_TLS_VERIFY" "QUANT_HTTP_REQUEST_TIMEOUT"
        "QUANT_WEBSERVER_URL" "QUANT_WEBSERVER_HOST" "QUANT_API_ENDPOINT"
        "QUANT_CUSTOMER" "QUANT_PROJECT" "QUANT_TOKEN"
        "QUANT_SMTP_FROM" "QUANT_SMTP_FROM_NAME"
    )
    
    for var in "${quant_vars[@]}"; do
        if [ -n "${!var:-}" ]; then
            echo "export ${var}=\"${!var}\"" | sudo tee -a /etc/apache2/envvars > /dev/null
            log "Mapped ${var} environment variable"
        fi
    done
}

# Configure sudo for www-data to run apache2-foreground as root and modify Apache config
configure_sudo() {
    log "Configuring sudo permissions for www-data..."
    
    cat > /etc/sudoers.d/laravel << 'EOF'
www-data ALL=(root) NOPASSWD:SETENV: /usr/local/bin/apache2-foreground-real
www-data ALL=(root) NOPASSWD: /usr/bin/tee -a /etc/apache2/envvars
www-data ALL=(root) NOPASSWD: /usr/bin/touch /etc/apache2/envvars
Defaults:www-data env_keep += "APP_KEY APP_ENV APP_DEBUG APP_URL LOG_CHANNEL LOG_LEVEL CACHE_DRIVER SESSION_DRIVER DB_HOST DB_DATABASE DB_USERNAME DB_PASSWORD QUANT_SMTP_FROM QUANT_SMTP_FROM_NAME QUANT_ENABLED QUANT_DISABLE_TLS_VERIFY QUANT_HTTP_REQUEST_TIMEOUT QUANT_WEBSERVER_URL QUANT_WEBSERVER_HOST QUANT_API_ENDPOINT QUANT_CUSTOMER QUANT_PROJECT QUANT_TOKEN"
EOF
    chmod 0440 /etc/sudoers.d/laravel
}

# Create wrapper for apache2-foreground that runs as root
create_apache_wrapper() {
    log "Creating Apache wrapper for privilege handling..."
    
    mv /usr/local/bin/apache2-foreground /usr/local/bin/apache2-foreground-real
    
    cat > /usr/local/bin/apache2-foreground << 'EOF'
#!/bin/bash
exec sudo --preserve-env=APP_KEY,APP_ENV,APP_DEBUG,APP_URL,LOG_CHANNEL,LOG_LEVEL,CACHE_DRIVER,SESSION_DRIVER,DB_HOST,DB_DATABASE,DB_USERNAME,DB_PASSWORD,QUANT_SMTP_FROM,QUANT_SMTP_FROM_NAME,QUANT_ENABLED,QUANT_DISABLE_TLS_VERIFY,QUANT_HTTP_REQUEST_TIMEOUT,QUANT_WEBSERVER_URL,QUANT_WEBSERVER_HOST,QUANT_API_ENDPOINT,QUANT_CUSTOMER,QUANT_PROJECT,QUANT_TOKEN /usr/local/bin/apache2-foreground-real "$@"
EOF
    
    chmod +x /usr/local/bin/apache2-foreground
}

# Run Quant entrypoints  
run_quant_entrypoints() {
    log "Running Quant entrypoints as root..."
    
    if [ -d /quant/entrypoints ]; then
      for i in /quant/entrypoints/*; do
        if [ -r $i ]; then
          log "Executing entrypoint: $(basename $i)"
          . $i
        fi
      done
      unset i
      log "Quant entrypoints complete"
    else
      log "No /quant/entrypoints directory found"
    fi
}

# Main execution
main() {
    log "Starting Laravel Docker entrypoint..."
    
    # Only run setup as root
    if [ "$(id -u)" = "0" ]; then
        # Run Quant entrypoints first
        run_quant_entrypoints
        
        configure_sudo
        create_apache_wrapper
        apply_env_mapping
        log "Root setup complete, switching to www-data for application start"
        # Execute as www-data but allow Apache to run as root via sudo
        exec gosu www-data "$@"
    else
        # Already running as www-data, execute the command
        exec "$@"
    fi
}

# Only run main if this script is being executed (not sourced)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi