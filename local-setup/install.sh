#!/bin/bash

#==================================================================================
# APProVe Local Installation Script
# Version: 4.0.0
# Description: Automated setup for APProVe microservices ecosystem
#==================================================================================

set -e  # Exit on any error
set -E  # Let the ERR trap fire inside functions too
set -o pipefail  # Catch errors in pipes

#----------------------------------------------------------------------------------
# CONFIGURATION
#----------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# docker compose, the cloned repos and .env are all resolved relative to this
# folder, so the script works no matter where it is called from.
cd "$SCRIPT_DIR"
LOG_FILE="${SCRIPT_DIR}/install.log"
REGISTRY="registry.gitlab.ibdf-frankfurt.de"
REQUIRED_MEMORY_GB=6
REQUIRED_DISK_GB=2
# Host names the browser and this script use to reach the services
REQUIRED_HOSTS=(approve.frontend approve.auth approve.backend approve.user approve.comment approve.mails approve.automation approve.import)
MAVEN_IMAGE="maven:3.9-eclipse-temurin-17"
CURRENT_STEP="startup"
COMPOSE="docker compose"  # replaced by the detected variant in check_prerequisites

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
    clear 2>/dev/null || true  # fails without a terminal (CI, SSH without TTY)
    echo -e "${BLUE}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║              APProVe Installation Script                  ║
    ║                    Version 4.0.0                          ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

#----------------------------------------------------------------------------------
# HEALTH CHECK FUNCTION
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
            log "${service_name} is healthy!"
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

    local response_code last_code=""
    while [ $count -lt $max_retries ]; do
        response_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null) || true
        # Only log changes, not every poll
        if [ "$response_code" != "$last_code" ]; then
            echo "" >> "$LOG_FILE"
            log_info "${service_name} answers HTTP ${response_code:-000}"
            last_code="$response_code"
        fi
        if [[ "$response_code" == "200" || "$response_code" == "401" || "$response_code" == "403" || "$response_code" == "404" ]]; then
            echo ""
            log "${service_name} is ready!"
            return 0
        fi

        echo -n "."
        sleep 5
        count=$((count + 1))
    done

    echo ""
    log_error "Timeout waiting for ${service_name} (${url})."
    return 1
}

# Usage: fail "<what went wrong>" [compose-service]
# Leaves the containers running so the problem can be inspected, shows the
# last log lines of the affected service and exits.
fail() {
    local message="$1"
    local service="$2"
    log_error "$message"
    if [ -n "$service" ]; then
        log_error "Last log lines of ${service}:"
        $COMPOSE logs --tail=30 "$service" 2>&1 | tee -a "$LOG_FILE" || true
        log_info "Full log: $COMPOSE logs ${service}"
    fi
    log_info "The containers are left running so you can inspect them."
    log_info "After fixing the cause, simply run ./install.sh again (it is safe to re-run)."
    exit 1
}

#----------------------------------------------------------------------------------
# PREREQUISITE CHECKS
#----------------------------------------------------------------------------------
check_prerequisites() {
    log "Checking system prerequisites..."

    # Check required binaries
    local required_bins=("docker" "git" "curl")
    for cmd in "${required_bins[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "${cmd} is not installed."
            log_error "Please install ${cmd} and try again."
            exit 1
        fi
    done
    log "All required binaries found."

    # Check Docker daemon
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker daemon is not running."
        log_error "Please start Docker Desktop/Daemon and try again."
        exit 1
    fi
    log "Docker daemon is running."

    # Docker Compose: prefer the plugin ("docker compose"), fall back to the
    # standalone binary ("docker-compose")
    if docker compose version &> /dev/null; then
        COMPOSE="docker compose"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE="docker-compose"
    else
        log_error "Docker Compose is not installed (neither 'docker compose' nor 'docker-compose')."
        exit 1
    fi
    local compose_version=$($COMPOSE version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    log_info "Docker Compose version: ${compose_version} (${COMPOSE})"

    # Check available memory
    if command -v free &> /dev/null; then
        local available_memory_gb=$(free -g | awk '/^Mem:/{print $7}')
        if [ "$available_memory_gb" -lt "$REQUIRED_MEMORY_GB" ]; then
            log_warning "Available memory (${available_memory_gb}GB) is below recommended (${REQUIRED_MEMORY_GB}GB)."
            log_warning "Performance may be degraded."
        else
            log "Sufficient memory available (${available_memory_gb}GB)."
        fi
    fi

    # Check available disk space (POSIX df output works on Linux, macOS and Git Bash)
    local available_disk_gb=$(df -Pk "$SCRIPT_DIR" | awk 'NR==2 {print int($4/1048576)}')
    if [ -z "$available_disk_gb" ]; then
        log_warning "Could not determine free disk space."
    elif [ "$available_disk_gb" -lt "$REQUIRED_DISK_GB" ]; then
        log_warning "Available disk space (${available_disk_gb}GB) is below recommended (${REQUIRED_DISK_GB}GB)."
    else
        log "Sufficient disk space available (${available_disk_gb}GB)."
    fi

    check_hosts_file
}

#----------------------------------------------------------------------------------
# HOSTS FILE CHECK
# The browser and this script reach the services via approve.* host names,
# which only resolve after they were added to the hosts file.
#----------------------------------------------------------------------------------
check_hosts_file() {
    local missing=()
    local host tmp
    tmp=$(mktemp -d)
    # Checked in parallel: a refused connection takes ~2s on Windows
    for host in "${REQUIRED_HOSTS[@]}"; do
        (
            # curl exit code 6 = host name could not be resolved
            rc=0
            curl -s -o /dev/null --connect-timeout 3 "http://${host}:1/" || rc=$?
            [ "$rc" -ne 6 ] || touch "${tmp}/${host}"
        ) &
    done
    wait
    for host in "${REQUIRED_HOSTS[@]}"; do
        [ ! -e "${tmp}/${host}" ] || missing+=("$host")
    done
    rm -rf "$tmp"

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "These host names do not resolve: ${missing[*]}"
        log_error "Add this line to your hosts file and run the script again:"
        log_error "  127.0.0.1 ${REQUIRED_HOSTS[*]}"
        log_info "Windows: C:\\Windows\\System32\\drivers\\etc\\hosts (edit as Administrator)"
        log_info "macOS/Linux: /etc/hosts (sudo)"
        exit 1
    fi
    log "Hosts file contains all approve.* host names."
}

#----------------------------------------------------------------------------------
# PORT CHECK
# Every port APProVe publishes must be free, unless an APProVe container
# already uses it (re-run of the script).
#----------------------------------------------------------------------------------
check_ports() {
    log "Checking that the required ports are free..."

    local ports=(
        "AUTH_PORT:${AUTH_PORT}"
        "BACKEND_PORT:${BACKEND_PORT}"
        "FRONTEND_PORT:${FRONTEND_PORT}"
        "USER_PORT:${USER_PORT}"
        "COMMENT_PORT:${COMMENT_PORT}"
        "EMAIL_PORT:${EMAIL_PORT}"
        "AUTOMATION_PORT:${AUTOMATION_PORT}"
        "IMPORT_PORT:${IMPORT_PORT}"
        "MANUAL_PORT:${MANUAL_PORT}"
        "CONFIG_PORT:${CONFIG_PORT}"
        "EUREKA_PORT:${EUREKA_PORT}"
        "POSTGRES_HOST_PORT:${POSTGRES_HOST_PORT}"
        "MONGO_HOST_PORT:${MONGO_HOST_PORT}"
    )
    local conflicts=0
    local entry name port owner tmp
    tmp=$(mktemp -d)
    # Checked in parallel: a refused connection takes ~2s on Windows
    for entry in "${ports[@]}"; do
        port="${entry##*:}"
        # Something accepts connections on this port?
        ( (exec 3<>"/dev/tcp/127.0.0.1/${port}") 2>/dev/null && touch "${tmp}/${port}" ) &
    done
    wait
    for entry in "${ports[@]}"; do
        name="${entry%%:*}"
        port="${entry##*:}"
        if [ -e "${tmp}/${port}" ]; then
            owner=$(docker ps --filter "publish=${port}" --format '{{.Names}}' 2>/dev/null | head -1)
            case "$owner" in
                approve.*) ;;  # our own container from a previous run
                *)
                    log_error "Port ${port} (${name}) is already in use${owner:+ by container ${owner}}."
                    conflicts=$((conflicts + 1))
                    ;;
            esac
        fi
    done
    rm -rf "$tmp"

    if [ $conflicts -gt 0 ]; then
        log_error "Stop the program using the port, or choose another port in .env"
        log_error "(e.g. POSTGRES_HOST_PORT=15432 if a local PostgreSQL runs on 5432)."
        exit 1
    fi
    log "All required ports are available."
}

#----------------------------------------------------------------------------------
# REGISTRY AUTHENTICATION CHECK
#----------------------------------------------------------------------------------
check_registry_auth() {
    log "Checking registry authentication..."

    if ! grep -q "$REGISTRY" ~/.docker/config.json 2>/dev/null; then
        log_warning "Not authenticated with ${REGISTRY}."
        log_info "Please authenticate now..."

        if ! docker login "$REGISTRY"; then
            log_error "Registry authentication failed."
            exit 1
        fi
    fi

    log "Authenticated with ${REGISTRY}."
}

#----------------------------------------------------------------------------------
# ENVIRONMENT SETUP
#----------------------------------------------------------------------------------
setup_environment() {
    log "Setting up environment..."

    if [ ! -f "${SCRIPT_DIR}/.env" ]; then
        log_error ".env file not found in ${SCRIPT_DIR}."
        log_error "Please ensure .env file exists and try again."
        exit 1
    fi

    # Fix CRLF line endings (Windows compatibility)
    if command -v dos2unix &> /dev/null; then
        dos2unix "${SCRIPT_DIR}/.env" 2>/dev/null || true
    else
        tr -d '\r' < "${SCRIPT_DIR}/.env" > "${SCRIPT_DIR}/.env.unix" && mv "${SCRIPT_DIR}/.env.unix" "${SCRIPT_DIR}/.env"
    fi

    # Load environment variables
    set -o allexport
    source "${SCRIPT_DIR}/.env"
    set +o allexport

    log "Environment configured."
}

#----------------------------------------------------------------------------------
# GIT REPOSITORIES UPDATE
#----------------------------------------------------------------------------------
update_dependencies() {
    log "Updating project dependencies..."

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

            git clone "$url" "$dir" || {
                log_error "Failed to clone ${dir}"
                exit 1
            }
        fi
    }

    update_repo "https://gitlab.ibdf-frankfurt.de/proskive/keycloak-themes.git" "keycloak-themes"
    update_repo "https://gitlab.ibdf-frankfurt.de/uct/keycloak-event-listener.git" "keycloak-event-listener"

    build_event_listener

    log "Dependencies updated."
}

#----------------------------------------------------------------------------------
# KEYCLOAK EVENT LISTENER BUILD
# Keycloak loads the jar from keycloak-event-listener/target. Without it, users
# created in Keycloak are never synced to the backend and the login fails.
#----------------------------------------------------------------------------------
build_event_listener() {
    local jar="keycloak-event-listener/target/keycloak-event-listener.jar"
    log_info "Building Keycloak event listener..."

    local built=false
    if command -v mvn &> /dev/null && command -v java &> /dev/null; then
        if (cd keycloak-event-listener && mvn clean package -q) >> "$LOG_FILE" 2>&1; then
            built=true
        else
            log_warning "Local Maven build failed (see ${LOG_FILE}), trying the Docker build."
        fi
    else
        log_info "Maven/Java not found locally, building with Docker (${MAVEN_IMAGE})."
        log_info "The first time this downloads the Maven image (~800 MB), please wait..."
    fi

    if [ "$built" = false ]; then
        # Windows paths for Docker Desktop when running in Git Bash
        local src
        src="$(cd keycloak-event-listener && (pwd -W 2>/dev/null || pwd))"
        if MSYS_NO_PATHCONV=1 docker run --rm \
            -v "${src}:/build" -v approve-maven-cache:/root/.m2 -w /build \
            "$MAVEN_IMAGE" mvn -q clean package >> "$LOG_FILE" 2>&1; then
            built=true
        fi
    fi

    if [ ! -f "$jar" ]; then
        log_error "The Keycloak event listener could not be built (${jar} is missing)."
        log_error "Without it, users created in Keycloak are not synced to APProVe and you cannot log in."
        log_error "See ${LOG_FILE} for the Maven output."
        exit 1
    fi
    [ "$built" = true ] || log_warning "Build failed, using the existing ${jar}."
    log "Keycloak event listener ready."
}

#----------------------------------------------------------------------------------
# DOCKER NETWORK SETUP
#----------------------------------------------------------------------------------
setup_network() {
    log "Setting up Docker network..."

    if ! docker network ls | grep -q "approve_network"; then
        docker network create approve_network
        log "Network 'approve_network' created."
    else
        log_info "Network 'approve_network' already exists."
    fi
}

#----------------------------------------------------------------------------------
# DOCKER COMPOSE OPERATIONS
#----------------------------------------------------------------------------------
start_core_services() {
    log "Starting core infrastructure services..."

    log_info "Pulling images (the first run downloads several GB, this can take a while)..."
    $COMPOSE pull --quiet || fail "Pulling the images failed (see the message above). Check: logged in to ${REGISTRY} (docker login ${REGISTRY})? VPN connected? Image names/tags in .env correct?"

    log_info "Starting PostgreSQL..."
    $COMPOSE up -d postgres
    # Use container health check for DB
    wait_for_container "approve.postgres" "PostgreSQL" 30 || fail "PostgreSQL did not become healthy." postgres

    log_info "Starting MongoDB..."
    $COMPOSE up -d mongo
    # Use container health check for DB
    wait_for_container "approve.mongo" "MongoDB" 30 || fail "MongoDB did not become healthy." mongo

    log_info "Starting Configuration Service..."
    $COMPOSE up -d config-service
    wait_for_service "http://localhost:${CONFIG_PORT}/actuator/health" "config-service" 60 || fail "The config service did not start." config-service

    log_info "Starting Eureka Service Registry..."
    $COMPOSE up -d eureka-service
    wait_for_service "http://localhost:${EUREKA_PORT}/actuator/health" "eureka" 60 || fail "Eureka did not start." eureka-service

    log_info "Starting Keycloak..."
    $COMPOSE up -d auth
    wait_for_service "${APPROVE_KEYCLOAK_URL}/health/live" "keycloak" 120 || fail "Keycloak did not start." auth
    if ! $COMPOSE logs auth 2>/dev/null | grep -q "sample_event_listener"; then
        log_warning "Keycloak did not report loading the APProVe event listener (sample_event_listener)."
    fi
}

#----------------------------------------------------------------------------------
# PHASE 1: KEYCLOAK INFRASTRUCTURE (Realm, Client, Service User)
#----------------------------------------------------------------------------------
configure_keycloak_infrastructure() {
    log "Configuring Keycloak Infrastructure (Realm, Client, Service User)..."

    docker exec approve.auth bash -c "
        set -e
        KC=/opt/keycloak/bin/kcadm.sh

        # Login
        \$KC config credentials --server '$APPROVE_KEYCLOAK_URL' --realm master --user '$APPROVE_KEYCLOAK_ADMIN_USER' --password '$APPROVE_KEYCLOAK_ADMIN_PASSWORD'

        # Re-runs: only create what is missing, so Keycloak logs no conflicts
        exists() { \$KC get \"\$@\" 2>/dev/null | grep -q '\"id\"'; }
        kept() { echo '     already exists, kept'; }

        # 1. Create Realm
        echo '[KC] Create realm'
        if exists realms/'$KEYCLOAK_REALM_NAME'; then kept; else
            \$KC create realms -s realm='$KEYCLOAK_REALM_NAME' -s enabled=true -s accountTheme=custom-theme
        fi
        # The frontend embeds the access token into the page and does not refresh it,
        # so the token must outlive filling in a project form (Keycloak default: 5 min)
        echo '[KC] Set access token lifespan to ${KEYCLOAK_ACCESS_TOKEN_LIFESPAN:-1800}s'
        \$KC update realms/'$KEYCLOAK_REALM_NAME' -s accessTokenLifespan='${KEYCLOAK_ACCESS_TOKEN_LIFESPAN:-1800}'

        # 2. Create Client Scope
        echo '[KC] Create OpenID client scope'
        if \$KC get client-scopes -r '$KEYCLOAK_REALM_NAME' --fields name 2>/dev/null | grep -q '\"openid\"'; then kept; else
            \$KC create client-scopes -r '$KEYCLOAK_REALM_NAME' -s name=openid -s protocol=openid-connect -s consentRequired=false
        fi

        # 3. Create Client (Web App)
        echo '[KC] Create APProVe client'
        if exists clients -r '$KEYCLOAK_REALM_NAME' -q clientId='$APPROVE_CLIENT_ID'; then kept; else
            \$KC create clients -r '$KEYCLOAK_REALM_NAME' -s clientId='$APPROVE_CLIENT_ID' -s rootUrl='$APPROVE_FRONTEND_URL' -s \"redirectUris=[\\\"$APPROVE_FRONTEND_URL/*\\\"]\" -s \"webOrigins=[\\\"$APPROVE_FRONTEND_URL/*\\\"]\" -s publicClient=true -s directAccessGrantsEnabled=true -s attributes.login_theme=custom-theme
        fi

        # 4. Create Service User (restuser) - Required for Backend to start
        echo '[KC] Create service user (restuser)'
        if exists users -r '$KEYCLOAK_REALM_NAME' -q exact=true -q username='$KEYCLOAK_USER_NAME'; then kept; else
            \$KC create users -r '$KEYCLOAK_REALM_NAME' -s username='$KEYCLOAK_USER_NAME' -s enabled=true -s emailVerified=true
        fi

        echo '[KC] Set service user password'
        \$KC set-password -r '$KEYCLOAK_REALM_NAME' --username '$KEYCLOAK_USER_NAME' --new-password '$KEYCLOAK_USER_PASSWORD'

        echo '[KC] Assign realm-admin role to service user'
        \$KC add-roles -r '$KEYCLOAK_REALM_NAME' --uusername '$KEYCLOAK_USER_NAME' --cclientid realm-management --rolename realm-admin

        # 5. Enable Event Listener (So next steps trigger the SPI)
        # adminEventsEnabled=true        -> Triggers on kcadm.sh commands
        # adminEventsDetailsEnabled=true -> Includes the JSON body
        echo '[KC] Configure event listeners'
        \$KC update events/config -r '$KEYCLOAK_REALM_NAME' \
            -s 'eventsListeners=[\"jboss-logging\",\"sample_event_listener\"]' \
            -s adminEventsEnabled=true \
            -s adminEventsDetailsEnabled=true
    "
    log "Keycloak Infrastructure ready."
}

#----------------------------------------------------------------------------------
# PHASE 2: ADMIN USER (Triggers SPI -> Backend)
#----------------------------------------------------------------------------------
create_approve_admin() {
    log "Creating Admin User & Role (Triggering SPI Sync)..."

    docker exec approve.auth bash -c "
        set -e
        KC=/opt/keycloak/bin/kcadm.sh

        # Login
        \$KC config credentials --server '$APPROVE_KEYCLOAK_URL' --realm master --user '$APPROVE_KEYCLOAK_ADMIN_USER' --password '$APPROVE_KEYCLOAK_ADMIN_PASSWORD'

        # Re-runs: only create what is missing, so Keycloak logs no conflicts
        exists() { \$KC get \"\$@\" 2>/dev/null | grep -q '\"id\"'; }
        kept() { echo '     already exists, kept'; }

        # 1. CREATE ROLE (Triggers SPI -> Backend 'createRole')
        # This sends the role JSON to APProVe
        echo '[KC] Create Admin Role'
        if exists roles/APPROVE_ADMIN_ROLE -r '$KEYCLOAK_REALM_NAME'; then kept; else
            \$KC create roles -r '$KEYCLOAK_REALM_NAME' -s name='APPROVE_ADMIN_ROLE' -s 'attributes={\"is_admin\":[true]}' -s 'description=Approve Admin Role'
        fi

        # 2. CREATE USER (Triggers SPI -> Backend 'createUser')
        # This sends the user JSON to APProVe
        echo '[KC] Create Admin User'
        if exists users -r '$KEYCLOAK_REALM_NAME' -q exact=true -q username='$APPROVE_ADMIN_USER'; then kept; else
            \$KC create users -r '$KEYCLOAK_REALM_NAME' -s username='$APPROVE_ADMIN_USER' -s enabled=true -s email='$APPROVE_ADMIN_EMAIL' -s emailVerified=true -s firstName='Admin' -s lastName='User'
        fi

        # (Password setting does not usually trigger a backend sync, but is required for login)
        \$KC set-password -r '$KEYCLOAK_REALM_NAME' --username '$APPROVE_ADMIN_USER' --new-password '$APPROVE_ADMIN_PASSWORD'

        # 3. ASSIGN ROLE (Triggers SPI -> Backend 'addRolesToUser')
        # This tells APProVe to link the user and the role
        echo '[KC] Assign Admin Role to User'
        \$KC add-roles -r '$KEYCLOAK_REALM_NAME' --uusername '$APPROVE_ADMIN_USER' --rolename 'APPROVE_ADMIN_ROLE'
    "
    log "Admin creation events sent to Backend."
}


#----------------------------------------------------------------------------------
# START APPLICATION SERVICES
#----------------------------------------------------------------------------------
start_application() {
    log "Starting application services..."

    # 1. Start Backend specifically
    log_info "Starting Backend Service..."
    $COMPOSE up -d backend-service

    # 2. WAIT for Backend
    wait_for_service "${APPROVE_BACKEND_URL}/api/actuator/health" "backend-service" 180 || fail "The backend did not start." backend-service

    # 3. Create the Admin User (Backend is up, SPI will trigger)
    create_approve_admin
    verify_admin_synced

    # 4. Start the rest of the stack
    log_info "Starting remaining microservices..."
    $COMPOSE up -d

    log "All services started."
}

#----------------------------------------------------------------------------------
# The event listener copies the admin from Keycloak into the backend database.
# Without that entry the admin can log in to Keycloak but not use APProVe.
#----------------------------------------------------------------------------------
verify_admin_synced() {
    local count=0 found=""
    while [ $count -lt 15 ]; do
        found=$(docker exec approve.postgres psql -U "$APPROVE_POSTGRES_USER" -d "$APPROVE_PROJECT_DB" -tAc \
            "select count(*) from person p join person_roles pr on pr.person_id = p.id where p.username = '${APPROVE_ADMIN_USER}'" 2>/dev/null || true)
        if [ "${found:-0}" -gt 0 ] 2>/dev/null; then
            log "Admin user and role were synced to the backend."
            return 0
        fi
        sleep 2
        count=$((count + 1))
    done
    log_warning "The admin user was not found in the backend database (${APPROVE_PROJECT_DB}.person)."
    log_warning "Keycloak -> backend sync (event listener) may not work. Check: $COMPOSE logs auth | grep -i event"
}

#----------------------------------------------------------------------------------
# VERIFICATION
#----------------------------------------------------------------------------------
verify_installation() {
    log "Verifying installation..."

    local failed_services=()
    local service state

    # Every service defined in docker-compose.yml must have a running container
    for service in $($COMPOSE config --services); do
        state=$($COMPOSE ps --format '{{.State}}' "$service" 2>/dev/null | head -1)
        if [ "$state" == "running" ]; then
            log_info "${service} is running"
        else
            log_warning "${service} is not running (${state:-no container})"
            failed_services+=("${service}")
        fi
    done

    # The frontend needs a few more seconds after the other services
    wait_for_service "${APPROVE_FRONTEND_URL}/index" "frontend-service" 60 || failed_services+=("frontend-service")

    if [ ${#failed_services[@]} -gt 0 ]; then
        log_warning "Some services failed to start: ${failed_services[*]}"
        log_info "Check logs with: $COMPOSE logs <service-name>"
    fi
}

#----------------------------------------------------------------------------------
# CLEANUP FUNCTION
#----------------------------------------------------------------------------------
cleanup_on_error() {
    local line="$1"
    trap - ERR
    log_error "Installation failed in step '${CURRENT_STEP}' (install.sh line ${line})."
    log_info "Details: ${LOG_FILE}"
    log_info "The containers are left running so you can inspect them ($COMPOSE ps / $COMPOSE logs <service>)."
    log_info "After fixing the cause, simply run ./install.sh again (it is safe to re-run)."
    exit 1
}

# Runs one installation step and remembers its name for error messages
step() {
    CURRENT_STEP="$1"
    "$1"
}

#----------------------------------------------------------------------------------
# MAIN EXECUTION
#----------------------------------------------------------------------------------
main() {
    # Trap errors
    trap 'cleanup_on_error $LINENO' ERR

    # Start installation
    show_banner
    log "Starting APProVe installation..."
    log "Log file: ${LOG_FILE}"

    step check_prerequisites
    step check_registry_auth
    step setup_environment
    step check_ports
    step update_dependencies
    step setup_network
    step start_core_services
    step configure_keycloak_infrastructure
    step start_application
    step verify_installation

    # Success message
    echo ""
    log "════════════════════════════════════════════════════════════════"
    log "APProVe installation completed successfully!"
    log "════════════════════════════════════════════════════════════════"
    echo ""
    log_info "Access URLs:"
    log_info "  - APProVe:   ${APPROVE_FRONTEND_URL}"
    log_info "  - Manual:    ${APPROVE_MANUAL_URL}/"
    log_info "  - Keycloak:  ${APPROVE_KEYCLOAK_URL}/admin (realm: ${KEYCLOAK_REALM_NAME})"
    log_info "  - Eureka:    http://localhost:${EUREKA_PORT}"
    echo ""
    log_info "APProVe login:"
    log_info "  - Username:  ${APPROVE_ADMIN_USER}"
    log_info "  - Password:  ${APPROVE_ADMIN_PASSWORD}"
    log_info "Keycloak admin console login: ${APPROVE_KEYCLOAK_ADMIN_USER} / ${APPROVE_KEYCLOAK_ADMIN_PASSWORD}"
    echo ""
    log_info "Useful Commands (run them in ${SCRIPT_DIR}):"
    log_info "  - View logs:     $COMPOSE logs -f [service-name]"
    log_info "  - Stop all:      $COMPOSE stop"
    log_info "  - Start again:   $COMPOSE up -d"
    log_info "  - Restart:       $COMPOSE restart [service-name]"
    log_info "  - View status:   $COMPOSE ps"
    echo ""
    log "════════════════════════════════════════════════════════════════"
}

# Run main function
main "$@"