#!/bin/bash

source /etc/nginx/modules/generate_certificate.sh
source /etc/nginx/modules/create_nginx_server_block.sh

# Generate certificates and create nginx server blocks
for service in "${!services[@]}"; do
    # Check if the service is the placeholder for empty keys and construct full_domain accordingly
    if [[ "$service" == "_empty_key" ]]; then
        # Use only the BALANCER_DOMAIN without subdomain
        full_domain="${BALANCER_DOMAIN}"
    else
        # Construct full_domain with subdomain
        full_domain="${service}.${BALANCER_DOMAIN}"
    fi
    
    # Generate certificate and create NGINX server block using the appropriate domain
    generate_certificate "${full_domain}"
    create_nginx_server_block "${service}"
done

# echo "All certificates and Nginx server blocks have been generated successfully!"
