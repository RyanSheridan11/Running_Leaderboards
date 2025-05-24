#!/bin/bash

# Health check script for Running Leaderboard
# Can be run via cron or monitoring systems

APP_URL="http://localhost:3000"
WEBHOOK_URL="http://localhost:9000"
LOG_FILE="/var/log/running_leaderboard_health.log"

echo "$(date): Starting health check" >> $LOG_FILE

# Check main application
if curl -f -s "${APP_URL}/up" > /dev/null; then
    echo "$(date): Application is healthy" >> $LOG_FILE
    APP_STATUS="OK"
else
    echo "$(date): Application health check failed" >> $LOG_FILE
    APP_STATUS="FAIL"
fi

# Check webhook service
if curl -f -s "${WEBHOOK_URL}" > /dev/null; then
    echo "$(date): Webhook service is healthy" >> $LOG_FILE
    WEBHOOK_STATUS="OK"
else
    echo "$(date): Webhook service check failed" >> $LOG_FILE
    WEBHOOK_STATUS="FAIL"
fi

# Send notification if either service is down (uncomment and configure)
if [ "$APP_STATUS" = "FAIL" ] || [ "$WEBHOOK_STATUS" = "FAIL" ]; then
    echo "$(date): Services are down - App: $APP_STATUS, Webhook: $WEBHOOK_STATUS" >> $LOG_FILE
    
    # Example Slack notification (configure your webhook URL)
    # curl -X POST -H 'Content-type: application/json' \
    #     --data "{\"text\":\"🚨 Running Leaderboard Alert: App=$APP_STATUS, Webhook=$WEBHOOK_STATUS\"}" \
    #     YOUR_SLACK_WEBHOOK_URL
    
    # Example email notification (requires mailutils)
    # echo "Running Leaderboard services are down. App: $APP_STATUS, Webhook: $WEBHOOK_STATUS" | \
    #     mail -s "Running Leaderboard Alert" admin@yourdomain.com
fi

echo "$(date): Health check completed - App: $APP_STATUS, Webhook: $WEBHOOK_STATUS" >> $LOG_FILE
