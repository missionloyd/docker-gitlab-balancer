#!/bin/bash

# Configuration variables
BALANCER_EMAIL_ADDRESS=${BALANCER_EMAIL_ADDRESS}
BALANCER_PASSWORD=${BALANCER_PASSWORD}
BALANCER_CERT_VALIDITY_DAYS=${BALANCER_CERT_VALIDITY_DAYS}
BALANCER_DH_PARAMS_BITS=${BALANCER_DH_PARAMS_BITS}
BALANCER_SSL_BASE_DIR=${BALANCER_SSL_BASE_DIR}
BALANCER_NGINX_CONF_DIR=${NGINX_CONF_DI}

# Create necessary directories
mkdir -p "${BALANCER_SSL_BASE_DIR}"
mkdir -p "${BALANCER_NGINX_CONF_DIR}"

# Define domains
declare -a domains=(
    "dev-powertwin.power-theory.io"
    "prev-powertwin.power-theory.io"
    "main-powertwin.power-theory.io"
    "dev-powertwin-db.power-theory.io"
    "prev-powertwin-db.power-theory.io"
    "main-powertwin-db.power-theory.io"
    "dev-powertwin-solver.power-theory.io"
    "prev-powertwin-solver.power-theory.io"
    "main-powertwin-solver.power-theory.io"
)

# Generate stronger DHE parameters
echo "Generating DHE parameters..."
openssl dhparam -out "${BALANCER_SSL_BASE_DIR}/dhparam.pem" ${BALANCER_DH_PARAMS_BITS}

# Initialize project.conf with static configuration
cat > "${BALANCER_NGINX_CONF_DIR}/project.conf" <<EOF
# Generated file - do not touch!
upstream dev-powertwin { server gitlab-runner:9443; }
upstream prev-powertwin { server gitlab-runner:9444; }
upstream main-powertwin { server gitlab-runner:9445; }
upstream dev-powertwin-db { server gitlab-runner:5443; }
upstream prev-powertwin-db { server gitlab-runner:5444; }
upstream main-powertwin-db { server powertwin-api:5445; }
upstream dev-powertwin-solver { server gitlab-runner:7443; }
upstream prev-powertwin-solver { server gitlab-runner:7444; }
upstream main-powertwin-solver { server gitlab-runner:7445; }

map \$http_host \$backend {
    default                                    "default-backend";
    dev-powertwin.power-theory.io:8880         dev-powertwin;
    prev-powertwin.power-theory.io:8880        prev-powertwin;
    main-powertwin.power-theory.io:8880        main-powertwin;
    dev-powertwin-db.power-theory.io:8880      dev-powertwin-db;
    prev-powertwin-db.power-theory.io:8880     prev-powertwin-db;
    main-powertwin-db.power-theory.io:8880     main-powertwin-db;
    dev-powertwin-solver.power-theory.io:8880  dev-powertwin-solver;
    prev-powertwin-solver.power-theory.io:8880 prev-powertwin-solver;
    main-powertwin-solver.power-theory.io:8880 main-powertwin-solver;
}

# HTTP Server block for redirecting to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name _;

    location / {
        return 301 https://\$host:2096\$request_uri;
    }
    
    error_log /var/log/nginx/http-error.log warn;
    access_log /var/log/nginx/http-access.log combined;
}
EOF

# Function to generate a certificate for a domain
generate_certificate() {
    local domain=$1
    local domain_dir="${BALANCER_SSL_BASE_DIR}/${domain}"
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
        -out "${domain_dir}/${domain}.crt"

    echo "Certificate generated for ${domain}"
}

# Function to create nginx server block
create_nginx_server_block() {
    local domain=$1
    local domain_dir="${BALANCER_SSL_BASE_DIR}/${domain}"
    echo "
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name ${domain};
    ssl_certificate ${domain_dir}/${domain}.crt;
    ssl_certificate_key ${domain_dir}/${domain}.key;
    include /etc/nginx/snippets/ssl-params.conf;
    location / {
        proxy_pass http://${domain%%.*};
        include /etc/nginx/snippets/proxy-params.conf;
    }
}
" >> "${BALANCER_NGINX_CONF_DIR}/project.conf"
}

# Generate certificates and nginx server blocks
for domain in "${domains[@]}"; do
    generate_certificate "${domain}"
    create_nginx_server_block "${domain}"
done

echo "All certificates and Nginx server blocks have been generated successfully!"

nginx -g "daemon off;"