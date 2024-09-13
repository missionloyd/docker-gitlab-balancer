#!/bin/bash

# Function to create nginx server block
create_nginx_server_block() {
    local domain=$1
    local full_domain

    # Check if the domain is the placeholder for empty keys and construct full_domain accordingly
    if [[ "$domain" == "_empty_key" ]]; then
        # Use only the BALANCER_DOMAIN without subdomain
        full_domain="${BALANCER_DOMAIN}"
    else
        # Construct full_domain with subdomain
        full_domain="${domain}.${BALANCER_DOMAIN}"
    fi

    local domain_dir="${BALANCER_NGINX_SSL_DIR}/${full_domain}"
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
