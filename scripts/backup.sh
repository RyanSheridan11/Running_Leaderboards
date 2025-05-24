#!/bin/bash

# Backup script for Running Leaderboard production data
# Run this script regularly to backup your application data

set -e

BACKUP_DIR="/opt/backups/running_leaderboard"
APP_DIR="/opt/running_leaderboard"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="running_leaderboard_backup_${DATE}.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

echo "Starting backup at $(date)"

# Stop the application temporarily for consistent backup
cd $APP_DIR
echo "Stopping application..."
docker-compose -f docker-compose.prod.yml stop web

# Create backup
echo "Creating backup..."
tar czf "${BACKUP_DIR}/${BACKUP_FILE}" \
    --exclude='log/*' \
    --exclude='tmp/*' \
    --exclude='.git' \
    storage/ \
    .env.production \
    config/master.key

# Restart application
echo "Restarting application..."
docker-compose -f docker-compose.prod.yml start web

# Wait for application to be healthy
echo "Waiting for application to start..."
timeout=60
counter=0
while [ $counter -lt $timeout ]; do
    if curl -f http://localhost:3000/up >/dev/null 2>&1; then
        echo "Application is healthy!"
        break
    fi
    sleep 2
    counter=$((counter + 2))
done

# Clean up old backups (keep last 7 days)
echo "Cleaning up old backups..."
find $BACKUP_DIR -name "running_leaderboard_backup_*.tar.gz" -mtime +7 -delete

# Get backup size
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)

echo "Backup completed successfully at $(date)"
echo "Backup file: ${BACKUP_FILE}"
echo "Backup size: ${BACKUP_SIZE}"

# Optional: Upload to cloud storage (uncomment and configure)
# aws s3 cp "${BACKUP_DIR}/${BACKUP_FILE}" s3://your-backup-bucket/
# rclone copy "${BACKUP_DIR}/${BACKUP_FILE}" remote:backup-folder/
