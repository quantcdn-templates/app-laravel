#!/bin/bash

# Configure ssmtp (lightweight sendmail replacement) if SMTP relay is NOT enabled
if [ -n "$QUANT_SMTP_HOST" ] && [ "$QUANT_SMTP_RELAY_ENABLED" != "true" ]; then
    echo "Configuring lightweight ssmtp with host: $QUANT_SMTP_HOST"
    
    # Install ssmtp if not already installed
    if ! command -v ssmtp >/dev/null 2>&1; then
        echo "Installing ssmtp..."
        apt-get update && apt-get install -y --no-install-recommends ssmtp
    fi
    
    # Ensure we can write to /etc/ssmtp directory
    chmod 755 /etc/ssmtp
    
    # Configure domain from QUANT_SMTP_FROM_DOMAIN or extract from QUANT_SMTP_FROM
    if [ -n "$QUANT_SMTP_FROM_DOMAIN" ]; then
        DOMAIN="$QUANT_SMTP_FROM_DOMAIN"
    elif [ -n "$QUANT_SMTP_FROM" ]; then
        DOMAIN=$(echo "$QUANT_SMTP_FROM" | cut -d@ -f2)
    else
        DOMAIN="quantcdn.io"  # fallback
    fi
    
    # Configure ssmtp
    cat > /etc/ssmtp/ssmtp.conf << EOF
root=${QUANT_SMTP_FROM:-postmaster@$DOMAIN}
mailhub=$QUANT_SMTP_HOST:${QUANT_SMTP_PORT:-587}
rewriteDomain=$DOMAIN
hostname=laravel.$DOMAIN
FromLineOverride=YES
UseTLS=YES
UseSTARTTLS=YES
EOF

    if [ -n "$QUANT_SMTP_USERNAME" ] && [ -n "$QUANT_SMTP_PASSWORD" ]; then
        cat >> /etc/ssmtp/ssmtp.conf << EOF
AuthUser=$QUANT_SMTP_USERNAME
AuthPass=$QUANT_SMTP_PASSWORD
AuthMethod=LOGIN
EOF
    fi
    
    echo "✅ ssmtp configured (sendmail replacement) - PHP mail() will work"
fi