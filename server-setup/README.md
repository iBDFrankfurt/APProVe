# APProVe Server Deployment Guide

<div align="center">
  <b>APProVe <sup>by iBDF</sup></b>
  <br>
  <p>Production Server Installation Manual</p>
  <p><b>Version 4.0.0</b></p>
</div>

This guide provides comprehensive instructions for deploying the APProVe microservices ecosystem on a server for production purposes.
If you want to start quickly head over to [Quickstart](quickstart.md).
---

## 📋 Table of Contents

- [System Requirements](#-system-requirements)
- [Architecture Overview](#-architecture-overview)
- [Prerequisites](#-prerequisites)
- [DNS Configuration](#-dns-configuration)
- [Installation Steps](#-installation-steps)
- [Post-Installation](#-post-installation)
- [Database Backups](#-database-backups)
- [Troubleshooting](#-troubleshooting)
- [Maintenance](#-maintenance)
- [Security Considerations](#-security-considerations)
- [FAQ](#-faq)

---

## 💻 System Requirements

### Minimum Requirements
- **OS:** Ubuntu 20.04 LTS or newer (Debian 11+ also supported)
- **RAM:** 6 GB (8 GB+ recommended)
- **CPU:** 4 cores (8+ cores recommended)
- **Disk Space:** 10 GB free space (20 GB+ recommended)
- **Network:** Public IP address with open ports 80 and 443
- **Domains:** 3 subdomains pointing to your server

### Recommended Specifications
- **RAM:** 16 GB total system memory
- **CPU:** 8+ cores for optimal performance
- **Disk:** SSD with 50 GB+ free space
- **Network:** Stable internet with low latency

---

## 🏗️ Architecture Overview

APProVe consists of multiple microservices deployed behind an Nginx reverse proxy:

```
┌─────────────────────────────────────────────────────────┐
│                     Internet                             │
└─────────────────────┬───────────────────────────────────┘
                      │ HTTPS (Port 443)
                      │ HTTP (Port 80 - redirected)
                      ▼
┌─────────────────────────────────────────────────────────┐
│                   Nginx Reverse Proxy                    │
│  ┌─────────────┬──────────────┬──────────────────┐     │
│  │ Keycloak    │  Frontend    │   Backend        │     │
│  │ (auth.*)    │  (approve.*) │   (backend.*)    │     │
│  └──────┬──────┴──────┬───────┴─────────┬────────┘     │
└─────────┼─────────────┼─────────────────┼──────────────┘
          │             │                 │
          │             │                 │
┌─────────▼─────────────▼─────────────────▼──────────────┐
│               Docker Network (approve_network)         │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Infrastructure Services                         │  │
│  │  • PostgreSQL (Port 5432)                        │  │
│  │  • MongoDB (Port 27017)                          │  │
│  │  • Keycloak (Port 8093)                          │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Core Services                                   │  │
│  │  • Config Service (Port 8888)                    │  │
│  │  • Eureka Service Registry (Port 8761)           │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Application Services                            │  │
│  │  • Backend (Port 8010)                           │  │
│  │  • Frontend (Port 8011)                          │  │
│  │  • User Service (Port 9011)                      │  │
│  │  • Comments Service (Port 3334)                  │  │
│  │  • Email Service (Port 4334)                     │  │
│  │  • Automation Service (Port 3433)                │  │
│  │  • Import Service (Port 8013)                    │  │
│  │  • Manual Service (Port 8443)                    │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

**Key Points:**
- All services run on localhost and are not directly accessible from the internet
- Nginx acts as reverse proxy and SSL termination point
- Only ports 80 and 443 are exposed to the internet
- Internal service communication happens on Docker network

---

## 🔧 Prerequisites

### 1. Ubuntu Server Setup

Ensure your Ubuntu server is up to date:

```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Install Docker

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Enable Docker to start on boot
sudo systemctl enable docker
sudo systemctl start docker

# Verify installation
docker --version
```

### 3. Check Docker Compose

The scripts use the Compose **plugin** (`docker compose`, with a space). The script from step 2 installs it already.
The old standalone program `docker-compose` (with a hyphen) is not needed.

```bash
docker compose version
# if missing:
sudo apt install -y docker-compose-plugin
```

### 4. Install Additional Tools

```bash
sudo apt install -y git curl nginx certbot python3-certbot-nginx
```

### 5. Firewall Configuration

```bash
# Allow SSH (if not already allowed)
sudo ufw allow OpenSSH

# Allow HTTP and HTTPS
sudo ufw allow 'Nginx Full'

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

---

## 🌐 DNS Configuration

**Before proceeding, configure DNS records for your domains:**

You need **3 subdomains** pointing to your server's public IP address:

| Subdomain | Purpose | Example |
|-----------|---------|---------|
| `auth.*` | Keycloak authentication | `auth.example.com` |
| `approve.*` or your choice | Frontend application | `approve.example.com` |
| `backend.*` | Backend API | `backend.example.com` |

**DNS Records (all A records):**
```
auth.example.com      -> YOUR_SERVER_IP
approve.example.com   -> YOUR_SERVER_IP
backend.example.com   -> YOUR_SERVER_IP
```

**Verification:**
```bash
# Test DNS resolution
dig auth.example.com +short
dig approve.example.com +short
dig backend.example.com +short
```

All three should return your server's IP address.

---

## 📦 Installation Steps

### Step 1: Download Installation Files

```bash
# Use a new, empty folder for every instance (e.g. /opt/approve-server)
sudo mkdir -p /opt/approve-server && cd /opt/approve-server
git clone https://gitlab.ibdf-frankfurt.de/uct/open-approve.git
cd open-approve/server-setup
```

Git asks for your GitLab username and a Personal Access Token (scope `read_repository`). Do not store these
credentials on the server permanently. Alternatively copy the `server-setup` folder to the server.

**Files in `server-setup`:**
- `.env.tmp` - Environment template
- `docker-compose.yml` - Service definitions
- `generate_env.sh` - Environment configuration script
- `generate_nginx_conf.sh` - Nginx configuration generator
- `install_server.sh` - Main installation script
- `backup.sh` - Database backup script
- `diagnostic_server.sh` - Diagnostic report
- `Makefile` - Shortcuts (`make help`)

### Step 2: Authenticate with Docker Registry

```bash
docker login registry.gitlab.ibdf-frankfurt.de
```

**You will need:**
- GitLab username
- Personal Access Token with `read_registry` scope

**Creating a Personal Access Token:**
1. Go to: https://gitlab.ibdf-frankfurt.de/-/profile/personal_access_tokens
2. Create token with `read_registry` scope
3. Copy the token (you won't see it again!)

### Step 3: Generate Environment Configuration

```bash
chmod +x generate_env.sh
bash generate_env.sh
```

**You will be prompted for:**

1. **Domain Configuration:**
    - Keycloak URL (e.g., `https://auth.example.com`)
    - Frontend URL (e.g., `https://approve.example.com`)
    - Backend URL (e.g., `https://backend.example.com`)

2. **Keycloak Configuration:**
    - Realm name (default: `production`)
    - Admin credentials
    - Service user credentials

3. **APProVe Admin User:**
    - Username
    - Password
    - Email

4. **Database Credentials:**
    - PostgreSQL username and password
    - MongoDB username and password

5. **Instance:**
    - Container name suffix (e.g. `-test`; leave empty if this is the only APProVe instance on the server)
    - Docker Compose project name (default `approve-server`)

**⚠️ Important:** Use strong, unique passwords for all credentials!

**⚠️ One project name per instance:** the databases are stored in the Docker volumes
`<project name>_postgres_data` and `<project name>_mongo_data`. A second instance with the same project name uses
the **same databases** as the first one. For an existing installation keep its project name – otherwise its data is
no longer found.

### Step 4: Generate Nginx Configuration

```bash
chmod +x generate_nginx_conf.sh
sudo bash generate_nginx_conf.sh
```

This script will:
- Stop if one of the three domains is already served by another enabled nginx site (nothing is changed then)
- Create nginx configuration files for all three domains in `/etc/nginx/sites-available/`:
  `approve<suffix>-keycloak.conf`, `approve<suffix>-frontend.conf`, `approve<suffix>-backend.conf`
  (e.g. `approve-test-keycloak.conf` with the suffix `-test`), so several instances do not overwrite each other
- Enable them in `/etc/nginx/sites-enabled/`
- Test the nginx configuration
- Reload nginx

> **Older installations with a suffix** have files named `approve-keycloak.conf` etc. (without suffix). When you run
> the script again there, it stops with "Domain already in use" – remove the three old links in
> `/etc/nginx/sites-enabled/` first.

### Step 5: Configure SSL Certificates

```bash
sudo certbot --nginx
```

**Certbot will:**
1. Detect your nginx configurations
2. Ask which domains to secure (select all three)
3. Automatically obtain SSL certificates
4. Configure nginx for HTTPS
5. Set up automatic renewal

**Test automatic renewal:**
```bash
sudo certbot renew --dry-run
```

### Step 6: Run Installation Script

```bash
chmod +x install_server.sh
bash install_server.sh
```

**The installation script will:**
1. ✅ Check system prerequisites
2. ✅ Verify Docker registry authentication
3. ✅ Load environment configuration
4. ✅ Clone Keycloak themes and event listener
5. ✅ Create Docker network
6. ✅ Pull all service images
7. ✅ Start infrastructure services (PostgreSQL, MongoDB, Keycloak)
8. ✅ Start core services (Config, Eureka)
9. ✅ Configure Keycloak (realm, client, users)
10. ✅ Start application services
11. ✅ Run health checks
12. ✅ Display access information

**Expected Duration:** 10-20 minutes (depending on network speed)

---

## 🎯 Post-Installation

### Verify Installation

**1. Check all services are running:**
```bash
docker compose ps
```

All services should show status: `Up` or `Up (healthy)`

**2. Check nginx status:**
```bash
sudo systemctl status nginx
```

**3. Test URLs in your browser:**
- Frontend: https://approve.example.com
- Keycloak: https://auth.example.com
- Backend API: https://backend.example.com/api/health

### First Login

1. Navigate to your frontend URL
2. Click "Login"
3. Use the admin credentials you configured:
    - Username: (from `.env` - default: `approve-admin`)
    - Password: (from `.env` - default: `approve-password`)

### Access Keycloak Admin Console

1. Navigate to: https://auth.example.com/admin
2. Login with Keycloak admin credentials:
    - Username: (from `.env` - default: `adminuser`)
    - Password: (from `.env` - default: `adminpass`)

---

## 💾 Database Backups

### Manual Backup

```bash
chmod +x backup.sh
bash backup.sh
```

This creates backups of:
- PostgreSQL (Keycloak database)
- PostgreSQL (APProVe database)
- MongoDB (Comments, emails, automation data)

**Backups are stored in:** `./backups/`

### Automated Backups with Cron

**Create daily backup at 2 AM:**

```bash
# Edit crontab
crontab -e

# Add this line:
0 2 * * * cd /path/to/approve-server && bash backup.sh >> backup.log 2>&1
```

### Restore from Backup

**PostgreSQL:**
```bash
# Restore Keycloak database
gunzip < backups/postgres_auth_TIMESTAMP.sql.gz | \
  docker exec -i approve.postgres psql -U postgres_admin

# Restore APProVe database
gunzip < backups/postgres_project_TIMESTAMP.sql.gz | \
  docker exec -i approve.postgres psql -U postgres_admin
```

**MongoDB:**
```bash
docker exec -i approve.mongo mongorestore \
  --authenticationDatabase admin \
  -u mongo_admin \
  -p mongopass \
  --archive < backups/mongo_TIMESTAMP.dump
```

---

## 🔧 Troubleshooting

### Service Won't Start

**Check logs:**
```bash
docker compose logs -f <service-name>

# Examples:
docker compose logs -f backend-service
docker compose logs -f auth
docker compose logs -f frontend-service
```

**Common issues:**
- **Database not ready:** Wait for PostgreSQL/MongoDB to be fully started
- **Port conflicts:** Check if another service is using the same port
- **Memory issues:** Increase server RAM or adjust Docker limits

### Cannot Access Frontend

**1. Check nginx:**
```bash
sudo nginx -t
sudo systemctl status nginx
```

**2. Check SSL certificates:**
```bash
sudo certbot certificates
```

**3. Check DNS:**
```bash
dig approve.example.com +short
```

**4. Check firewall:**
```bash
sudo ufw status
```

### Keycloak Configuration Issues

**Start from scratch (fresh installation):**

> ⚠️ The PostgreSQL volume holds **both** databases: Keycloak (`auth_db`, users and roles) **and** APProVe
> (`approve_db`, all projects). Removing it deletes all projects as well. Run `bash backup.sh` first. To fix only
> Keycloak settings, use the Keycloak admin console instead.

```bash
# Removes the containers AND the volumes of this instance (project name from .env)
docker compose down -v

# Reinstall
bash install_server.sh
```

### Performance Issues

**Check resource usage:**
```bash
docker stats

# Check disk space
df -h

# Check memory
free -h
```

**Optimize:**
```bash
# Restart services
docker compose restart

# Prune unused resources
docker system prune -a
```

---

## 🛠️ Maintenance

### Useful Commands

**Service management:**
```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart specific service
docker compose restart backend-service

# View logs
docker compose logs -f

# Check status
docker compose ps
```

**Update services:**
```bash
# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d
```

**Database access:**
```bash
# PostgreSQL
docker exec -it approve.postgres psql -U postgres_admin -d approve_db

# MongoDB
docker exec -it approve.mongo mongosh -u mongo_admin -p mongopass
```

### Monitoring

**Check service health:**
```bash
# Backend health
curl https://backend.example.com/api/actuator/health

# Keycloak health
curl https://auth.example.com/realms/master

# Frontend health
curl https://approve.example.com/actuator/health
```

**Set up monitoring (recommended):**
- Install Prometheus + Grafana for metrics
- Configure log aggregation (ELK stack)
- Set up uptime monitoring (e.g., UptimeRobot)

---

## 🔒 Security Considerations

### Essential Security Measures

**1. Change Default Passwords**

Edit `.env` file and update ALL passwords:
```bash
nano .env

# Change these:
APPROVE_POSTGRES_PASSWORD=...
APPROVE_MONGO_PASSWORD=...
APPROVE_KEYCLOAK_ADMIN_PASSWORD=...
KEYCLOAK_USER_PASSWORD=...
APPROVE_ADMIN_PASSWORD=...
```

**2. Firewall Configuration**

Only expose necessary ports:
```bash
sudo ufw status
# Should only show: 22 (SSH), 80 (HTTP), 443 (HTTPS)
```

**3. SSL/TLS**

- Always use HTTPS in production
- Keep certificates up to date (Certbot auto-renews)
- Test SSL configuration: https://www.ssllabs.com/ssltest/

**4. Regular Updates**

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
cd ~/approve-server
docker compose pull
docker compose up -d
```

**5. Backup Strategy**

- Automate daily backups
- Store backups off-site
- Test restore procedures regularly

**6. Access Control**

- Use strong passwords
- Implement 2FA in Keycloak
- Regularly review user access
- Monitor failed login attempts

**7. Database Security**

- Databases are only accessible from localhost
- Change default credentials
- Regular security audits

---

## ❓ FAQ

### Q: Can I run multiple APProVe instances on the same server?

**A:** Yes. Give every instance its own folder, its own domains and these three settings in `.env`
(`generate_env.sh` asks for the first two):

```bash
# Instance 1                              # Instance 2
CONTAINER_NAME_SUFFIX=                    CONTAINER_NAME_SUFFIX=-dev
COMPOSE_PROJECT_NAME=approve-server       COMPOSE_PROJECT_NAME=approve-server-dev
AUTH_PORT=8093 ... IMPORT_PORT=8013       AUTH_PORT=8095 ... IMPORT_PORT=8017
POSTGRES_HOST_PORT=5432                   POSTGRES_HOST_PORT=15432
MONGO_HOST_PORT=27017                     MONGO_HOST_PORT=27018
```

Do **not** change `POSTGRES_PORT` / `MONGO_PORT` – they are the ports inside the Docker network.

- `CONTAINER_NAME_SUFFIX` keeps the container names apart and gives each instance its own nginx files
  (`approve-dev-*.conf`).
- `COMPOSE_PROJECT_NAME` keeps the **databases** apart (Docker volumes `<project>_postgres_data`). Two instances with
  the same project name share their data.
- The host ports (`*_PORT` of the services and `*_HOST_PORT` of the databases) must differ, otherwise the second
  instance does not start.
- Run `docker compose` commands and `make` only in the folder of the instance you mean.

---

### Q: How do I upgrade to a new version?

**A:**
```bash
# 1. Backup first!
bash backup.sh

# 2. Set the new image versions in .env (e.g. :4.0.0 -> :4.0.1)
nano .env

# 3. Pull new images
docker compose pull

# 4. Restart services
docker compose up -d
```

---

### Q: What if I lose my `.env` file?

**A:** The `.env` file contains critical configuration. Store a backup securely off-server. You can regenerate it using `generate_env.sh`, but you'll need to reconfigure everything.

---

### Q: How do I change the domain names after installation?

**A:**
1. Update DNS records
2. Edit `.env` file with new URLs
3. Run: `sudo bash generate_nginx_conf.sh`
4. Run: `sudo certbot --nginx`
5. Restart: `docker compose down && docker compose up -d`

---

### Q: Can I use this on a different port than 443?

**A:** Not recommended for production. Browsers expect HTTPS on port 443. You can modify nginx configurations for development/testing.

---

### Q: How much does it cost to run APProVe?

**A:** Server costs depend on your hosting provider:
- **Small instance** (6GB RAM, 4 cores): ~$20-40/month
- **Recommended** (16GB RAM, 8 cores): ~$50-100/month
- **Domain + SSL:** Domain costs vary; SSL is free with Let's Encrypt

---

### Q: What backup retention policy should I use?

**A:** Recommended strategy:
- **Daily backups:** Keep for 7 days
- **Weekly backups:** Keep for 4 weeks
- **Monthly backups:** Keep for 12 months

---

## 📚 Additional Resources

- **APProVe GitLab:** https://gitlab.ibdf-frankfurt.de/uct/open-approve
- **Keycloak Documentation:** https://www.keycloak.org/documentation
- **Docker Documentation:** https://docs.docker.com
- **Nginx Documentation:** https://nginx.org/en/docs/
- **Certbot Documentation:** https://certbot.eff.org/docs/

---

## 🤝 Support

If you encounter issues:

1. Check the logs: `docker compose logs -f`
2. Review the troubleshooting section above
3. Check GitLab issues
4. Contact your system administrator

---

**Production deployment complete! 🚀**

For questions or support, please contact your iBDF administrator.
