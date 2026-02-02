#!/bin/bash

#==================================================================================
# APProVe Environment Configuration Generator
# Version: 4.0.0
# Description: Interactive script to generate .env file from template
#==================================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INPUT_ENV_FILE=".env.tmp"
OUTPUT_ENV_FILE=".env"

#----------------------------------------------------------------------------------
# Banner
#----------------------------------------------------------------------------------
clear
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         APProVe Environment Configuration                 ║
║                  Version 4.0.0                            ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

#----------------------------------------------------------------------------------
# Check Prerequisites
#----------------------------------------------------------------------------------
echo -e "${BLUE}Checking prerequisites...${NC}"

if ! command -v openssl &> /dev/null; then
    echo -e "${RED}✗ openssl is not installed.${NC}"
    echo "Please install openssl and try again."
    exit 1
fi

if [ ! -f "$INPUT_ENV_FILE" ]; then
    echo -e "${RED}✗ Template file $INPUT_ENV_FILE not found.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites satisfied${NC}"
echo ""

#----------------------------------------------------------------------------------
# Copy Template
#----------------------------------------------------------------------------------
echo -e "${BLUE}Creating .env file from template...${NC}"
cp "$INPUT_ENV_FILE" "$OUTPUT_ENV_FILE"

# Remove carriage returns (Windows compatibility)
tr -d '\r' < "$OUTPUT_ENV_FILE" > .env.unix
mv .env.unix "$OUTPUT_ENV_FILE"

echo -e "${GREEN}✓ Template copied${NC}"
echo ""

#----------------------------------------------------------------------------------
# Generate Encryption Key
#----------------------------------------------------------------------------------
echo -e "${BLUE}Generating encryption key...${NC}"

if ! grep -q "^ENCRYPTION_KEY=" "$OUTPUT_ENV_FILE"; then
    ENCRYPTION_KEY=$(openssl rand -hex 32)
    cat >> "$OUTPUT_ENV_FILE" << EOF

#----------------------------------------------------------------------------------
# ENCRYPTION KEY (Auto-generated)
# Generated: $(date)
#----------------------------------------------------------------------------------
ENCRYPTION_KEY=$ENCRYPTION_KEY
EOF
    echo -e "${GREEN}✓ Encryption key generated${NC}"
else
    echo -e "${YELLOW}⚠ Encryption key already exists, skipping...${NC}"
fi

echo ""

#----------------------------------------------------------------------------------
# Interactive Configuration
#----------------------------------------------------------------------------------
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           Interactive Configuration                       ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Please provide the following information."
echo "Press ENTER to keep the current/default value shown in brackets."
echo ""

# Function to prompt for variable
prompt_for_variable() {
    local var_name="$1"
    local var_description="$2"
    local is_password="${3:-false}"

    # Get current value
    local current_value
     current_value=$(grep "^${var_name}=" "$OUTPUT_ENV_FILE" | head -1 | cut -d '=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//')

    # Display prompt
    if [ "$is_password" = "true" ]; then
        echo -e "${YELLOW}${var_description}${NC}"
        read -s -p "  [$current_value]: " new_value
        echo ""
    else
        echo -e "${YELLOW}${var_description}${NC}"
        read -p "  [$current_value]: " new_value
    fi

    # Use current value if input is empty
    new_value="${new_value:-$current_value}"

    # Update .env file
    if grep -q "^${var_name}=" "$OUTPUT_ENV_FILE"; then
        sed -i "s|^${var_name}=.*|${var_name}=\"${new_value}\"|" "$OUTPUT_ENV_FILE"
    else
        echo "${var_name}=\"${new_value}\"" >> "$OUTPUT_ENV_FILE"
    fi
}

#----------------------------------------------------------------------------------
# Domain Configuration
#----------------------------------------------------------------------------------
echo -e "${BLUE}─── Domain Configuration ───${NC}"
echo ""

prompt_for_variable "APPROVE_KEYCLOAK_URL" "Keycloak URL (e.g., https://auth.example.com)"
prompt_for_variable "APPROVE_FRONTEND_URL" "Frontend URL (e.g., https://approve.example.com)"
prompt_for_variable "APPROVE_BACKEND_URL" "Backend URL (e.g., https://backend.example.com)"

echo ""

#----------------------------------------------------------------------------------
# Keycloak Configuration
#----------------------------------------------------------------------------------
echo -e "${BLUE}─── Keycloak Configuration ───${NC}"
echo ""

prompt_for_variable "KEYCLOAK_REALM_NAME" "Keycloak Realm Name"
prompt_for_variable "APPROVE_KEYCLOAK_ADMIN_USER" "Keycloak Admin Username"
prompt_for_variable "APPROVE_KEYCLOAK_ADMIN_PASSWORD" "Keycloak Admin Password" true
prompt_for_variable "KEYCLOAK_USER_NAME" "Keycloak Service User (for API access)"
prompt_for_variable "KEYCLOAK_USER_PASSWORD" "Keycloak Service User Password" true

echo ""

#----------------------------------------------------------------------------------
# APProVe Admin User
#----------------------------------------------------------------------------------
echo -e "${BLUE}─── APProVe Admin User ───${NC}"
echo ""

prompt_for_variable "APPROVE_ADMIN_USER" "APProVe Admin Username"
prompt_for_variable "APPROVE_ADMIN_PASSWORD" "APProVe Admin Password" true
prompt_for_variable "APPROVE_ADMIN_EMAIL" "APProVe Admin Email"

echo ""

#----------------------------------------------------------------------------------
# Database Configuration
#----------------------------------------------------------------------------------
echo -e "${BLUE}─── Database Configuration ───${NC}"
echo ""

prompt_for_variable "APPROVE_POSTGRES_USER" "PostgreSQL Username"
prompt_for_variable "APPROVE_POSTGRES_PASSWORD" "PostgreSQL Password" true
prompt_for_variable "APPROVE_MONGO_USER" "MongoDB Username"
prompt_for_variable "APPROVE_MONGO_PASSWORD" "MongoDB Password" true

echo ""

#----------------------------------------------------------------------------------
# Optional: Container Name Suffix
#----------------------------------------------------------------------------------
echo -e "${BLUE}─── Optional Settings ───${NC}"
echo ""

prompt_for_variable "CONTAINER_NAME_SUFFIX" "Container Name Suffix (leave empty for single instance)"

echo ""

#----------------------------------------------------------------------------------
# Perform Variable Substitution
#----------------------------------------------------------------------------------
echo -e "\n${BLUE}Performing variable substitution...${NC}"

# Instead of sourcing (which fails on spaces/dashes), we manually export each variable
while IFS='=' read -r key value || [[ -n "$key" ]]; do
    # Skip comments and empty lines
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue

    # Clean the value: strip whitespace and surrounding quotes
    clean_value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//')

    # Export the variable so envsubst can see it
    export "$key"="$clean_value"
done < "$OUTPUT_ENV_FILE"

BASE_URL=$(echo "$APPROVE_BACKEND_URL" | sed 's|/$||')

# Update the .env file with the correctly formatted URLs
sed -i "s|^APPROVE_USER_URL=.*|APPROVE_USER_URL=\"${BASE_URL}/user-service\"|" "$OUTPUT_ENV_FILE"
sed -i "s|^APPROVE_AUTOMATION_URL=.*|APPROVE_AUTOMATION_URL=\"${BASE_URL}/automation-service\"|" "$OUTPUT_ENV_FILE"
sed -i "s|^APPROVE_COMMENTS_URL=.*|APPROVE_COMMENTS_URL=\"${BASE_URL}/comment-service\"|" "$OUTPUT_ENV_FILE"
sed -i "s|^APPROVE_MAIL_URL=.*|APPROVE_MAIL_URL=\"${BASE_URL}/mail-service\"|" "$OUTPUT_ENV_FILE"
sed -i "s|^APPROVE_MANUAL_URL=.*|APPROVE_MANUAL_URL=\"${BASE_URL}/manual\"|" "$OUTPUT_ENV_FILE"
sed -i "s|^APPROVE_DRAFT_URL=.*|APPROVE_DRAFT_URL=\"${BASE_URL}/draft-service\"|" "$OUTPUT_ENV_FILE"
sed -i "s|^APPROVE_IMPORT_URL=.*|APPROVE_IMPORT_URL=\"${BASE_URL}/import-service\"|" "$OUTPUT_ENV_FILE"

envsubst < "$OUTPUT_ENV_FILE" > .env.temp
mv .env.temp "$OUTPUT_ENV_FILE"

echo -e "${GREEN}✓ Configuration complete!${NC}"
echo -e "${BLUE}Final .env file is ready.${NC}\n"
echo ""

#----------------------------------------------------------------------------------
# Summary
#----------------------------------------------------------------------------------
# Helper to show values without quotes in the summary
get_val() {
    grep "^$1=" .env | cut -d'=' -f2- | sed 's/^"//;s/"$//'
}
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}           Configuration Complete!                         ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Configuration file created: ${OUTPUT_ENV_FILE}"
echo ""
echo -e "${YELLOW}Key Configuration:${NC}"
echo -e "  • Keycloak URL:  $(get_val APPROVE_KEYCLOAK_URL)"
echo -e "  • Frontend URL:  $(get_val APPROVE_FRONTEND_URL)"
echo -e "  • Backend URL:   $(get_val APPROVE_BACKEND_URL)"
echo -e "  • Realm Name:    $(get_val KEYCLOAK_REALM_NAME)"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Review the .env file and verify all settings"
echo -e "  2. Run: ${YELLOW}make nginx${NC}"
echo -e "  3. Configure SSL with: ${YELLOW}make certbot${NC}"
echo -e "  4. Run: ${YELLOW}make install${NC}"
echo ""
echo -e "${RED}⚠  IMPORTANT SECURITY NOTE:${NC}"
echo -e "   Make sure to change all default passwords before going to production!"
echo -e "   Protect your .env file - it contains sensitive credentials."
echo ""