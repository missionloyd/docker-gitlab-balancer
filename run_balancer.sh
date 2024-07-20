#!/bin/bash

# Load environment variables from a file
ENV_FILE="./.env.local"
if [ -f "$ENV_FILE" ]; then
  echo "Loading environment variables from '$ENV_FILE'"
  export $(cat $ENV_FILE | sed 's/#.*//g' | xargs)
else
  echo "Environment file '$ENV_FILE' not found."
  exit 1
fi

# Check if the Docker network exists
NETWORK_NAME="gitlab-network"
if ! docker network ls | grep -qw $NETWORK_NAME; then
  echo "You must build the runner first!"
else
  # Create empty pre-generated file and build image
  touch $(pwd)/balancer/project.conf

  docker rm -f gitlab-balancer

  echo "Building Balancer image..."
  docker build -t gitlab-balancer ./balancer

  # Run Balancer container
  echo "Starting Balancer..."
docker run -d \
    --name gitlab-balancer \
    --network $NETWORK_NAME \
    --restart always \
    -p $BALANCER_PORT_HTTP:80 \
    -p $BALANCER_PORT_HTTPS:443 \
    -v $BALANCER_SSL_BASE_DIR:$BALANCER_NGINX_CONF_DIR \
    -v $(pwd)/balancer/project.conf:$BALANCER_NGINX_PROJ_CONF_FILE \
    -e BALANCER_PORT_HTTP=$BALANCER_PORT_HTTP \
    -e BALANCER_PORT_HTTPS=$BALANCER_PORT_HTTPS \
    -e BALANCER_CERTBOT_EMAIL=$BALANCER_CERTBOT_EMAIL \
    -e BALANCER_PORT_HTTP=$BALANCER_PORT_HTTP \
    -e BALANCER_PORT_HTTPS=$BALANCER_PORT_HTTPS \
    -e BALANCER_PORT=$BALANCER_PORT \
    -e BALANCER_DOMAIN=$BALANCER_DOMAIN \
    -e BALANCER_SSL_BASE_DIR=$BALANCER_SSL_BASE_DIR \
    -e BALANCER_NGINX_CONF_DIR=$BALANCER_NGINX_CONF_DIR \
    -e BALANCER_EMAIL_ADDRESS=$BALANCER_EMAIL_ADDRESS \
    -e BALANCER_CERT_VALIDITY_DAYS=$BALANCER_CERT_VALIDITY_DAYS \
    -e BALANCER_DH_PARAMS_BITS=$BALANCER_DH_PARAMS_BITS \
    -e BALANCER_NGINX_PROJ_CONF_FILE=$BALANCER_NGINX_PROJ_CONF_FILE \
    gitlab-balancer
fi