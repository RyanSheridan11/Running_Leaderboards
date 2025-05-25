#!/bin/bash

# Local Production Test Script
# This script simulates production deployment locally for testing

set -e

echo "🧪 Local Production Test Environment"
echo "===================================="

# Stop any running development server
echo "🛑 Stopping development server..."
pkill -f "rails server" || true
sleep 2

# Create test environment file
echo "📝 Creating test production environment..."
if [ ! -f ".env.production.test" ]; then
    cp .env.production.example .env.production.test

    # Generate test keys
    MASTER_KEY=$(openssl rand -hex 32)
    WEBHOOK_SECRET=$(openssl rand -hex 32)

    sed -i.bak "s/RAILS_MASTER_KEY=.*/RAILS_MASTER_KEY=$MASTER_KEY/" .env.production.test
    sed -i.bak "s/WEBHOOK_SECRET=.*/WEBHOOK_SECRET=$WEBHOOK_SECRET/" .env.production.test
    sed -i.bak "s/RAILS_HOST=.*/RAILS_HOST=localhost/" .env.production.test

    rm -f .env.production.test.bak
fi

# Copy test env to production env for Docker
cp .env.production.test .env.production

echo "🐳 Building and starting production containers..."

# Clean up any existing containers
docker-compose -f docker-compose.prod.yml down 2>/dev/null || true

# Build and start
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

echo "⏳ Waiting for application to start..."
sleep 15

# Test the application
echo "🔍 Testing application..."
for i in {1..30}; do
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        echo "✅ Application is running!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Application failed to start after 30 attempts"
        docker-compose -f docker-compose.prod.yml logs
        exit 1
    fi
    echo "Attempt $i/30: Waiting for app to start..."
    sleep 2
done

# Test webhook
echo "🔗 Testing webhook server..."
if curl -f http://localhost:9000 > /dev/null 2>&1; then
    echo "✅ Webhook server is running!"
else
    echo "⚠️  Webhook server not responding (this is OK for local testing)"
fi

# Show application info
echo ""
echo "🎉 Local production test successful!"
echo ""
echo "📊 Application URLs:"
echo "  - Main app: http://localhost:3000"
echo "  - Health check: http://localhost:3000/up"
echo "  - Webhook: http://localhost:9000/hooks/deploy"
echo ""
echo "📋 Test Commands:"
echo "  - View logs: docker-compose -f docker-compose.prod.yml logs"
echo "  - Stop test: docker-compose -f docker-compose.prod.yml down"
echo "  - Restart: docker-compose -f docker-compose.prod.yml restart"
echo ""

# Open browser
if command -v open &> /dev/null; then
    echo "🌐 Opening browser..."
    open http://localhost:3000
elif command -v xdg-open &> /dev/null; then
    echo "🌐 Opening browser..."
    xdg-open http://localhost:3000
fi

echo "✨ Test environment is ready! Press Ctrl+C to stop when done testing."
