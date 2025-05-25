#!/bin/bash

# GitHub Repository Setup Script
# This script will help you create and configure a GitHub repository

echo "🐙 GitHub Repository Setup for Running Leaderboard"
echo "================================================="

# Check if we're in the right directory
if [ ! -f "app/models/user.rb" ]; then
    echo "❌ Error: Please run this script from the running_leaderboard directory"
    exit 1
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "📦 GitHub CLI not found. Installing..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install gh
        else
            echo "❌ Please install Homebrew first: https://brew.sh"
            echo "Then run: brew install gh"
            exit 1
        fi
    else
        echo "❌ Please install GitHub CLI: https://cli.github.com"
        exit 1
    fi
fi

# Check if user is logged in to GitHub CLI
if ! gh auth status &> /dev/null; then
    echo "🔑 Please log in to GitHub CLI first:"
    echo "gh auth login"
    exit 1
fi

# Get repository name
read -p "📝 Enter repository name (default: running_leaderboard): " REPO_NAME
REPO_NAME=${REPO_NAME:-running_leaderboard}

# Get repository description
read -p "📄 Enter repository description (optional): " REPO_DESC
REPO_DESC=${REPO_DESC:-"Running time leaderboard app with Rails and automated deployment"}

# Create repository
echo "🚀 Creating GitHub repository..."
if gh repo create "$REPO_NAME" --public --description "$REPO_DESC" --source=. --remote=origin --push; then
    echo "✅ Repository created successfully!"

    # Get the repository URL
    REPO_URL=$(gh repo view --json url -q .url)
    echo "🔗 Repository URL: $REPO_URL"

    # Update deployment scripts with the correct repository URL
    GITHUB_USERNAME=$(gh api user --jq .login)
    echo "👤 GitHub Username: $GITHUB_USERNAME"

    # Update the deployment scripts
    sed -i.bak "s/YOUR_GITHUB_USERNAME/$GITHUB_USERNAME/g" scripts/deploy-production.sh scripts/server-setup.sh PRODUCTION_DEPLOY.md
    sed -i.bak "s/YOUR_USERNAME/$GITHUB_USERNAME/g" PRODUCTION_DEPLOY.md

    # Clean up backup files
    rm -f scripts/deploy-production.sh.bak scripts/server-setup.sh.bak PRODUCTION_DEPLOY.md.bak

    # Commit the updated files
    git add .
    git commit -m "Update deployment scripts with correct GitHub repository URL"
    git push origin main

    echo ""
    echo "🎉 Setup Complete!"
    echo ""
    echo "📋 Next Steps for Production Deployment:"
    echo "1. Get your production server ready"
    echo "2. Run this command on your server as root:"
    echo "   curl -fsSL https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/scripts/server-setup.sh | sudo bash"
    echo ""
    echo "3. Then switch to deploy user and run:"
    echo "   su - deploy"
    echo "   curl -fsSL https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/scripts/deploy-production.sh | bash"
    echo ""
    echo "4. Configure GitHub webhook:"
    echo "   - Go to $REPO_URL/settings/hooks"
    echo "   - Add webhook: http://your-server:9000/hooks/deploy"
    echo "   - Use webhook secret from .env.production on your server"
    echo ""
    echo "📚 Full documentation: PRODUCTION_DEPLOY.md"

else
    echo "❌ Failed to create repository. Please check your GitHub CLI setup."
    exit 1
fi
