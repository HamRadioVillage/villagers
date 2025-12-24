# Villagers

Village volunteer scheduling software for hacker conference villages.

## Setup

### Prerequisites

* Ruby (see `.ruby-version`)
* PostgreSQL
* Node.js (see `.node-version`)
* Yarn

### Installation

1. Clone the repository
2. Run `bin/setup`
3. Start the server with `bin/dev`

## Configuration

### Sass Version

Sass is pinned to version `1.94.2` in `package.json` to maintain consistency. Deprecation warnings from Bootstrap's SCSS files are suppressed using the `--quiet-deps` and `--silence-deprecation` flags in the build script. This prevents noise from third-party dependency warnings while still showing warnings from our own code.

## Database Seeds

The application includes seed data for development and testing. Run `bin/rails db:seed` to populate the database with test data.

### Seed Users

**All seed users have the password: `password`**

| Email | Password | Role | Description |
|-------|----------|------|-------------|
| `admin@example.com` | `password` | Village Admin | Can manage all conferences and village settings |
| `coordinator@example.com` | `password` | Conference Lead | Conference Lead for DEF CON 32 |
| `admin1@example.com` | `password` | Conference Admin | Conference Admin for DEF CON 32 |
| `admin2@example.com` | `password` | Conference Admin | Conference Admin for DEF CON 32 |
| `volunteer1@example.com` | `password` | Volunteer | Can view conferences and sign up for shifts |
| `volunteer2@example.com` | `password` | Volunteer | Can view conferences and sign up for shifts |
| `volunteer3@example.com` | `password` | Volunteer | Can view conferences and sign up for shifts |
| `volunteer4@example.com` | `password` | Volunteer | Can view conferences and sign up for shifts |
| `volunteer5@example.com` | `password` | Volunteer | Can view conferences and sign up for shifts |

**Quick Login Reference:**
- **Village Admin**: `admin@example.com` / `password`
- **Conference Lead**: `coordinator@example.com` / `password`
- **Conference Admin**: `admin1@example.com` or `admin2@example.com` / `password`
- **Volunteer**: `volunteer1@example.com` through `volunteer5@example.com` / `password`

### Other Seed Data

- **Village**: Ham Radio Village
- **Conference**: DEF CON 32 (August 8-11, 2024, Las Vegas, NV)

## Development

* Run tests: `bin/rails test`
* Run system tests: `bin/rails test:system`
* Lint code: `bin/rubocop`

## Demo Mode

Demo mode allows running Villagers as a publicly accessible demonstration instance. When enabled, the application provides a safe, self-resetting environment for potential users to explore.

### Enabling Demo Mode

Set the following in your `.env` file:

```bash
DEMO_MODE=true
```

Optional configuration:

```bash
DEMO_BANNER_TEXT="Custom demo message"      # Custom banner text
```

### Demo Mode Features

When demo mode is enabled:

- **Email disabled**: All email sending is disabled
- **Auto-confirmation**: New accounts don't require email verification
- **Demo banner**: A warning banner displays at the top of all pages
- **Login credentials**: Demo account credentials are shown on the login page
- **Protected accounts**: Seed demo accounts cannot be deleted
- **Health endpoint**: `/health` returns JSON with demo mode status

### Enhanced Demo Seeds

When `DEMO_MODE=true`, running `bin/rails db:seed` loads enhanced demo data including:

| Data | Description |
|------|-------------|
| **3 Conferences** | DEF CON 31 (archived), DEF CON 32 (current), DEF CON 33 (future) |
| **5 Programs** | Fox Hunting, Kit Building, Antenna Building, License Exams, On-Air Operations |
| **Timeslots** | Pre-configured schedules with volunteer slots |
| **Qualifications** | Licensed Ham, Soldering Certified, VE Certified |
| **Sample Signups** | Volunteers pre-assigned to some shifts |

### Automated Daily Reset

To automatically reset the demo database daily:

1. Add to crontab (`crontab -e`):
   ```cron
   0 4 * * * /path/to/villagers/scripts/reset_demo_database.sh >> /var/log/villagers/demo_reset.log 2>&1
   ```

2. Or use the rake task directly:
   ```bash
   bin/rails demo:reset
   ```

### Demo Rake Tasks

```bash
bin/rails demo:status  # Show demo mode configuration
bin/rails demo:reset   # Drop, recreate, and reseed database
bin/rails demo:seed    # Load demo data without reset
```

For complete documentation, see [docs/demo_mode.md](docs/demo_mode.md).
