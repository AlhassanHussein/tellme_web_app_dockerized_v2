# Quick Start Guide

## ✅ Services are Running!

All containers have been started successfully in **HTTP-only mode** (no SSL yet).

### Current Status

```bash
docker compose ps
```

You should see 5 containers running:
- ✅ `tellme_backend` - FastAPI application
- ✅ `tellme_frontend` - Static file server
- ✅ `tellme_nginx` - Reverse proxy (HTTP only)
- ✅ `tellme_certbot` - SSL certificate manager
- ✅ `tellme_duckdns` - Dynamic DNS updater

---

## 🌐 Access Your Application

**Local access (HTTP):**
```
http://localhost
```

**Public access (HTTP):**
```
http://saytruth.duckdns.org
```

> ⚠️ **Note:** Currently running on HTTP only. SSL/HTTPS will be added in the next step.

---

## 🔐 Next Step: Setup SSL/HTTPS

### Before Running SSL Setup:

1. **Verify DuckDNS is working:**
   ```bash
   nslookup saytruth.duckdns.org
   ```
   This should return your server's public IP.

2. **Update your `.env` file:**
   ```bash
   nano .env
   ```
   Make sure these are set correctly:
   - `DUCKDNS_TOKEN` - Your actual DuckDNS token
   - `SSL_EMAIL` - Your email for Let's Encrypt notifications

3. **Ensure ports are open:**
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

### Run SSL Setup:

```bash
./scripts/init-letsencrypt.sh
```

This script will:
1. Request SSL certificate from Let's Encrypt
2. Switch nginx to HTTPS configuration
3. Enable automatic HTTP → HTTPS redirect

After successful SSL setup, your site will be available at:
```
https://saytruth.duckdns.org
```

---

## 📊 Useful Commands

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f nginx
docker compose logs -f duckdns
```

### Check Container Status
```bash
docker compose ps
```

### Restart a Service
```bash
docker compose restart backend
docker compose restart nginx
```

### Stop All Services
```bash
docker compose down
```

### Start All Services
```bash
docker compose up -d
```

---

## 🐛 Troubleshooting

### If nginx fails to start:
```bash
# Check nginx logs
docker compose logs nginx

# Verify nginx config
docker compose exec nginx nginx -t
```

### If backend fails:
```bash
# Check backend logs
docker compose logs backend

# Verify database
docker compose exec backend ls -la /app/data/
```

### If DuckDNS not updating:
```bash
# Check DuckDNS logs
docker compose logs duckdns

# Manually update DuckDNS
curl "https://www.duckdns.org/update?domains=saytruth&token=YOUR_TOKEN&ip="
```

---

## 📝 Important Files

- **nginx/nginx.conf** - Current nginx config (HTTP-only)
- **nginx/nginx-ssl.conf** - SSL-enabled config (will be used after SSL setup)
- **nginx/nginx-http-only.conf** - HTTP-only config (backup)
- **.env** - Environment variables (update DuckDNS token here)
- **DEPLOYMENT.md** - Full deployment documentation

---

## 🎯 Current Setup Summary

✅ **Completed:**
- All Docker containers built and running
- Backend API accessible
- Frontend serving static files
- Nginx reverse proxy working (HTTP)
- DuckDNS integration active
- Database persistent volume created

⏳ **Next:**
- Obtain SSL certificate with `./scripts/init-letsencrypt.sh`
- Enable HTTPS
- Test production deployment

---

For more details, see [DEPLOYMENT.md](../DEPLOYMENT.md)
