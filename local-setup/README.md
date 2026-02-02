# APProVe - Local Installation Guide

> **Version:** 4.0.0  
> **Last Updated:** January 2026

This guide provides comprehensive instructions for deploying the APProVe microservices ecosystem locally for development and testing purposes.

---

## 📋 Table of Contents

- [System Requirements](#-system-requirements)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Detailed Installation](#-detailed-installation)
- [Post-Installation](#-post-installation)
- [Service Architecture](#-service-architecture)
- [Troubleshooting](#-troubleshooting)
- [Maintenance](#-maintenance)
- [FAQ](#-faq)

---

## 💻 System Requirements

### Minimum Requirements
- **OS:** Windows 10/11 (with WSL2 or Git Bash), macOS 11+, or Linux (Ubuntu 20.04+/Debian 11+)
- **RAM:** 6 GB available (8 GB+ recommended for optimal performance)
- **Disk Space:** 2 GB free space (5 GB recommended)
- **CPU:** 4 cores recommended
- **Network:** Access to `gitlab.ibdf-frankfurt.de` (VPN required for remote access)

### Recommended Specifications
- **RAM:** 16 GB total system memory
- **Disk:** SSD with 10 GB+ free space
- **CPU:** 8+ cores for better performance
- **Network:** Stable internet connection with low latency

---

## 🔧 Prerequisites

Install the following tools before proceeding:

### 1. Docker & Docker Compose

**Installation:**
- **Windows/Mac:** [Docker Desktop](https://www.docker.com/products/docker-desktop)
- **Linux:**
  ```bash
  # Ubuntu/Debian
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo usermod -aG docker $USER
  ```

**Verification:**
```bash
docker --version          # Should show Docker version 20.10+
docker-compose --version  # Should show Compose version 2.0+
docker info              # Should show Docker daemon running
```

### 2. Git

**Installation:**
- **Windows:** [Git for Windows](https://git-scm.com/downloads) (includes Git Bash)
- **Mac:** `brew install git` or [Download](https://git-scm.com/downloads)
- **Linux:** `sudo apt install git` (Ubuntu/Debian)

**Verification:**
```bash
git --version  # Should show Git version 2.20+
```

### 3. Bash Shell (Windows Only)

**Windows users MUST use one of the following:**
- **Git Bash** (recommended, included with Git for Windows)
- **WSL2** (Ubuntu or Debian distribution)

**❌ NOT SUPPORTED:** Windows CMD, PowerShell

---

## ⚡ Quick Start

For experienced users who want to get started immediately:

```bash
# 1. Clone and navigate to local-setup directory
cd local-setup

# 2. Authenticate with registry
docker login registry.gitlab.ibdf-frankfurt.de

# 3. Run installation script
chmod +x install.sh
./install.sh

# 4. Access APProVe
# Open: http://approve.frontend:8001
# Login: approve-admin / approve-password
```

---

## 📖 Detailed Installation

### Step 1: Network Configuration

APProVe uses custom domain names for service communication. Add these entries to your hosts file:

#### Windows
1. Open Notepad **as Administrator**
2. Open file: `C:\Windows\System32\drivers\etc\hosts`
3. Add the following lines at the end:

```text
# APProVe Local Development
127.0.0.1 approve.backend
127.0.0.1 approve.auth
127.0.0.1 approve.user
127.0.0.1 approve.frontend
127.0.0.1 approve.comment
127.0.0.1 approve.mails
127.0.0.1 approve.automation
127.0.0.1 approve.import
127.0.0.1 approve.draft
127.0.0.1 approve.eureka
127.0.0.1 approve.postgres
127.0.0.1 approve.mongo
```

4. Save and close

#### macOS/Linux
```bash
sudo nano /etc/hosts
# Add the lines above, then save (Ctrl+O, Enter, Ctrl+X)
```

**Verification:**
```bash
ping approve.frontend  # Should resolve to 127.0.0.1
```

---

### Step 2: Docker Registry Authentication

APProVe images are hosted in a private GitLab registry.

**Authenticate:**
```bash
docker login registry.gitlab.ibdf-frankfurt.de
```

**When prompted:**
- **Username:** Your GitLab username
- **Password/Token:** Your GitLab Personal Access Token (PAT)

**Creating a Personal Access Token:**
1. Log in to GitLab: https://gitlab.ibdf-frankfurt.de
2. Go to: User Settings → Access Tokens
3. Create token with scope: `read_registry`
4. Copy the token (you won't see it again!)

**Troubleshooting Authentication:**
- ❌ "Access Forbidden" → Token lacks `read_registry` scope
- ❌ "Unauthorized" → Wrong username/token
- ✅ "Login Succeeded" → You're ready to proceed!

---

### Step 3: Project Setup

**Clone or navigate to the repository:**
```bash
cd /path/to/approve/local-setup
```

**Verify directory structure:**
```bash
ls -la
# You should see:
# - install.sh
# - docker-compose.yml
# - .env
# - README.md
```

---

### Step 4: Run Installation

**Make the script executable:**
```bash
chmod +x install.sh
```

**Execute the installation:**
```bash
./install.sh
```

**What the script does:**
1. ✅ Verifies system prerequisites
2. ✅ Checks Docker daemon status
3. ✅ Confirms registry authentication
4. ✅ Clones/updates dependencies (Keycloak themes & SPI)
5. ✅ Creates Docker network
6. ✅ Pulls all service images
7. ✅ Starts infrastructure services (Postgres, MongoDB, Config, Eureka)
8. ✅ Configures Keycloak (realm, clients, users, roles)
9. ✅ Starts application services
10. ✅ Performs health checks
11. ✅ Displays access information

**Expected Duration:** 5-15 minutes (depending on network speed)

**Progress Indicators:**
- Green checkmarks (✅) indicate successful steps
- Yellow warnings (⚠️) are informational (usually safe to ignore)
- Red errors (❌) require attention

---

## 🎯 Post-Installation

### Access URLs

| Service | URL | Purpose |
|---------|-----|---------|
| **Frontend (Main App)** | http://approve.frontend:8001 | Primary user interface |
| **Keycloak (Auth)** | http://approve.auth:8080 | Identity & access management |
| **Eureka (Registry)** | http://approve.eureka:8761 | Service discovery dashboard |
| **Backend API** | http://approve.backend:8000 | REST API endpoint |
| **Documentation** | http://localhost:443 | User manual |

### Default Credentials

**Application Admin:**
- Username: `approve-admin`
- Password: `approve-password`
- Email: `admin@mail.de`

**Keycloak Admin:**
- Username: `adminuser`
- Password: `adminpass`
- Console: http://approve.auth:8080/admin

**Service Account:**
- Username: `restuser`
- Password: `restuser_pass`

> ⚠️ **Security Note:** Change these passwords before deploying to production!

### First Login

1. Open http://approve.frontend:8001
2. Click "Login"
3. Enter credentials: `approve-admin` / `approve-password`
4. You may be prompted to:
    - Update your profile
    - Change your password
    - Accept terms & conditions

---

## 🏗️ Service Architecture

### Infrastructure Layer
```
┌─────────────┐  ┌──────────┐  ┌──────────┐
│ PostgreSQL  │  │ MongoDB  │  │ Keycloak │
│  (Port:     │  │ (Port:   │  │ (Port:   │
│   5432)     │  │  27017)  │  │  8080)   │
└─────────────┘  └──────────┘  └──────────┘
```

### Service Discovery & Configuration
```
┌───────────────┐  ┌─────────────────┐
│ Config Server │  │ Eureka Registry │
│ (Port: 8888)  │  │ (Port: 8761)    │
└───────────────┘  └─────────────────┘
```

### Application Services
```
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│ Backend  │  │ Frontend │  │   User   │  │ Comments │
│ (8000)   │  │ (8001)   │  │  (9001)  │  │ (3234)   │
└──────────┘  └──────────┘  └──────────┘  └──────────┘

┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│  Email   │  │Automation│  │  Draft   │  │  Import  │
│ (4234)   │  │ (3233)   │  │ (8002)   │  │ (8003)   │
└──────────┘  └──────────┘  └──────────┘  └──────────┘
```

### Service Dependencies

**Critical Path (Sequential):**
1. PostgreSQL → Keycloak
2. Keycloak → Config Service
3. Config Service → Eureka
4. Eureka → Backend Service
5. Backend Service → Frontend

**Parallel Services (After Backend):**
- User Service
- Comments Service (requires MongoDB)
- Email Service (requires MongoDB)
- Automation Service (requires MongoDB)
- Draft Service
- Import Service

---

## 🔧 Troubleshooting

### Common Issues

#### 1. "Docker is not running"
**Symptoms:**
```
❌ Error: Docker is not running. Please start Docker Desktop/Daemon.
```

**Solution:**
- **Windows/Mac:** Launch Docker Desktop, wait for whale icon to be green
- **Linux:** `sudo systemctl start docker`
- Verify: `docker info`

---

#### 2. "Access Forbidden" During Image Pull
**Symptoms:**
```
Error response from daemon: pull access denied for registry.gitlab.ibdf-frankfurt.de/...
```

**Solutions:**
1. Re-authenticate: `docker login registry.gitlab.ibdf-frankfurt.de`
2. Verify token has `read_registry` scope
3. Check GitLab account has access to the projects
4. Ensure VPN is connected (if remote)

---

#### 3. Service Won't Start / Health Check Fails
**Symptoms:**
```
❌ Timeout waiting for backend-service.
```

**Diagnosis:**
```bash
# Check service logs
docker logs approve.backend

# Check service status
docker-compose ps

# Check container health
docker inspect approve.backend | grep -A 10 "Health"
```

**Common Causes:**
- **Port conflicts:** Another service using the same port
- **Memory exhaustion:** Increase Docker memory limit (Docker Desktop → Settings → Resources)
- **Database not ready:** Check postgres/mongo logs
- **Network issues:** Verify `approve_network` exists

**Solutions:**
```bash
# Restart specific service
docker-compose restart backend-service

# View real-time logs
docker-compose logs -f backend-service

# Reset everything (nuclear option)
docker-compose down -v
docker network prune
./install.sh
```

---

#### 4. Keycloak Configuration Fails
**Symptoms:**
```
❌ Failed to authenticate with Keycloak.
```

**Solutions:**
1. Wait longer (Keycloak takes 2-3 minutes to fully start)
2. Check Keycloak logs: `docker logs approve.auth`
3. Verify database connection:
   ```bash
   docker exec -it approve.postgres psql -U postgres_admin -d auth_db -c "\dt"
   ```
4. Manual verification:
    - Open http://approve.auth:8080
    - Should show Keycloak landing page

---

#### 5. "Cannot Connect to Frontend"
**Symptoms:**
- Browser shows "This site can't be reached"
- http://approve.frontend:8001 doesn't load

**Checklist:**
1. ✅ Hosts file configured correctly?
   ```bash
   ping approve.frontend  # Should resolve to 127.0.0.1
   ```
2. ✅ Frontend service running?
   ```bash
   docker ps | grep approve.frontend
   ```
3. ✅ Port 8001 available?
   ```bash
   # Windows
   netstat -ano | findstr :8001
   # Linux/Mac
   lsof -i :8001
   ```
4. ✅ Service healthy?
   ```bash
   curl http://localhost:8001/actuator/health
   ```

---

#### 6. Windows Line Ending Issues
**Symptoms:**
```
/bin/bash^M: bad interpreter: No such file or directory
```

**Solution:**
```bash
# Automatic fix (script handles this)
dos2unix install.sh

# Manual fix
sed -i 's/\r$//' install.sh
```

---

### Port Conflicts

If you receive "port already in use" errors:

**Identify conflicting process:**
```bash
# Windows
netstat -ano | findstr :<PORT>

# Linux/Mac
lsof -i :<PORT>
```

**Resolution options:**
1. Stop the conflicting service
2. Change port in `.env` file
3. Remove conflicting Docker container

---

### Performance Issues

**Symptoms:**
- Services very slow to start
- High CPU/memory usage
- Timeouts during health checks

**Solutions:**

1. **Increase Docker resources:**
    - Docker Desktop → Settings → Resources
    - Recommended: 8 GB RAM, 4 CPUs

2. **Free up system resources:**
   ```bash
   # Stop unused Docker containers
   docker stop $(docker ps -aq)
   
   # Prune unused resources
   docker system prune -a
   ```

3. **Adjust health check timeouts in docker-compose.yml:**
   ```yaml
   healthcheck:
     interval: 60s      # Increase from 30s
     timeout: 20s       # Increase from 10s
     start_period: 180s # Increase from 120s
   ```

---

## 🛠️ Maintenance

### Useful Commands

**View service logs:**
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend-service

# Last 100 lines
docker-compose logs --tail=100 frontend-service
```

**Service management:**
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart specific service
docker-compose restart backend-service

# View service status
docker-compose ps

# View resource usage
docker stats
```

**Database access:**
```bash
# PostgreSQL
docker exec -it approve.postgres psql -U postgres_admin -d approve_db

# MongoDB
docker exec -it approve.mongo mongosh -u mongo_admin -p mongopass
```

**Clean slate (reset everything):**
```bash
# Stop and remove containers, networks, volumes
docker-compose down -v

# Remove network
docker network rm approve_network

# Prune all unused resources
docker system prune -a --volumes

# Reinstall
./install.sh
```

---

### Updating Services

**Pull latest images:**
```bash
docker-compose pull
docker-compose up -d
```

**Update specific service:**
```bash
# Update image tag in .env
nano .env

# Pull and restart
docker-compose pull backend-service
docker-compose up -d backend-service
```

---

### Backup & Restore

**Backup databases:**
```bash
# PostgreSQL
docker exec approve.postgres pg_dump -U postgres_admin approve_db > backup_postgres.sql

# MongoDB
docker exec approve.mongo mongodump -u mongo_admin -p mongopass --out=/tmp/backup
docker cp approve.mongo:/tmp/backup ./backup_mongo
```

**Restore databases:**
```bash
# PostgreSQL
docker exec -i approve.postgres psql -U postgres_admin approve_db < backup_postgres.sql

# MongoDB
docker cp ./backup_mongo approve.mongo:/tmp/backup
docker exec approve.mongo mongorestore -u mongo_admin -p mongopass /tmp/backup
```

---

## ❓ FAQ

### Q: Can I run APProVe in production?
**A:** This setup is for **local development only**. Production requires:
- Proper SSL/TLS certificates
- Hardened security configuration
- External database services
- Load balancing
- Monitoring & logging infrastructure

---

### Q: How do I add a new user?
**A:**
1. Go to http://approve.auth:8080/admin
2. Login with Keycloak admin credentials
3. Select realm: `local-test`
4. Users → Add User
5. Set credentials and assign roles

---

### Q: Can I change the ports?
**A:** Yes! Edit the `.env` file:
```bash
nano .env
# Change port variables (e.g., FRONTEND_PORT=8001)
# Restart: docker-compose down && docker-compose up -d
```

---

### Q: How do I enable debug logging?
**A:** Add to `.env`:
```bash
LOG_LEVEL=DEBUG
SPRING_PROFILES_ACTIVE=debug
```
Then restart services: `docker-compose restart`

---

### Q: Services keep crashing - what should I do?
**A:**
1. Check logs: `docker-compose logs -f <service>`
2. Verify system requirements (RAM, disk space)
3. Check for port conflicts
4. Try a clean reinstall (see Maintenance section)
5. Review error messages in `install.log`

---

### Q: How do I connect from other devices on my network?
**A:**
1. Get your local IP: `ipconfig` (Windows) or `ifconfig` (Linux/Mac)
2. Update `.env` to use your IP instead of `localhost`
3. Update hosts file on other devices
4. Ensure firewall allows connections on required ports

---

### Q: What if I encounter "x509: certificate signed by unknown authority"?
**A:** This happens with self-signed certificates. Set:
```bash
export GIT_SSL_NO_VERIFY=1
export DOCKER_TLS_VERIFY=0
```
⚠️ **Not recommended for production**

---

## 📚 Additional Resources

- **APProVe Documentation:** http://localhost:443 (after installation)
- **Keycloak Documentation:** https://www.keycloak.org/documentation
- **Docker Documentation:** https://docs.docker.com
- **Issue Tracker:** [Your GitLab Issues URL]

---

## 🤝 Support

If you encounter issues not covered in this guide:

1. Check `install.log` for detailed error messages
2. Review service logs: `docker-compose logs`
3. Consult your team's internal documentation
4. Contact system administrator

---

## 📝 Changelog

### Version 4.0.0 (2026-01-29)
- ✨ Added comprehensive health checks
- ✨ Improved error handling in installation script
- ✨ Enhanced logging with color-coded output
- ✨ Better resource limit configuration
- ✨ Automated dependency management
- 📚 Significantly expanded documentation
- 🐛 Fixed Windows line ending issues
- 🔧 Optimized service startup order

---

**Happy coding! 🚀**