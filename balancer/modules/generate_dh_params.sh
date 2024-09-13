#!/bin/bash

# Generate DHE parameters only if any certificate needs to be generated
need_dh_params=false
for domain in "${!services[@]}"; do
    # Check if the domain is the placeholder for empty keys and construct full_domain accordingly
    if [[ "$domain" == "_empty_key" ]]; then
        # Use only the BALANCER_DOMAIN without subdomain
        full_domain="${BALANCER_DOMAIN}"
    else
        # Construct full_domain with subdomain
        full_domain="${domain}.${BALANCER_DOMAIN}"
    fi

    # Check if the certificate for the full_domain exists
    if ! certificate_exists "$full_domain"; then
        need_dh_params=true
        break
    fi
done

# Generate DHE parameters if needed
if [ "$need_dh_params" = true ]; then
    echo "Generating DHE parameters..."
    openssl dhparam -out "${BALANCER_NGINX_SSL_DIR}/dhparam.pem" ${BALANCER_CERT_DH_PARAMS_BITS}
# else
#     # echo "All certificates exist, skipping DHE parameter generation."
fi
