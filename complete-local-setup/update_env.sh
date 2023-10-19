#!/bin/bash

# Function to update an environment variable in .env.tmp file
update_variable() {
  local variable_name="$1"
  local current_value
  current_value=$(grep "^$variable_name=" .env.tmp | cut -d '=' -f2)
  local new_value
  read -r -p "Enter a new value for $variable_name (current: $current_value): " new_value
  # Use the current value if the user input is empty
  new_value="${new_value:-$current_value}"
  # Replace or add the variable in .env.tmp
  if [ -z "$current_value" ]; then
    echo "$variable_name=$new_value" >> .env.tmp
  else
    # Use a different delimiter for sed
    delimiter="|"
    sed -i "s$delimiter$variable_name=.*$delimiter$variable_name=$new_value$delimiter" .env.tmp
  fi
}

# Check if .env.tmp file exists
if [ ! -f .env.tmp ]; then
  echo "The .env file does not exist in the current directory. Please create it first."
  exit 1
fi

# List of environment variables to update
variables_to_update=(
  "APPROVE_POSTGRES_USER"
  "APPROVE_POSTGRES_PASSWORD"
  "APPROVE_MONGO_USER"
  "APPROVE_MONGO_PASSWORD"
  "KEYCLOAK_REALM_NAME"
  "APPROVE_KEYCLOAK_ADMIN_USER"
  "APPROVE_KEYCLOAK_ADMIN_PASSWORD"
  "APPROVE_KEYCLOAK_URL"
  "APPROVE_FRONTEND_URL"
  "APPROVE_BACKEND_URL"
  "KEYCLOAK_USER_NAME"
  "KEYCLOAK_USER_PASSWORD"
  "APPROVE_ADMIN_USER"
  "APPROVE_ADMIN_PASSWORD"
  "APPROVE_ADMIN_EMAIL"
)

# Loop through the list and update the variables
for variable in "${variables_to_update[@]}"; do
  update_variable "$variable"
done

echo "Environment variables have been updated in .env."
