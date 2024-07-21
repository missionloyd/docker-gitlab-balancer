#!/bin/bash

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
    openssl dhparam -out "${BALANCER_NGINX_CONF_DIR}/dhparam.pem" ${BALANCER_CERT_DH_PARAMS_BITS}
# else
#     # echo "All certificates exist, skipping DHE parameter generation."
fi
