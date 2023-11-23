#!/bin/bash

# Define the input and output files
input_env_file=".env.tmp"
output_env_file=".env"

# Copy the .env.tmp file to .env
cp "$input_env_file" "$output_env_file"

# Function to generate a random hexadecimal key
generate_random_key() {
  openssl rand -hex 32
}

# Check if ENCRYPTION_KEY is already set, if not, generate a new key
if ! grep -q "^CONTAINER_NAME_SUFFIX=" "$output_env_file"; then
  new_key=$(generate_random_key)
  echo -e "# Used for encryption\n# You can generate it by: openssl rand -hex 32" >> "$output_env_file"
  echo "ENCRYPTION_KEY=$new_key" >> "$output_env_file"
fi

if ! grep -q "^CONTAINER_NAME_SUFFIX=" "$output_env_file"; then
  echo -e "#---------------------------------------------------------------------------------------------------------\n# Only important if approve runs multiple times on the same server. Adjusts the container names\n # Can be left blank" >> "$output_env_file"
  echo "CONTAINER_NAME_SUFFIX=" >> "$output_env_file"
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
  "KEYCLOAK_USER_NAME"
  "KEYCLOAK_USER_PASSWORD"
  "APPROVE_ADMIN_USER"
  "APPROVE_ADMIN_PASSWORD"
  "APPROVE_ADMIN_EMAIL"
)

# Loop through the list and update the variables
for variable in "${variables_to_update[@]}"; do
  current_value=$(grep "^$variable=" "$output_env_file" | cut -d '=' -f2)
  read -r -p "Enter a new value for $variable (current: $current_value): " new_value
  # Use the current value if the user input is empty
  new_value="${new_value:-$current_value}"
  # Replace or add the variable in .env
  if [ -z "$current_value" ]; then
    echo "$variable=$new_value" >> "$output_env_file"
  else
    # Use a different delimiter for sed
    delimiter="|"
    sed -i "s$delimiter$variable=.*$delimiter$variable=$new_value$delimiter" "$output_env_file"
  fi
done

# Perform variable substitution using envsubst to generate .env
export "$(grep -v '^#' "$output_env_file" | xargs)"
envsubst < "$output_env_file" > "temp.env"
mv "temp.env" "$output_env_file"

echo "Environment variables have been updated in $output_env_file."
