#!/bin/bash

#==================================================================================
# APProVe Nginx Configuration Generator
# Version: 4.0.0
# Description: Generates nginx reverse proxy configurations from .env file
#==================================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ENV_FILE=".env"
NGINX_CONF_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"

#----------------------------------------------------------------------------------
# Banner
#----------------------------------------------------------------------------------
clear
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         APProVe Nginx Configuration Generator             ║
║                  Version 4.0.0                            ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

#----------------------------------------------------------------------------------
# Check Prerequisites
#----------------------------------------------------------------------------------
echo -e "${BLUE}Checking prerequisites...${NC}"

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}✗ .env file not found!${NC}"
    echo "Please run: bash generate_env.sh first"
    exit 1
fi

if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}⚠ Nginx is not installed.${NC}"
    echo "Install with: sudo apt install nginx"
    exit 1
fi

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root or with sudo${NC}"
    echo "Run with: sudo bash generate_nginx_conf.sh"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites satisfied${NC}"
echo ""

#----------------------------------------------------------------------------------
# Load Environment Variables
#----------------------------------------------------------------------------------
echo -e "${BLUE}Loading environment variables...${NC}"

while IFS='=' read -r key value || [[ -n "$key" ]]; do
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue

    clean_value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//')

    # Export the variable so it's available for the HEREDOC below
    export "$key"="$clean_value"
done < "$ENV_FILE"

echo -e "${GREEN}✓ Environment loaded${NC}\n"

#----------------------------------------------------------------------------------
# Extract Domain Names
#----------------------------------------------------------------------------------
echo -e "${BLUE}Extracting domain configuration...${NC}"

# Function to extract domain from URL
extract_domain() {
    echo "$1" | sed -e 's|https\?://||' -e 's|/.*||'
}

KEYCLOAK_DOMAIN=$(extract_domain "$APPROVE_KEYCLOAK_URL")
FRONTEND_DOMAIN=$(extract_domain "$APPROVE_FRONTEND_URL")
BACKEND_DOMAIN=$(extract_domain "$APPROVE_BACKEND_URL")

echo "  • Keycloak domain: ${KEYCLOAK_DOMAIN}"
echo "  • Frontend domain: ${FRONTEND_DOMAIN}"
echo "  • Backend domain:  ${BACKEND_DOMAIN}"
echo ""

#----------------------------------------------------------------------------------
# Create Keycloak Nginx Configuration
#----------------------------------------------------------------------------------
echo -e "${BLUE}Creating Keycloak nginx configuration...${NC}"

cat > "$NGINX_CONF_DIR/approve-keycloak.conf" << EOF
#==================================================================================
# APProVe Keycloak Nginx Configuration
# Generated: $(date)
#==================================================================================

server {
    listen 80;
    listen [::]:80;
    server_name ${KEYCLOAK_DOMAIN};

    # Redirect HTTP to HTTPS (will be configured by certbot)
    # return 301 https://\$server_name\$request_uri;

    # Temporary location for certbot verification
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        proxy_pass http://127.0.0.1:${AUTH_PORT};

        # Standard proxy headers
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Port \$server_port;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Buffer settings
        proxy_buffering off;
        proxy_request_buffering off;
    }
}

# HTTPS configuration (will be added by certbot)
EOF

echo -e "${GREEN}✓ Keycloak configuration created${NC}"

#----------------------------------------------------------------------------------
# Create Frontend Nginx Configuration
#----------------------------------------------------------------------------------
echo -e "${BLUE}Creating Frontend nginx configuration...${NC}"

cat > "$NGINX_CONF_DIR/approve-frontend.conf" << EOF
#==================================================================================
# APProVe Frontend Nginx Configuration
# Generated: $(date)
#==================================================================================

server {
    listen 80;
    listen [::]:80;
    server_name ${FRONTEND_DOMAIN};

    # Client max body size for file uploads
    client_max_body_size 100M;

    # Redirect HTTP to HTTPS (will be configured by certbot)
    # return 301 https://\$server_name\$request_uri;

    # Temporary location for certbot verification
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        proxy_pass http://127.0.0.1:${FRONTEND_PORT};

        # Standard proxy headers
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Port \$server_port;

        # WebSocket support for live updates
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;

        # Buffer settings
        proxy_buffering off;
        proxy_request_buffering off;
    }
}

# HTTPS configuration (will be added by certbot)
EOF

echo -e "${GREEN}✓ Frontend configuration created${NC}"

#----------------------------------------------------------------------------------
# Create Backend Nginx Configuration
#----------------------------------------------------------------------------------
echo -e "${BLUE}Creating Backend nginx configuration...${NC}"

cat > "$NGINX_CONF_DIR/approve-backend.conf" << EOF
#==================================================================================
# APProVe Backend Nginx Configuration
# Generated: $(date)
#==================================================================================

server {
    listen 80;
    listen [::]:80;
    server_name ${BACKEND_DOMAIN};

    # Client max body size for file uploads
    client_max_body_size 100M;

    # Redirect HTTP to HTTPS (will be configured by certbot)
    # return 301 https://\$server_name\$request_uri;

    # Temporary location for certbot verification
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # Main Backend Service
    location / {
        proxy_pass http://127.0.0.1:${BACKEND_PORT};

        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Port \$server_port;

        proxy_connect_timeout 60s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;

        proxy_buffering off;
    }

    # User Service
    location /user-service/ {
        proxy_pass http://127.0.0.1:${USER_PORT}/;

        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Port \$server_port;
    }

    # Automation Service
    location /automation-service/ {
        proxy_pass http://127.0.0.1:${AUTOMATION_PORT}/;

        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Port \$server_port;
    }

    # Comment Service
    location /comment-service/ {
        proxy_pass http://127.0.0.1:${COMMENT_PORT}/;

        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Port \$server_port;
    }

    # Mail Service
    location /mail-service/ {
        proxy_pass http://127.0.0.1:${EMAIL_PORT}/;

        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Port \$server_port;
    }

    # Manual Service
    location /manual/ {
        proxy_pass http://127.0.0.1:${MANUAL_PORT}/manual/;

        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Port \$server_port;
    }

    # Import Service
    location /import-service/ {
        proxy_pass http://127.0.0.1:${IMPORT_PORT}/;

        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Port \$server_port;
    }
}

# HTTPS configuration (will be added by certbot)
EOF

echo -e "${GREEN}✓ Backend configuration created${NC}"

#----------------------------------------------------------------------------------
# Enable Configurations
#----------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}Enabling nginx configurations...${NC}"

# Remove old symlinks if they exist
rm -f "$NGINX_ENABLED_DIR/approve-keycloak.conf"
rm -f "$NGINX_ENABLED_DIR/approve-frontend.conf"
rm -f "$NGINX_ENABLED_DIR/approve-backend.conf"

# Create new symlinks
ln -s "$NGINX_CONF_DIR/approve-keycloak.conf" "$NGINX_ENABLED_DIR/approve-keycloak.conf"
ln -s "$NGINX_CONF_DIR/approve-frontend.conf" "$NGINX_ENABLED_DIR/approve-frontend.conf"
ln -s "$NGINX_CONF_DIR/approve-backend.conf" "$NGINX_ENABLED_DIR/approve-backend.conf"

echo -e "${GREEN}✓ Configurations enabled${NC}"

#----------------------------------------------------------------------------------
# Test Nginx Configuration
#----------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}Testing nginx configuration...${NC}"

if nginx -t; then
    echo -e "${GREEN}✓ Nginx configuration test passed${NC}"

    # Reload nginx
    echo ""
    echo -e "${BLUE}Reloading nginx...${NC}"
    systemctl reload nginx
    echo -e "${GREEN}✓ Nginx reloaded successfully${NC}"
else
    echo -e "${RED}✗ Nginx configuration test failed${NC}"
    echo "Please check the configuration files and fix any errors."
    exit 1
fi

#----------------------------------------------------------------------------------
# Summary
#----------------------------------------------------------------------------------
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}      Nginx Configuration Complete!                        ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Configuration Files Created:${NC}"
echo "  • ${NGINX_CONF_DIR}/approve-keycloak.conf"
echo "  • ${NGINX_CONF_DIR}/approve-frontend.conf"
echo "  • ${NGINX_CONF_DIR}/approve-backend.conf"
echo ""
echo -e "${YELLOW}Domains Configured:${NC}"
echo "  • Keycloak:  ${KEYCLOAK_DOMAIN}"
echo "  • Frontend:  ${FRONTEND_DOMAIN}"
echo "  • Backend:   ${BACKEND_DOMAIN}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Configure SSL with certbot:"
echo -e "     ${YELLOW}sudo certbot --nginx${NC}"
echo ""
echo "  2. Run the installation script:"
echo -e "     ${YELLOW}bash install.sh${NC}"
echo ""
echo -e "${YELLOW}⚠  Note:${NC} Make sure DNS records for all domains point to this server!"
echo ""