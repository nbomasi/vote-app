#!/bin/bash
set -e

echo "=== Instance Initialization (Golden AMI) ==="
echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
echo "Launch Time: $(date)"

# Verify Golden AMI components are present
echo "Verifying Golden AMI components..."

if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js not found in Golden AMI!"
    exit 1
fi

if ! command -v codedeploy-agent &> /dev/null; then
    echo "ERROR: CodeDeploy Agent not found in Golden AMI!"
    exit 1
fi

echo "✓ Node.js: $(node --version)"
echo "✓ npm: $(npm --version)"
echo "✓ CodeDeploy Agent: Found"

# Ensure CodeDeploy Agent is running
echo "Starting CodeDeploy Agent..."
sudo service codedeploy-agent start || true

# Verify CodeDeploy Agent status
sleep 2
AGENT_STATUS=$(sudo service codedeploy-agent status | grep -o 'active\|inactive' || echo 'unknown')
echo "CodeDeploy Agent status: $AGENT_STATUS"

if [ "$AGENT_STATUS" != "active" ]; then
    echo "WARNING: CodeDeploy Agent is not active. Attempting to start..."
    sudo service codedeploy-agent restart
    sleep 3
fi

# Ensure application directory exists and has correct permissions
sudo mkdir -p /var/www/app
sudo chown ubuntu:ubuntu /var/www/app

# Instance-specific configuration (if needed)
# Example: Set instance tags, configure logging, etc.

echo "=== Instance ready for CodeDeploy ==="
echo "CodeDeploy will automatically deploy application when instance registers"
