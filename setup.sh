#!/bin/bash

# Laravel Application Template Setup Script
# This script initializes a new Laravel application for the template

set -e

echo "🚀 Setting up Laravel Application Template..."

# Check if src directory already exists
if [ -d "src" ]; then
    echo "⚠️  Laravel application already exists in src/ directory"
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing existing Laravel application..."
        rm -rf src/
    else
        echo "✅ Using existing Laravel application"
        exit 0
    fi
fi

# Create Laravel application
echo "📦 Creating fresh Laravel 11 application..."
composer create-project laravel/laravel:^11.0 src --no-dev --prefer-dist

echo "🔧 Configuring Laravel for Docker deployment..."

# Update .env.example for Docker
cat > src/.env.example << 'EOF'
APP_NAME=Laravel
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://localhost

LOG_CHANNEL=stderr
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=laravel

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"

QUANT_ENABLED=false
QUANT_DISABLE_TLS_VERIFY=false
QUANT_HTTP_REQUEST_TIMEOUT=30
QUANT_WEBSERVER_URL=
QUANT_WEBSERVER_HOST=
QUANT_API_ENDPOINT=
QUANT_CUSTOMER=
QUANT_PROJECT=
QUANT_TOKEN=
EOF

echo "✅ Laravel application template setup complete!"
echo ""
echo "Next steps:"
echo "1. Copy docker-compose.override.yml.example to docker-compose.override.yml"
echo "2. Set your APP_KEY in the override file"
echo "3. Run: docker-compose up -d"
echo "4. Generate application key: docker-compose exec laravel php artisan key:generate"
echo "5. Run migrations: docker-compose exec laravel php artisan migrate"
echo ""
echo "🎉 Your Laravel application will be available at http://localhost"