#!/bin/bash

# Production Deployment Script for Running Leaderboard
# Run this script on your production server

set -e

echo "🚀 Starting Running Leaderboard Production Deployment..."

# Configuration
APP_NAME="running-leaderboard"
APP_DIR="/home/deploy/$APP_NAME"
REPO_URL="https://github.com/YOUR_GITHUB_USERNAME/running_leaderboard.git"  # Update this
WEBHOOK_PORT=9000

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as deploy user
if [ "$USER" != "deploy" ]; then
    print_error "This script should be run as the 'deploy' user"
    print_status "Switch to deploy user with: su - deploy"
    exit 1
fi

# Create application directory
print_status "Creating application directory..."
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# Clone or update repository
if [ -d ".git" ]; then
    print_status "Updating existing repository..."
    git fetch origin
    git reset --hard origin/main
else
    print_status "Cloning repository..."
    git clone "$REPO_URL" .
fi

# Create production environment file
print_status "Setting up environment configuration..."
if [ ! -f ".env.production" ]; then
    cp .env.production.example .env.production
    print_warning "Created .env.production from example. Please edit it with your production values:"
    print_warning "  - RAILS_MASTER_KEY"
    print_warning "  - RAILS_HOST"
    print_warning "  - WEBHOOK_SECRET"
    echo ""
    read -p "Press Enter to continue after editing .env.production..."
fi

# Generate Rails master key if needed
if ! grep -q "RAILS_MASTER_KEY=" .env.production || grep -q "your_master_key_here" .env.production; then
    print_status "Generating Rails master key..."
    MASTER_KEY=$(openssl rand -hex 32)
    sed -i "s/RAILS_MASTER_KEY=.*/RAILS_MASTER_KEY=$MASTER_KEY/" .env.production
fi

# Generate webhook secret if needed
if ! grep -q "WEBHOOK_SECRET=" .env.production || grep -q "your-webhook-secret-here" .env.production; then
    print_status "Generating webhook secret..."
    WEBHOOK_SECRET=$(openssl rand -hex 32)
    sed -i "s/WEBHOOK_SECRET=.*/WEBHOOK_SECRET=$WEBHOOK_SECRET/" .env.production
fi

# Build and start the application
print_status "Building and starting the application..."
docker-compose -f docker-compose.prod.yml down || true
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# Wait for application to start
print_status "Waiting for application to start..."
sleep 10

# Check if application is running
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    print_status "✅ Application is running successfully!"
else
    print_error "❌ Application failed to start. Check logs with:"
    print_error "docker-compose -f docker-compose.prod.yml logs"
    exit 1
fi

# Setup webhook server
print_status "Setting up webhook server..."
if ! command -v webhook &> /dev/null; then
    print_status "Installing webhook..."

    # Install webhook based on OS
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y webhook
    elif command -v yum &> /dev/null; then
        sudo yum install -y webhook
    else
        # Install from source
        print_status "Installing webhook from source..."
        wget https://github.com/adnanh/webhook/releases/download/2.8.1/webhook-linux-amd64.tar.gz
        tar -xzf webhook-linux-amd64.tar.gz
        sudo mv webhook-linux-amd64/webhook /usr/local/bin/
        rm -rf webhook-linux-amd64*
    fi
fi

# Start webhook server
print_status "Starting webhook server..."
nohup webhook -hooks deploy/hooks.json -verbose -port $WEBHOOK_PORT > webhook.log 2>&1 &
echo $! > webhook.pid

# Setup systemd service for webhook (optional)
if command -v systemctl &> /dev/null; then
    print_status "Creating systemd service for webhook..."
    sudo tee /etc/systemd/system/running-leaderboard-webhook.service > /dev/null <<EOF
[Unit]
Description=Running Leaderboard Webhook Server
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=$APP_DIR
ExecStart=/usr/local/bin/webhook -hooks deploy/hooks.json -verbose -port $WEBHOOK_PORT
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable running-leaderboard-webhook
    sudo systemctl start running-leaderboard-webhook
    print_status "Webhook service created and started"
fi

# Setup health check cron job
print_status "Setting up health check..."
(crontab -l 2>/dev/null; echo "*/5 * * * * $APP_DIR/scripts/health-check.sh") | crontab -

# Setup backup cron job
print_status "Setting up daily backup..."
(crontab -l 2>/dev/null; echo "0 2 * * * $APP_DIR/scripts/backup.sh") | crontab -

# Display deployment information
echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "  - Application URL: http://$(hostname -I | awk '{print $1}'):3000"
echo "  - Webhook URL: http://$(hostname -I | awk '{print $1}'):$WEBHOOK_PORT/hooks/deploy"
echo "  - Application directory: $APP_DIR"
echo "  - Logs: docker-compose -f docker-compose.prod.yml logs"
echo ""
echo "🔧 Next Steps:"
echo "  1. Configure your domain/reverse proxy (see config/nginx.conf)"
echo "  2. Set up SSL certificate"
echo "  3. Configure GitHub webhook with URL above"
echo "  4. Test the deployment by pushing to your repository"
echo ""
echo "📚 For more information, see DEPLOYMENT.md"
