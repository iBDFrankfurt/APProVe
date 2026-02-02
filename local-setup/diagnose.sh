#!/bin/bash

#==================================================================================
# APProVe Diagnostic Script
# Collects system information and checks for common issues
#==================================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPORT_FILE="diagnostic_report_$(date +%Y%m%d_%H%M%S).txt"

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
echo -e "${BLUE}║          APProVe Diagnostic Report Generator              ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Generating diagnostic report: $REPORT_FILE"
echo ""

# Header
echo "APProVe Diagnostic Report" > "$REPORT_FILE"
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

# Docker
if command -v docker &> /dev/null; then
    check_pass "Docker is installed"
    docker --version | tee -a "$REPORT_FILE"
else
    check_fail "Docker is NOT installed"
fi

# Docker Compose
if command -v docker-compose &> /dev/null; then
    check_pass "Docker Compose is installed"
    docker-compose --version | tee -a "$REPORT_FILE"
else
    check_fail "Docker Compose is NOT installed"
fi

# Git
if command -v git &> /dev/null; then
    check_pass "Git is installed"
    git --version | tee -a "$REPORT_FILE"
else
    check_fail "Git is NOT installed"
fi

# Curl
if command -v curl &> /dev/null; then
    check_pass "Curl is installed"
    curl --version | head -1 | tee -a "$REPORT_FILE"
else
    check_fail "Curl is NOT installed"
fi

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Docker Status
#----------------------------------------------------------------------------------
log_section "3. Docker Engine Status"

if docker info &> /dev/null; then
    check_pass "Docker daemon is running"
    echo "" | tee -a "$REPORT_FILE"
    echo "Docker Info:" | tee -a "$REPORT_FILE"
    docker info | grep -E "Server Version|Operating System|Total Memory|CPUs" | tee -a "$REPORT_FILE"
else
    check_fail "Docker daemon is NOT running"
fi

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Registry Authentication
#----------------------------------------------------------------------------------
log_section "4. Registry Authentication"

if grep -q "registry.gitlab.ibdf-frankfurt.de" ~/.docker/config.json 2>/dev/null; then
    check_pass "Authenticated with GitLab registry"
else
    check_fail "NOT authenticated with GitLab registry"
    echo "Run: docker login registry.gitlab.ibdf-frankfurt.de" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Hosts File Configuration
#----------------------------------------------------------------------------------
log_section "5. Hosts File Configuration"

REQUIRED_HOSTS=(
    "approve.backend"
    "approve.auth"
    "approve.user"
    "approve.frontend"
    "approve.comment"
    "approve.mails"
    "approve.automation"
    "approve.import"
    "approve.draft"
    "approve.eureka"
    "approve.postgres"
    "approve.mongo"
)

HOSTS_FILE="/etc/hosts"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    HOSTS_FILE="/c/Windows/System32/drivers/etc/hosts"
fi

echo "Checking hosts file: $HOSTS_FILE" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

for host in "${REQUIRED_HOSTS[@]}"; do
    if grep -q "$host" "$HOSTS_FILE" 2>/dev/null; then
        check_pass "$host is configured"
    else
        check_fail "$host is NOT configured"
    fi
done

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Docker Network
#----------------------------------------------------------------------------------
log_section "6. Docker Network"

if docker network ls | grep -q "approve_network"; then
    check_pass "approve_network exists"
    echo "" | tee -a "$REPORT_FILE"
    echo "Network Details:" | tee -a "$REPORT_FILE"
    docker network inspect approve_network | grep -E "Name|Subnet" | tee -a "$REPORT_FILE"
else
    check_fail "approve_network does NOT exist"
    echo "Run: docker network create approve_network" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Running Containers
#----------------------------------------------------------------------------------
log_section "7. Running Containers"

if docker ps &> /dev/null; then
    echo "Container Status:" | tee -a "$REPORT_FILE"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "approve\.|NAMES" | tee -a "$REPORT_FILE"

    echo "" | tee -a "$REPORT_FILE"

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
# Service Health Checks
#----------------------------------------------------------------------------------
log_section "8. Service Health Checks"

check_service() {
    local name=$1
    local url=$2

    if curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null | grep -qE "200|401"; then
        check_pass "$name is responding"
    else
        check_fail "$name is NOT responding at $url"
    fi
}

check_service "Frontend" "http://localhost:8001/actuator/health"
check_service "Backend" "http://localhost:8000/api/health"
check_service "Keycloak" "http://localhost:8080/health"
check_service "Eureka" "http://localhost:8761/actuator/health"

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Port Availability
#----------------------------------------------------------------------------------
log_section "9. Port Availability Check"

REQUIRED_PORTS=(5432 27017 8080 8888 8761 8000 8001 9001 3234 4234 3233 8002 8003)

echo "Checking if required ports are in use:" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

for port in "${REQUIRED_PORTS[@]}"; do
    if command -v netstat &> /dev/null; then
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            check_pass "Port $port is in use (expected)"
        else
            check_warn "Port $port is NOT in use"
        fi
    elif command -v lsof &> /dev/null; then
        if lsof -i ":$port" &> /dev/null; then
            check_pass "Port $port is in use (expected)"
        else
            check_warn "Port $port is NOT in use"
        fi
    else
        echo "Cannot check port $port (no netstat/lsof)" | tee -a "$REPORT_FILE"
    fi
done

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Environment File
#----------------------------------------------------------------------------------
log_section "10. Environment Configuration"

if [ -f ".env" ]; then
    check_pass ".env file exists"
    echo "" | tee -a "$REPORT_FILE"
    echo "Key Configuration Values:" | tee -a "$REPORT_FILE"
    grep -E "^[A-Z_]+=.+" .env | grep -v PASSWORD | grep -v KEY | head -20 | tee -a "$REPORT_FILE"
else
    check_fail ".env file NOT found"
fi

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Recent Logs
#----------------------------------------------------------------------------------
log_section "11. Recent Installation Logs"

if [ -f "install.log" ]; then
    check_pass "install.log found"
    echo "" | tee -a "$REPORT_FILE"
    echo "Last 20 lines of install.log:" | tee -a "$REPORT_FILE"
    tail -20 install.log | tee -a "$REPORT_FILE"
else
    check_warn "install.log not found (installation may not have run)"
fi

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Docker Resource Usage
#----------------------------------------------------------------------------------
log_section "12. Docker Resource Usage"

if docker stats --no-stream &> /dev/null; then
    echo "Current Resource Usage:" | tee -a "$REPORT_FILE"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E "approve\.|NAME" | tee -a "$REPORT_FILE"
else
    check_warn "Cannot retrieve Docker stats"
fi

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Recommendations
#----------------------------------------------------------------------------------
log_section "13. Recommendations"

# Check available memory
if command -v free &> /dev/null; then
    AVAILABLE_MEM=$(free -g | awk '/^Mem:/{print $7}')
    if [ "$AVAILABLE_MEM" -lt 4 ]; then
        check_warn "Low available memory (${AVAILABLE_MEM}GB). Recommend 6GB+ for optimal performance"
    fi
fi

# Check Docker memory limit
if docker info 2>/dev/null | grep -q "Total Memory"; then
    DOCKER_MEM=$(docker info 2>/dev/null | grep "Total Memory" | awk '{print $3}')
    echo "Docker has access to ${DOCKER_MEM}GiB memory" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Summary
#----------------------------------------------------------------------------------
log_section "14. Summary"

echo "Report saved to: $REPORT_FILE" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Count issues
FAIL_COUNT=$(grep -c "✗" "$REPORT_FILE" || true)
WARN_COUNT=$(grep -c "⚠" "$REPORT_FILE" || true)

if [ "$FAIL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! System appears healthy.${NC}" | tee -a "$REPORT_FILE"
elif [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "${RED}Found $FAIL_COUNT critical issues that need attention.${NC}" | tee -a "$REPORT_FILE"
else
    echo -e "${YELLOW}Found $WARN_COUNT warnings. System should work but may have minor issues.${NC}" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"
echo "For detailed troubleshooting, see README.md" | tee -a "$REPORT_FILE"

#----------------------------------------------------------------------------------
# Cleanup Recommendations
#----------------------------------------------------------------------------------
if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "" | tee -a "$REPORT_FILE"
    echo "Suggested next steps:" | tee -a "$REPORT_FILE"
    echo "1. Review the failures above" | tee -a "$REPORT_FILE"
    echo "2. Check install.log for detailed error messages" | tee -a "$REPORT_FILE"
    echo "3. Try: docker-compose logs -f [service-name]" | tee -a "$REPORT_FILE"
    echo "4. For a fresh start: docker-compose down -v && ./install.sh" | tee -a "$REPORT_FILE"
fi

echo ""
echo -e "${GREEN}Diagnostic report complete!${NC}"
echo "Report saved to: $REPORT_FILE"