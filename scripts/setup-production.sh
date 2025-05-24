#!/bin/bash

# Production Server Setup Script for Running Leaderboard
# Run this script on your Proxmox/Docker server to set up the deployment environment

set -e

echo "Setting up Running Leaderboard production environment..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Configuration
DEPLOY_DIR="/opt/running_leaderboard"
REPO_URL="https://github.com/YOUR_USERNAME/running_leaderboard.git"

# Create deploy directory
echo "Creating deployment directory..."
sudo mkdir -p $DEPLOY_DIR
sudo chown $USER:$USER $DEPLOY_DIR

# Clone repository
echo "Cloning repository..."
cd $DEPLOY_DIR
git clone $REPO_URL .

# Copy environment file
echo "Setting up environment configuration..."
cp .env.production.example .env.production
echo "Please edit .env.production with your actual configuration values:"
echo "  - RAILS_MASTER_KEY"
echo "  - WEBHOOK_SECRET"
echo "  - RAILS_HOST"

# Generate Rails master key if needed
if [ ! -f config/master.key ]; then
    echo "Generating Rails master key..."
    openssl rand -hex 32 > config/master.key
    echo "Master key generated: $(cat config/master.key)"
fi

# Make deploy script executable
chmod +x deploy/deploy.sh

# Create storage directories
mkdir -p storage log

# Build initial image
echo "Building Docker image..."
docker build -t running_leaderboard:latest .

# Start services
echo "Starting services..."
export RAILS_MASTER_KEY=$(cat config/master.key)
docker-compose -f docker-compose.prod.yml up -d

echo ""
echo "Setup complete! Next steps:"
echo "1. Edit $DEPLOY_DIR/.env.production with your configuration"
echo "2. Update deploy/hooks.json with your webhook secret"
echo "3. Update deploy/deploy.sh with your GitHub repository URL"
echo "4. Configure GitHub webhook to point to http://your-server:9000/hooks/redeploy-running-leaderboard"
echo "5. Set up reverse proxy (nginx) if needed"
echo ""
echo "Your application should be running at http://localhost:3000"
echo "Webhook endpoint: http://localhost:9000/hooks/redeploy-running-leaderboard"
