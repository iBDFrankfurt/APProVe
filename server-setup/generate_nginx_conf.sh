#!/bin/bash

# Read environment variables from .env.tmp file
if [ -f .env.tmp ]; then
  source .env.tmp
else
  echo "The .env file does not exist."
  exit 1
fi

# Directory to store Nginx configuration files (current working directory)
nginx_conf_dir="/etc/nginx/sites-available"
nginx_enabled_dir="/etc/nginx/sites-enabled"

# Read the .env.tmp file and export the variables
export "$(grep -v '^#' .env.tmp | xargs)"

# Function to extract subdomain from URL
get_subdomain() {
  local url="$1"
  local subdomain
  subdomain=$(echo "$url" | sed 's/https\?:\/\///' | tr ':/' '_')
  echo "$subdomain"
}

# Derive subdomains based on the URLs
subdomain_keycloak=$(get_subdomain "$APPROVE_KEYCLOAK_URL")
subdomain_frontend=$(get_subdomain "$APPROVE_FRONTEND_URL")
subdomain_backend=$(get_subdomain "$APPROVE_BACKEND_URL")

# Create Nginx configuration for Keycloak
cat <<EOL > "$nginx_conf_dir/approve-keycloak.conf"
server {
    server_name $subdomain_keycloak;

    location / {
        proxy_pass http://localhost:${AUTH_PORT};
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Scheme \$scheme;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_set_header   X-Forwarded-Port \$server_port;
        proxy_set_header   Host \$http_host;
    }
}
EOL

# Create Nginx configuration for Frontend
cat <<EOL > "$nginx_conf_dir/approve-frontend.conf"
server {
    server_name $subdomain_frontend;

    location / {
        proxy_pass http://localhost:${FRONTEND_PORT};
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Scheme \$scheme;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_set_header   X-Forwarded-Port \$server_port;
        proxy_set_header   Host \$http_host;
    }
}
EOL

# Create Nginx configuration for Backend
cat <<EOL > "$nginx_conf_dir/approve-backend.conf"
server {
    server_name $subdomain_backend;

    location / {
        proxy_pass http://localhost:${BACKEND_PORT};
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Scheme \$scheme;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_set_header   X-Forwarded-Port \$server_port;
        proxy_set_header   Host \$http_host;
    }
    location /user-service/ {
        proxy_pass http://localhost:${USER_PORT}/;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Scheme \$scheme;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_set_header   X-Forwarded-Port \$server_port;
        proxy_set_header   Host \$http_host;
    }

    location /automation-service/ {
        proxy_pass http://localhost:${AUTOMATION_PORT}/;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Scheme \$scheme;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_set_header   X-Forwarded-Port \$server_port;
        proxy_set_header   Host \$http_host;
    }

    location /comment-service/ {
        proxy_pass http://localhost:${COMMENT_PORT}/;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Scheme \$scheme;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_set_header   X-Forwarded-Port \$server_port;
        proxy_set_header   Host \$http_host;
    }

    location /mail-service/ {
        proxy_pass http://localhost:${EMAIL_PORT}/;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Scheme \$scheme;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_set_header   X-Forwarded-Port \$server_port;
        proxy_set_header   Host \$http_host;
    }

    #location /eureka-service/ {
    #    proxy_pass http://localhost:${EUREKA_PORT}/;
    #    proxy_set_header   X-Real-IP \$remote_addr;
    #    proxy_set_header   X-Scheme \$scheme;
    #    proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
    #    proxy_set_header   X-Forwarded-Proto \$scheme;
    #    proxy_set_header   X-Forwarded-Port \$server_port;
    #    proxy_set_header   Host \$http_host;
    #}

    location /manual/ {
        proxy_pass http://localhost:${MANUAL_PORT}/manual/;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Scheme \$scheme;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_set_header   X-Forwarded-Port \$server_port;
        proxy_set_header   Host \$http_host;
    }

    location /draft-service/ {
        proxy_pass http://localhost:${DRAFT_PORT}/;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Scheme \$scheme;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_set_header   X-Forwarded-Port \$server_port;
        proxy_set_header   Host \$http_host;
    }

    location /import-service/ {
        proxy_pass http://localhost:${IMPORT_PORT}/;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Scheme \$scheme;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
        proxy_set_header   X-Forwarded-Port \$server_port;
        proxy_set_header   Host \$http_host;
    }
}
EOL

# Create symbolic links to enable the configurations
ln -s "$nginx_conf_dir/approve-keycloak.conf" "$nginx_enabled_dir/approve-keycloak.conf"
ln -s "$nginx_conf_dir/approve-frontend.conf" "$nginx_enabled_dir/approve-frontend.conf"
ln -s "$nginx_conf_dir/approve-backend.conf" "$nginx_enabled_dir/approve-backend.conf"

# Test Nginx configuration
if nginx -t; then
  # Reload Nginx if the test is successful
  systemctl reload nginx
  echo "Nginx configuration updated and reloaded successfully."
else
  echo "Nginx configuration test failed. Please check your configurations."
fi
