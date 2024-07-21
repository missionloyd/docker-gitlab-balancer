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
docker build -t gitlab-balancer ./balancer

# Run Balancer container
echo "Starting Balancer..."
docker run -d \
    --name gitlab-balancer \
    --network $NETWORK_NAME \
    --restart always \
    -p $BALANCER_PORT_HTTP:80 \
    -p $BALANCER_PORT_HTTPS:443 \
    -v $BALANCER_NGINX_SSL_BASE_DIR:$BALANCER_NGINX_CONF_DIR \
    -v $(pwd)/balancer/project.conf:$BALANCER_NGINX_PROJ_CONF_FILE \
    -v $(pwd)/services:$BALANCER_NGINX_SERVICES_DIR \
    --env-file $ENV_FILE \
    gitlab-balancer
