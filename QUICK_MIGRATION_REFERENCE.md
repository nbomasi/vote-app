# Quick Migration Reference

## Fastest Way to Run Migrations

### On EC2 Instance (Recommended)

```bash
cd /var/www/app/backend
npm run migrate
```

Or directly:
```bash
cd /var/www/app/backend
node scripts/run-migrations.js
```

### From Local Machine

```bash
# Set environment variables
export AWS_REGION=us-east-1
export DB_SECRET_NAME=rds-db-credentials

# Run migrations
cd app/backend
node scripts/run-migrations.js
```

## What It Does

1. ✅ Connects to RDS using Secrets Manager credentials
2. ✅ Runs all SQL files in `migrations/` directory
3. ✅ Executes in order (001, 002, 003...)
4. ✅ Skips if tables already exist (safe to re-run)

## Migration Files

- `backend/migrations/001_create_users_table.sql`
- `backend/migrations/002_create_counter_table.sql`

## Verify Migrations

```bash
# Check health endpoint
curl http://localhost:3000/api/health

# Should return: {"status":"ok","database":"connected"}
```

## Common Commands

```bash
# Run migrations
npm run migrate

# Or
node scripts/run-migrations.js

# Check what will run
ls backend/migrations/
```

See `MIGRATION_GUIDE.md` for detailed instructions and troubleshooting.
