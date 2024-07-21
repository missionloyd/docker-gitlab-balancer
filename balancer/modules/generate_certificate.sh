#!/bin/bash

# Function to check if a certificate exists for a domain
certificate_exists() {
    local domain=$1
    local cert_path="${BALANCER_NGINX_SSL_DIR}/${domain}/${domain}.crt"
    [ -f "${cert_path}" ]
}

# Function to generate a certificate for a domain
generate_certificate() {
    local domain=$1
    local domain_dir="${BALANCER_NGINX_SSL_DIR}/${domain}"
    local cert_path="${domain_dir}/${domain}.crt"

    # Check if the certificate already exists
    if certificate_exists "$domain"; then
        # echo "Certificate already exists for ${domain}, skipping generation."
        return
    fi

    mkdir -p "${domain_dir}"

    # Step 1: Generate the server private key
    openssl genrsa -out "${domain_dir}/${domain}.key" 2048

    # Step 2: Generate the CSR with additional information
    openssl req -new \
        -key "${domain_dir}/${domain}.key" \
        -out "${domain_dir}/${domain}.csr" \
        -subj "/C=${BALANCER_CERT_COUNTRY}/ST=${BALANCER_CERT_STATE}/L=${BALANCER_CERT_LOCALITY}/O=${BALANCER_CERT_ORGANIZATION}/OU=${BALANCER_CERT_ORGANIZATIONAL_UNIT}/CN=${domain}/emailAddress=${BALANCER_CERT_EMAIL_ADDRESS}" \
        -addext "subjectAltName = DNS:${domain}" \
        -passout pass:${BALANCER_CERT_PASSWORD}

    # Step 3: Sign the certificate
    openssl x509 -req -days ${BALANCER_CERT_VALIDITY_DAYS} \
        -in "${domain_dir}/${domain}.csr" \
        -signkey "${domain_dir}/${domain}.key" \
        -out "${cert_path}"

    echo "Certificate generated for ${domain}"
}
