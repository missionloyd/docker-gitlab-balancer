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
  echo "Creating Docker network $NETWORK_NAME..."
  docker network create $NETWORK_NAME
else
  echo "Docker network $NETWORK_NAME already exists."
fi

docker rm -f gitlab-runner

# Run GitLab Runner container
echo "Starting GitLab Runner..."
docker run -d \
  --name gitlab-runner \
  --network $NETWORK_NAME \
  --restart always \
  -p 999:999 \
  -v /srv/gitlab-runner:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e RUNNER_CI_SERVER_URL=$RUNNER_CI_SERVER_URL \
  -e RUNNER_REGISTRATION_TOKEN=$RUNNER_REGISTRATION_TOKEN \
  gitlab/gitlab-runner:alpine
