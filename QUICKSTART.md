# Quick Start Guide

## 🚀 Quickstart Steps

### 1. Local Setup (5 minutes)
```bash
# Build the project
mvn clean package

# Run tests
mvn test

# Start the application
mvn spring-boot:run
```

### 2. Docker Local Development (5 minutes)
```bash
# Using Docker Compose
docker-compose up --build

# Test the app
curl http://localhost:8080/api/hello
```

### 3. GitHub Setup (10 minutes)
```bash
# Initialize git repo
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/first-maven-project
git push -u origin main
```

### 4. Configure GitHub Secrets (5 minutes)
Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:
- `DOCKER_USERNAME` = your Docker Hub username
- `DOCKER_PASSWORD` = Docker Hub Personal Access Token
- `EC2_HOST` = your EC2 IP (e.g., 54.123.45.678)
- `EC2_USER` = ec2-user
- `EC2_SSH_KEY` = contents of your EC2 .pem file
- `SLACK_WEBHOOK` = (optional) your Slack webhook URL

### 5. Setup EC2 Instance (15 minutes)
```bash
# Launch Amazon Linux 2 t3.micro instance on AWS
# SSH into it
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# Run setup script
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/first-maven-project/main/scripts/setup-ec2.sh
chmod +x setup-ec2.sh
./setup-ec2.sh
```

### 6. Test Full CI/CD (5 minutes)
```bash
# Make a change to any file
echo "# Updated" >> README.md

# Commit and push to main
git add .
git commit -m "Test change"
git push origin main

# Watch GitHub Actions run the workflow
# Visit: https://github.com/YOUR_USERNAME/first-maven-project/actions
```

## 📊 CI/CD Pipeline Flow

```
Code Push to main
    ↓
GitHub Actions Trigger
    ↓
Job 1: Build & Test (Maven)
    ↓ (if passed)
Job 2: Build & Push Docker Image
    ↓ (if on main/develop)
Job 3: Deploy to EC2
    ↓
Application Running on EC2:8080
```

## 🧪 Testing Your Setup

### Test Locally
```bash
curl http://localhost:8080/api/hello
curl http://localhost:8080/api/health
curl http://localhost:8080/actuator/health
```

### Test in Docker
```bash
docker-compose up -d
curl http://localhost:8080/api/hello
docker-compose down
```

### Test on EC2
```bash
curl http://YOUR_EC2_IP:8080/api/hello
```

## 🔧 Common Commands

### Maven
```bash
mvn clean package              # Build everything
mvn test                        # Run only tests
mvn spring-boot:run            # Run locally
```

### Docker
```bash
docker build -t first-maven-app .           # Build image
docker run -d -p 8080:8080 first-maven-app # Run container
docker-compose up -d                        # Start with compose
docker-compose logs -f                      # View logs
```

### Git
```bash
git status                   # Check status
git add .                    # Stage all changes
git commit -m "message"      # Commit changes
git push origin main         # Push to main (triggers deploy!)
git push origin develop      # Push to develop (triggers build & push image)
```

## 📋 Architecture Overview

```
┌─────────────────────────────────────────────────┐
│         Developer's Local Machine               │
│  (Maven Build, Docker Compose, Git Push)        │
└──────────────┬──────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────┐
│         GitHub Repository                       │
│  (Store Code, Track Changes, Workflows)         │
└──────────────┬──────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────┐
│         GitHub Actions                          │
│  ├─ Build & Test using Maven                    │
│  ├─ Build Docker Image                          │
│  └─ Deploy to AWS EC2                           │
└──┬──────────────────┬──────────────────────────┘
   │                  │
   ▼                  ▼
┌────────────────┐ ┌──────────────────────┐
│   Docker Hub   │ │  AWS EC2 Instance    │
│  (Store Image) │ │  (Running App)       │
│                │ │  Port 8080           │
└────────────────┘ └──────────────────────┘
```

## ⚡ Environment Variables

### Local Development
Set in `src/main/resources/application.properties`

### Docker Container
Set in GitHub Actions workflow:
```yaml
environment:
  - SPRING_PROFILES_ACTIVE=production
```

### EC2 Deployment
Application will automatically use production profile

## 🆘 Troubleshooting

### Build Fails
```bash
mvn clean install -DskipTests
mvn dependency:resolve
```

### Docker Image Won't Push
```bash
docker login
docker tag first-maven-app YOUR_USERNAME/first-maven-app
docker push YOUR_USERNAME/first-maven-app
```

### EC2 Connection Issues
```bash
# Check security group allows port 22 and 8080
# Verify SSH key permissions: chmod 400 key.pem
# Test SSH: ssh -i key.pem -vvv ec2-user@IP
```

### Application Won't Start on EC2
```bash
docker logs first-maven-app
docker exec first-maven-app ps aux
curl http://localhost:8080/actuator/health
```

## 📚 Next Steps

1. ✅ Local Development: Run `mvn clean package` and `mvn spring-boot:run`
2. ✅ Docker: Run `docker-compose up --build`
3. ✅ GitHub: Push code and watch Actions run
4. ✅ AWS: Deploy to EC2 and test the application
5. ✅ Scale: Add more endpoints, databases, or caching

---
**Start with Week 1 of the learning path in README.md!**
