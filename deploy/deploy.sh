#!/bin/bash

# Deployment script for Running Leaderboard
# This script is executed by the webhook when GitHub pushes to main branch

set -e

echo "Starting deployment at $(date)"

# Configuration
REPO_URL="https://github.com/YOUR_USERNAME/running_leaderboard.git"
DEPLOY_DIR="/opt/running_leaderboard"
COMPOSE_FILE="docker-compose.prod.yml"

# Create deploy directory if it doesn't exist
mkdir -p $DEPLOY_DIR

# Navigate to deploy directory
cd $DEPLOY_DIR

# If this is the first deployment, clone the repo
if [ ! -d ".git" ]; then
    echo "First deployment - cloning repository..."
    git clone $REPO_URL .
else
    echo "Pulling latest changes..."
    git fetch origin
    git reset --hard origin/main
fi

# Check if there are any changes
if git diff HEAD@{1} --quiet; then
    echo "No changes detected, skipping deployment"
    exit 0
fi

echo "Changes detected, proceeding with deployment..."

# Stop existing containers
echo "Stopping existing containers..."
docker-compose -f $COMPOSE_FILE down --remove-orphans || true

# Build new image
echo "Building new Docker image..."
docker build -t running_leaderboard:latest .

# Start services
echo "Starting services..."
docker-compose -f $COMPOSE_FILE up -d

# Wait for health check
echo "Waiting for application to be healthy..."
timeout=300
counter=0
while [ $counter -lt $timeout ]; do
    if docker-compose -f $COMPOSE_FILE exec -T web curl -f http://localhost:80/up >/dev/null 2>&1; then
        echo "Application is healthy!"
        break
    fi
    echo "Waiting for application to start... ($counter/$timeout)"
    sleep 5
    counter=$((counter + 5))
done

if [ $counter -ge $timeout ]; then
    echo "Application failed to start within $timeout seconds"
    docker-compose -f $COMPOSE_FILE logs
    exit 1
fi

# Clean up old images
echo "Cleaning up old Docker images..."
docker image prune -f

echo "Deployment completed successfully at $(date)"

# Optional: Send notification (uncomment and configure as needed)
# curl -X POST -H 'Content-type: application/json' \
#     --data '{"text":"Running Leaderboard deployed successfully!"}' \
#     YOUR_SLACK_WEBHOOK_URL
