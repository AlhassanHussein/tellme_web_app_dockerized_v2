# TellMe - Anonymous Temporary Messages Platform

A secure, anonymous messaging platform where users can receive temporary anonymous messages through unique shareable links.

## 🚀 Quick Start (Production)

### Prerequisites
- Ubuntu Server (20.04+)
- Docker & Docker Compose
- DuckDNS account

### Deploy in 4 Steps

```bash
# 1. Configure environment
cp .env.example .env
nano .env  # Update DUCKDNS_TOKEN and SSL_EMAIL

# 2. Build and start
docker compose build
docker compose up -d

# 3. Setup SSL
./scripts/init-letsencrypt.sh

# 4. Access your site
# https://saytruth.duckdns.org
```

**📖 Full deployment guide:** See [DEPLOYMENT.md](DEPLOYMENT.md)

---

## 🏗️ Architecture

### Production Setup
- **Backend:** FastAPI (Python) with SQLite
- **Frontend:** Static HTML/CSS/JS served by Nginx
- **Reverse Proxy:** Nginx with SSL/HTTPS
- **SSL:** Let's Encrypt (auto-renewal)
- **DNS:** DuckDNS (dynamic IP updates)

### Containers
```
┌─────────────────────────────────────┐
│  Nginx Reverse Proxy (SSL)         │  :80, :443
│  ├─ /api/* → Backend                │
│  └─ /* → Frontend                   │
└─────────────────────────────────────┘
         │              │
    ┌────┴────┐    ┌────┴────┐
    │ Backend │    │Frontend │
    │ FastAPI │    │  Nginx  │
    └────┬────┘    └─────────┘
         │
    ┌────┴────┐
    │ SQLite  │
    │ Volume  │
    └─────────┘
```

---

## 📁 Project Structure

```
tellme/
├── backend/              # FastAPI application
│   ├── Dockerfile       # Backend container
│   ├── main.py          # FastAPI app
│   ├── database.py      # Database config
│   ├── models.py        # SQLModel models
│   └── routers/         # API routes
├── frontend/            # Static web files
│   ├── Dockerfile       # Frontend container
│   ├── index.html       # Main page
│   ├── public.html      # Public message page
│   ├── private.html     # Private inbox page
│   ├── app.js           # Frontend logic
│   ├── i18n.js          # Multi-language support
│   └── style.css        # Styling
├── nginx/
│   └── nginx.conf       # Reverse proxy config
├── scripts/
│   ├── init-letsencrypt.sh  # SSL setup
│   ├── backup-db.sh         # Database backup
│   └── restore-db.sh        # Database restore
├── docker-compose.yml   # Service orchestration
├── .env                 # Environment variables
└── DEPLOYMENT.md        # Full deployment guide
```

---

## 🔧 Features

### Core Functionality
- ✅ Create temporary anonymous message sessions (6h, 12h, 24h)
- ✅ Unique public/private link pairs
- ✅ Anonymous message submission
- ✅ Private inbox for session owners
- ✅ Automatic session expiration
- ✅ Multi-language support (English, Arabic, Spanish)

### Production Features
- ✅ SSL/HTTPS with Let's Encrypt
- ✅ DuckDNS dynamic DNS integration
- ✅ Persistent data with Docker volumes
- ✅ Automated SSL certificate renewal
- ✅ Database backup/restore scripts
- ✅ Health checks and auto-restart
- ✅ Security headers and best practices

---

## 🛠️ Development

### Local Development

```bash
# Backend
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn backend.main:app --reload

# Frontend
cd frontend
# Open index.html in browser or use a local server
python -m http.server 8080
```

### Environment Variables

```bash
# Production (.env)
DOMAIN_NAME=saytruth.duckdns.org
DUCKDNS_SUBDOMAIN=saytruth
DUCKDNS_TOKEN=your-token
DATABASE_PATH=/app/data/database.db
SSL_EMAIL=your-email@example.com
```

---

## 📊 Database

### Current: SQLite
- Simple, file-based database
- Perfect for small to medium traffic
- Easy backups with provided scripts
- Persistent via Docker volumes

### Future: PostgreSQL
Easy migration path when scaling:
- Update `docker-compose.yml`
- Update `backend/database.py`
- Run migration script

---

## 🔐 Security

- **SSL/HTTPS:** All traffic encrypted
- **Non-root containers:** Security best practice
- **Security headers:** HSTS, X-Frame-Options, etc.
- **Network isolation:** Internal Docker network
- **Secret management:** Environment variables

---

## 📦 Maintenance

### Backup Database
```bash
./scripts/backup-db.sh
```

### Restore Database
```bash
./scripts/restore-db.sh backups/database_backup_YYYYMMDD_HHMMSS.db
```

### View Logs
```bash
docker compose logs -f
docker compose logs backend
docker compose logs nginx
```

### Update Application
```bash
git pull
docker compose up -d --build
```

---

## 🐛 Troubleshooting

See [DEPLOYMENT.md](DEPLOYMENT.md#troubleshooting) for detailed troubleshooting guide.

Quick checks:
```bash
# Check all containers
docker compose ps

# Check logs
docker compose logs -f

# Restart service
docker compose restart backend

# Verify SSL
curl -I https://saytruth.duckdns.org
```

---

## 📚 Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete deployment guide
- **[implementation_plan.md](.gemini/...)** - Technical implementation details
- **[walkthrough.md](.gemini/...)** - Implementation walkthrough

---

## 🌐 Multi-Language Support

The platform supports:
- 🇬🇧 English (default)
- 🇸🇦 Arabic (RTL support)
- 🇪🇸 Spanish

Language switcher available on all pages.

---

## 🚀 Deployment Checklist

- [ ] Docker and Docker Compose installed
- [ ] DuckDNS account and domain configured
- [ ] `.env` file configured with actual values
- [ ] Firewall ports 80 and 443 open
- [ ] Services started: `docker compose up -d`
- [ ] SSL certificates obtained: `./scripts/init-letsencrypt.sh`
- [ ] HTTPS access verified
- [ ] Backup script tested
- [ ] Automated backups configured (optional)

---

## 📝 License

This project is for educational and personal use.

---

## 🤝 Contributing

Contributions welcome! Please ensure:
- Code follows existing style
- Docker builds successfully
- Documentation updated
- Security best practices followed

---

## 📧 Support

For issues:
1. Check logs: `docker compose logs`
2. Review [DEPLOYMENT.md](DEPLOYMENT.md)
3. Check Docker documentation

---

**Built with ❤️ using FastAPI, Docker, and Nginx**
