# Production Deployment Guide

Complete guide for deploying the TellMe anonymous messaging platform to production with Docker, SSL, and DuckDNS.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Configuration](#configuration)
4. [Deployment](#deployment)
5. [SSL Certificate Setup](#ssl-certificate-setup)
6. [Maintenance](#maintenance)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements

- **Ubuntu Server** (20.04 LTS or newer recommended)
- **Docker** (20.10+)
- **Docker Compose** (2.0+)
- **Minimum 1GB RAM**, 10GB disk space
- **Public IP address** with ports 80 and 443 accessible

### Install Docker and Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Verify installation
docker --version
docker compose version
```

Log out and back in for group changes to take effect.

### DuckDNS Account

1. Go to https://www.duckdns.org/
2. Sign in with your preferred method
3. Create a subdomain (e.g., `saytruth`)
4. Note your **token** (you'll need this later)

---

## Initial Setup

### 1. Clone or Upload Project

```bash
# If using git
git clone <your-repo-url>
cd tellme

# Or upload files to your server
scp -r /path/to/tellme user@server:/home/user/tellme
```

### 2. Configure Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Edit with your actual values
nano .env
```

**Required values to update in `.env`:**

```bash
# Your DuckDNS domain
DOMAIN_NAME=saytruth.duckdns.org

# DuckDNS configuration
DUCKDNS_SUBDOMAIN=saytruth
DUCKDNS_TOKEN=your-actual-token-from-duckdns

# Your email for SSL certificate notifications
SSL_EMAIL=your-email@example.com

# Database path (leave as default)
DATABASE_PATH=/app/data/database.db
```

### 3. Update DuckDNS IP

Before deployment, ensure your DuckDNS domain points to your server:

```bash
# Get your server's public IP
curl ifconfig.me

# Update DuckDNS (replace with your values)
curl "https://www.duckdns.org/update?domains=saytruth&token=your-token&ip="
```

Verify it worked:
```bash
nslookup saytruth.duckdns.org
```

---

## Configuration

### Firewall Setup

Ensure ports 80 and 443 are open:

```bash
# Using UFW (Ubuntu Firewall)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status
```

### Docker Network

The application uses an internal Docker network (`app_network`) for service communication. No additional configuration needed.

---

## Deployment

### 1. Build and Start Services

```bash
# Build all Docker images
docker compose build

# Start all services in detached mode
docker compose up -d

# Check all containers are running
docker compose ps
```

You should see 5 containers running:
- `tellme_backend` - FastAPI application
- `tellme_frontend` - Nginx serving static files
- `tellme_nginx` - Reverse proxy
- `tellme_certbot` - SSL certificate manager
- `tellme_duckdns` - Dynamic DNS updater

### 2. Verify Services

```bash
# Check logs for any errors
docker compose logs backend
docker compose logs frontend
docker compose logs nginx
docker compose logs duckdns

# Test HTTP access (before SSL)
curl http://localhost
```

---

## SSL Certificate Setup

### Automatic SSL Setup Script

Run the initialization script to obtain SSL certificates:

```bash
# Make sure you're in the project directory
cd /home/user/tellme

# Run the SSL setup script
./scripts/init-letsencrypt.sh
```

**What this script does:**
1. Creates necessary directories for Certbot
2. Temporarily configures Nginx for ACME challenge
3. Requests SSL certificate from Let's Encrypt
4. Restores production Nginx configuration with SSL
5. Restarts Nginx with HTTPS enabled

**Expected output:**
```
=== Let's Encrypt SSL Certificate Setup ===
Domain: saytruth.duckdns.org
Email: your-email@example.com

Step 1: Starting nginx temporarily for ACME challenge...
Step 2: Requesting SSL certificate from Let's Encrypt...
✓ SSL certificate obtained successfully!
Step 3: Restarting nginx with SSL configuration...

=== Setup Complete! ===
Your site is now available at: https://saytruth.duckdns.org
```

### Verify SSL

```bash
# Test HTTPS access
curl -I https://saytruth.duckdns.org

# Verify HTTP redirects to HTTPS
curl -I http://saytruth.duckdns.org

# Check certificate details
openssl s_client -connect saytruth.duckdns.org:443 -servername saytruth.duckdns.org < /dev/null
```

### SSL Auto-Renewal

The `certbot` container automatically renews certificates every 12 hours. No manual intervention needed.

Check renewal status:
```bash
docker compose logs certbot
```

---

## Maintenance

### Database Backups

**Create a backup:**
```bash
./scripts/backup-db.sh
```

Backups are stored in `backups/` directory with timestamps. The script keeps the last 10 backups automatically.

**Restore from backup:**
```bash
./scripts/restore-db.sh backups/database_backup_20260119_120000.db
```

**Automated backups with cron:**
```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * cd /home/user/tellme && ./scripts/backup-db.sh >> /var/log/tellme-backup.log 2>&1
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f nginx

# Last 100 lines
docker compose logs --tail=100 backend
```

### Update Application

```bash
# Pull latest changes (if using git)
git pull

# Rebuild and restart
docker compose down
docker compose build
docker compose up -d

# Or restart specific service
docker compose restart backend
```

### Monitor Resources

```bash
# Container resource usage
docker stats

# Disk usage
docker system df

# Clean up unused images/containers
docker system prune -a
```

---

## Troubleshooting

### SSL Certificate Issues

**Problem:** Certificate request fails

**Solutions:**
1. Verify domain points to your server:
   ```bash
   nslookup saytruth.duckdns.org
   ```

2. Check port 80 is accessible:
   ```bash
   sudo netstat -tlnp | grep :80
   curl http://saytruth.duckdns.org/.well-known/acme-challenge/test
   ```

3. Check Certbot logs:
   ```bash
   docker compose logs certbot
   ```

4. Try manual certificate request:
   ```bash
   docker compose run --rm certbot certonly --webroot \
     --webroot-path=/var/www/certbot \
     --email your-email@example.com \
     --agree-tos \
     -d saytruth.duckdns.org
   ```

### DuckDNS Not Updating

**Problem:** IP address not updating

**Solutions:**
1. Check DuckDNS container logs:
   ```bash
   docker compose logs duckdns
   ```

2. Verify token and subdomain in `.env`

3. Manually update DuckDNS:
   ```bash
   curl "https://www.duckdns.org/update?domains=saytruth&token=your-token&ip="
   ```

4. Restart DuckDNS container:
   ```bash
   docker compose restart duckdns
   ```

### Backend Not Responding

**Problem:** API requests fail

**Solutions:**
1. Check backend logs:
   ```bash
   docker compose logs backend
   ```

2. Verify database file exists:
   ```bash
   docker compose exec backend ls -la /app/data/
   ```

3. Test backend directly:
   ```bash
   docker compose exec backend curl http://localhost:8000/api/
   ```

4. Restart backend:
   ```bash
   docker compose restart backend
   ```

### Database Issues

**Problem:** Database corruption or errors

**Solutions:**
1. Check database file:
   ```bash
   docker compose exec backend sqlite3 /app/data/database.db "PRAGMA integrity_check;"
   ```

2. Restore from backup:
   ```bash
   ./scripts/restore-db.sh backups/database_backup_YYYYMMDD_HHMMSS.db
   ```

3. If no backup, recreate database (⚠️ **data loss**):
   ```bash
   docker compose down
   docker volume rm tellme_sqlite_data
   docker compose up -d
   ```

### Container Won't Start

**Problem:** Container exits immediately

**Solutions:**
1. Check logs for errors:
   ```bash
   docker compose logs <service-name>
   ```

2. Verify environment variables:
   ```bash
   docker compose config
   ```

3. Check file permissions:
   ```bash
   ls -la backend/
   ls -la frontend/
   ```

4. Rebuild container:
   ```bash
   docker compose build --no-cache <service-name>
   docker compose up -d
   ```

### Port Already in Use

**Problem:** Port 80 or 443 already in use

**Solutions:**
1. Find what's using the port:
   ```bash
   sudo lsof -i :80
   sudo lsof -i :443
   ```

2. Stop conflicting service:
   ```bash
   sudo systemctl stop apache2  # or nginx, etc.
   sudo systemctl disable apache2
   ```

3. Or change ports in `docker-compose.yml`:
   ```yaml
   ports:
     - "8080:80"
     - "8443:443"
   ```

---

## Advanced Configuration

### Migrating to PostgreSQL (Future)

When you need to scale, migrate from SQLite to PostgreSQL:

1. Create PostgreSQL backup of current data
2. Update `docker-compose.yml` to add PostgreSQL service
3. Update `backend/database.py` to support PostgreSQL
4. Migrate data using migration script
5. Update `.env` with PostgreSQL credentials

Detailed migration guide will be provided when needed.

### Custom Domain (Non-DuckDNS)

To use your own domain:

1. Point your domain's A record to your server IP
2. Update `DOMAIN_NAME` in `.env`
3. Update `server_name` in `nginx/nginx.conf`
4. Re-run SSL setup: `./scripts/init-letsencrypt.sh`

### Load Balancing

For high traffic, add multiple backend replicas:

```yaml
backend:
  deploy:
    replicas: 3
```

Update nginx configuration to load balance across replicas.

---

## Security Best Practices

1. **Keep secrets secure**: Never commit `.env` to git
2. **Regular updates**: Update Docker images regularly
3. **Monitor logs**: Check for suspicious activity
4. **Backups**: Automate daily database backups
5. **Firewall**: Only expose necessary ports (80, 443)
6. **SSL**: Keep certificates up to date (auto-renewal handles this)
7. **Strong passwords**: If adding authentication, use strong passwords

---

## Quick Reference

### Common Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart specific service
docker compose restart backend

# View logs
docker compose logs -f

# Backup database
./scripts/backup-db.sh

# Restore database
./scripts/restore-db.sh <backup-file>

# Setup SSL
./scripts/init-letsencrypt.sh

# Check status
docker compose ps

# Update and restart
git pull && docker compose up -d --build
```

### File Structure

```
tellme/
├── backend/
│   ├── Dockerfile          # Backend container config
│   ├── main.py            # FastAPI app
│   ├── database.py        # Database config
│   └── ...
├── frontend/
│   ├── Dockerfile         # Frontend container config
│   ├── index.html         # Main page
│   └── ...
├── nginx/
│   └── nginx.conf         # Reverse proxy config
├── scripts/
│   ├── init-letsencrypt.sh   # SSL setup
│   ├── backup-db.sh          # Database backup
│   └── restore-db.sh         # Database restore
├── docker-compose.yml     # Service orchestration
├── .env                   # Environment variables (not in git)
├── .env.example          # Environment template
└── DEPLOYMENT.md         # This file
```

---

## Support

For issues or questions:
1. Check logs: `docker compose logs`
2. Review this troubleshooting guide
3. Check Docker and Docker Compose documentation
4. Verify DuckDNS status at https://www.duckdns.org/

---

**Deployment checklist:**
- [ ] Docker and Docker Compose installed
- [ ] DuckDNS account created and domain configured
- [ ] `.env` file configured with actual values
- [ ] Firewall ports 80 and 443 open
- [ ] Services started: `docker compose up -d`
- [ ] SSL certificates obtained: `./scripts/init-letsencrypt.sh`
- [ ] HTTPS access verified: `https://saytruth.duckdns.org`
- [ ] Backup script tested: `./scripts/backup-db.sh`
- [ ] Automated backups configured (optional)

**Your site is ready! 🚀**
