#!/bin/bash

# Function to generate or renew certificates
manage_cert() {
    DOMAIN=$1
    # Check if the certificate already exists
    if [ ! -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ]; then
        # Generate certificate if it does not exist
        certbot certonly --standalone --agree-tos -m ${BALANCER_CERTBOT_EMAIL} -d $DOMAIN --non-interactive
    fi
}

# Manage certificates for each domain
# manage_cert dev-powertwin.power-theory.io
# manage_cert prev-powertwin.power-theory.io
# manage_cert main-powertwin.power-theory.io
# manage_cert dev-powertwin-db.power-theory.io
# manage_cert prev-powertwin-db.power-theory.io
# manage_cert main-powertwin-db.power-theory.io
# manage_cert dev-powertwin-solver.power-theory.io
# manage_cert prev-powertwin-solver.power-theory.io
# manage_cert main-powertwin-solver.power-theory.io

# Start nginx in the foreground
nginx -g 'daemon off;'

# Schedule a cron job or a loop to periodically renew all certificates
# while :; do
#     sleep 12h
#     certbot renew --nginx --non-interactive && nginx -s reload
# done
