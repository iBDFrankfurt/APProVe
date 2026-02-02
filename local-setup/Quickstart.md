# 🚀 APProVe Quick Start Guide

**Get APProVe running in 5 minutes!**

---

## Prerequisites Checklist

Before you begin, ensure you have:

- [ ] Docker Desktop installed and running
- [ ] Git installed
- [ ] Bash terminal (Git Bash on Windows)
- [ ] 6GB+ RAM available
- [ ] 2GB+ disk space free
- [ ] VPN connected (if remote)

---

## Step 1: Hosts File (1 minute)

Copy-paste this into your hosts file:

**Windows:** `C:\Windows\System32\drivers\etc\hosts` (open Notepad as Admin)  
**Mac/Linux:** `/etc/hosts` (use `sudo nano /etc/hosts`)

```
127.0.0.1 approve.backend approve.auth approve.user approve.frontend approve.comment approve.mails approve.automation approve.import approve.draft approve.eureka approve.postgres approve.mongo
```

---

## Step 2: Docker Login (1 minute)

```bash
docker login registry.gitlab.ibdf-frankfurt.de
```

Enter your GitLab username and Personal Access Token (needs `read_registry` scope).

---

## Step 3: Installation (3-10 minutes)

```bash
cd local-setup
chmod +x install.sh
./install.sh
```

The script will:
- ✅ Check prerequisites
- ✅ Pull Docker images (this is the slowest part)
- ✅ Start services
- ✅ Configure Keycloak
- ✅ Run health checks

**Coffee break recommended ☕** - First run takes longer due to image downloads.

---

## Step 4: Access APProVe

Open your browser and navigate to:

**🌐 http://approve.frontend:8001**

**Login Credentials:**
- Username: `approve-admin`
- Password: `approve-password`

---

## That's It! 🎉

You're now running APProVe locally!

---

## Quick Commands

```bash
# View logs
docker-compose logs -f

# Restart a service
docker-compose restart backend-service

# Stop everything
docker-compose down

# Check service status
docker-compose ps
```

---

## Common Issues & Quick Fixes

### ❌ "Docker is not running"
**Fix:** Start Docker Desktop, wait for green status

### ❌ "Access Forbidden" during pull
**Fix:** Re-run `docker login registry.gitlab.ibdf-frankfurt.de`

### ❌ "Can't reach approve.frontend:8001"
**Fix:** Check hosts file configuration (Step 1)

### ❌ Service won't start
**Fix:** Check logs: `docker logs approve.<service-name>`

---

## Need Help?

See the full [README.md](README.md) for detailed troubleshooting.

---

## Useful URLs

| Service | URL |
|---------|-----|
| Frontend | http://approve.frontend:8001 |
| Keycloak | http://approve.auth:8080 |
| Eureka | http://approve.eureka:8761 |

---

**Happy coding! 🚀**