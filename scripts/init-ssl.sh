#!/bin/bash

# ========================================
# SSL Certificate Initialization Script
# ========================================
# 
# This script obtains SSL certificates from Let's Encrypt
# for your domain using Certbot and the ACME HTTP-01 challenge.
#
# Prerequisites:
# - Domain name must point to this server's IP address
# - Ports 80 and 443 must be open in firewall
# - Docker containers must be running (docker compose up -d)
# - .env file must be configured with DOMAIN_NAME and SSL_EMAIL
#
# Usage:
#   ./scripts/init-ssl.sh
#
# This script should be run ONCE after initial deployment.
# After successful setup, certificates will auto-renew via Certbot container.
# ========================================

set -e  # Exit on any error

# ========================================
# Load Environment Variables
# ========================================
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo ""
    echo "Please create .env file from .env.example:"
    echo "  cp .env.example .env"
    echo "  nano .env  # Update DOMAIN_NAME and SSL_EMAIL"
    exit 1
fi

# Load variables from .env
export $(cat .env | grep -v '^#' | grep -v '^$' | xargs)

# ========================================
# Validate Required Variables
# ========================================
if [ -z "$DOMAIN_NAME" ] || [ "$DOMAIN_NAME" = "your-domain.com" ]; then
    echo "❌ Error: DOMAIN_NAME not configured in .env file"
    echo ""
    echo "Please update .env file with your actual domain name:"
    echo "  DOMAIN_NAME=example.com"
    exit 1
fi

if [ -z "$SSL_EMAIL" ] || [ "$SSL_EMAIL" = "your-email@example.com" ]; then
    echo "❌ Error: SSL_EMAIL not configured in .env file"
    echo ""
    echo "Please update .env file with your actual email:"
    echo "  SSL_EMAIL=admin@example.com"
    exit 1
fi

echo "========================================="
echo "SSL Certificate Setup"
echo "========================================="
echo "Domain: $DOMAIN_NAME"
echo "Email:  $SSL_EMAIL"
echo ""

# ========================================
# Check if Certificates Already Exist
# ========================================
if docker compose exec -T certbot test -d "/etc/letsencrypt/live/$DOMAIN_NAME" 2>/dev/null; then
    echo "⚠️  Certificates already exist for $DOMAIN_NAME"
    echo ""
    read -p "Do you want to renew them? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping certificate generation."
        exit 0
    fi
    RENEW_FLAG="--force-renewal"
else
    RENEW_FLAG=""
fi

# ========================================
# Verify Domain DNS
# ========================================
echo "Step 1: Verifying DNS configuration..."
echo ""

# Get server's public IP
SERVER_IP=$(curl -s --max-time 5 ifconfig.me || curl -s --max-time 5 icanhazip.com || echo "unknown")
echo "Server IP: $SERVER_IP"

# Check domain resolution
DOMAIN_IP=$(dig +short "$DOMAIN_NAME" @8.8.8.8 | grep -E '^[0-9.]+$' | head -n1 || echo "unknown")
echo "Domain IP: $DOMAIN_IP"
echo ""

if [ "$SERVER_IP" != "$DOMAIN_IP" ] && [ "$DOMAIN_IP" != "unknown" ]; then
    echo "⚠️  Warning: Domain IP ($DOMAIN_IP) doesn't match server IP ($SERVER_IP)"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. Please update your domain's DNS records."
        exit 1
    fi
fi

# ========================================
# Ensure Containers are Running
# ========================================
echo "Step 2: Checking Docker containers..."
echo ""

if ! docker compose ps | grep -q "tellme_nginx.*Up"; then
    echo "Starting Docker containers..."
    docker compose up -d
    echo "Waiting for containers to be ready..."
    sleep 10
fi

# ========================================
# Clean up any stuck certbot containers
# ========================================
echo "Cleaning up any previous certbot runs..."
docker ps -a | grep "certbot-run" | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true

# ========================================
# Request SSL Certificate
# ========================================
echo ""
echo "Step 3: Requesting SSL certificate from Let's Encrypt..."
echo ""
echo "This may take 1-2 minutes. Please wait..."
echo ""

# Request certificate using Certbot with timeout
# Use --non-interactive and --no-eff-email to avoid hanging
timeout 300 docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$SSL_EMAIL" \
    --agree-tos \
    --no-eff-email \
    --non-interactive \
    --keep-until-expiring \
    $RENEW_FLAG \
    -d "$DOMAIN_NAME" 2>&1 | tee /tmp/certbot-output.log

CERTBOT_EXIT_CODE=${PIPESTATUS[0]}

# Check if certificate was obtained successfully
if [ $CERTBOT_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ SSL certificate obtained successfully!"
    echo ""
elif [ $CERTBOT_EXIT_CODE -eq 124 ]; then
    echo ""
    echo "❌ Certificate request timed out after 5 minutes!"
    echo ""
    echo "This usually means:"
    echo "1. Port 80 is not accessible from the internet"
    echo "2. Firewall is blocking Let's Encrypt servers"
    echo "3. Domain doesn't resolve correctly"
    echo ""
    echo "Check the output above for specific errors."
    exit 1
else
    echo ""
    echo "❌ Failed to obtain SSL certificate!"
    echo ""
    echo "Common issues:"
    echo "1. Domain $DOMAIN_NAME doesn't point to this server"
    echo "2. Port 80 is not accessible from the internet"
    echo "3. Firewall is blocking incoming connections"
    echo "4. Another service is using port 80"
    echo "5. Rate limit reached (5 failures per hour)"
    echo ""
    echo "Troubleshooting:"
    echo "  - Check DNS: dig $DOMAIN_NAME"
    echo "  - Check port 80: sudo netstat -tlnp | grep :80"
    echo "  - Check firewall: sudo ufw status"
    echo "  - Check nginx logs: docker compose logs nginx"
    echo "  - Test ACME challenge: curl http://$DOMAIN_NAME/.well-known/acme-challenge/test"
    echo ""
    echo "Certbot output saved to: /tmp/certbot-output.log"
    exit 1
fi

# ========================================
# Update Nginx Configuration
# ========================================
echo "Step 4: Updating Nginx configuration with SSL..."
echo ""

# Replace DOMAIN_PLACEHOLDER with actual domain name
sed "s/DOMAIN_PLACEHOLDER/$DOMAIN_NAME/g" nginx/nginx-ssl.conf > nginx/nginx.conf

# Test nginx configuration
echo "Testing Nginx configuration..."
if docker compose exec nginx nginx -t 2>&1 | grep -q "successful"; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration test failed!"
    docker compose exec nginx nginx -t
    exit 1
fi

# Reload Nginx to apply new configuration
echo "Reloading Nginx..."
if docker compose exec nginx nginx -s reload 2>&1; then
    echo "✅ Nginx reloaded successfully!"
else
    echo "⚠️  Nginx reload failed. Restarting container..."
    docker compose restart nginx
    sleep 3
fi

# ========================================
# Verify SSL is Working
# ========================================
echo ""
echo "Step 5: Verifying SSL configuration..."
echo ""

# Wait a moment for nginx to fully reload
sleep 2

# Test HTTPS
if curl -I -s --max-time 10 "https://$DOMAIN_NAME" | grep -q "200 OK"; then
    echo "✅ HTTPS is working!"
elif curl -I -s --max-time 10 "https://$DOMAIN_NAME" | grep -q "HTTP"; then
    echo "✅ HTTPS is responding (check status above)"
else
    echo "⚠️  HTTPS test inconclusive. Please test manually:"
    echo "   curl -I https://$DOMAIN_NAME"
fi

# ========================================
# Setup Complete
# ========================================
echo ""
echo "========================================="
echo "✅ SSL Setup Complete!"
echo "========================================="
echo ""
echo "Your site is now available at:"
echo "  https://$DOMAIN_NAME"
echo ""
echo "SSL certificates will automatically renew every 12 hours"
echo "via the Certbot container (30 days before expiry)."
echo ""
echo "Next steps:"
echo "  - Test HTTPS: curl -I https://$DOMAIN_NAME"
echo "  - Verify redirect: curl -I http://$DOMAIN_NAME"
echo "  - Check certificate: openssl s_client -connect $DOMAIN_NAME:443 -servername $DOMAIN_NAME < /dev/null | grep -A 2 'Verify return code'"
echo ""
echo "If you encounter issues, check:"
echo "  - Nginx logs: docker compose logs nginx"
echo "  - Certbot logs: docker compose logs certbot"
echo "  - Certificate status: docker compose exec certbot certbot certificates"
echo ""
