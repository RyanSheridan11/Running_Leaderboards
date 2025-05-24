# Running Leaderboard - Production Deployment Guide

This guide will help you set up automated deployment for the Running Leaderboard application using GitHub webhooks and Docker.

## Architecture

- **Application**: Rails app running in Docker container
- **Database**: SQLite (for simplicity, can be upgraded to PostgreSQL)
- **Deployment**: Automated via GitHub webhooks
- **Reverse Proxy**: Nginx (optional but recommended)

## Prerequisites

1. **Proxmox server** with Docker and Docker Compose installed
2. **GitHub repository** for your code
3. **Domain name** or static IP (optional but recommended)

## Setup Instructions

### 1. Prepare Your Production Server

```bash
# SSH into your Proxmox server
ssh root@your-server-ip

# Install Docker (if not already installed)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create a non-root user for deployment (recommended)
useradd -m -s /bin/bash deploy
usermod -aG docker deploy
```

### 2. Clone and Setup the Application

```bash
# Switch to deploy user
su - deploy

# Run the setup script
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/running_leaderboard/main/scripts/setup-production.sh -o setup.sh
chmod +x setup.sh
./setup.sh
```

### 3. Configure Environment Variables

Edit the configuration file:

```bash
cd /opt/running_leaderboard
nano .env.production
```

Update these values:
- `RAILS_MASTER_KEY`: Use the generated key or create your own
- `WEBHOOK_SECRET`: Generate a random string for GitHub webhook security
- `RAILS_HOST`: Your domain name or IP address

### 4. Update Deployment Configuration

Edit the deployment script with your GitHub repository:

```bash
nano deploy/deploy.sh
```

Update the `REPO_URL` variable with your GitHub repository URL.

Edit the webhook configuration:

```bash
nano deploy/hooks.json
```

Update the `secret` field with your webhook secret.

### 5. Setup GitHub Webhook

1. Go to your GitHub repository
2. Navigate to **Settings** → **Webhooks**
3. Click **Add webhook**
4. Configure:
   - **Payload URL**: `http://your-server-ip:9000/hooks/redeploy-running-leaderboard`
   - **Content type**: `application/json`
   - **Secret**: Enter your webhook secret from `.env.production`
   - **Events**: Select "Just the push event"
   - **Active**: Check this box

### 6. Setup Reverse Proxy (Optional but Recommended)

Install and configure Nginx:

```bash
# Install Nginx
sudo apt update
sudo apt install nginx

# Copy the configuration
sudo cp /opt/running_leaderboard/config/nginx.conf /etc/nginx/sites-available/running-leaderboard

# Update the domain name in the config
sudo nano /etc/nginx/sites-available/running-leaderboard

# Enable the site
sudo ln -s /etc/nginx/sites-available/running-leaderboard /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default  # Remove default site

# Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx
```

### 7. SSL/HTTPS Setup (Recommended)

Use Let's Encrypt for free SSL certificates:

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate (replace with your domain)
sudo certbot --nginx -d your-domain.com

# Auto-renewal is usually set up automatically, but you can test it:
sudo certbot renew --dry-run
```

## Deployment Process

Once everything is set up:

1. **Make changes** to your Rails application locally
2. **Commit and push** to the `main` branch on GitHub
3. **GitHub automatically triggers** the webhook
4. **Your server pulls** the latest code and redeploys
5. **Application is updated** with zero downtime (during the build process)

## Monitoring and Maintenance

### Check Application Status

```bash
# Check if containers are running
docker-compose -f /opt/running_leaderboard/docker-compose.prod.yml ps

# View application logs
docker-compose -f /opt/running_leaderboard/docker-compose.prod.yml logs -f web

# View webhook logs
docker-compose -f /opt/running_leaderboard/docker-compose.prod.yml logs -f webhook
```

### Manual Deployment

If you need to deploy manually:

```bash
cd /opt/running_leaderboard
./deploy/deploy.sh
```

### Backup

```bash
# Backup database and uploaded files
sudo tar czf backup-$(date +%Y%m%d).tar.gz /opt/running_leaderboard/storage/
```

### Update Configuration

If you need to update environment variables:

```bash
# Edit configuration
nano /opt/running_leaderboard/.env.production

# Restart services
cd /opt/running_leaderboard
docker-compose -f docker-compose.prod.yml restart
```

## Troubleshooting

### Application Won't Start

```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs web

# Check if port is available
sudo netstat -tlnp | grep :3000
```

### Webhook Not Triggering

1. Check GitHub webhook delivery logs
2. Verify webhook secret matches
3. Check webhook container logs:
   ```bash
   docker-compose -f docker-compose.prod.yml logs webhook
   ```

### Database Issues

```bash
# Access Rails console
docker-compose -f docker-compose.prod.yml exec web rails console

# Run migrations manually
docker-compose -f docker-compose.prod.yml exec web rails db:migrate
```

## Security Considerations

1. **Firewall**: Only open ports 80, 443, and 9000 (webhook)
2. **User permissions**: Use non-root user for deployment
3. **Secrets**: Never commit real secrets to version control
4. **Updates**: Keep Docker and system packages updated
5. **Monitoring**: Set up log monitoring and alerts

## Scaling and Upgrades

- **Database**: Upgrade to PostgreSQL for better performance
- **Load Balancing**: Add multiple app containers
- **Monitoring**: Add Prometheus/Grafana for metrics
- **Backup**: Implement automated database backups
- **CDN**: Use CloudFlare or similar for static assets

---

For questions or issues, please check the application logs and GitHub issues.
