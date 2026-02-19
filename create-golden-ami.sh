#!/bin/bash
set -e

echo "=== Creating Golden AMI Base Instance ==="
echo "This script prepares an EC2 instance for Golden AMI creation"
echo ""

# Update system
echo "Updating system packages..."
sudo apt-get update -y

# Install Node.js 18
echo "Installing Node.js 18..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "✓ Node.js installed: $(node --version)"
else
    echo "✓ Node.js already installed: $(node --version)"
fi

# Install CodeDeploy Agent
echo "Installing CodeDeploy Agent..."
if ! command -v codedeploy-agent &> /dev/null; then
    sudo apt-get install -y ruby-full wget
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
    cd /home/ubuntu
    wget https://aws-codedeploy-${REGION}.s3.${REGION}.amazonaws.com/latest/install
    chmod +x ./install
    sudo ./install auto
    sudo service codedeploy-agent start
    echo "✓ CodeDeploy Agent installed and started"
else
    echo "✓ CodeDeploy Agent already installed"
    sudo service codedeploy-agent start || true
fi

# Install system dependencies
echo "Installing system dependencies..."
sudo apt-get install -y curl postgresql-client

# Create application directory structure
echo "Creating application directory structure..."
sudo mkdir -p /var/www/app
sudo chown ubuntu:ubuntu /var/www/app

# Install AWS CLI (optional, for instance management)
echo "Installing AWS CLI v2..."
if ! command -v aws &> /dev/null; then
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    echo "✓ AWS CLI installed: $(aws --version)"
else
    echo "✓ AWS CLI already installed: $(aws --version)"
fi

# Verify installations
echo ""
echo "=== Installation Verification ==="
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "CodeDeploy Agent: $(sudo service codedeploy-agent status | grep -o 'active\|inactive' || echo 'checking...')"
echo "AWS CLI: $(aws --version 2>/dev/null || echo 'not installed')"
echo ""

# Prepare for AMI creation
echo "=== Preparing for AMI Creation ==="
echo "Cleaning up temporary files..."

# Clean package cache
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

# Clear logs (optional - be careful)
# sudo rm -rf /var/log/*.log
# sudo rm -rf /var/log/cloud-init*

# Clear temporary files
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Clear bash history
history -c
rm -f ~/.bash_history
sudo rm -f /root/.bash_history

echo ""
echo "=== Golden AMI Preparation Complete ==="
echo ""
echo "Next steps:"
echo "1. Stop this instance (do NOT terminate)"
echo "2. Go to EC2 Console → Instances"
echo "3. Select instance → Actions → Image and templates → Create image"
echo "4. Name: app-golden-ami-v1.0"
echo "5. Description: Golden AMI with Node.js 18, CodeDeploy Agent, system dependencies"
echo "6. Create image"
echo ""
echo "After AMI is created:"
echo "1. Update Launch Template to use new AMI"
echo "2. Test with one instance"
echo "3. Roll out to Auto Scaling Group"
echo ""
