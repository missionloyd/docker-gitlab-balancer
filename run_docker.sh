#!/bin/bash

echo "Loading env variables from './.env.local'"
export ENV_FILE=./.env.local

echo "killing old docker processes"
docker compose rm -fs

echo "building docker containers"
docker compose --env-file $ENV_FILE build --force-rm --no-cache && docker compose --env-file $ENV_FILE up --detach && docker compose --env-file $ENV_FILE logs --follow
