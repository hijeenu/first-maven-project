#!/bin/bash
set -e

echo "=========================================="
echo "Setting up EC2 instance for Maven App"
echo "=========================================="

# Update system packages
echo "Updating system packages..."
sudo yum update -y
sudo yum install -y git curl wget

# Install Docker
echo "Installing Docker..."
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group
echo "Configuring Docker permissions..."
sudo usermod -aG docker ec2-user

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create application directory
echo "Creating application directory..."
sudo mkdir -p /home/ec2-user/first-maven-app
sudo chown ec2-user:ec2-user /home/ec2-user/first-maven-app

# Clone repository (optional)
echo "Clone your repository into /home/ec2-user/first-maven-app"
echo "Setup complete!"

echo "=========================================="
echo "Start application with:"
echo "cd /home/ec2-user/first-maven-app"
echo "docker-compose up -d"
echo "=========================================="
