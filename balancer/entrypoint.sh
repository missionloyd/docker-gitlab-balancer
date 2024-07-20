#!/bin/bash

# Create necessary directories
mkdir -p "${BALANCER_SSL_BASE_DIR}"
mkdir -p "${BALANCER_NGINX_CONF_DIR}"

# Define domains and servers
declare -A services=(
    [dev-powertwin]=gitlab-runner:9443
    [prev-powertwin]=gitlab-runner:9444
    [main-powertwin]=gitlab-runner:9445
    [dev-powertwin-db]=gitlab-runner:5443
    [prev-powertwin-db]=gitlab-runner:5444
    [main-powertwin-db]=gitlab-runner:5445
    [dev-powertwin-solver]=gitlab-runner:7443
    [prev-powertwin-solver]=gitlab-runner:7444
    [main-powertwin-solver]=gitlab-runner:7445
)

# Remove existing project.conf to ensure it's reinitialized
rm -f "${BALANCER_NGINX_PROJ_CONF_FILE}"

# Initialize project.conf with dynamic configuration
cat > "${BALANCER_NGINX_PROJ_CONF_FILE}" <<EOF
# Generated file @ $(date '+%Y-%m-%d %H:%M:%S')

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

# Function to check if a certificate exists for a domain
certificate_exists() {
    local domain=$1
    local cert_path="${BALANCER_NGINX_CONF_DIR}/${domain}/${domain}.crt"
    [ -f "${cert_path}" ]
}

# Function to generate a certificate for a domain
generate_certificate() {
    local domain=$1
    local domain_dir="${BALANCER_NGINX_CONF_DIR}/${domain}"
    local cert_path="${domain_dir}/${domain}.crt"

    # Check if the certificate already exists
    if certificate_exists "$domain"; then
        echo "Certificate already exists for ${domain}, skipping generation."
        return
    fi

    mkdir -p "${domain_dir}"

    # Step 1: Generate the server private key
    openssl genrsa -out "${domain_dir}/${domain}.key" 2048

    # Step 2: Generate the CSR with additional information
    openssl req -new \
        -key "${domain_dir}/${domain}.key" \
        -out "${domain_dir}/${domain}.csr" \
        -subj "/C=US/ST=WY/L=Laramie/O=Power Theory Inc./OU=Operations/CN=${domain}/emailAddress=${BALANCER_EMAIL_ADDRESS}" \
        -addext "subjectAltName = DNS:${domain}" \
        -passout pass:${BALANCER_PASSWORD}

    # Step 3: Sign the certificate
    openssl x509 -req -days ${BALANCER_CERT_VALIDITY_DAYS} \
        -in "${domain_dir}/${domain}.csr" \
        -signkey "${domain_dir}/${domain}.key" \
        -out "${cert_path}"

    echo "Certificate generated for ${domain}"
}

# Generate DHE parameters only if any certificate needs to be generated
need_dh_params=false
for domain in "${!services[@]}"; do
    full_domain="${domain}.${BALANCER_DOMAIN}"
    if ! certificate_exists "$full_domain"; then
        need_dh_params=true
        break
    fi
done

if [ "$need_dh_params" = true ]; then
    echo "Generating DHE parameters..."
    openssl dhparam -out "${BALANCER_NGINX_CONF_DIR}/dhparam.pem" ${BALANCER_DH_PARAMS_BITS}
else
    echo "All certificates exist, skipping DHE parameter generation."
fi

# Function to create nginx server block
create_nginx_server_block() {
    local domain=$1
    local full_domain="${domain}.${BALANCER_DOMAIN}"
    local domain_dir="${BALANCER_NGINX_CONF_DIR}/${full_domain}"
    echo "
# ${full_domain}
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name ${full_domain};
    ssl_certificate ${domain_dir}/${full_domain}.crt;
    ssl_certificate_key ${domain_dir}/${full_domain}.key;
    include /etc/nginx/snippets/ssl-params.conf;
    location / {
        resolver 127.0.0.11;
        proxy_pass http://${domain};
        include /etc/nginx/snippets/proxy-params.conf;
    }
}
" >> "${BALANCER_NGINX_PROJ_CONF_FILE}"
}

# Generate certificates and create nginx server blocks
for service in "${!services[@]}"; do
    full_domain="${service}.${BALANCER_DOMAIN}"
    generate_certificate "${full_domain}"
    create_nginx_server_block "${service}"
done

echo "All certificates and Nginx server blocks have been generated successfully!"

nginx -g "daemon off;"
