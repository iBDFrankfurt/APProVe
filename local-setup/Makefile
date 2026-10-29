# APProVe Local Development Makefile
# Convenient shortcuts for common operations

.PHONY: help install setup-hosts start stop restart pull update status health logs stats \
	db-postgres db-mongo backup backup-postgres backup-mongo urls credentials \
	clean clean-all prune reset dev network-info ports login test-connectivity

# Default target
.DEFAULT_GOAL := help
SHELL := /bin/bash

# Same Docker Compose variant as install.sh: plugin first, standalone binary as fallback
COMPOSE := $(shell docker compose version >/dev/null 2>&1 && echo "docker compose" || echo "docker-compose")
HOSTS := approve.frontend approve.auth approve.backend approve.user approve.comment approve.mails approve.automation approve.import
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)

# Color output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

##@ General Commands

help: ## Display this help message
	@printf "$(BLUE)APProVe Local Development - Available Commands$(NC)\n\n"
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(YELLOW)<target>$(NC)\n"} /^[a-zA-Z_%-]+:.*?##/ { printf "  $(GREEN)%-18s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Installation & Setup

install: ## Run full installation script
	@printf "$(GREEN)Starting APProVe installation...$(NC)\n"
	@chmod +x install.sh
	@./install.sh

setup-hosts: ## Display the line to add to your hosts file
	@printf "$(YELLOW)Add this line to your hosts file:$(NC)\n\n"
	@printf "127.0.0.1 $(HOSTS)\n\n"
	@printf "$(YELLOW)Windows:$(NC) C:\\\\Windows\\\\System32\\\\drivers\\\\etc\\\\hosts (edit as Administrator)\n"
	@printf "$(YELLOW)Linux/Mac:$(NC) /etc/hosts (sudo)\n"

##@ Service Management

start: ## Start all services
	@printf "$(GREEN)Starting all services...$(NC)\n"
	@$(COMPOSE) up -d

stop: ## Stop all services (containers and data are kept)
	@printf "$(YELLOW)Stopping all services...$(NC)\n"
	@$(COMPOSE) stop

restart: ## Restart all services
	@printf "$(YELLOW)Restarting all services...$(NC)\n"
	@$(COMPOSE) restart

restart-%: ## Restart one service (e.g. make restart-backend-service)
	@printf "$(YELLOW)Restarting $* ...$(NC)\n"
	@$(COMPOSE) restart $*

pull: ## Pull latest images
	@printf "$(GREEN)Pulling latest images...$(NC)\n"
	@$(COMPOSE) pull

update: pull ## Pull images and recreate changed services
	@$(COMPOSE) up -d

##@ Monitoring & Logs

status: ## Show status of all services
	@$(COMPOSE) ps

health: ## Check health of the core services
	@for check in \
		"Frontend|http://localhost:8001/actuator/health" \
		"Backend|http://localhost:8000/api/actuator/health" \
		"Keycloak|http://localhost:8080/health/live" \
		"Eureka|http://localhost:8761/actuator/health" \
		"User|http://localhost:9001/api/health" \
		"Import|http://localhost:8003/api/v1/actuator/health"; do \
		name=$${check%%|*}; url=$${check#*|}; \
		if curl -s "$$url" | grep -q "UP"; then printf "$(GREEN)OK  $(NC) %-9s %s\n" "$$name" "$$url"; \
		else printf "$(RED)FAIL$(NC) %-9s %s\n" "$$name" "$$url"; fi; \
	done

logs: ## Show logs for all services (follow mode)
	@$(COMPOSE) logs -f

logs-%: ## Show logs for one service (e.g. make logs-backend-service)
	@$(COMPOSE) logs -f $*

stats: ## Show resource usage statistics
	@docker stats --no-stream

##@ Database Operations

db-postgres: ## Connect to PostgreSQL database
	@docker exec -it approve.postgres psql -U postgres_admin -d approve_db

db-mongo: ## Connect to MongoDB database
	@docker exec -it approve.mongo mongosh -u mongo_admin -p mongopass

backup: backup-postgres backup-mongo ## Backup all databases

backup-postgres: ## Backup PostgreSQL database to backups/
	@mkdir -p backups
	@docker exec approve.postgres pg_dump -U postgres_admin approve_db > backups/postgres_$(TIMESTAMP).sql
	@printf "$(GREEN)PostgreSQL backup: backups/postgres_$(TIMESTAMP).sql$(NC)\n"

backup-mongo: ## Backup MongoDB database to backups/
	@mkdir -p backups
	@docker exec approve.mongo mongodump -u mongo_admin -p mongopass --out=/tmp/backup
	@docker cp approve.mongo:/tmp/backup backups/mongo_$(TIMESTAMP)
	@printf "$(GREEN)MongoDB backup: backups/mongo_$(TIMESTAMP)$(NC)\n"

##@ Access URLs

urls: ## Display all service URLs
	@printf "$(YELLOW)Main Application:$(NC)\n"
	@printf "  APProVe:       http://approve.frontend:8001\n"
	@printf "  Manual:        http://localhost:8090/manual/\n"
	@printf "$(YELLOW)Administration:$(NC)\n"
	@printf "  Keycloak:      http://approve.auth:8080/admin\n"
	@printf "  Eureka:        http://localhost:8761\n"
	@printf "$(YELLOW)API Endpoints:$(NC)\n"
	@printf "  Backend:       http://approve.backend:8000/api\n"
	@printf "  User Service:  http://approve.user:9001/api\n"
	@printf "  Comments:      http://approve.comment:3234\n"
	@printf "  Email:         http://approve.mails:4234\n"
	@printf "  Automation:    http://approve.automation:3233\n"
	@printf "  Import:        http://approve.import:8003\n"
	@printf "$(YELLOW)Databases (host ports, see .env):$(NC)\n"
	@printf "  PostgreSQL:    localhost:POSTGRES_HOST_PORT (default 5432)\n"
	@printf "  MongoDB:       localhost:MONGO_HOST_PORT (default 27017)\n"

credentials: ## Display default credentials
	@printf "$(YELLOW)APProVe Admin:$(NC)   approve-admin / approve-password\n"
	@printf "$(YELLOW)Keycloak Admin:$(NC)  adminuser / adminpass\n"
	@printf "$(RED)WARNING:Change these in production!$(NC)\n"

##@ Cleanup & Maintenance

clean: ## Remove containers (data in the volumes is kept)
	@$(COMPOSE) down
	@printf "$(GREEN)Containers removed$(NC)\n"

clean-all: ## Remove containers, network and volumes (deletes all data!)
	@printf "$(RED)WARNING:This will delete all data!$(NC)\n"
	@read -p "Are you sure? [y/N] " -n 1 -r; echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(COMPOSE) down -v; \
		docker network rm approve_network 2>/dev/null || true; \
		printf "$(GREEN)Complete cleanup finished$(NC)\n"; \
	else \
		printf "$(YELLOW)Cleanup cancelled$(NC)\n"; \
	fi

prune: ## Prune unused Docker resources
	@docker system prune -f

reset: clean-all install ## Complete reset and reinstall

##@ Development

dev: ## Start services in the foreground (logs in the terminal)
	@$(COMPOSE) up

shell-%: ## Open a shell in a container (e.g. make shell-backend)
	@docker exec -it approve.$* /bin/bash || docker exec -it approve.$* /bin/sh

##@ Network

network-info: ## Show Docker network information
	@docker network inspect approve_network

ports: ## Show all published ports
	@$(COMPOSE) ps --format "table {{.Name}}\t{{.Ports}}"

login: ## Login to GitLab registry
	@docker login registry.gitlab.ibdf-frankfurt.de

test-connectivity: ## Check that the approve.* host names resolve
	@for host in $(HOSTS); do \
		curl -s -o /dev/null --connect-timeout 3 "http://$$host:1/"; \
		if [ $$? -ne 6 ]; then printf "$(GREEN)OK  $(NC) $$host\n"; else printf "$(RED)FAIL$(NC) $$host (missing in hosts file)\n"; fi; \
	done
