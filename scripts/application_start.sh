#!/bin/bash
set -e

APP_DIR="/var/www/app"
BACKEND_DIR="$APP_DIR/backend"
PID_FILE="$APP_DIR/app.pid"
LOG_FILE="$APP_DIR/app.log"

cd "$BACKEND_DIR"

echo "Starting application..."

export NODE_ENV=production
export PORT=${PORT:-3000}
export AWS_REGION=${AWS_REGION:-us-east-1}
export DB_SECRET_NAME=${DB_SECRET_NAME:-rds-db-credentials}
export JWT_SECRET=${JWT_SECRET:-change-this-in-production}

echo "Environment variables set:"
echo "  - AWS_REGION: $AWS_REGION"
echo "  - DB_SECRET_NAME: $DB_SECRET_NAME"
echo "  - PORT: $PORT"
echo ""
echo "Note: Database credentials will be retrieved from Secrets Manager at runtime"
echo "      by the Node.js application (backend/config/database.js)"

nohup node server.js > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"

sleep 3

if ps -p $(cat "$PID_FILE") > /dev/null 2>&1; then
    echo "Application started successfully (PID: $(cat $PID_FILE))"
else
    echo "Failed to start application"
    cat "$LOG_FILE" || true
    exit 1
fi
