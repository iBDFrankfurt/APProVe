#!/bin/bash

#==================================================================================
# APProVe Server Diagnostic Script
# Collects system information, checks Nginx, SSL, and Docker status
#==================================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPORT_FILE="diagnostic_report_server_$(date +%Y%m%d_%H%M%S).txt"

#----------------------------------------------------------------------------------
# Helper Functions
#----------------------------------------------------------------------------------
log_section() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$REPORT_FILE"
    echo -e "${BLUE}$1${NC}" | tee -a "$REPORT_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n" | tee -a "$REPORT_FILE"
}

check_pass() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$REPORT_FILE"
}

check_fail() {
    echo -e "${RED}✗ $1${NC}" | tee -a "$REPORT_FILE"
}

check_warn() {
    echo -e "${YELLOW}⚠ $1${NC}" | tee -a "$REPORT_FILE"
}

#----------------------------------------------------------------------------------
# Start Report
#----------------------------------------------------------------------------------
clear
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       APProVe Server Diagnostic Report Generator          ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Generating diagnostic report: $REPORT_FILE"
echo ""

# Header
echo "APProVe Server Diagnostic Report" > "$REPORT_FILE"
echo "Generated: $(date)" >> "$REPORT_FILE"
echo "Hostname: $(hostname)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

#----------------------------------------------------------------------------------
# System Information
#----------------------------------------------------------------------------------
log_section "1. System Information"

# Operating System
echo "Operating System:" | tee -a "$REPORT_FILE"
uname -a | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Memory
echo "Memory Information:" | tee -a "$REPORT_FILE"
if command -v free &> /dev/null; then
    free -h | tee -a "$REPORT_FILE"
else
    echo "free command not available" | tee -a "$REPORT_FILE"
fi
echo "" | tee -a "$REPORT_FILE"

# Disk Space
echo "Disk Space:" | tee -a "$REPORT_FILE"
df -h | grep -E '^/dev/' | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Required Software
#----------------------------------------------------------------------------------
log_section "2. Required Software Check"

check_cmd() {
    if command -v "$1" &> /dev/null; then
        check_pass "$1 is installed"
    else
        check_fail "$1 is NOT installed"
    fi
}

check_cmd docker
check_cmd docker-compose
check_cmd git
check_cmd curl
check_cmd nginx
check_cmd certbot
check_cmd openssl

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Environment Configuration
#----------------------------------------------------------------------------------
log_section "3. Environment Configuration"

if [ -f ".env" ]; then
    check_pass ".env file exists"

    # Load .env for checks
    set -o allexport
    source .env
    set +o allexport

    echo "" | tee -a "$REPORT_FILE"
    echo "Public URLs Configured:" | tee -a "$REPORT_FILE"
    echo "  Frontend: $APPROVE_FRONTEND_URL" | tee -a "$REPORT_FILE"
    echo "  Backend:  $APPROVE_BACKEND_URL" | tee -a "$REPORT_FILE"
    echo "  Keycloak: $APPROVE_KEYCLOAK_URL" | tee -a "$REPORT_FILE"
else
    check_fail ".env file NOT found"
fi

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Nginx Status
#----------------------------------------------------------------------------------
log_section "4. Nginx Reverse Proxy Status"

if systemctl is-active --quiet nginx; then
    check_pass "Nginx service is running"
else
    check_fail "Nginx service is NOT running"
fi

echo "Checking Nginx configuration syntax:" | tee -a "$REPORT_FILE"
if nginx -t 2>&1 | tee -a "$REPORT_FILE" | grep -q "successful"; then
    check_pass "Nginx syntax is valid"
else
    check_fail "Nginx syntax errors detected"
fi

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Docker Engine & Network
#----------------------------------------------------------------------------------
log_section "5. Docker Status"

if docker info &> /dev/null; then
    check_pass "Docker daemon is running"
else
    check_fail "Docker daemon is NOT running"
fi

if docker network ls | grep -q "approve_network"; then
    check_pass "approve_network exists"
else
    check_fail "approve_network does NOT exist"
fi

# Registry Auth
if grep -q "registry.gitlab.ibdf-frankfurt.de" ~/.docker/config.json 2>/dev/null; then
    check_pass "Authenticated with GitLab registry"
else
    check_warn "NOT authenticated with GitLab registry (pulls may fail)"
fi

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Running Containers
#----------------------------------------------------------------------------------
log_section "6. Running Containers"

if docker ps &> /dev/null; then
    echo "Container Status:" | tee -a "$REPORT_FILE"
    # Show Approve containers + Name + Status + Ports
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "approve\.|NAMES" | tee -a "$REPORT_FILE"

    CONTAINER_COUNT=$(docker ps | grep -c "approve\." || true)
    if [ "$CONTAINER_COUNT" -gt 0 ]; then
        check_pass "$CONTAINER_COUNT APProVe containers running"
    else
        check_warn "No APProVe containers running"
    fi
else
    check_fail "Cannot access Docker containers"
fi

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Internal Service Health (Bypassing Nginx)
#----------------------------------------------------------------------------------
log_section "7. Internal Service Health (Localhost)"

check_local_service() {
    local name=$1
    local port=$2
    local path=$3

    local url="http://localhost:${port}${path}"

    if curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null | grep -qE "200|401|403|404"; then
        check_pass "$name responding on port $port"
    else
        check_fail "$name NOT responding on port $port"
    fi
}

# Check based on standard ports defined in Nginx generator
check_local_service "Frontend" "8001" "/actuator/health"
check_local_service "Backend" "8000" "/api/actuator/health"
check_local_service "Keycloak" "8080" "/health"
check_local_service "Eureka" "8761" "/actuator/health"

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Public URL Reachability
#----------------------------------------------------------------------------------
log_section "8. Public URL Reachability"

if [ -f ".env" ]; then
    check_public_url() {
        local url=$1
        if [ -z "$url" ]; then return; fi

        local code=$(curl -s -o /dev/null -w "%{http_code}" "$url" --connect-timeout 5)
        if [[ "$code" =~ ^(200|301|302|401|403)$ ]]; then
            check_pass "$url is reachable (HTTP $code)"
        else
            check_warn "$url might be unreachable (HTTP $code)"
        fi
    }

    check_public_url "$APPROVE_FRONTEND_URL"
    check_public_url "$APPROVE_BACKEND_URL/api/actuator/health"
    check_public_url "$APPROVE_KEYCLOAK_URL"
else
    echo "Skipping (no .env loaded)" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Logs Check
#----------------------------------------------------------------------------------
log_section "9. Logs"

if [ -f "install.log" ]; then
    check_pass "install.log found"
    echo "Last 10 lines of install.log:" | tee -a "$REPORT_FILE"
    tail -10 install.log | tee -a "$REPORT_FILE"
else
    check_warn "install.log not found"
fi

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Summary
#----------------------------------------------------------------------------------
log_section "10. Summary"

FAIL_COUNT=$(grep -c "✗" "$REPORT_FILE" || true)
WARN_COUNT=$(grep -c "⚠" "$REPORT_FILE" || true)

if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! System appears healthy.${NC}" | tee -a "$REPORT_FILE"
elif [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "${RED}Found $FAIL_COUNT critical issues.${NC}" | tee -a "$REPORT_FILE"
else
    echo -e "${YELLOW}Found $WARN_COUNT warnings.${NC}" | tee -a "$REPORT_FILE"
fi

echo ""
echo -e "${GREEN}Report saved to: $REPORT_FILE${NC}"