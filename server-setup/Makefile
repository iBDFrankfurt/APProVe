# APProVe Server Deployment Makefile
# Shortcuts for installation, maintenance, and backups

.PHONY: help setup install start stop restart logs clean backup health status nginx certbot

# Default target
.DEFAULT_GOAL := help
SHELL := /bin/bash

# Color output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

##@ General

help: ## Display this help message
	@printf "$(BLUE)APProVe Server Management - Available Commands$(NC)\n\n"
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(YELLOW)<target>$(NC)\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Initial Setup & Installation

setup: env nginx certbot ## Run full environment setup (Env -> Nginx -> Certbot)

env: ## Generate or edit .env configuration
	@printf "$(GREEN)Generating environment configuration...$(NC)\n"
	@chmod +x generate_env.sh
	@./generate_env.sh

nginx: ## Generate and enable Nginx configuration
	@printf "$(GREEN)Generating Nginx configuration...$(NC)\n"
	@chmod +x generate_nginx.sh
	@sudo ./generate_nginx.sh

certbot: ## Obtain SSL certificates (requires Nginx to be running)
	@printf "$(GREEN)Running Certbot for SSL...$(NC)\n"
	@sudo certbot --nginx

install: ## Run the main server installation script
	@printf "$(GREEN)Starting APProVe Server installation...$(NC)\n"
	@chmod +x install_server.sh
	@./install_server.sh

##@ Service Management

start: ## Start all services
	@printf "$(GREEN)Starting all services...$(NC)\n"
	@docker-compose up -d

stop: ## Stop all services
	@printf "$(YELLOW)Stopping all services...$(NC)\n"
	@docker-compose down

restart: ## Restart all services
	@printf "$(YELLOW)Restarting all services...$(NC)\n"
	@docker-compose restart

pull: ## Pull latest images
	@printf "$(GREEN)Pulling latest images...$(NC)\n"
	@docker-compose pull

update: pull restart ## Pull latest images and restart services

##@ Monitoring & Diagnostics

status: ## Show Docker container status
	@printf "$(BLUE)Service Status:$(NC)\n"
	@docker-compose ps

health: ## Run the diagnostic script
	@printf "$(BLUE)Running diagnostic checks...$(NC)\n"
	@chmod +x diagnostic_server.sh
	@./diagnostic_server.sh

logs: ## Show logs for all services (follow mode)
	@docker-compose logs -f

logs-%: ## Show logs for specific service (e.g., make logs-backend)
	@docker-compose logs -f $*

##@ Database & Backups

backup: ## Run database backup script
	@printf "$(GREEN)Starting database backup...$(NC)\n"
	@chmod +x backup.sh
	@./backup.sh

db-postgres: ## Connect to PostgreSQL database
	@# Finds the postgres container ID dynamically in case suffix is used
	@ID=$$(docker ps -q -f "name=approve.postgres"); \
	if [ -z "$$ID" ]; then echo "$(RED)Postgres not running$(NC)"; else \
	echo "$(GREEN)Connecting to Postgres ($$ID)...$(NC)"; \
	docker exec -it $$ID psql -U postgres_admin -d approve_db; fi

db-mongo: ## Connect to MongoDB database
	@ID=$$(docker ps -q -f "name=approve.mongo"); \
	if [ -z "$$ID" ]; then echo "$(RED)Mongo not running$(NC)"; else \
	echo "$(GREEN)Connecting to Mongo ($$ID)...$(NC)"; \
	docker exec -it $$ID mongosh -u mongo_admin -p mongopass; fi

##@ Maintenance

clean: ## Stop services and remove containers
	@printf "$(YELLOW)Stopping and removing containers...$(NC)\n"
	@docker-compose down

prune: ## Prune unused Docker resources
	@printf "$(YELLOW)Pruning unused Docker resources...$(NC)\n"
	@docker system prune -f

urls: ## Show configured public URLs
	@if [ -f .env ]; then \
		echo ""; \
		echo "$(BLUE)Configured Public URLs:$(NC)"; \
		grep "URL=" .env; \
	else \
		echo "$(RED).env file not found$(NC)"; \
	fi