# AWS SDK vs AWS CLI - Understanding the Difference

## Key Distinction

**AWS SDK** (JavaScript library) ≠ **AWS CLI** (command-line tool)

## What the Application Uses

### AWS SDK (JavaScript Library)
- **What**: Node.js package (`aws-sdk`)
- **Where**: Listed in `backend/package.json`
- **How installed**: Via `npm install` (automatic)
- **Used for**: Programmatic access to AWS services from Node.js code

### AWS CLI (Command-Line Tool)
- **What**: System command-line tool (`aws` command)
- **Where**: NOT used by this application
- **How installed**: Manual installation required (not automatic)
- **Used for**: Command-line operations (not needed here)

## Installation Process

### 1. EC2 Instance Setup
- **AWS CLI**: NOT automatically installed
- **Node.js**: Installed via `install.sh` script (if not pre-installed)
- **AWS SDK**: NOT automatically installed (installed via npm)

### 2. Application Deployment (install.sh)
```bash
cd "$BACKEND_DIR"
npm install --production
```

This command:
- Reads `backend/package.json`
- Installs all dependencies including `aws-sdk`
- Creates `node_modules/` directory with AWS SDK

### 3. What Gets Installed

When `npm install --production` runs:
```json
{
  "dependencies": {
    "aws-sdk": "^2.1500.0",  // ← This gets installed
    "express": "^4.18.2",
    "pg": "^8.11.3",
    // ... other dependencies
  }
}
```

## How AWS SDK Works Without AWS CLI

### Authentication

AWS SDK automatically uses **IAM Instance Role** credentials:

1. **EC2 Instance Role**: Attached to EC2 instance
2. **IAM Permissions**: Role has Secrets Manager read permissions
3. **Automatic Credentials**: AWS SDK automatically retrieves credentials from instance metadata
4. **No Configuration Needed**: No AWS CLI, no access keys, no manual setup

### Code Example

```javascript
// backend/config/database.js
const AWS = require('aws-sdk');

// AWS SDK automatically uses IAM instance role credentials
const secretsManager = new AWS.SecretsManager({
  region: process.env.AWS_REGION || 'us-east-1'
  // No credentials needed - uses instance role automatically
});

// Works without AWS CLI or manual credential configuration
const data = await secretsManager.getSecretValue({ SecretId: secretName }).promise();
```

## Installation Flow

```
CodeDeploy runs install.sh
    ↓
install.sh runs: npm install --production
    ↓
npm reads package.json
    ↓
Downloads and installs aws-sdk from npm registry
    ↓
AWS SDK available in node_modules/
    ↓
Application can use AWS SDK
    ↓
AWS SDK uses IAM instance role (automatic)
    ↓
Can access Secrets Manager, S3, etc.
```

## Requirements

### What You Need:
✅ **IAM Instance Role** on EC2 with Secrets Manager permissions
✅ **Node.js** installed (via install.sh or pre-installed)
✅ **npm install** runs (via install.sh) to install aws-sdk

### What You DON'T Need:
❌ **AWS CLI** - Not required
❌ **Access Keys** - IAM role handles this
❌ **Manual SDK installation** - npm handles this
❌ **Credential configuration** - Automatic via IAM role

## Verification

### Check if AWS SDK is installed:
```bash
cd /var/www/app/backend
ls node_modules/aws-sdk
```

### Check if IAM role is attached:
```bash
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

### Test AWS SDK access (from Node.js):
```javascript
const AWS = require('aws-sdk');
const secretsManager = new AWS.SecretsManager({ region: 'us-east-1' });
// Should work automatically if IAM role is configured
```

## Summary

| Component | Auto-Installed? | How Installed | Needed? |
|-----------|----------------|---------------|----------|
| **AWS CLI** | ❌ No | Manual install | ❌ No |
| **AWS SDK** | ❌ No | Via `npm install` | ✅ Yes |
| **Node.js** | ❌ No | Via install.sh | ✅ Yes |
| **IAM Role** | ❌ No | Manual setup | ✅ Yes |

**Answer**: AWS SDK is NOT automatically installed. It's installed when `install.sh` runs `npm install --production`, which reads `package.json` and installs all dependencies including `aws-sdk`.
