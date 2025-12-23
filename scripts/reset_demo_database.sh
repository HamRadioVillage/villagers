#!/bin/bash
#
# Demo Database Reset Script
# This script resets the demo database and is intended to be run via cron.
#
# Usage:
#   ./scripts/reset_demo_database.sh
#
# Cron example (reset daily at 4 AM UTC):
#   0 4 * * * /path/to/villagers/scripts/reset_demo_database.sh >> /var/log/villagers/demo_reset.log 2>&1
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

# Change to application directory
cd "$APP_DIR"

echo "$LOG_PREFIX Starting demo database reset..."

# Source environment file if it exists
if [ -f "$APP_DIR/.env" ]; then
    export $(grep -v '^#' "$APP_DIR/.env" | xargs)
fi

# Verify DEMO_MODE is enabled
if [ "$DEMO_MODE" != "true" ]; then
    echo "$LOG_PREFIX ERROR: DEMO_MODE is not enabled. Aborting."
    exit 1
fi

# Set Rails environment if not set
export RAILS_ENV="${RAILS_ENV:-production}"

echo "$LOG_PREFIX Environment: $RAILS_ENV"
echo "$LOG_PREFIX Application directory: $APP_DIR"

# Run the demo reset rake task
echo "$LOG_PREFIX Running demo:reset task..."
bundle exec rails demo:reset

# Restart application server (adjust command based on your deployment)
# Uncomment and modify as needed for your setup:
#
# For systemd:
# echo "$LOG_PREFIX Restarting application..."
# sudo systemctl restart villagers
#
# For Puma with pumactl:
# echo "$LOG_PREFIX Restarting Puma..."
# bundle exec pumactl -P tmp/pids/puma.pid restart
#
# For Docker:
# echo "$LOG_PREFIX Restarting container..."
# docker restart villagers

echo "$LOG_PREFIX Demo database reset completed successfully."
echo "$LOG_PREFIX Next scheduled reset: $(bundle exec rails runner 'puts DemoMode.next_reset_time')"
