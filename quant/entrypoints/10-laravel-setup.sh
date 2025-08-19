#!/bin/bash

# Laravel-specific setup tasks
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Running Laravel setup..." >&2

# Ensure storage directories exist and have correct permissions
mkdir -p /var/www/html/storage/framework/cache/data
mkdir -p /var/www/html/storage/framework/sessions
mkdir -p /var/www/html/storage/framework/views
mkdir -p /var/www/html/storage/app/public
mkdir -p /var/www/html/storage/logs

# Set proper permissions for Laravel directories
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Ensure the public/storage symlink exists (for file uploads)
if [ ! -L /var/www/html/public/storage ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Creating storage symlink..." >&2
    # Create symlink as root, then fix ownership
    ln -sf /var/www/html/storage/app/public /var/www/html/public/storage 2>/dev/null || true
    chown -h www-data:www-data /var/www/html/public/storage 2>/dev/null || true
fi

# Cache Laravel configuration in production
if [ "${APP_ENV:-production}" = "production" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Optimizing Laravel for production..." >&2
    su -s /bin/bash www-data -c "php /var/www/html/artisan config:cache" 2>/dev/null || true
    su -s /bin/bash www-data -c "php /var/www/html/artisan route:cache" 2>/dev/null || true
    su -s /bin/bash www-data -c "php /var/www/html/artisan view:cache" 2>/dev/null || true
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Laravel setup complete" >&2