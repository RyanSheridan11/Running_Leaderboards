# 🏃‍♂️ Running Leaderboard - Production Deployment

Quick deployment guide for getting the Running Leaderboard app running on your production server.

## 🚀 One-Command Deployment

### Option 1: Fresh Server Setup
If you have a fresh Ubuntu/Debian/CentOS server:

```bash
# 1. Run server setup as root
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/running_leaderboard/main/scripts/server-setup.sh | sudo bash

# 2. Switch to deploy user and run deployment
su - deploy
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/running_leaderboard/main/scripts/deploy-production.sh | bash
```

### Option 2: Manual Setup
If you prefer manual control:

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/running_leaderboard.git
cd running_leaderboard

# 2. Run the deployment script
./scripts/deploy-production.sh
```

## 📋 Prerequisites

- **Server**: Ubuntu 20.04+ / Debian 11+ / CentOS 8+ (or any Docker-compatible Linux)
- **RAM**: Minimum 1GB (2GB+ recommended)
- **Storage**: 5GB free space
- **Ports**: 80, 443, 3000, 9000 (configurable)

## 🔧 Configuration

### Environment Variables

The deployment will create a `.env.production` file with these settings:

```bash
# Rails configuration
RAILS_MASTER_KEY=auto-generated-key
RAILS_HOST=your-server-ip-or-domain

# Database (SQLite for simplicity)
DATABASE_URL=sqlite3:///rails/storage/production.sqlite3

# Webhook security
WEBHOOK_SECRET=auto-generated-secret
```

### GitHub Webhook Setup

After deployment, configure your GitHub repository webhook:

1. Go to your repository Settings → Webhooks
2. Add webhook with URL: `http://your-server:9000/hooks/deploy`
3. Set content type to `application/json`
4. Use the generated webhook secret from `.env.production`
5. Select "Push" events

## 🌐 Domain Setup (Optional)

### Nginx Configuration

The app includes a ready-to-use Nginx config:

```bash
# Copy Nginx config
sudo cp config/nginx.conf /etc/nginx/sites-available/running-leaderboard
sudo ln -s /etc/nginx/sites-available/running-leaderboard /etc/nginx/sites-enabled/

# Edit the config with your domain
sudo nano /etc/nginx/sites-available/running-leaderboard

# Test and restart Nginx
sudo nginx -t
sudo systemctl restart nginx
```

### SSL Certificate (Let's Encrypt)

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal is set up automatically
```

## 📊 Monitoring

The deployment includes:

- **Health Check**: Every 5 minutes (`/up` endpoint)
- **Daily Backups**: Database backup at 2 AM
- **Log Rotation**: Automatic log management
- **Auto Restart**: Docker containers restart on failure

### Check Application Status

```bash
# Check if app is running
curl http://localhost:3000

# View logs
docker-compose -f docker-compose.prod.yml logs

# Check webhook server
curl http://localhost:9000/hooks/deploy
```

## 🔄 Manual Updates

If you need to manually update the application:

```bash
cd /home/deploy/running-leaderboard
git pull origin main
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

## 🆘 Troubleshooting

### Application Won't Start
```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs web

# Check if database exists
ls -la storage/
```

### Webhook Not Working
```bash
# Check webhook logs
tail -f webhook.log

# Test webhook manually
curl -X POST http://localhost:9000/hooks/deploy \
  -H "Content-Type: application/json" \
  -d '{"ref":"refs/heads/main"}'
```

### Database Issues
```bash
# Reset database (CAUTION: This will delete all data)
docker-compose -f docker-compose.prod.yml exec web rails db:reset RAILS_ENV=production

# Or just run migrations
docker-compose -f docker-compose.prod.yml exec web rails db:migrate RAILS_ENV=production
```

## 📞 Support

- **Issues**: Create an issue on GitHub
- **Logs**: Always check `docker-compose logs` first
- **Updates**: Push to your main branch triggers auto-deployment

## 🔐 Security Notes

- Change default webhook secret
- Use HTTPS in production
- Regular security updates: `sudo apt update && sudo apt upgrade`
- Monitor logs for suspicious activity
- Backup your data regularly (automatic backups included)

---

**Happy Running! 🏃‍♀️🏃‍♂️**
