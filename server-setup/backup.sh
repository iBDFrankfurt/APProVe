#!/bin/bash

#==================================================================================
# APProVe Database Backup Script
# Version: 4.0.0
# Description: Creates backups of PostgreSQL and MongoDB databases
#==================================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

#----------------------------------------------------------------------------------
# Banner
#----------------------------------------------------------------------------------
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║             APProVe Database Backup                       ║
║                  Version 4.0.0                            ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

#----------------------------------------------------------------------------------
# Load Environment
#----------------------------------------------------------------------------------
if [ ! -f "${SCRIPT_DIR}/.env" ]; then
    echo -e "${RED}✗ .env file not found!${NC}"
    echo "Please ensure .env file exists in ${SCRIPT_DIR}"
    exit 1
fi

echo -e "${BLUE}Loading environment variables...${NC}"
set -o allexport
source "${SCRIPT_DIR}/.env"
set +o allexport
echo -e "${GREEN}✓ Environment loaded${NC}"
echo ""

#----------------------------------------------------------------------------------
# Create Backup Directory
#----------------------------------------------------------------------------------
echo -e "${BLUE}Preparing backup directory...${NC}"
mkdir -p "$BACKUP_DIR"
echo -e "${GREEN}✓ Backup directory ready: ${BACKUP_DIR}${NC}"
echo ""

#----------------------------------------------------------------------------------
# PostgreSQL Backup
#----------------------------------------------------------------------------------
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  PostgreSQL Backup                                        ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

POSTGRES_CONTAINER="approve.postgres${CONTAINER_NAME_SUFFIX}"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER}$"; then
    echo -e "${RED}✗ PostgreSQL container not running: ${POSTGRES_CONTAINER}${NC}"
    exit 1
fi

echo -e "${YELLOW}Backing up Keycloak database (${APPROVE_AUTH_DB})...${NC}"
AUTH_BACKUP_FILE="${BACKUP_DIR}/postgres_auth_${TIMESTAMP}.sql.gz"

if docker exec -t "$POSTGRES_CONTAINER" pg_dump \
    --dbname="$APPROVE_AUTH_DB" \
    --create \
    --clean \
    --if-exists \
    --format=p \
    --column-inserts \
    -U "$APPROVE_POSTGRES_USER" | gzip > "$AUTH_BACKUP_FILE"; then
    echo -e "${GREEN}✓ Keycloak database backed up${NC}"
    echo "  File: ${AUTH_BACKUP_FILE}"
    echo "  Size: $(du -h "$AUTH_BACKUP_FILE" | cut -f1)"
else
    echo -e "${RED}✗ Failed to backup Keycloak database${NC}"
fi

echo ""

echo -e "${YELLOW}Backing up APProVe database (${APPROVE_PROJECT_DB})...${NC}"
PROJECT_BACKUP_FILE="${BACKUP_DIR}/postgres_project_${TIMESTAMP}.sql.gz"

if docker exec -t "$POSTGRES_CONTAINER" pg_dump \
    --dbname="$APPROVE_PROJECT_DB" \
    --create \
    --clean \
    --if-exists \
    --format=p \
    --column-inserts \
    -U "$APPROVE_POSTGRES_USER" | gzip > "$PROJECT_BACKUP_FILE"; then
    echo -e "${GREEN}✓ APProVe database backed up${NC}"
    echo "  File: ${PROJECT_BACKUP_FILE}"
    echo "  Size: $(du -h "$PROJECT_BACKUP_FILE" | cut -f1)"
else
    echo -e "${RED}✗ Failed to backup APProVe database${NC}"
fi

echo ""

#----------------------------------------------------------------------------------
# MongoDB Backup
#----------------------------------------------------------------------------------
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  MongoDB Backup                                           ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

MONGO_CONTAINER="approve.mongo${CONTAINER_NAME_SUFFIX}"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${MONGO_CONTAINER}$"; then
    echo -e "${RED}✗ MongoDB container not running: ${MONGO_CONTAINER}${NC}"
    exit 1
fi

echo -e "${YELLOW}Backing up MongoDB (store database)...${NC}"
MONGO_BACKUP_FILE="${BACKUP_DIR}/mongo_${TIMESTAMP}.dump"

if docker exec "$MONGO_CONTAINER" sh -c \
    "mongodump --authenticationDatabase admin -u $APPROVE_MONGO_USER -p $APPROVE_MONGO_PASSWORD --db store --archive" \
    > "$MONGO_BACKUP_FILE"; then
    echo -e "${GREEN}✓ MongoDB backed up${NC}"
    echo "  File: ${MONGO_BACKUP_FILE}"
    echo "  Size: $(du -h "$MONGO_BACKUP_FILE" | cut -f1)"
else
    echo -e "${RED}✗ Failed to backup MongoDB${NC}"
fi

echo ""

#----------------------------------------------------------------------------------
# Summary
#----------------------------------------------------------------------------------
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Backup Complete!                                         ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Backup Files Created:${NC}"
echo "  • PostgreSQL (Auth):    ${AUTH_BACKUP_FILE}"
echo "  • PostgreSQL (Project): ${PROJECT_BACKUP_FILE}"
echo "  • MongoDB:              ${MONGO_BACKUP_FILE}"
echo ""
echo -e "${YELLOW}Total Backup Size:${NC}"
du -sh "$BACKUP_DIR"
echo ""
echo -e "${BLUE}To restore from backup:${NC}"
echo ""
echo -e "${YELLOW}PostgreSQL:${NC}"
echo "  gunzip < ${AUTH_BACKUP_FILE} | docker exec -i ${POSTGRES_CONTAINER} psql -U ${APPROVE_POSTGRES_USER}"
echo "  gunzip < ${PROJECT_BACKUP_FILE} | docker exec -i ${POSTGRES_CONTAINER} psql -U ${APPROVE_POSTGRES_USER}"
echo ""
echo -e "${YELLOW}MongoDB:${NC}"
echo "  docker exec -i ${MONGO_CONTAINER} mongorestore --authenticationDatabase admin -u ${APPROVE_MONGO_USER} -p ${APPROVE_MONGO_PASSWORD} --archive < ${MONGO_BACKUP_FILE}"
echo ""
echo -e "${GREEN}✓ All backups completed successfully${NC}"
echo ""

#----------------------------------------------------------------------------------
# Optional: Cleanup Old Backups
#----------------------------------------------------------------------------------
read -p "Do you want to remove backups older than 30 days? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cleaning up old backups...${NC}"
    find "$BACKUP_DIR" -name "*.sql.gz" -mtime +30 -delete
    find "$BACKUP_DIR" -name "*.dump" -mtime +30 -delete
    echo -e "${GREEN}✓ Old backups removed${NC}"
fi

echo ""
echo -e "${BLUE}Backup script finished.${NC}"