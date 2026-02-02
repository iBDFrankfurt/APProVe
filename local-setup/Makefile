# APProVe Local Development Makefile
# Convenient shortcuts for common operations

.PHONY: help install start stop restart logs clean backup health status

# Default target
.DEFAULT_GOAL := help
SHELL := /bin/bash

# Color output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

##@ General Commands

help: ## Display this help message
	@printf "$(BLUE)APProVe Local Development - Available Commands$(NC)"
	@printf ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(YELLOW)<target>$(NC)\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Installation & Setup

install: ## Run full installation script
	@printf "$(GREEN)Starting APProVe installation...$(NC)"
	@chmod +x install.sh
	@./install.sh

setup-hosts: ## Display hosts file configuration instructions
	@printf "$(YELLOW)Add these entries to your hosts file:$(NC)"
	@printf ""
	@printf "127.0.0.1 approve.backend"
	@printf "127.0.0.1 approve.auth"
	@printf "127.0.0.1 approve.user"
	@printf "127.0.0.1 approve.frontend"
	@printf "127.0.0.1 approve.comment"
	@printf "127.0.0.1 approve.mails"
	@printf "127.0.0.1 approve.automation"
	@printf "127.0.0.1 approve.import"
	@printf "127.0.0.1 approve.draft"
	@printf "127.0.0.1 approve.eureka"
	@printf "127.0.0.1 approve.postgres"
	@printf "127.0.0.1 approve.mongo"
	@printf ""
	@printf "$(YELLOW)Windows:$(NC) C:\\Windows\\System32\\drivers\\etc\\hosts"
	@printf "$(YELLOW)Linux/Mac:$(NC) /etc/hosts"

##@ Service Management

start: ## Start all services
	@printf "$(GREEN)Starting all services...$(NC)"
	@docker-compose up -d

stop: ## Stop all services
	@printf "$(YELLOW)Stopping all services...$(NC)"
	@docker-compose down

restart: ## Restart all services
	@printf "$(YELLOW)Restarting all services...$(NC)"
	@docker-compose restart

restart-%: ## Restart specific service (e.g., make restart-backend)
	@printf "$(YELLOW)Restarting $* service...$(NC)"
	@docker-compose restart $*

pull: ## Pull latest images
	@printf "$(GREEN)Pulling latest images...$(NC)"
	@docker-compose pull

update: pull restart ## Pull images and restart services

##@ Monitoring & Logs

status: ## Show status of all services
	@printf "$(BLUE)Service Status:$(NC)"
	@docker-compose ps

health: ## Check health of all services
	@printf "$(BLUE)Checking service health...$(NC)"
	@printf ""
	@printf "$(YELLOW)Frontend:$(NC) http://approve.frontend:8001"
	@curl -s http://localhost:8001/actuator/health | grep -q "UP" && printf "$(GREEN)✓ Healthy$(NC)" || printf "$(RED)✗ Unhealthy$(NC)"
	@printf ""
	@printf "$(YELLOW)Backend:$(NC) http://approve.backend:8000"
	@curl -s http://localhost:8000/api/health | grep -q "UP" && printf "$(GREEN)✓ Healthy$(NC)" || printf "$(RED)✗ Unhealthy$(NC)"
	@printf ""
	@printf "$(YELLOW)Keycloak:$(NC) http://approve.auth:8080"
	@curl -s http://localhost:8080/health | grep -q "UP" && printf "$(GREEN)✓ Healthy$(NC)" || printf "$(RED)✗ Unhealthy$(NC)"
	@printf ""
	@printf "$(YELLOW)Eureka:$(NC) http://approve.eureka:8761"
	@curl -s http://localhost:8761/actuator/health | grep -q "UP" && printf "$(GREEN)✓ Healthy$(NC)" || printf "$(RED)✗ Unhealthy$(NC)"

logs: ## Show logs for all services (follow mode)
	@docker-compose logs -f

logs-%: ## Show logs for specific service (e.g., make logs-backend)
	@printf "$(BLUE)Showing logs for $* service...$(NC)"
	@docker-compose logs -f $*

stats: ## Show resource usage statistics
	@printf "$(BLUE)Resource Usage:$(NC)"
	@docker stats --no-stream

##@ Database Operations

db-postgres: ## Connect to PostgreSQL database
	@printf "$(GREEN)Connecting to PostgreSQL...$(NC)"
	@docker exec -it approve.postgres psql -U postgres_admin -d approve_db

db-mongo: ## Connect to MongoDB database
	@printf "$(GREEN)Connecting to MongoDB...$(NC)"
	@docker exec -it approve.mongo mongosh -u mongo_admin -p mongopass

backup: backup-postgres backup-mongo ## Backup all databases

backup-postgres: ## Backup PostgreSQL database
	@printf "$(GREEN)Backing up PostgreSQL...$(NC)"
	@docker exec approve.postgres pg_dump -U postgres_admin approve_db > backups/postgres_$(shell date +%Y%m%d_%H%M%S).sql
	@printf "$(GREEN)✓ PostgreSQL backup complete$(NC)"

backup-mongo: ## Backup MongoDB database
	@printf "$(GREEN)Backing up MongoDB...$(NC)"
	@mkdir -p backups/mongo_$(shell date +%Y%m%d_%H%M%S)
	@docker exec approve.mongo mongodump -u mongo_admin -p mongopass --out=/tmp/backup
	@docker cp approve.mongo:/tmp/backup backups/mongo_$(shell date +%Y%m%d_%H%M%S)/
	@printf "$(GREEN)✓ MongoDB backup complete$(NC)"

##@ Access URLs

urls: ## Display all service URLs
	@printf "$(BLUE)═══════════════════════════════════════$(NC)"
	@printf "$(GREEN)APProVe Service URLs$(NC)"
	@printf "$(BLUE)═══════════════════════════════════════$(NC)"
	@printf ""
	@printf "$(YELLOW)Main Application:$(NC)"
	@printf "  Frontend:      http://approve.frontend:8001"
	@printf ""
	@printf "$(YELLOW)Administration:$(NC)"
	@printf "  Keycloak:      http://approve.auth:8080"
	@printf "  Eureka:        http://approve.eureka:8761"
	@printf ""
	@printf "$(YELLOW)API Endpoints:$(NC)"
	@printf "  Backend:       http://approve.backend:8000"
	@printf "  User Service:  http://approve.user:9001"
	@printf "  Comments:      http://approve.comment:3234"
	@printf "  Email:         http://approve.mails:4234"
	@printf "  Automation:    http://approve.automation:3233"
	@printf "  Draft:         http://approve.draft:8002"
	@printf "  Import:        http://approve.import:8003"
	@printf ""
	@printf "$(YELLOW)Databases:$(NC)"
	@printf "  PostgreSQL:    localhost:5432"
	@printf "  MongoDB:       localhost:27017"
	@printf ""
	@printf "$(BLUE)═══════════════════════════════════════$(NC)"

credentials: ## Display default credentials
	@printf "$(BLUE)═══════════════════════════════════════$(NC)"
	@printf "$(GREEN)Default Credentials$(NC)"
	@printf "$(BLUE)═══════════════════════════════════════$(NC)"
	@printf ""
	@printf "$(YELLOW)APProVe Admin:$(NC)"
	@printf "  Username: approve-admin"
	@printf "  Password: approve-password"
	@printf ""
	@printf "$(YELLOW)Keycloak Admin:$(NC)"
	@printf "  Username: adminuser"
	@printf "  Password: adminpass"
	@printf ""
	@printf "$(RED)⚠ Change these in production!$(NC)"
	@printf "$(BLUE)═══════════════════════════════════════$(NC)"

##@ Cleanup & Maintenance

clean: ## Stop services and remove containers
	@printf "$(YELLOW)Stopping and removing containers...$(NC)"
	@docker-compose down
	@printf "$(GREEN)✓ Cleanup complete$(NC)"

clean-all: ## Remove containers, networks, and volumes
	@printf "$(RED)⚠ This will delete all data!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	printf; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		printf "$(YELLOW)Removing containers, networks, and volumes...$(NC)"; \
		docker-compose down -v; \
		docker network rm approve_network 2>/dev/null || true; \
		printf "$(GREEN)✓ Complete cleanup finished$(NC)"; \
	else \
		printf "$(YELLOW)Cleanup cancelled$(NC)"; \
	fi

prune: ## Prune unused Docker resources
	@printf "$(YELLOW)Pruning unused Docker resources...$(NC)"
	@docker system prune -f
	@printf "$(GREEN)✓ Prune complete$(NC)"

reset: clean-all install ## Complete reset and reinstall

##@ Development

dev: ## Start services in development mode
	@printf "$(GREEN)Starting in development mode...$(NC)"
	@docker-compose up

shell-%: ## Open shell in specific service (e.g., make shell-backend)
	@printf "$(GREEN)Opening shell in $* service...$(NC)"
	@docker exec -it approve.$* /bin/bash || docker exec -it approve.$* /bin/sh

inspect-%: ## Inspect specific service (e.g., make inspect-backend)
	@printf "$(BLUE)Inspecting $* service...$(NC)"
	@docker inspect approve.$*

##@ Network & Security

network-info: ## Show Docker network information
	@printf "$(BLUE)Network Information:$(NC)"
	@docker network inspect approve_network

ports: ## Show all exposed ports
	@printf "$(BLUE)Exposed Ports:$(NC)"
	@docker-compose ps --format json | jq -r '.[] | "\(.Name): \(.Publishers // [])"'

login: ## Login to GitLab registry
	@printf "$(GREEN)Logging in to GitLab registry...$(NC)"
	@docker login registry.gitlab.ibdf-frankfurt.de

##@ Testing

test-health: ## Run health checks on all services
	@printf "$(BLUE)Running health checks...$(NC)"
	@printf ""
	@./scripts/health-check.sh || printf "$(YELLOW)Health check script not found. Run 'make health' instead.$(NC)"

test-connectivity: ## Test network connectivity
	@printf "$(BLUE)Testing network connectivity...$(NC)"
	@for host in approve.frontend approve.backend approve.auth approve.eureka; do \
		printf -n "$$host: "; \
		ping -c 1 $$host > /dev/null 2>&1 && printf "$(GREEN)✓$(NC)" || printf "$(RED)✗$(NC)"; \
	done