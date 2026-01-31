ARG PHP_VERSION=8.4
FROM ghcr.io/quantcdn-templates/app-apache-php:${PHP_VERSION}

# Set document root to Laravel's public directory
ENV DOCUMENT_ROOT=/var/www/html/public

# Set working directory to Laravel root
WORKDIR /var/www/html

# Copy dependency files first (changes occasionally)
COPY src/composer.json src/composer.lock* ./

# Install PHP dependencies (cached until composer files change)
RUN set -eux; \
    export COMPOSER_HOME="$(mktemp -d)"; \
    composer config apcu-autoloader true; \
    composer install --optimize-autoloader --apcu-autoloader --no-dev --no-scripts; \
    rm -rf "$COMPOSER_HOME"

# Copy custom entrypoint scripts to Quant platform location
COPY .docker/quant/entrypoints/ /quant-entrypoint.d/
RUN if [ "$(ls -A /quant-entrypoint.d/)" ]; then chmod +x /quant-entrypoint.d/*; fi

# Copy custom PHP configuration files
COPY .docker/quant/php.ini.d/ /usr/local/etc/php/conf.d/

# Set up permissions (rarely changes)
RUN usermod -a -G www-data nobody && \
    usermod -a -G root nobody && \
    usermod -a -G www-data root

# Copy source code (changes frequently - do this last!)
COPY src/ /var/www/html/

# Final setup that depends on source code
RUN set -eux; \
    # Run the Composer scripts that were skipped during install
    export COMPOSER_HOME="$(mktemp -d)"; \
    composer dump-autoload --optimize --apcu --no-dev; \
    rm -rf "$COMPOSER_HOME"; \
    # Create storage directories
    mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/app/public storage/logs; \
    # Set up permissions
    chown -R www-data:www-data storage bootstrap/cache; \
    chmod -R 775 storage bootstrap/cache

# Set PATH
ENV PATH=${PATH}:/var/www/html/vendor/bin

# Copy custom entrypoint script for local development
# (Only used when overridden in docker-compose.override.yml)
COPY .docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint-laravel.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-laravel.sh

# Expose ports
EXPOSE 80

# Use standard Apache/PHP entrypoint by default
# In Quant Cloud, the platform wrapper runs /quant-entrypoint.d/ scripts automatically
# For local dev, copy docker-compose.override.yml.example to docker-compose.override.yml
ENTRYPOINT ["docker-php-entrypoint"]
CMD ["apache2-foreground"]
