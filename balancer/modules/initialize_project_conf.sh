#!/bin/bash

# Remove existing project.conf to ensure it's reinitialized
rm -f "${BALANCER_NGINX_PROJ_CONF_FILE}"

# Initialize project.conf with dynamic configuration
cat > "${BALANCER_NGINX_PROJ_CONF_FILE}" <<EOF
# Generated file @ $(date '+%Y-%m-%d %I:%M:%S %p %Z')

# Define upstream servers based on service type and port
EOF

for service in "${!services[@]}"; do
    echo "upstream $service { server ${services[$service]}; }" >> "${BALANCER_NGINX_PROJ_CONF_FILE}"
done

cat >> "${BALANCER_NGINX_PROJ_CONF_FILE}" <<EOF

# Map hostnames to the correct backend
map \$http_host \$backend {
    default "default-backend";
EOF

for service in "${!services[@]}"; do
    echo "    ${service}.${BALANCER_DOMAIN}:${BALANCER_PORT_HTTP} $service;" >> "${BALANCER_NGINX_PROJ_CONF_FILE}"
done

cat >> "${BALANCER_NGINX_PROJ_CONF_FILE}" <<EOF
}

# HTTP Server block for redirecting to HTTPS
server {
    listen 80;
    listen [::]:80;
EOF

# Populate server_name with dynamically created domain names
server_names=$(printf ",%s.${BALANCER_DOMAIN}" "${!services[@]}")
server_names=${server_names:1} # Remove the leading comma

cat >> "${BALANCER_NGINX_PROJ_CONF_FILE}" <<EOF
    server_name $server_names;

    location / {
        return 301 https://\$host:${BALANCER_PORT}\$request_uri;
    }
    
    error_log /var/log/nginx/http-error.log warn;
    access_log /var/log/nginx/http-access.log combined;
}
EOF
