# Database Credentials Flow

## How Multiple Key-Value Pairs Are Handled

The database credentials from AWS Secrets Manager contain multiple key-value pairs in JSON format:

```json
{
  "host": "your-rds-endpoint.rds.amazonaws.com",
  "port": 5432,
  "dbname": "your_database_name",
  "username": "your_username",
  "password": "your_password"
}
```

## Current Implementation

### 1. application_start.sh (Shell Script)
**What it does:**
- Sets environment variables for AWS region and secret name
- Does NOT retrieve or parse credentials
- Just tells the Node.js app WHERE to find the secret

```bash
export AWS_REGION=${AWS_REGION:-us-east-1}
export DB_SECRET_NAME=${DB_SECRET_NAME:-rds-db-credentials}
```

### 2. database.js (Node.js Code)
**What it does:**
- Retrieves the secret from Secrets Manager at runtime
- Parses the JSON to extract individual key-value pairs
- Handles multiple keys and optional values

```javascript
// Retrieves secret
const data = await secretsManager.getSecretValue({ SecretId: secretName }).promise();

// Parses JSON (handles multiple key-value pairs)
const secret = JSON.parse(data.SecretString);

// Extracts individual values
return {
  host: secret.host,                    // Required
  port: secret.port || 5432,            // Optional, defaults to 5432
  database: secret.dbname || secret.database,  // Handles both 'dbname' and 'database' keys
  user: secret.username,                 // Required
  password: secret.password             // Required
};
```

## Flow Diagram

```
application_start.sh
    ↓
Sets environment variables:
  - AWS_REGION
  - DB_SECRET_NAME
    ↓
Starts Node.js server (server.js)
    ↓
server.js calls initializeDatabase()
    ↓
database.js calls getDatabaseCredentials()
    ↓
AWS SDK retrieves secret from Secrets Manager
    ↓
JSON.parse() extracts all key-value pairs
    ↓
Individual values extracted:
  - host
  - port (with default)
  - database/dbname (handles both)
  - username
  - password
    ↓
PostgreSQL connection pool created
```

## Key Points

1. **Shell script doesn't parse credentials** - It only sets environment variables
2. **Node.js code handles parsing** - Uses AWS SDK and JSON.parse()
3. **Multiple keys handled automatically** - JSON.parse() extracts all key-value pairs
4. **Optional values supported** - Uses defaults (port) and handles alternate keys (dbname/database)
5. **Runtime retrieval** - Credentials fetched when app starts, not at script execution time

## Supported Secret Formats

The code handles these secret formats:

### Format 1: Standard
```json
{
  "host": "endpoint.rds.amazonaws.com",
  "port": 5432,
  "database": "mydb",
  "username": "admin",
  "password": "secret"
}
```

### Format 2: Using 'dbname' instead of 'database'
```json
{
  "host": "endpoint.rds.amazonaws.com",
  "port": 5432,
  "dbname": "mydb",
  "username": "admin",
  "password": "secret"
}
```

### Format 3: Without port (defaults to 5432)
```json
{
  "host": "endpoint.rds.amazonaws.com",
  "database": "mydb",
  "username": "admin",
  "password": "secret"
}
```

## Error Handling

If credentials are missing or invalid:
- `getDatabaseCredentials()` throws an error
- `initializeDatabase()` catches and logs the error
- Server fails to start (prevents running without database)

## Security

- Credentials never stored in environment variables
- Retrieved securely from Secrets Manager at runtime
- Only the secret name is in environment variables
- IAM role on EC2 provides authentication to Secrets Manager
