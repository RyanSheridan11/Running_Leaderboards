#!/bin/bash

# Quick Production Setup for Running Leaderboard
# This script prepares a fresh server for deployment

set -e

echo "🏃‍♂️ Running Leaderboard - Quick Production Setup"
echo "================================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root (sudo)"
    exit 1
fi

# Update system
echo "📦 Updating system packages..."
if command -v apt-get &> /dev/null; then
    apt-get update && apt-get upgrade -y
    apt-get install -y curl git nginx
elif command -v yum &> /dev/null; then
    yum update -y
    yum install -y curl git nginx
fi

# Install Docker
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

# Install Docker Compose
echo "🔧 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Create deploy user
echo "👤 Setting up deploy user..."
if ! id "deploy" &>/dev/null; then
    useradd -m -s /bin/bash deploy
    usermod -aG docker deploy
    
    # Set up SSH for deploy user (optional)
    mkdir -p /home/deploy/.ssh
    chmod 700 /home/deploy/.ssh
    chown deploy:deploy /home/deploy/.ssh
fi

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Configure firewall (basic setup)
echo "🔥 Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw allow ssh
    ufw allow 80
    ufw allow 443
    ufw allow 3000  # For direct app access during setup
    ufw allow 9000  # For webhook
    ufw --force enable
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --permanent --add-port=3000/tcp
    firewall-cmd --permanent --add-port=9000/tcp
    firewall-cmd --reload
fi

echo ""
echo "✅ Server setup complete!"
echo ""
echo "Next steps:"
echo "1. Switch to deploy user: su - deploy"
echo "2. Run the deployment script:"
echo "   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/running_leaderboard/main/scripts/deploy-production.sh | bash"
echo ""
echo "Or manually:"
echo "1. git clone https://github.com/YOUR_USERNAME/running_leaderboard.git"
echo "2. cd running_leaderboard"
echo "3. ./scripts/deploy-production.sh"
