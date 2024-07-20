#!/bin/bash

source /etc/nginx/modules/generate_certificate.sh
source /etc/nginx/modules/create_nginx_server_block.sh

# Generate certificates and create nginx server blocks
for service in "${!services[@]}"; do
    full_domain="${service}.${BALANCER_DOMAIN}"
    generate_certificate "${full_domain}"
    create_nginx_server_block "${service}"
done

# echo "All certificates and Nginx server blocks have been generated successfully!"
