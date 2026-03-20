#!/bin/bash

# Configuration
COMPOSE_FILE="docker-compose.yml"
# Replace with your actual Docker Hub username
DOCKER_USER="ranitzahak" 

echo "--- Starting Deployment ---"

# 1. Pull latest images from Docker Hub
echo "Pulling latest images..."
docker-compose -f $COMPOSE_FILE pull

# 2. Down and Remove old containers (to ensure clean state)
echo "Stopping existing containers..."
docker-compose -f $COMPOSE_FILE down --remove-orphans

# 3. Start the services in detached mode
echo "Starting services..."
docker-compose -f $COMPOSE_FILE up -d

# 4. Verification
if [ $? -eq 0 ]; then
  echo "-----------------------"
  echo "SUCCESS: Keycloak and Nginx are running!"
  echo "Admin Console: http://localhost:8080/admin"
  echo "-----------------------"
  docker-compose ps
else
  echo "-----------------------"
  echo "FAILED: Check 'docker-compose logs' for details."
  echo "-----------------------"
  exit 1
fi