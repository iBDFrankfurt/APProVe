#!/bin/bash
# Script to configure Keycloak and related services locally.
# As of now it is untested on a server architecture and only for local deployments. I can be adjusted to run of a server though.
# The script will do the following things:
# 1. Check if docker, docker-compose and git are installed
# 2. Checks if the .env file is present
# 3. Login to the registry for APProVe Images
# 4. Downloads the custom made themes for keycloak from https://gitlab.ibdf-frankfurt.de/proskive/keycloak-themes.git
# 5. Downloads the custom made keycloak-event-listener to update the database of APProVe https://gitlab.ibdf-frankfurt.de/uct/keycloak-event-listener.git
# 6. Creates the APProVe Docker Network and pulls the latest versions
# 7. Starts all services
# 8. After the services started it will begin to configure Keycloak based on the provides .env file
# 8.1 Create new realm
# 8.2 Creates user to communicate between APProVe and Keycloak
# 8.3 Sets the previously downloaded keycloak-event-listener to this realm
# 8.4 Creates a client in Keycloak
# 8.5 Creates a default admin role
# 8.6 Creates an admin user with that admin role
# 8.7 Checks if the role and admin user were created in APProVe


# Check if Docker, docker-compose, and git are installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "docker-compose is not installed. Please install docker-compose and try again."
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "git is not installed. Please install git and try again."
    exit 1
fi

echo "-----------------------------------------------------"
echo "   Starting APProVe installation "
echo "-----------------------------------------------------"

# Check if .env file is present and read variables from it
echo "Checking if .env file is present..."
if [ -e ".env" ]; then
  echo "File .env found."
  echo "removing carriage return (CR) ..."
  tr -d '\r' < .env > .env.temp
  mv .env.temp .env
  source .env
  # Loop through the variables and print key-value pairs without comments
  echo "Variables defined in .env:"
  while IFS= read -r line; do
    # Ignore lines starting with "#" (comments) or empty lines
    if [[ "$line" =~ ^[[:space:]]*# || -z "$line" ]]; then
      continue
    fi

    # Extract key (portion before '=') and value (portion after '=')
    key="${line%%=*}"
    value="${line#*=}"

    # Print key and value
    echo "$key = $value"
  done < .env
else
  echo "File .env not found. Exiting."
  exit 1
fi

# Clone the Keycloak Themes and keycloak event listener SPI repositories
echo "Getting the Keycloak Themes..."
GIT_SSL_NO_VERIFY=1 git clone https://gitlab.ibdf-frankfurt.de/proskive/keycloak-themes.git

echo "Getting the keycloak event listener SPI..."
GIT_SSL_NO_VERIFY=1 git clone https://gitlab.ibdf-frankfurt.de/uct/keycloak-event-listener.git

# Create a Docker network and start the services using docker-compose
echo "Create network"
docker network create approve_network
docker-compose pull && docker-compose up -d

# Wait for services to be ready before continuing
echo "Waiting for services to be ready..."
# Define the API endpoints to check
backend_endpoint="${APPROVE_BACKEND_URL}/api/health"
keycloak_endpoint="${APPROVE_KEYCLOAK_URL}/health"

is_endpoint_available() {
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$1")
    echo "curl backend at ${backend_endpoint} returned ${response_code}"
    echo "curl auth at ${keycloak_endpoint} returned ${response_code}"
    if [ "$response_code" = "200" ]; then
        return 0  # Endpoint is available
    else
        return 1  # Endpoint is not available
    fi
}

while ! is_endpoint_available "$backend_endpoint" || ! is_endpoint_available "$keycloak_endpoint"; do
    echo "Waiting for services..."
    sleep 10
done

echo "Services are up and running. Performing additional logic..."

# Log in to Keycloak with the master user based on .env-file
echo "Logging in to Keycloak with master user based on .env-file..."
docker exec -t approve.auth sh -c "/opt/keycloak/bin/kcadm.sh config credentials --server \"$APPROVE_KEYCLOAK_URL\" --realm master --user \"$APPROVE_KEYCLOAK_ADMIN_USER\" --password \"$APPROVE_KEYCLOAK_ADMIN_PASSWORD\""

# Create a new realm in Keycloak
echo "Creating realm..."
docker exec -t approve.auth sh -c "/opt/keycloak/bin/kcadm.sh create realms -s realm=\"$KEYCLOAK_REALM_NAME\" -s enabled=true -s 'accountTheme=custom-theme' -o"
docker exec -t approve.auth sh -c "/opt/keycloak/bin/kcadm.sh get realms/\"$KEYCLOAK_REALM_NAME\" --fields realm,enabled,accountTheme"


# Add a restuser for APProVe
echo "Adding restuser for APProVe..."
docker exec -t approve.auth sh -c "/opt/keycloak/bin/kcadm.sh create users -r \"$KEYCLOAK_REALM_NAME\" -s username=\"$KEYCLOAK_USER_NAME\" -s enabled=true -s \"emailVerified=true\""

echo "Adding password..."
docker exec -t approve.auth sh -c "/opt/keycloak/bin/kcadm.sh set-password -r \"$KEYCLOAK_REALM_NAME\" --username \"$KEYCLOAK_USER_NAME\" --new-password \"$KEYCLOAK_USER_PASSWORD\""

echo "Adding realm-management role..."
docker exec -t approve.auth sh -c "/opt/keycloak/bin/kcadm.sh add-roles -r \"$KEYCLOAK_REALM_NAME\" --uusername \"$KEYCLOAK_USER_NAME\" --cclientid realm-management --rolename realm-admin"

echo "Done setting restuser. Setting keycloak-event-listener..."
docker exec -t approve.auth sh -c "/opt/keycloak/bin/kcadm.sh update events/config -r \"$KEYCLOAK_REALM_NAME\" -s 'eventsListeners=[\"jboss-logging\",\"sample_event_listener\"]'"

# Create client scope 'openid' and retrieve its ID
CLIENT_SCOPE_NAME="openid"
SID_STRING=$(docker exec -t approve.auth sh -c "/opt/keycloak/bin/kcadm.sh create client-scopes -r \"$KEYCLOAK_REALM_NAME\" -s name=\"$CLIENT_SCOPE_NAME\" -s protocol=openid-connect -s consentRequired=false")
SID=$(echo "$SID_STRING" | grep -o "id '[^']*'" | grep -o "'[^']*'" | grep -o "[^']*")
echo "Client Scope ID: $SID"

# Create a client protected by Keycloak
echo "Creating Client which will be protected by Keycloak."
CID=$(docker exec -t approve.auth sh -c "/opt/keycloak/bin/kcadm.sh create clients -r \"$KEYCLOAK_REALM_NAME\" -s clientId=\"$APPROVE_CLIENT_ID\" -s 'rootUrl=\"$APPROVE_FRONTEND_URL\"' -s 'redirectUris=[\"$APPROVE_FRONTEND_URL/*\"]' -s 'webOrigins=[\"$APPROVE_FRONTEND_URL/*\"]' -s 'attributes.login_theme=custom-theme' -s 'directAccessGrantsEnabled=true' -s 'publicClient=true' -i")
docker exec -t approve.auth sh -c "/opt/keycloak/bin/kcadm.sh update \"$APPROVE_KEYCLOAK_URL\"/admin/realms/\"$KEYCLOAK_REALM_NAME\"/clients/\"$CID\"/default-client-scopes/\"$SID\""
echo "Done setting the client; $CID"


# Create the default admin role in Keycloak and APProVe
echo "Creating the default admin role in Keycloak and APProVe..."
docker exec -t approve.auth sh -c "/opt/keycloak/bin/kcadm.sh create roles -r \"$KEYCLOAK_REALM_NAME\" -s name='APPROVE_ADMIN_ROLE' -s 'attributes={\"is_admin\":[true]}' -s 'description=This is the default APProVe-Admin Role.'"

# Check if the role is created in APProVe as well
output="$(docker exec -t approve.postgres psql -U "$APPROVE_POSTGRES_USER" -d "$APPROVE_PROJECT_DB" -c "select id, name, is_admin from keycloak_roles;" | awk 'NR==3 {print $1, $2, $3}')"
if [[ -z "$output" || "$output" == "null" ]]; then
    echo "The role id is null. Check logs of approve.backend!"
    docker logs approve.backend
fi
echo "Role found in APProVe Database:"
echo "$output"

# Finally, create the admin user to log in to APProVe
echo "Creating admin user to log in to APProVe."
docker exec -t approve.auth sh -c "/opt/keycloak/bin/kcadm.sh create users -r \"$KEYCLOAK_REALM_NAME\" -s username=\"$APPROVE_ADMIN_USER\" -s enabled=true -s 'email=\"$APPROVE_ADMIN_EMAIL\"' -s \"emailVerified=true\" -s 'firstName=\"Your_First_Name\"' -s 'lastName=\"Your_Last_Name\"' -s 'requiredActions=[\"VERIFY_EMAIL\",\"UPDATE_PROFILE\",\"terms_and_conditions\",\"update_password\"]'"

docker exec -t approve.auth sh -c "/opt/keycloak/bin/kcadm.sh set-password -r \"$KEYCLOAK_REALM_NAME\" --username \"$APPROVE_ADMIN_USER\" --new-password \"$APPROVE_ADMIN_PASSWORD\""

docker exec -t approve.auth sh -c "/opt/keycloak/bin/kcadm.sh add-roles -r \"$KEYCLOAK_REALM_NAME\" --uusername \"$APPROVE_ADMIN_USER\" --rolename 'APPROVE_ADMIN_ROLE'"

# Check if the user is created in APProVe as well
output="$(docker exec -t approve.postgres psql -U "$APPROVE_POSTGRES_USER" -d "$APPROVE_PROJECT_DB" -c "select id, last_name from person;" | awk 'NR==3 {print $1}')"
if [[ -z "$output" || "$output" == "null" ]]; then
    echo "The person id is null. Check logs of approve.backend!"
    docker logs approve.backend
fi
echo "User found in APProVe Database:"
echo "$output"

echo "================================================================================================="
echo "Congratulations! Installation was complete!"
echo "Please check the logs if their are any errors via: docker-compose logs -f"
echo "You only need to run this install script once. After it successfully completed you can just use: docker-compose up -d in the future!"
echo "You should now be able to log in $APPROVE_FRONTEND_URL"
echo ">>> Depending on your system and installation, you may have to add NGINX entries or, if locally installed adjusting the hosts file. <<<"
echo "For further documentation please visit https://gitlab.ibdf-frankfurt.de/uct/open-approve"
echo "================================================================================================="
# Wait for a key press without displaying a prompt
echo "Press any key to exit..."
read -n 1 -s -r -p ""
