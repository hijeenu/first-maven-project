# EC2 Production Deployment Guide

## Pre-Deployment Checklist

- [ ] AWS EC2 instance launched (Amazon Linux 2, t3.micro or larger)
- [ ] Security group configured (port 22 for SSH, port 8080 for app)
- [ ] SSH key pair generated and saved locally
- [ ] Docker Hub account created and PAT generated
- [ ] GitHub repository created and code pushed
- [ ] All GitHub Secrets configured
- [ ] EC2 setup script prepared and tested

## Step-by-Step Deployment

### Phase 1: EC2 Instance Setup (15 minutes)

#### 1a. Launch EC2 Instance via AWS Console
```
AWS Console → EC2 → Launch Instance
├─ Name: first-maven-app
├─ AMI: Amazon Linux 2
├─ Instance Type: t3.micro (free tier eligible)
├─ Key Pair: Create or select existing
├─ Security Group: Create new or select
│  ├─ SSH (22): Your IP (for testing)
│  └─ HTTP (8080): Anywhere (0.0.0.0/0)
└─ Storage: 30 GB gp3
```

#### 1b. Configure Security Group
```bash
# Via AWS CLI
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxx \
  --protocol tcp \
  --port 22 \
  --cidr YOUR_IP/32

aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxx \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0
```

#### 1c. Test SSH Connection
```bash
# SSH into instance to verify connectivity
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# If successful, you should see a shell prompt
# Exit with: exit
```

### Phase 2: Install Docker and Dependencies (10 minutes)

#### 2a. Option 1: Run Automated Setup Script
```bash
# SSH to EC2
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# Download setup script
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/first-maven-project/main/scripts/setup-ec2.sh

# Make executable and run
chmod +x setup-ec2.sh
./setup-ec2.sh

# Verify installation
docker --version
docker-compose --version
```

#### 2b. Option 2: Manual Setup
```bash
# Update system
sudo yum update -y
sudo yum install -y git curl wget

# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (avoid sudo for docker commands)
sudo usermod -aG docker ec2-user

# Log out and back in for group changes to take effect
exit
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# Verify docker works
docker ps

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o ~/docker-compose
chmod +x ~/docker-compose
sudo mv ~/docker-compose /usr/local/bin/

# Verify
docker-compose --version

# Create app directory
mkdir -p ~/first-maven-app
cd ~/first-maven-app
```

### Phase 3: Configure GitHub Secrets (5 minutes)

#### 3a. Prepare EC2 SSH Key
```bash
# On your local machine, get private key content
cat ~/.ssh/your-key.pem

# Copy entire content (including -----BEGIN PRIVATE KEY----- and END)
```

#### 3b. Add GitHub Secrets
Navigate to: GitHub Repo → Settings → Secrets and variables → Actions

| Secret | Value |
|--------|-------|
| `DOCKER_USERNAME` | Your Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub Personal Access Token |
| `EC2_HOST` | EC2 public IP (123.45.67.89) |
| `EC2_USER` | ec2-user |
| `EC2_SSH_KEY` | Private key content (from step 3a) |
| `SLACK_WEBHOOK` | Optional Slack webhook |

### Phase 4: Manual Test Deployment (Before Automation)

#### 4a. Create docker-compose.yml on EC2
```bash
# SSH to EC2
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# Navigate to app directory
cd ~/first-maven-app

# Create docker-compose file
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  app:
    image: YOUR_DOCKER_USERNAME/first-maven-app:latest
    container_name: first-maven-app
    ports:
      - "8080:8080"
    environment:
      SPRING_PROFILES_ACTIVE: production
    restart: always
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  nginx:  # Optional: Reverse proxy
    image: nginx:latest
    container_name: nginx
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    restart: always
    depends_on:
      - app
EOF
```

#### 4b. Deploy Manually
```bash
# Login to Docker to pull private images (if needed)
docker login

# Pull and start the application
docker-compose up -d

# Check if running
docker ps

# View logs
docker logs -f first-maven-app

# Test the application
curl http://localhost:8080/api/hello
curl http://localhost:8080/actuator/health

# If successful, stop for now
docker-compose down
```

### Phase 5: Enable GitHub Actions Automation

#### 5a. Verify SSH Key Format
GitHub Actions expects SSH key in specific format:
```bash
# On your local machine, verify key format
head -1 ~/.ssh/your-key.pem

# Should output: -----BEGIN RSA PRIVATE KEY----- or -----BEGIN PRIVATE KEY-----
```

#### 5b. Test GitHub Actions Workflow
```bash
# Make a small change locally
echo "# Test" >> README.md

# Commit and push to develop branch first (won't deploy)
git add README.md
git commit -m "Test workflow"
git push origin develop

# Monitor GitHub Actions: https://github.com/YOUR_USERNAME/first-maven-project/actions
# After successful build-docker-image, merge to main to trigger deployment
```

#### 5c. Merge to Main for Deployment
```bash
# Merge develop to main
git checkout main
git merge develop
git push origin main

# GitHub Actions will now:
# 1. Build and test
# 2. Build and push Docker image
# 3. Deploy to EC2 via SSH

# Monitor deployment at: GitHub Actions tab
```

### Phase 6: Verify Production Deployment

#### 6a. Check application on EC2
```bash
# SSH to EC2
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# Check running containers
docker ps

# View logs
docker logs first-maven-app

# Test endpoints
curl http://localhost:8080/api/hello
curl http://localhost:8080/actuator/health
curl http://localhost:8080/actuator/metrics
```

#### 6b. Check from your local machine
```bash
# Test from outside EC2
curl http://YOUR_EC2_IP:8080/api/hello

# Compare timestamps with local version to verify new deployment
```

#### 6c. Verify Health Check
```bash
# SSH to EC2
docker logs first-maven-app | grep -i health

# Or manually
curl http://localhost:8080/actuator/health
```

## Production Best Practices

### 1. Use Environment Variables
```yaml
docker-compose.yml:
  environment:
    SPRING_PROFILES_ACTIVE: production
    SERVER_PORT: 8080
    JAVA_OPTS: "-Xmx512m -Xms256m"
```

### 2. Add Nginx Reverse Proxy
```nginx
upstream app {
    server app:8080;
}

server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 3. Implement Monitoring
```bash
# Add CloudWatch agent on EC2
# Monitor: CPU, Memory, Disk, Network

# Application monitoring:
- Spring Boot Actuator (/actuator)
- Custom metrics
- Structured logging
```

### 4. Setup Auto-Recovery
```yaml
docker-compose.yml:
  restart: always  # Always restart if container crashes
  
  healthcheck:     # Container health check
    test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
    interval: 30s
    timeout: 10s
    retries: 3
```

### 5. Backup and Updates
```bash
# Create snapshot of EC2 instance
# Automated backup strategy
# Rolling deployments for zero-downtime updates
```

## Troubleshooting

### Docker Image Won't Pull
```bash
# Check Docker Hub login
docker login
docker pull YOUR_USERNAME/first-maven-app:latest

# Verify image exists on Docker Hub
# Check Docker Hub credentials in GitHub Secrets
```

### SSH Connection Failed in GitHub Actions
```bash
# Verify SSH key format
# Check EC2 Security Group allows port 22
# Verify EC2_HOST is correct IP
# Test locally: ssh -i key.pem ec2-user@IP
```

### Application Won't Start
```bash
# SSH to EC2 and check logs
docker logs first-maven-app

# Check available memory
free -h

# Check disk space
df -h

# Restart container
docker restart first-maven-app
```

### Port 8080 Not Accessible
```bash
# Verify Security Group rule: 8080 is open
# Verify application is running: docker ps
# Verify on EC2: curl http://localhost:8080/api/health
# Check firewall on EC2: sudo firewall-cmd --list-all
```

## Maintenance Tasks

### Regular Updates
```bash
# Update EC2 system packages
sudo yum update -y

# Update Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o ~/docker-compose
sudo mv ~/docker-compose /usr/local/bin/docker-compose
```

### Monitor Logs
```bash
# View recent logs
docker logs --tail 50 first-maven-app

# Follow logs in real-time
docker logs -f first-maven-app

# View logs from specific time
docker logs --since 2024-01-01T10:00:00 first-maven-app
```

### Scaling
```bash
# Multiple instances (scale with load balancer)
# Add more EC2 instances
# Use AWS Auto Scaling Group
# Configure Application Load Balancer
```

## Security Best Practices

- [ ] Use IAM roles for EC2 instead of access keys
- [ ] Enable VPC Flow Logs for network monitoring
- [ ] Use Security Groups to restrict access
- [ ] Enable CloudTrail for API auditing
- [ ] Use AWS Secrets Manager for sensitive data
- [ ] Enable EC2 IMDSv2 for security
- [ ] Use EBS encryption for data at rest
- [ ] Implement VPN for private deployments

## Disaster Recovery

### Backup Strategy
```bash
# Automated AMI snapshots
# Database backups (if applicable)
# Configuration backups
# SSH key backups in secure location
```

### Recovery Procedure
```bash
# Launch new instance from backup AMI
# Restore from Docker image in Docker Hub
# Verify health checks pass
# Update load balancer/DNS
```

---

**Complete! Your application is now in production on EC2 with full CI/CD automation.**
