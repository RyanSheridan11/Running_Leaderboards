#!/bin/bash

# Local Rails Production Test (without Docker)
# This script tests the Rails app in production mode locally

set -e

echo "🧪 Local Rails Production Test"
echo "=============================="

# Check if we're in the right directory
if [ ! -f "app/models/user.rb" ]; then
    echo "❌ Error: Please run this script from the running_leaderboard directory"
    exit 1
fi

# Stop any running development server
echo "🛑 Stopping development server..."
pkill -f "rails server" || true
sleep 2

# Create test production environment
echo "📝 Setting up test production environment..."
if [ ! -f "config/master.key" ]; then
    echo "Generating master key..."
    bundle exec rails credentials:edit --environment=production
fi

# Set production environment variables
export RAILS_ENV=production
export DATABASE_URL="sqlite3:storage/production_test.sqlite3"

# Install dependencies
echo "📦 Installing production dependencies..."
bundle install --without development test

# Setup database
echo "🗄️  Setting up production database..."
bundle exec rails db:create RAILS_ENV=production
bundle exec rails db:migrate RAILS_ENV=production

# Precompile assets
echo "🎨 Precompiling assets..."
bundle exec rails assets:precompile RAILS_ENV=production

# Start production server
echo "🚀 Starting Rails in production mode..."
echo "Press Ctrl+C to stop the server when done testing"
echo ""
echo "🌐 Application will be available at: http://localhost:3000"
echo ""

# Start the server
bundle exec rails server -e production -p 3000
