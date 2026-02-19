#!/bin/bash
set -e

echo "=== Auto Scaling Instance Initialization ==="
echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
echo "Launch Time: $(date)"

# Update system packages
sudo apt-get update -y

# Install Node.js 18 (if not already installed)
if ! command -v node &> /dev/null; then
    echo "Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "Node.js installed: $(node --version)"
else
    echo "Node.js already installed: $(node --version)"
fi

# Install CodeDeploy Agent (REQUIRED for CodeDeploy to work)
echo "Installing CodeDeploy Agent..."
if ! command -v codedeploy-agent &> /dev/null; then
    sudo apt-get install -y ruby-full wget
    cd /home/ubuntu
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
    wget https://aws-codedeploy-${REGION}.s3.${REGION}.amazonaws.com/latest/install
    chmod +x ./install
    sudo ./install auto
    sudo service codedeploy-agent start
    echo "CodeDeploy Agent installed and started"
else
    echo "CodeDeploy Agent already installed"
    sudo service codedeploy-agent start || true
fi

# Install system dependencies
echo "Installing system dependencies..."
sudo apt-get install -y curl postgresql-client > /dev/null 2>&1 || true

# Verify installations
echo "=== Installation Verification ==="
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "CodeDeploy Agent: $(sudo service codedeploy-agent status | grep -o 'active\|inactive' || echo 'checking...')"

# Create application directory structure (CodeDeploy will populate it)
sudo mkdir -p /var/www/app
sudo chown ubuntu:ubuntu /var/www/app

echo "=== Base setup complete ==="
echo "Waiting for CodeDeploy to register this instance and deploy application..."
echo "CodeDeploy will run install.sh to install npm packages (including AWS SDK)"
