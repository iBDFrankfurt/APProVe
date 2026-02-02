# 🚀 APProVe Server Deployment - Quick Start

**Get APProVe running on your Ubuntu server in under 30 minutes using our automated toolset.**

---

## Prerequisites Checklist

Before you begin, ensure you have:

- [ ] Ubuntu 20.04+ server with a public IP
- [ ] 8GB RAM (Recommended), 4+ cores, 20GB+ disk space
- [ ] 3 subdomains configured in DNS (pointing to your server)
- [ ] Root or sudo access
- [ ] GitLab account with registry access

---

## Quick Installation (5 Steps)

### Step 1: Install System Dependencies (5 minutes)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker & Compose
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo apt install -y docker-compose

# Install Server Tools
sudo apt install -y git nginx certbot python3-certbot-nginx make jq

# Configure Firewall
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

---

### Step 2: Configure DNS

**Create 3 A records pointing to your server IP:**

| Service | Example Subdomain | Target |
|--------|------|-------|
| Frontend | `approve.example.com` | YOUR_SERVER_IP |
| Auth (Keycloak) | `auth.example.com` | YOUR_SERVER_IP |
| Backend API | `backend.example.com` | YOUR_SERVER_IP |

---

### Step 3: Project Setup (2 minutes)

```bash
# Create directory
mkdir -p ~/approve-server && cd ~/approve-server

# [Action Required] Transfer your setup files here:
# .env.tmp, docker-compose.yml, Makefile, and all .sh scripts

# Make scripts executable
chmod +x *.sh

# Login to GitLab Registry
make login
```

---

### Step 4: Environment & Network (5 minutes)

We will now use the `Makefile` to trigger the interactive configuration.

```bash
# 1. Generate your .env file
make env

# 2. Generate Nginx site configs
make nginx

# 3. Obtain SSL Certificates via Certbot
# Select 'Redirect' if prompted to ensure HTTPS-only access
make certbot
```

---

### Step 5: Deploy APProVe (15 minutes)

This triggers the automated installation, Keycloak setup, and admin creation.

```bash
# Run the full installation suite
make install
```

**☕ Installation takes 10-15 minutes.** The script will wait for databases and core services to become healthy before proceeding.

---

## Post-Installation Health Check

Run the new diagnostic tool to ensure everything is configured correctly:

```bash
make health
```
*This generates a `diagnostic_report_server_*.txt` file and checks Nginx, Docker, SSL, and internal microservice health.*

---

## Access Your Installation

**🌐 Frontend:** `https://approve.example.com`  
**🔐 Admin Console:** `https://auth.example.com/admin`

**Admin Credentials:**
- **Username:** As configured in `make env` (default: `approve-admin`)
- **Password:** As configured in `make env`

---

## Common Management Commands

The `Makefile` provides shortcuts for daily operations:

| Command | Action |
|---------|--------|
| `make status` | View running containers |
| `make logs` | Stream logs from all services |
| `make restart` | Restart the entire stack |
| `make update` | Pull latest images and restart |
| `make backup` | Create immediate DB backups |
| `make db-postgres` | Open a CLI shell to the SQL database |
| `make clean` | Stop and remove containers |

---

## Backup Strategy

Your data is stored in Docker volumes. To prevent data loss:

```bash
# Run a manual backup now
make backup

# Add to crontab for daily 2 AM backups
(crontab -l 2>/dev/null; echo "0 2 * * * cd $(pwd) && make backup >> backup.log 2>&1") | crontab -
```

---

## Troubleshooting

### ❌ "Nginx configuration test failed"
Run `sudo nginx -t` to see the specific line error. Ensure your `.env` URLs do not contain trailing slashes.

### ❌ "Timeout waiting for backend-service"
Check the logs: `make logs-backend`. Usually caused by the server having less than the required 6GB of available RAM.

### ❌ SSL / Connection Refused
Ensure your firewall is open (`sudo ufw status`) and that Nginx is running (`systemctl status nginx`).

---

**🎉 Congratulations! APProVe is now deployed in a production-ready server environment.**