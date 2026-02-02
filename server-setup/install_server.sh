#!/bin/bash

#==================================================================================
# APProVe Server Installation Script
# Version: 4.0.0
# Description: Automated setup for APProVe microservices ecosystem on Ubuntu server
#==================================================================================

set -e  # Exit on any error
set -o pipefail  # Catch errors in pipes

#----------------------------------------------------------------------------------
# CONFIGURATION
#----------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/install.log"
REGISTRY="registry.gitlab.ibdf-frankfurt.de"
REQUIRED_MEMORY_GB=6
REQUIRED_DISK_GB=10

#----------------------------------------------------------------------------------
# COLOR CODES
#----------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#----------------------------------------------------------------------------------
# LOGGING FUNCTIONS
#----------------------------------------------------------------------------------
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"
}

#----------------------------------------------------------------------------------
# BANNER
#----------------------------------------------------------------------------------
show_banner() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║         APProVe Server Installation Script                ║
    ║                    Version 4.0.0                          ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

#----------------------------------------------------------------------------------
# HEALTH CHECK FUNCTIONS
#----------------------------------------------------------------------------------
wait_for_container() {
    local container_name="$1"
    local service_name="$2"
    local max_retries="${3:-60}"
    local count=0

    log_info "Waiting for ${service_name} container to be healthy..."

    while [ $count -lt $max_retries ]; do
        local status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "unstarted")

        if [ "$status" == "healthy" ]; then
            log "✅ ${service_name} is healthy!"
            return 0
        fi

        echo -n "."
        sleep 2
        count=$((count + 1))
    done

    log_error "Timeout waiting for ${service_name}."
    return 1
}

wait_for_service() {
    local url="$1"
    local service_name="$2"
    local max_retries="${3:-60}"
    local count=0

    log_info "Waiting for ${service_name} to be ready at ${url}..."

    while [ $count -lt $max_retries ]; do
        local response_code
        response_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")

        if [[ "$response_code" == "200" || "$response_code" == "401" || "$response_code" == "403" || "$response_code" == "404" ]]; then
            log "✅ ${service_name} is ready!"
            return 0
        fi

        echo -n "."
        sleep 5
        count=$((count + 1))
    done

    log_error "Timeout waiting for ${service_name}."
    log_error "Check logs: docker logs ${service_name,,}"
    return 1
}

#----------------------------------------------------------------------------------
# PREREQUISITE CHECKS
#----------------------------------------------------------------------------------
check_prerequisites() {
    log "🔍 Checking system prerequisites..."

    # Check required binaries
    local required_bins=("docker" "docker-compose" "git" "curl")
    for cmd in "${required_bins[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "${cmd} is not installed."
            log_error "Please install ${cmd} and try again."
            exit 1
        fi
    done
    log "✅ All required binaries found."

    # Check Docker daemon
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker daemon is not running."
        log_error "Please start Docker daemon: sudo systemctl start docker"
        exit 1
    fi
    log "✅ Docker daemon is running."

    # Check Docker Compose version
    local compose_version=$(docker compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    log_info "Docker Compose version: ${compose_version}"

    # Check available memory
    if command -v free &> /dev/null; then
        local available_memory_gb=$(free -g | awk '/^Mem:/{print $7}')
        if [ "$available_memory_gb" -lt "$REQUIRED_MEMORY_GB" ]; then
            log_warning "Available memory (${available_memory_gb}GB) is below recommended (${REQUIRED_MEMORY_GB}GB)."
            log_warning "Performance may be degraded."
        else
            log "✅ Sufficient memory available (${available_memory_gb}GB)."
        fi
    fi

    # Check available disk space
    local available_disk_gb=$(df -BG "$SCRIPT_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_disk_gb" -lt "$REQUIRED_DISK_GB" ]; then
        log_warning "Available disk space (${available_disk_gb}GB) is below recommended (${REQUIRED_DISK_GB}GB)."
    else
        log "✅ Sufficient disk space available (${available_disk_gb}GB)."
    fi
}

#----------------------------------------------------------------------------------
# REGISTRY AUTHENTICATION CHECK
#----------------------------------------------------------------------------------
check_registry_auth() {
    log "🔐 Checking registry authentication..."

    if ! grep -q "$REGISTRY" ~/.docker/config.json 2>/dev/null; then
        log_warning "Not authenticated with ${REGISTRY}."
        log_info "Please authenticate now..."

        if ! docker login "$REGISTRY"; then
            log_error "Registry authentication failed."
            exit 1
        fi
    fi

    log "✅ Authenticated with ${REGISTRY}."
}

#----------------------------------------------------------------------------------
# ENVIRONMENT SETUP
#----------------------------------------------------------------------------------
setup_environment() {
    log "⚙️  Setting up environment..."

    if [ ! -f "${SCRIPT_DIR}/.env" ]; then
        log_error ".env file not found in ${SCRIPT_DIR}."
        log_error "Please run: bash generate_env.sh first"
        exit 1
    fi

    # Fix CRLF line endings (Windows compatibility)
    tr -d '\r' < "${SCRIPT_DIR}/.env" > "${SCRIPT_DIR}/.env.unix" && mv "${SCRIPT_DIR}/.env.unix" "${SCRIPT_DIR}/.env"

    # Load environment variables
    set -o allexport
    source "${SCRIPT_DIR}/.env"
    set +o allexport

    log "✅ Environment configured."
}

#----------------------------------------------------------------------------------
# GIT REPOSITORIES UPDATE
#----------------------------------------------------------------------------------
update_dependencies() {
    log "📦 Updating project dependencies..."

    update_repo() {
        local url="$1"
        local dir="$2"

        if [ -d "$dir/.git" ]; then
            log_info "Updating ${dir}..."
            (cd "$dir" && git pull --quiet) || log_warning "Failed to update ${dir}"
        else
            log_info "Cloning ${dir}..."

            if [ -d "$dir" ]; then
                log_warning "${dir} exists but is not a git repo. Removing it."
                rm -rf "$dir"
            fi

            GIT_SSL_NO_VERIFY=1 git clone "$url" "$dir" || {
                log_error "Failed to clone ${dir}"
                exit 1
            }
        fi
    }

    update_repo "https://gitlab.ibdf-frankfurt.de/proskive/keycloak-themes.git" "keycloak-themes"
    update_repo "https://gitlab.ibdf-frankfurt.de/uct/keycloak-event-listener.git" "keycloak-event-listener"

    # Build Keycloak event listener if needed
    if [ -d "keycloak-event-listener" ] && [ -f "keycloak-event-listener/pom.xml" ]; then
        log_info "Building Keycloak event listener..."
        if command -v mvn &> /dev/null; then
            (cd keycloak-event-listener && mvn clean package -q) || log_warning "Maven build failed"
        else
            log_warning "Maven not found. Skipping event listener build."
        fi
    fi

    log "✅ Dependencies updated."
}

#----------------------------------------------------------------------------------
# DOCKER NETWORK SETUP
#----------------------------------------------------------------------------------
setup_network() {
    log "🌐 Setting up Docker network..."

    if ! docker network ls | grep -q "approve_network"; then
        docker network create approve_network
        log "✅ Network 'approve_network' created."
    else
        log_info "Network 'approve_network' already exists."
    fi
}

#----------------------------------------------------------------------------------
# DOCKER COMPOSE OPERATIONS
#----------------------------------------------------------------------------------
start_core_services() {
    log "🚀 Starting core infrastructure services..."

    docker compose pull --quiet

    log_info "Starting PostgreSQL..."
    docker compose up -d postgres
    wait_for_container "approve.postgres${CONTAINER_NAME_SUFFIX}" "PostgreSQL" 30 || exit 1

    log_info "Starting MongoDB..."
    docker compose up -d mongo
    wait_for_container "approve.mongo${CONTAINER_NAME_SUFFIX}" "MongoDB" 30 || exit 1

    log_info "Starting Configuration Service..."
    docker compose up -d config-service
    wait_for_container "approve.config${CONTAINER_NAME_SUFFIX}" "config-service" 60 || exit 1

    log_info "Starting Eureka Service Registry..."
    docker compose up -d eureka-service
    wait_for_container "approve.eureka${CONTAINER_NAME_SUFFIX}" "eureka" 60 || exit 1

    log_info "Starting Keycloak..."
    docker compose up -d auth
    wait_for_service "http://localhost:${AUTH_PORT}/health/live" "keycloak" 120 || exit 1
}

#----------------------------------------------------------------------------------
# PHASE 1: KEYCLOAK INFRASTRUCTURE (Realm, Client, Service User)
#----------------------------------------------------------------------------------
configure_keycloak_infrastructure() {
    log "🔧 Configuring Keycloak Infrastructure (Realm, Client, Service User)..."

    docker exec approve.auth${CONTAINER_NAME_SUFFIX} bash -c "
        set -e
        KC=/opt/keycloak/bin/kcadm.sh

        # Login
        \$KC config credentials --server 'http://localhost:8080' --realm master --user '$APPROVE_KEYCLOAK_ADMIN_USER' --password '$APPROVE_KEYCLOAK_ADMIN_PASSWORD'

        # 1. Create Realm
        echo '[KC] Create realm'
        \$KC create realms -s realm='$KEYCLOAK_REALM_NAME' -s enabled=true -s accountTheme=custom-theme -o || true

        # 2. Create Client Scope
        echo '[KC] Create OpenID client scope'
        \$KC create client-scopes -r '$KEYCLOAK_REALM_NAME' -s name=openid -s protocol=openid-connect -s consentRequired=false || true

        # 3. Create Client (Web App)
        echo '[KC] Create APProVe client'
        \$KC create clients -r '$KEYCLOAK_REALM_NAME' -s clientId='$APPROVE_CLIENT_ID' -s rootUrl='$APPROVE_FRONTEND_URL' -s \"redirectUris=[\\\"$APPROVE_FRONTEND_URL/*\\\"]\" -s \"webOrigins=[\\\"$APPROVE_FRONTEND_URL/*\\\"]\" -s publicClient=true -s directAccessGrantsEnabled=true -s attributes.login_theme=custom-theme || true

        # 4. Create Service User (restuser) - Required for Backend to start
        echo '[KC] Create service user (restuser)'
        \$KC create users -r '$KEYCLOAK_REALM_NAME' -s username='$KEYCLOAK_USER_NAME' -s enabled=true -s emailVerified=true || true

        echo '[KC] Set service user password'
        \$KC set-password -r '$KEYCLOAK_REALM_NAME' --username '$KEYCLOAK_USER_NAME' --new-password '$KEYCLOAK_USER_PASSWORD'

        echo '[KC] Assign realm-admin role to service user'
        \$KC add-roles -r '$KEYCLOAK_REALM_NAME' --uusername '$KEYCLOAK_USER_NAME' --cclientid realm-management --rolename realm-admin

        # 5. Enable Event Listener
        echo '[KC] Configure event listeners'
        \$KC update events/config -r '$KEYCLOAK_REALM_NAME' \
            -s 'eventsListeners=[\"jboss-logging\",\"sample_event_listener\"]' \
            -s adminEventsEnabled=true \
            -s adminEventsDetailsEnabled=true
    "
    log "✅ Keycloak Infrastructure ready."
}

#----------------------------------------------------------------------------------
# PHASE 2: ADMIN USER (Triggers SPI -> Backend)
#----------------------------------------------------------------------------------
create_approve_admin() {
    log "👤 Creating Admin User & Role (Triggering SPI Sync)..."

    docker exec approve.auth${CONTAINER_NAME_SUFFIX} bash -c "
        set -e
        KC=/opt/keycloak/bin/kcadm.sh

        # Login
          \$KC config credentials --server 'http://localhost:8080' --realm master --user '$APPROVE_KEYCLOAK_ADMIN_USER' --password '$APPROVE_KEYCLOAK_ADMIN_PASSWORD'

        # 1. CREATE ROLE
        echo '[KC] Create Admin Role'
        \$KC create roles -r '$KEYCLOAK_REALM_NAME' -s name='APPROVE_ADMIN_ROLE' -s 'attributes={\"is_admin\":[true]}' -s 'description=Approve Admin Role' || true

        # 2. CREATE USER
        echo '[KC] Create Admin User'
        \$KC create users -r '$KEYCLOAK_REALM_NAME' -s username='$APPROVE_ADMIN_USER' -s enabled=true -s email='$APPROVE_ADMIN_EMAIL' -s emailVerified=true -s firstName='Admin' -s lastName='User' || true

        \$KC set-password -r '$KEYCLOAK_REALM_NAME' --username '$APPROVE_ADMIN_USER' --new-password '$APPROVE_ADMIN_PASSWORD'

        # 3. ASSIGN ROLE
        echo '[KC] Assign Admin Role to User'
        \$KC add-roles -r '$KEYCLOAK_REALM_NAME' --uusername '$APPROVE_ADMIN_USER' --rolename 'APPROVE_ADMIN_ROLE'
    "
    log "✅ Admin creation events sent to Backend."
}

#----------------------------------------------------------------------------------
# START APPLICATION SERVICES
#----------------------------------------------------------------------------------
start_application() {
    log "🚀 Starting application services..."

    # 1. Start Backend specifically
    log_info "Starting Backend Service..."
    docker compose up -d backend-service

    # 2. WAIT for Backend
    wait_for_service "http://localhost:${BACKEND_PORT}/api/actuator/health" "backend-service" 180 || exit 1

    # 3. Create the Admin User (Backend is up, SPI will trigger)
    create_approve_admin

    # 4. Start the rest of the stack
    log_info "Starting remaining microservices..."
    docker compose up -d

    log "✅ All services started."
}

#----------------------------------------------------------------------------------
# VERIFICATION
#----------------------------------------------------------------------------------
verify_installation() {
    log "🔍 Verifying installation..."

    local failed_services=()

    # Check service health
    local services=(
        "postgres:${POSTGRES_PORT}"
        "mongo:${MONGO_PORT}"
        "auth:${AUTH_PORT}"
        "eureka:${EUREKA_PORT}"
        "backend:${BACKEND_PORT}"
        "frontend:${FRONTEND_PORT}"
    )

    for service in "${services[@]}"; do
        local name="${service%%:*}"
        local port="${service##*:}"

        if docker ps | grep -q "approve.${name}"; then
            log_info "✅ ${name} is running on port ${port}"
        else
            log_warning "❌ ${name} is not running"
            failed_services+=("${name}")
        fi
    done

    if [ ${#failed_services[@]} -gt 0 ]; then
        log_warning "Some services failed to start: ${failed_services[*]}"
        log_info "Check logs with: docker compose logs <service-name>"
    fi
}

#----------------------------------------------------------------------------------
# CLEANUP FUNCTION
#----------------------------------------------------------------------------------
cleanup_on_error() {
    log_error "Installation failed. Cleaning up..."
    docker compose down
    exit 1
}

#----------------------------------------------------------------------------------
# MAIN EXECUTION
#----------------------------------------------------------------------------------
main() {
    # Trap errors
    trap cleanup_on_error ERR

    # Start installation
    show_banner
    log "🎬 Starting APProVe server installation..."
    log "📝 Log file: ${LOG_FILE}"

    check_prerequisites
    check_registry_auth
    setup_environment
    update_dependencies
    setup_network
    start_core_services
    configure_keycloak_infrastructure
    start_application
    verify_installation

    # Success message
    echo ""
    log "════════════════════════════════════════════════════════════════"
    log "🎉 APProVe server installation completed successfully!"
    log "════════════════════════════════════════════════════════════════"
    echo ""
    log_info "Access URLs:"
    log_info "  • Frontend:  ${APPROVE_FRONTEND_URL}"
    log_info "  • Keycloak:  ${APPROVE_KEYCLOAK_URL}"
    log_info "  • Backend:   ${APPROVE_BACKEND_URL}"
    echo ""
    log_info "Admin Credentials:"
    log_info "  • Username:  ${APPROVE_ADMIN_USER}"
    log_info "  • Password:  ${APPROVE_ADMIN_PASSWORD}"
    echo ""
    log_info "Useful Commands:"
    log_info "  • View logs:     docker compose logs -f [service-name]"
    log_info "  • Stop all:      docker compose down"
    log_info "  • Restart:       docker compose restart [service-name]"
    log_info "  • View status:   docker compose ps"
    echo ""
    log "════════════════════════════════════════════════════════════════"
}

# Run main function
main "$@"