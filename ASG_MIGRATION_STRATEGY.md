# ASG Migration Strategy

## Important: Migrations Run on DATABASE, Not Each Instance

**Key Point**: Database migrations modify the **database schema**, not the application code. You run them **once on the database**, not on each EC2 instance.

## Understanding Migrations

### What Migrations Do:
- Create/modify database tables
- Add indexes
- Modify schema
- **Database-level changes** (affects all instances)

### What They DON'T Do:
- Install application code
- Configure instances
- Instance-specific setup

## The Correct Approach

### Database Architecture:
```
RDS PostgreSQL (ONE database)
    ↑
    ├── EC2 Instance 1 (connects to database)
    ├── EC2 Instance 2 (connects to database)
    └── EC2 Instance 3 (connects to database)

Migrations modify the DATABASE (once)
All EC2 instances use the same migrated database
```

## Recommended: Run Once Before ASG

### Process:

1. **Set up RDS database** (Step 12 in IMPLEMENTATION-ORDER.md)

2. **Run migrations ONCE** (before creating ASG):
   ```bash
   # From your local machine or a temporary EC2 instance
   cd app/backend
   export AWS_REGION=us-east-1
   export DB_SECRET_NAME=rds-db-credentials
   npm run migrate
   ```

3. **Verify database**:
   ```bash
   # Check tables exist
   psql -h your-rds-endpoint -U username -d database -c "\dt"
   ```

4. **Create ASG** - All instances connect to the already-migrated database

5. **Deploy application** - CodeDeploy handles application code

## Alternative: Automated Migration Check (Now Included)

I've added an **automated migration check** to `install.sh` that's safe for ASG.

### How It Works:

1. **Checks if database is migrated** (checks if `users` table exists)
2. **Only runs migrations if needed** (if tables don't exist)
3. **Safe for multiple instances** (first one migrates, others skip)
4. **Idempotent** (safe to re-run)

### What Happens:

**Scenario 1: Database Not Migrated (First Instance)**
```
Instance 1 deploys → Checks database → Tables don't exist → Runs migrations → ✓
Instance 2 deploys → Checks database → Tables exist → Skips migrations → ✓
Instance 3 deploys → Checks database → Tables exist → Skips migrations → ✓
```

**Scenario 2: Database Already Migrated**
```
All instances deploy → Check database → Tables exist → All skip migrations → ✓
```

### Implementation:

The `install.sh` script now includes:
```bash
node scripts/check-and-run-migrations.js
```

This script:
- ✅ Checks if `users` table exists
- ✅ Only runs migrations if table doesn't exist
- ✅ Safe for ASG (no race conditions)
- ✅ Idempotent (can run multiple times safely)

### Benefits:

- ✅ **Automatic** - No manual intervention needed
- ✅ **Safe** - Only runs if needed
- ✅ **ASG-friendly** - Works with multiple instances
- ✅ **Idempotent** - Safe to re-run

### When It Runs:

- During CodeDeploy `AfterInstall` hook
- On every deployment (but only migrates if needed)
- On all ASG instances (but only first one migrates)

## Comparison

| Approach | Manual Step? | ASG Safe? | Best For |
|----------|-------------|-----------|----------|
| **Manual (Before ASG)** | ✅ Yes (once) | ✅ Yes | Production (most control) |
| **Automated Check** | ❌ No | ✅ Yes | Development/Staging |
| **Always Run** | ❌ No | ⚠️ Risky | Not recommended |

## Recommendation

### For Production:
**Option 1: Manual (Recommended)**
- Run migrations once before creating ASG
- Full control, no surprises
- Professional approach

### For Development/Staging:
**Option 2: Automated Check (Now Included)**
- Automatic, no manual steps
- Safe for ASG
- Already implemented in `install.sh`

## Summary

**You have TWO options:**

1. **Manual (Before ASG)**: Run `npm run migrate` once before creating ASG instances
2. **Automated (Included)**: The `install.sh` script now automatically checks and runs migrations if needed

**The automated option is now included** - migrations will run automatically on the first instance that deploys if the database isn't migrated yet. Subsequent instances will skip migrations since tables already exist.

**No manual intervention needed** if you use the automated approach!