#!/bin/bash

# Initialize Let's Encrypt SSL certificates for production
# This script should be run ONCE after initial deployment

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found!"
    echo "Please copy .env.example to .env and configure it first."
    exit 1
fi

# Check required variables
if [ -z "$DOMAIN_NAME" ] || [ -z "$SSL_EMAIL" ]; then
    echo "Error: DOMAIN_NAME and SSL_EMAIL must be set in .env file"
    exit 1
fi

echo "=== Let's Encrypt SSL Certificate Setup ==="
echo "Domain: $DOMAIN_NAME"
echo "Email: $SSL_EMAIL"
echo ""

# Create directories for certbot
mkdir -p certbot/conf
mkdir -p certbot/www

# Check if certificates already exist
if [ -d "certbot/conf/live/$DOMAIN_NAME" ]; then
    echo "Certificates already exist for $DOMAIN_NAME"
    read -p "Do you want to renew them? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping certificate generation."
        exit 0
    fi
fi

echo "Step 1: Starting nginx temporarily for ACME challenge..."

# Create temporary nginx config for HTTP only (for initial certificate)
cat > nginx/nginx.conf.temp << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 200 'ACME challenge server running';
        add_header Content-Type text/plain;
    }
}
EOF

# Backup current nginx config
if [ -f "nginx/nginx.conf" ]; then
    cp nginx/nginx.conf nginx/nginx.conf.backup
fi

# Use temporary config
cp nginx/nginx.conf.temp nginx/nginx.conf

# Start nginx temporarily
echo "Starting nginx for ACME challenge..."
docker-compose up -d nginx

sleep 5

echo ""
echo "Step 2: Requesting SSL certificate from Let's Encrypt..."
echo "This may take a minute..."
echo ""

# Request certificate
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $SSL_EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d $DOMAIN_NAME

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ SSL certificate obtained successfully!"
    echo ""
    
    # Restore production nginx config
    if [ -f "nginx/nginx.conf.backup" ]; then
        mv nginx/nginx.conf.backup nginx/nginx.conf
    fi
    
    # Remove temporary config
    rm -f nginx/nginx.conf.temp
    
    echo "Step 3: Restarting nginx with SSL configuration..."
    docker-compose restart nginx
    
    echo ""
    echo "=== Setup Complete! ==="
    echo "Your site is now available at: https://$DOMAIN_NAME"
    echo ""
    echo "SSL certificates will auto-renew every 12 hours via the certbot container."
    echo ""
else
    echo ""
    echo "✗ Failed to obtain SSL certificate!"
    echo ""
    echo "Common issues:"
    echo "1. Domain $DOMAIN_NAME doesn't point to this server's IP"
    echo "2. Port 80 is not accessible from the internet"
    echo "3. Firewall blocking incoming connections"
    echo ""
    echo "Please fix the issue and run this script again."
    
    # Restore backup if exists
    if [ -f "nginx/nginx.conf.backup" ]; then
        mv nginx/nginx.conf.backup nginx/nginx.conf
    fi
    
    exit 1
fi
