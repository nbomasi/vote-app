# Auto Scaling Group Setup Guide

## Overview

When ASG scales and creates new instances, installations must be automated. This guide explains the two-layer approach.

## Two-Layer Installation Strategy

### Layer 1: Launch Template User Data (Base Setup)
**Purpose**: Install base dependencies that every instance needs
**Runs**: When instance launches (before CodeDeploy)
**File**: `launch-template-user-data.sh`

### Layer 2: CodeDeploy (Application Deployment)
**Purpose**: Deploy application code and npm packages
**Runs**: After instance registers with CodeDeploy
**File**: `appspec.yml` → `scripts/install.sh`

## Step-by-Step Setup

### Step 1: Choose Your Approach

### Option A: Golden AMI (Recommended for Production)

1. **Create Golden AMI**:
   - Launch an EC2 instance
   - Run `create-golden-ami.sh` script
   - Stop instance and create AMI
   - Name: `app-golden-ami-v1.0`

2. **Configure Launch Template**:
   - Use Golden AMI as base image
   - Use minimal User Data from `launch-template-user-data-minimal.sh`
   - This only verifies components and starts CodeDeploy Agent

**Benefits:**
- ✅ Faster instance launch (2-3 minutes)
- ✅ More reliable (pre-tested)
- ✅ Professional standard

### Option B: User Data Only (Alternative)

1. **Configure Launch Template**:
   - Use standard AMI (Amazon Linux 2 or Ubuntu)
   - Use full User Data from `launch-template-user-data.sh`

**What it installs:**
- ✅ Node.js 18
- ✅ CodeDeploy Agent (required!)
- ✅ System dependencies (curl, postgresql-client)
- ✅ Creates `/var/www/app` directory

**Note**: See `GOLDEN_AMI_VS_USER_DATA.md` for comparison. Golden AMI is recommended for production.

### Step 2: Configure CodeDeploy Deployment Group

1. Go to **CodeDeploy Console** → **Applications** → Your App
2. Edit **Deployment Group**
3. Set **Deployment type**: **In-place deployment**
4. Set **Environment configuration**: **Amazon EC2 Auto Scaling groups**
5. Select your Auto Scaling Group
6. Enable **Automatic deployment on new instances**

**Key Settings:**
```json
{
  "AutoScalingGroups": ["your-asg-name"],
  "DeploymentConfigName": "CodeDeployDefault.AllAtOnce",
  "AutoRollbackConfiguration": {
    "Enabled": true,
    "Events": ["DEPLOYMENT_FAILURE"]
  }
}
```

### Step 3: Verify CodeDeploy Auto-Deploy

In CodeDeploy Deployment Group settings:
- ✅ **Enable automatic deployment on new instances**: Yes
- ✅ **Deployment configuration**: AllAtOnce (or HalfAtATime for zero-downtime)

## Complete Flow When ASG Scales

```
┌─────────────────────────────────────────────────┐
│ ASG Detects Need for New Instance              │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Launch Template Creates EC2 Instance            │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ User Data Script Runs (launch-template-user-data.sh)
│   • Installs Node.js 18                         │
│   • Installs CodeDeploy Agent                    │
│   • Installs system dependencies                │
│   • Creates /var/www/app directory              │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Instance Registers with CodeDeploy              │
│ (CodeDeploy Agent running)                       │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ CodeDeploy Detects New Instance                 │
│ (Automatic deployment enabled)                   │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ CodeDeploy Triggers Deployment                  │
│ Downloads artifacts from S3                      │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ CodeDeploy Runs appspec.yml Hooks:              │
│   • BeforeInstall: application_stop.sh           │
│   • AfterInstall: install.sh                     │
│     - Installs npm packages (AWS SDK, etc.)     │
│   • ApplicationStart: application_start.sh       │
│   • ValidateService: validate_service.sh         │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Application Running on New Instance              │
│ Instance passes health checks                    │
│ ASG marks instance as healthy                   │
└─────────────────────────────────────────────────┘
```

## What Gets Installed Where

| Component | When | Where Configured | Persists? |
|-----------|------|------------------|-----------|
| **Node.js** | Instance launch | Launch Template User Data | ✅ Yes |
| **CodeDeploy Agent** | Instance launch | Launch Template User Data | ✅ Yes |
| **System deps** | Instance launch | Launch Template User Data | ✅ Yes |
| **Application code** | CodeDeploy | CodePipeline → CodeDeploy | ✅ Yes |
| **npm packages** | CodeDeploy | install.sh (via appspec.yml) | ✅ Yes |
| **AWS SDK** | CodeDeploy | install.sh → npm install | ✅ Yes |

## Testing the Setup

### Test 1: Manual Instance Launch
1. Manually launch instance from Launch Template
2. SSH into instance
3. Check: `node --version` (should show v18.x)
4. Check: `sudo service codedeploy-agent status` (should be active)
5. Wait for CodeDeploy to deploy (check CodeDeploy console)

### Test 2: ASG Scale-Out
1. Increase ASG desired capacity
2. Monitor CloudWatch → ASG activity
3. Check CodeDeploy console for new deployment
4. Verify new instance in Target Group (healthy)
5. Test application on new instance

### Test 3: Verify Installations
SSH into new instance and run:
```bash
# Check Node.js
node --version
npm --version

# Check CodeDeploy Agent
sudo service codedeploy-agent status

# Check application
cd /var/www/app/backend
ls node_modules/aws-sdk  # Should exist

# Check application running
curl http://localhost:3000/api/health
```

## Troubleshooting

### Issue: CodeDeploy not deploying to new instances

**Solution:**
1. Check CodeDeploy Agent is running: `sudo service codedeploy-agent status`
2. Check IAM role has CodeDeploy permissions
3. Verify "Automatic deployment" is enabled in Deployment Group
4. Check CodeDeploy Agent logs: `sudo tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log`

### Issue: Node.js not installed

**Solution:**
1. Check User Data script ran: `sudo cat /var/log/cloud-init-output.log`
2. Verify User Data in Launch Template
3. Check instance logs in CloudWatch

### Issue: npm packages not installing

**Solution:**
1. Check install.sh ran: Look for CodeDeploy deployment logs
2. Verify package.json exists: `ls /var/www/app/backend/package.json`
3. Check npm install output in CodeDeploy logs

## Best Practices

1. ✅ **Use Launch Template User Data** for base dependencies
2. ✅ **Use CodeDeploy** for application code (versioned, rollbackable)
3. ✅ **Enable auto-deploy** on new instances in CodeDeploy
4. ✅ **Test with manual instance** before relying on ASG
5. ✅ **Monitor CodeDeploy deployments** for failures
6. ✅ **Use health checks** (ALB + CodeDeploy validation)

## Summary

**Answer**: Installations persist to new instances through:

1. **Launch Template User Data** → Installs Node.js, CodeDeploy Agent (runs on every new instance)
2. **CodeDeploy Auto-Deploy** → Deploys application code and npm packages (runs automatically when instance registers)

Both layers work together to ensure every new instance gets the same setup automatically.
