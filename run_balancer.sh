#!/bin/bash

# Load environment variables from a file
ENV_FILE="./.env.local"
if [ -f "$ENV_FILE" ]; then
  echo "Environment file '$ENV_FILE' found."
  # Load environment variables
  set -o allexport
  source $ENV_FILE
  set +o allexport
else
  echo "Environment file '$ENV_FILE' not found."
  exit 1
fi

# Check if the Docker network exists
if ! docker network ls | grep -qw $NETWORK_NAME; then
  echo "You must build the runner first!"
  exit 1
fi

# Create empty pre-generated file and build image
touch $(pwd)/balancer/project.conf

# Remove any existing container named gitlab-balancer
docker rm -f gitlab-balancer

echo "Building Balancer image..."
docker build --build-arg BALANCER_TIMEZONE=$BALANCER_TIMEZONE -t gitlab-balancer ./balancer

# Run Balancer container
echo "Starting Balancer..."
docker run -d \
    --name gitlab-balancer \
    --network $NETWORK_NAME \
    --restart always \
    -p $BALANCER_PORT_HTTP:80 \
    -p $BALANCER_PORT_HTTPS:443 \
    -v $BALANCER_SSL_BASE_DIR:$BALANCER_NGINX_SSL_DIR \
    -v $(pwd)/balancer/project.conf:$BALANCER_NGINX_PROJ_CONF_FILE \
    -v $(pwd)/services/$BALANCER_SERVICES_FILE_NAME:$BALANCER_NGINX_SERVICES_FILE \
    -e BALANCER_PORT_HTTP=$BALANCER_PORT_HTTP \
    -e BALANCER_PORT_HTTPS=$BALANCER_PORT_HTTPS \
    -e BALANCER_DOMAIN=$BALANCER_DOMAIN \
    -e BALANCER_SLEEP_BUFFER=$BALANCER_SLEEP_BUFFER \
    -e BALANCER_NGINX_SSL_DIR=$BALANCER_NGINX_SSL_DIR \
    -e BALANCER_NGINX_PROJ_CONF_FILE=$BALANCER_NGINX_PROJ_CONF_FILE \
    -e BALANCER_NGINX_SERVICES_FILE=$BALANCER_NGINX_SERVICES_FILE \
    -e BALANCER_CERT_COUNTRY=$BALANCER_CERT_COUNTRY \
    -e BALANCER_CERT_STATE=$BALANCER_CERT_STATE \
    -e BALANCER_CERT_LOCALITY=$BALANCER_CERT_LOCALITY \
    -e BALANCER_CERT_ORGANIZATION="$BALANCER_CERT_ORGANIZATION" \
    -e BALANCER_CERT_ORGANIZATIONAL_UNIT=$BALANCER_CERT_ORGANIZATIONAL_UNIT \
    -e BALANCER_CERT_EMAIL_ADDRESS=$BALANCER_CERT_EMAIL_ADDRESS \
    -e BALANCER_CERT_PASSWORD=$BALANCER_CERT_PASSWORD \
    -e BALANCER_CERT_VALIDITY_DAYS=$BALANCER_CERT_VALIDITY_DAYS \
    -e BALANCER_CERT_DH_PARAMS_BITS=$BALANCER_CERT_DH_PARAMS_BITS \
    gitlab-balancer

