# Production Docker Setup - Refactored for Static IP

Clean, minimal, production-grade Docker Compose setup for web applications with SSL/HTTPS support.

## 🏗️ Architecture

```
Internet (Static IP)
        ↓
    Port 80/443
        ↓
┌───────────────────────┐
│  Nginx Reverse Proxy  │ ← SSL Certificates
│  (Port 80, 443)       │   (Certbot)
└───────────────────────┘
         │
    ┌────┴────┐
    │         │
┌───▼───┐ ┌──▼──────┐
│Backend│ │Frontend │
│FastAPI│ │ Nginx   │
└───┬───┘ └─────────┘
    │
┌───▼────┐
│SQLite  │
│Volume  │
└────────┘
```

## 📦 Components

| Service | Purpose | Exposed Ports |
|---------|---------|---------------|
| **nginx** | Reverse proxy with SSL | 80, 443 |
| **backend** | FastAPI application | Internal only |
| **frontend** | Static file server | Internal only |
| **certbot** | SSL certificate manager | None |

## 🚀 Quick Start

### 1. Prerequisites

- Ubuntu Server with **static Elastic IP**
- Domain name pointing to your server's IP
- Docker & Docker Compose installed
- Ports 80 and 443 open in firewall

```bash
# Install Docker (if needed)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose plugin
sudo apt install docker-compose-plugin -y
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with your values
nano .env
```

**Update these values:**
```bash
DOMAIN_NAME=your-domain.com      # Your actual domain
SSL_EMAIL=your-email@example.com # For SSL notifications
```

### 3. Deploy Application

```bash
# Build and start all containers
docker compose up -d

# Check status
docker compose ps
```

### 4. Setup SSL/HTTPS

```bash
# Run one-time SSL initialization
./scripts/init-ssl.sh
```

**That's it!** Your site is now live at `https://your-domain.com` 🎉

---

## 📁 Project Structure

```
.
├── backend/
│   ├── Dockerfile              # Backend container
│   ├── main.py                 # FastAPI application
│   ├── database.py             # Database configuration
│   └── ...
├── frontend/
│   ├── Dockerfile              # Frontend container
│   ├── nginx.conf              # Frontend nginx config
│   ├── index.html              # Static files
│   └── ...
├── nginx/
│   ├── nginx.conf              # Active config (generated)
│   ├── nginx-ssl.conf          # SSL template
│   └── nginx-http-only.conf    # HTTP-only config
├── scripts/
│   ├── init-ssl.sh             # SSL setup script
│   ├── backup-db.sh            # Database backup
│   └── restore-db.sh           # Database restore
├── docker-compose.yml          # Service orchestration
├── .env                        # Environment variables (gitignored)
├── .env.example                # Environment template
└── README-REFACTORED.md        # This file
```

---

## 🔧 Configuration

### Environment Variables

All configuration is in `.env` file:

```bash
# Domain (must point to your static IP)
DOMAIN_NAME=your-domain.com

# Email for SSL certificate notifications
SSL_EMAIL=your-email@example.com

# Database path (inside container)
DATABASE_PATH=/app/data/database.db
```

### Changing Domain

To change your domain:

1. Update DNS to point new domain to your server
2. Update `DOMAIN_NAME` in `.env`
3. Re-run SSL setup: `./scripts/init-ssl.sh`

No code changes needed!

### Migrating to PostgreSQL

To switch from SQLite to PostgreSQL:

1. Add PostgreSQL service to `docker-compose.yml`
2. Update `.env` with PostgreSQL credentials
3. Update `backend/database.py` to use `DATABASE_URL`
4. Restart: `docker compose up -d`

---

## 🔐 SSL/HTTPS

### How It Works

1. **Initial Setup**: `init-ssl.sh` requests certificate from Let's Encrypt
2. **ACME Challenge**: Certbot uses HTTP-01 challenge via `/.well-known/acme-challenge/`
3. **Auto-Renewal**: Certbot checks twice daily and renews 30 days before expiry
4. **Nginx Reload**: Nginx reloads every 6 hours to pick up renewed certificates

### Certificate Locations

- **Certificates**: Docker volume `certbot_conf`
- **Inside container**: `/etc/letsencrypt/live/${DOMAIN_NAME}/`
- **Files**:
  - `fullchain.pem` - Certificate chain
  - `privkey.pem` - Private key

### Manual Renewal

```bash
# Force renewal
docker compose run --rm certbot renew --force-renewal

# Reload nginx
docker compose exec nginx nginx -s reload
```

---

## 🛠️ Maintenance

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f nginx
docker compose logs -f certbot
```

### Restart Services

```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart backend
docker compose restart nginx
```

### Update Application

```bash
# Pull latest changes
git pull

# Rebuild and restart
docker compose down
docker compose build
docker compose up -d
```

### Database Backup

```bash
# Create backup
./scripts/backup-db.sh

# Backups stored in: backups/database_backup_YYYYMMDD_HHMMSS.db
```

### Database Restore

```bash
# List backups
ls -lh backups/

# Restore from backup
./scripts/restore-db.sh backups/database_backup_20260119_120000.db
```

---

## 🐛 Troubleshooting

### SSL Certificate Issues

**Problem**: Certificate request fails

**Solutions**:

1. **Verify DNS**:
   ```bash
   dig +short your-domain.com
   # Should return your server's IP
   ```

2. **Check port 80**:
   ```bash
   sudo netstat -tlnp | grep :80
   # Should show nginx
   ```

3. **Test ACME challenge**:
   ```bash
   curl http://your-domain.com/.well-known/acme-challenge/test
   ```

4. **Check Certbot logs**:
   ```bash
   docker compose logs certbot
   ```

### Nginx Issues

**Problem**: 502 Bad Gateway

**Solutions**:

1. **Check backend is running**:
   ```bash
   docker compose ps backend
   docker compose logs backend
   ```

2. **Test backend directly**:
   ```bash
   docker compose exec nginx wget -O- http://backend:8000/api/
   ```

3. **Reload nginx config**:
   ```bash
   docker compose exec nginx nginx -t  # Test config
   docker compose exec nginx nginx -s reload
   ```

### Container Won't Start

**Problem**: Container exits immediately

**Solutions**:

1. **Check logs**:
   ```bash
   docker compose logs <service-name>
   ```

2. **Verify environment**:
   ```bash
   docker compose config
   ```

3. **Rebuild container**:
   ```bash
   docker compose build --no-cache <service-name>
   docker compose up -d
   ```

---

## 📊 Monitoring

### Check Container Status

```bash
# List all containers
docker compose ps

# Resource usage
docker stats

# Disk usage
docker system df
```

### Health Checks

```bash
# Backend health
curl http://localhost/api/

# Frontend
curl -I http://localhost

# SSL certificate expiry
docker compose exec certbot certbot certificates
```

---

## 🔒 Security Best Practices

✅ **Implemented**:
- SSL/TLS encryption (TLS 1.2+)
- Modern cipher suites
- Security headers (HSTS, X-Frame-Options, etc.)
- Non-root users in containers
- Internal Docker network
- Secrets in `.env` (gitignored)

**Recommendations**:
- Keep Docker images updated
- Monitor logs regularly
- Enable firewall (UFW)
- Regular database backups
- Use strong passwords if adding authentication

---

## 📚 Key Differences from Previous Setup

### ✅ Removed
- ❌ DuckDNS container (not needed with static IP)
- ❌ DuckDNS environment variables
- ❌ Dynamic DNS update logic

### ✅ Improved
- ✨ Cleaner `docker-compose.yml` with comprehensive comments
- ✨ Simplified `.env` configuration
- ✨ Better SSL initialization script with DNS verification
- ✨ Domain placeholder system for easy domain changes
- ✨ Production-ready nginx configuration
- ✨ Comprehensive documentation

### ✅ Maintained
- ✅ All containers properly separated
- ✅ SSL/HTTPS with Let's Encrypt
- ✅ Auto-renewal of certificates
- ✅ Persistent volumes for data
- ✅ Health checks
- ✅ Restart policies
- ✅ Backup/restore scripts

---

## 🎯 Production Checklist

Before going live:

- [ ] Domain points to server's static IP
- [ ] `.env` configured with actual values
- [ ] Firewall allows ports 80 and 443
- [ ] Docker containers running: `docker compose ps`
- [ ] SSL certificates obtained: `./scripts/init-ssl.sh`
- [ ] HTTPS working: `curl -I https://your-domain.com`
- [ ] HTTP redirects to HTTPS
- [ ] Database backup tested: `./scripts/backup-db.sh`
- [ ] Automated backups configured (optional)

---

## 📞 Support

### Useful Commands

```bash
# Quick health check
docker compose ps && curl -I https://your-domain.com

# Full restart
docker compose down && docker compose up -d

# View all logs
docker compose logs -f

# Clean up
docker system prune -a
```

### Documentation

- **Docker Compose**: https://docs.docker.com/compose/
- **Let's Encrypt**: https://letsencrypt.org/docs/
- **Nginx**: https://nginx.org/en/docs/

---

**Built for production with ❤️**

*Clean, minimal, maintainable, and ready to scale.*
