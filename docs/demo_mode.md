# Demo Mode

Demo mode allows running Villagers as a publicly accessible demonstration instance. When enabled, the application provides a safe, self-resetting environment where potential users can explore all features.

## Features

When demo mode is enabled:

- **Email disabled**: All email sending is disabled
- **Auto-confirmation**: New user accounts don't require email verification
- **Demo banner**: A persistent banner displays at the top of all pages
- **Login credentials**: Demo account credentials are shown on the login page
- **Protected accounts**: Seed demo accounts cannot be deleted
- **Health endpoint**: `/health` endpoint includes demo mode status

## Configuration

### Environment Variables

Add these to your `.env` file:

```bash
# Required: Enable demo mode
DEMO_MODE=true

# Optional: Custom banner text
DEMO_BANNER_TEXT="Demo Instance - Data resets daily"
```

### Quick Start

1. Copy the environment example:
   ```bash
   cp .env.example .env
   ```

2. Enable demo mode in `.env`:
   ```bash
   DEMO_MODE=true
   ```

3. Set up the database with demo data:
   ```bash
   bin/rails db:setup
   ```

4. Start the server:
   ```bash
   bin/rails server
   ```

## Demo Accounts

The following accounts are created when demo mode is enabled:

| Role | Email | Password |
|------|-------|----------|
| Village Admin | admin@example.com | password |
| Conference Lead | coordinator@example.com | password |
| Conference Admin | admin1@example.com | password |
| Conference Admin | admin2@example.com | password |
| Volunteer | volunteer1@example.com | password |
| Volunteer | volunteer2@example.com | password |
| Volunteer | volunteer3@example.com | password |
| Volunteer | volunteer4@example.com | password |
| Volunteer | volunteer5@example.com | password |

## Rake Tasks

### Check Demo Status

```bash
bin/rails demo:status
```

Shows current demo mode configuration, last reset time, and protected accounts.

### Reset Demo Database

```bash
bin/rails demo:reset
```

Drops and recreates the database with fresh demo data. Only works when `DEMO_MODE=true`. This task also records the reset time, which the banner uses to display a countdown until the next reset.

### Seed Demo Data Only

```bash
bin/rails demo:seed
```

Loads enhanced demo data without resetting the database.

## Automated Daily Reset

### How the Reset Countdown Works

The demo banner shows a countdown until the next reset. This is based on a timestamp file (`tmp/demo_last_reset.txt`) that records when `demo:reset` last ran. The next reset is calculated as 24 hours after that time.

This means:
- The banner countdown reflects the actual cron schedule
- No configuration needed to keep the banner in sync with cron

### Setting Up Cron

To automatically reset the demo database daily:

1. Open crontab:
   ```bash
   crontab -e
   ```

2. Add the following line (example: reset at 4 AM UTC):
   ```cron
   0 4 * * * /path/to/villagers/scripts/reset_demo_database.sh >> /var/log/villagers/demo_reset.log 2>&1
   ```

3. Create the log directory:
   ```bash
   sudo mkdir -p /var/log/villagers
   sudo chown $USER:$USER /var/log/villagers
   ```

### Script Options

The reset script is located at `scripts/reset_demo_database.sh`. It:

- Verifies `DEMO_MODE=true` is set
- Drops and recreates the database
- Runs all migrations
- Seeds with demo data
- Records the reset timestamp for the banner countdown
- Logs all output with timestamps

### Troubleshooting Cron

1. **Check if cron is running**:
   ```bash
   sudo systemctl status cron
   ```

2. **View cron logs**:
   ```bash
   grep CRON /var/log/syslog
   ```

3. **Test the script manually**:
   ```bash
   ./scripts/reset_demo_database.sh
   ```

4. **Common issues**:
   - Ensure the script has execute permissions: `chmod +x scripts/reset_demo_database.sh`
   - Ensure environment variables are set in the script or `.env` file
   - Use absolute paths in crontab

## Health Check Endpoint

The `/health` endpoint returns JSON with application status:

```bash
curl http://localhost:3000/health
```

Response when demo mode is enabled (after a reset has been run):
```json
{
  "status": "ok",
  "database": true,
  "demo_mode": true,
  "next_reset": "2024-01-15T04:00:00Z",
  "time_until_reset": "12h 30m"
}
```

Response when demo mode is enabled but no reset has been run yet:
```json
{
  "status": "ok",
  "database": true,
  "demo_mode": true
}
```

Response when demo mode is disabled:
```json
{
  "status": "ok",
  "database": true,
  "demo_mode": false
}
```

## Security Considerations

Demo mode includes several safety features:

1. **Protected accounts**: Seed demo accounts (admin@example.com, etc.) cannot be deleted
2. **Email disabled**: No emails are sent, preventing spam
3. **Auto-confirmation**: Simplifies account creation for demo purposes
4. **Daily reset**: All user-created data is cleared daily

### Recommendations for Production Demo Instances

1. **Rate limiting**: Consider adding rate limiting to prevent abuse
2. **Monitoring**: Set up alerts for the `/health` endpoint
3. **Log rotation**: Configure log rotation for demo reset logs
4. **Separate database**: Use a dedicated database for the demo instance

## Files

| File | Description |
|------|-------------|
| `app/models/demo_mode.rb` | Core demo mode logic |
| `app/views/shared/_demo_banner.html.erb` | Demo mode banner partial |
| `app/views/shared/_demo_credentials.html.erb` | Login page credentials |
| `app/controllers/health_controller.rb` | Health check endpoint |
| `db/seeds/demo_seeds.rb` | Enhanced demo seed data |
| `lib/tasks/demo.rake` | Demo rake tasks |
| `scripts/reset_demo_database.sh` | Cron reset script |
| `tmp/demo_last_reset.txt` | Timestamp of last reset (auto-generated) |
