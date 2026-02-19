# Database Migration Guide

This guide explains how to run database migrations for the application.

## Migration Files

Migrations are located in: `backend/migrations/`

Current migrations:
- `001_create_users_table.sql` - Creates users table
- `002_create_counter_table.sql` - Creates counter table

## Method 1: Node.js Migration Runner (Recommended)

### Prerequisites
- Node.js installed
- AWS credentials configured (IAM role or credentials)
- Database credentials in AWS Secrets Manager

### Run Migrations

```bash
cd /var/www/app/backend
node scripts/run-migrations.js
```

### How It Works
1. Connects to database using Secrets Manager credentials
2. Reads all `.sql` files from `migrations/` directory
3. Executes them in alphabetical order
4. Skips if tables already exist (safe to re-run)

### Environment Variables
Set these if not using defaults:
```bash
export AWS_REGION=us-east-1
export DB_SECRET_NAME=rds-db-credentials
```

## Method 2: Using psql (PostgreSQL Client)

### Prerequisites
- `psql` installed (`postgresql-client` package)
- Database credentials available

### Step 1: Retrieve Credentials from Secrets Manager

```bash
# Using AWS CLI
aws secretsmanager get-secret-value \
  --secret-id rds-db-credentials \
  --region us-east-1 \
  --query SecretString \
  --output text | jq -r '.host, .username, .password, .dbname'
```

### Step 2: Set Environment Variables

```bash
export DB_HOST="your-rds-endpoint.rds.amazonaws.com"
export DB_USER="your_username"
export DB_PASSWORD="your_password"
export DB_NAME="your_database"
```

### Step 3: Run Migrations

```bash
cd /var/www/app/backend
chmod +x scripts/run-migrations.sh
./scripts/run-migrations.sh
```

## Method 3: Manual Execution with psql

### Connect to Database

```bash
psql -h your-rds-endpoint.rds.amazonaws.com \
     -U your_username \
     -d your_database
```

### Run Individual Migration

```sql
\i backend/migrations/001_create_users_table.sql
\i backend/migrations/002_create_counter_table.sql
```

Or from command line:

```bash
psql -h your-rds-endpoint.rds.amazonaws.com \
     -U your_username \
     -d your_database \
     -f backend/migrations/001_create_users_table.sql
```

## Method 4: Automated Check (Safe for ASG)

### Automated Migration Check

The `install.sh` script now includes an automated migration check that:
- ✅ Checks if database tables exist
- ✅ Only runs migrations if tables don't exist
- ✅ Safe to run on multiple instances (idempotent)
- ✅ Skips if already migrated

**How it works:**
1. Checks if `users` table exists
2. If not found, runs migrations
3. If found, skips (database already migrated)

**Command used:**
```bash
node scripts/check-and-run-migrations.js
```

**Note**: This is safe for ASG because:
- Migrations are idempotent (safe to re-run)
- Only runs if tables don't exist
- Multiple instances won't conflict (first one migrates, others skip)

### Option B: Separate Migration Step

Create a separate CodeDeploy hook or manual process for migrations.

## When to Run Migrations

### Initial Setup
Run migrations once when setting up the database for the first time.

### New Migrations
Run new migration files when:
- Adding new tables
- Modifying schema
- Adding indexes
- Database structure changes

### Best Practices

1. ✅ **Run migrations manually** for production (more control)
2. ✅ **Test migrations** in staging first
3. ✅ **Backup database** before running migrations
4. ✅ **Run during maintenance window** for production
5. ✅ **Verify migrations** after running
6. ❌ **Don't auto-run** in production deployments

## Verification

### Check Tables Exist

```sql
-- Connect to database
psql -h your-rds-endpoint.rds.amazonaws.com -U your_username -d your_database

-- List tables
\dt

-- Check users table
SELECT * FROM users LIMIT 1;

-- Check counter table
SELECT * FROM counter LIMIT 1;
```

### Check from Application

```bash
curl http://localhost:3000/api/health
```

Should return:
```json
{
  "status": "ok",
  "database": "connected",
  "timestamp": "2024-01-10T12:00:00.000Z"
}
```

## Migration File Naming Convention

Use numbered prefixes for ordering:
- `001_create_users_table.sql`
- `002_create_counter_table.sql`
- `003_add_user_profile_table.sql`
- `004_add_indexes.sql`

The migration runner executes them in alphabetical order.

## Troubleshooting

### Error: "relation already exists"
- **Meaning**: Table already created
- **Solution**: Migration is idempotent (safe to re-run)
- **Action**: Migration runner will skip it

### Error: "permission denied"
- **Meaning**: Database user lacks permissions
- **Solution**: Grant CREATE, ALTER permissions to database user

### Error: "connection refused"
- **Meaning**: Can't connect to RDS
- **Solution**: 
  - Check security group allows connections
  - Verify RDS endpoint is correct
  - Check credentials

### Error: "Secret not found"
- **Meaning**: Secrets Manager secret doesn't exist
- **Solution**: 
  - Verify secret name: `DB_SECRET_NAME`
  - Check AWS region
  - Verify IAM permissions

## Production Workflow

### Recommended Process

1. **Create migration file** in `backend/migrations/`
2. **Test in development/staging** first
3. **Backup production database**
4. **Run migration manually** using Node.js runner
5. **Verify migration** succeeded
6. **Deploy application code** (CodeDeploy)
7. **Monitor application** for issues

### Example Production Run

```bash
# SSH into one EC2 instance
ssh ubuntu@your-ec2-instance

# Navigate to application
cd /var/www/app/backend

# Run migrations
node scripts/run-migrations.js

# Verify
psql -h your-rds-endpoint.rds.amazonaws.com \
     -U your_username \
     -d your_database \
     -c "\dt"
```

## Summary

**Recommended Method**: Node.js migration runner (`node scripts/run-migrations.js`)

**When to Run**:
- ✅ Initial database setup
- ✅ After creating new migration files
- ✅ Manually (not automatically in production)

**Best Practice**: Run migrations manually in production for better control and safety.
