# Auto Scaling Group - Installation Persistence

## The Problem

When Auto Scaling Group (ASG) creates a new EC2 instance:
- ❌ Node.js is NOT pre-installed
- ❌ Application code is NOT present
- ❌ Dependencies are NOT installed
- ✅ Instance is just a fresh EC2 instance

## Solution: Two-Layer Approach

### Layer 1: Launch Template User Data (Base Setup)
**Runs when instance launches** - Before CodeDeploy

### Layer 2: CodeDeploy (Application Deployment)
**Runs after instance is registered** - Deploys application code

## Implementation

### 1. Launch Template User Data Script

Add this to your **EC2 Launch Template User Data**:

```bash
#!/bin/bash
set -e

echo "=== Auto Scaling Instance Initialization ==="

# Update system
sudo apt-get update -y

# Install Node.js 18
if ! command -v node &> /dev/null; then
    echo "Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install CodeDeploy Agent (required for CodeDeploy to work)
echo "Installing CodeDeploy Agent..."
sudo apt-get install -y ruby-full wget
cd /home/ubuntu
wget https://aws-codedeploy-${AWS::Region}.s3.${AWS::Region}.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent start

# Install other system dependencies
sudo apt-get install -y curl postgresql-client

# Verify installations
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"
echo "CodeDeploy Agent status: $(sudo service codedeploy-agent status | grep -o 'active\|inactive')"

# Tag instance for CodeDeploy (if needed)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo "Instance ID: $INSTANCE_ID"

echo "=== Base setup complete - CodeDeploy will handle application deployment ==="
```

### 2. CodeDeploy Deployment Group Configuration

Configure your CodeDeploy Deployment Group to:
- **Target**: Auto Scaling Group (not individual instances)
- **Trigger**: New instances in ASG automatically trigger deployment
- **Deployment Configuration**: AllAtOnce, HalfAtATime, or OneAtATime

### 3. Application Deployment (install.sh)

Your existing `install.sh` will run via CodeDeploy:

```bash
# This runs AFTER instance is registered with CodeDeploy
cd "$BACKEND_DIR"
npm install --production  # Installs AWS SDK and other dependencies
```

## Complete Flow When ASG Scales

```
1. ASG detects need for new instance
    ↓
2. Launch Template creates new EC2 instance
    ↓
3. User Data script runs (on instance launch):
   - Installs Node.js
   - Installs CodeDeploy Agent
   - Installs system dependencies
    ↓
4. Instance registers with CodeDeploy
    ↓
5. CodeDeploy detects new instance
    ↓
6. CodeDeploy triggers deployment
    ↓
7. CodeDeploy runs appspec.yml hooks:
   - BeforeInstall: application_stop.sh
   - AfterInstall: install.sh (installs npm packages)
   - ApplicationStart: application_start.sh
   - ValidateService: validate_service.sh
    ↓
8. Application is running on new instance
```

## Best Practices

### Option A: User Data + CodeDeploy (Recommended)

**Pros:**
- ✅ Base dependencies installed quickly
- ✅ Application code deployed via CodeDeploy (versioned, rollbackable)
- ✅ Consistent across all instances
- ✅ Can update application without recreating instances

**Cons:**
- ⚠️ Slight delay for CodeDeploy to register and deploy

### Option B: Custom AMI (Alternative)

**Create a custom AMI with:**
- Node.js pre-installed
- CodeDeploy Agent pre-installed
- System dependencies pre-installed

**Pros:**
- ✅ Faster instance launch
- ✅ Less to install on launch

**Cons:**
- ⚠️ AMI needs updates when Node.js version changes
- ⚠️ Application code still needs CodeDeploy

## CodeDeploy Configuration for ASG

### Deployment Group Settings

```json
{
  "ApplicationName": "your-app-name",
  "DeploymentGroupName": "your-asg-deployment-group",
  "ServiceRoleArn": "arn:aws:iam::account:role/CodeDeployRole",
  "AutoScalingGroups": [
    "your-auto-scaling-group-name"
  ],
  "DeploymentConfigName": "CodeDeployDefault.AllAtOnce",
  "DeploymentStyle": {
    "DeploymentType": "IN_PLACE",
    "DeploymentOption": "WITH_TRAFFIC_CONTROL"
  },
  "LoadBalancerInfo": {
    "TargetGroupInfoList": [
      {
        "Name": "your-target-group-name"
      }
    ]
  }
}
```

### Auto-Deploy on New Instances

CodeDeploy can automatically deploy when:
- New instance is added to ASG
- Instance health check passes
- Instance is registered with deployment group

## Updated install.sh for ASG

Your current `install.sh` is already good, but here's an enhanced version:

```bash
#!/bin/bash
set -e

APP_DIR="/var/www/app"
BACKEND_DIR="$APP_DIR/backend"

cd "$APP_DIR"

echo "=== Application Installation (CodeDeploy) ==="
echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

# Verify Node.js is installed (should be from User Data)
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js not found. Should be installed via Launch Template User Data."
    exit 1
fi

echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"

echo "Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y curl postgresql-client > /dev/null 2>&1 || true

echo "Installing Node.js dependencies (including AWS SDK)..."
cd "$BACKEND_DIR"
npm install --production

echo "Verifying AWS SDK installation..."
if [ -d "node_modules/aws-sdk" ]; then
    echo "✓ AWS SDK installed successfully"
else
    echo "✗ ERROR: AWS SDK not found in node_modules"
    exit 1
fi

echo "Installation completed successfully"
```

## Health Checks

Ensure your ASG health checks work with CodeDeploy:

1. **ASG Health Check Type**: ELB (not EC2)
2. **Target Group Health**: Instance must pass ALB health check
3. **CodeDeploy Validation**: validate_service.sh must pass

## Summary

| Component | When Installed | Where Configured |
|-----------|---------------|-------------------|
| **Node.js** | Instance launch | Launch Template User Data |
| **CodeDeploy Agent** | Instance launch | Launch Template User Data |
| **System dependencies** | Instance launch | Launch Template User Data |
| **Application code** | After CodeDeploy registration | CodeDeploy (appspec.yml) |
| **npm packages (AWS SDK)** | After CodeDeploy registration | CodeDeploy (install.sh) |

## Key Points

1. ✅ **User Data** handles base setup (Node.js, CodeDeploy Agent)
2. ✅ **CodeDeploy** handles application deployment (code, npm packages)
3. ✅ **Every new instance** gets the same setup automatically
4. ✅ **Consistent** across all instances in ASG
5. ✅ **Version controlled** - application code comes from CodePipeline
