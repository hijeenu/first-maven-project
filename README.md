# First Maven Application - Complete CI/CD Setup

A complete example of setting up a Maven-based Spring Boot application with full CI/CD pipeline using GitHub Actions, Docker, and EC2.

## Table of Contents
- [Project Structure](#project-structure)
- [Local Development](#local-development)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [Docker Setup](#docker-setup)
- [EC2 Deployment](#ec2-deployment)
- [GitHub Secrets Configuration](#github-secrets-configuration)

## Project Structure

```
first-maven-project/
├── .github/workflows/
│   └── ci-cd.yml                 # GitHub Actions workflow
├── scripts/
│   └── setup-ec2.sh              # EC2 setup script
├── src/
│   ├── main/
│   │   ├── java/com/example/
│   │   │   ├── Application.java
│   │   │   └── controller/
│   │   │       └── HelloController.java
│   │   └── resources/
│   │       └── application.properties
│   └── test/
│       └── java/com/example/controller/
│           └── HelloControllerTest.java
├── pom.xml                       # Maven configuration
├── Dockerfile                    # Docker image definition
├── docker-compose.yml            # Docker Compose for local dev
├── .dockerignore
├── .gitignore
└── README.md
```

## Local Development

### Prerequisites
- Java 17+
- Maven 3.9+
- Docker (optional, for container-based development)
- Docker Compose (optional)

### Build and Run with Maven

```bash
# Clone the repository
git clone <repository-url>
cd first-maven-project

# Build the project
mvn clean package

# Run the application
mvn spring-boot:run

# Run tests
mvn test
```

The application will be available at `http://localhost:8080`

### API Endpoints
- `GET /api/hello` - Returns a hello message
- `GET /api/health` - Custom health endpoint
- `GET /actuator/health` - Spring Boot health endpoint
- `GET /actuator/metrics` - Application metrics

### Example Requests
```bash
curl http://localhost:8080/api/hello
curl http://localhost:8080/api/health
curl http://localhost:8080/actuator/health
```

### Run with Docker Compose (Local)

```bash
# Build and start the container
docker-compose up --build

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

## GitHub Actions CI/CD

### Workflow Overview

The CI/CD pipeline (`ci-cd.yml`) includes three main jobs:

#### 1. **Build and Test** (Runs on all pushes and PRs)
- Checks out code
- Sets up Java 17 with Maven
- Builds the project with `mvn clean package`
- Runs unit tests
- Uploads test results as artifacts

#### 2. **Build and Push Docker Image** (Runs on main/develop pushes)
- Builds multi-stage Docker image
- Pushes to Docker Hub with two tags:
  - `<username>/first-maven-app:<commit-sha>`
  - `<username>/first-maven-app:latest`
- Uses Docker layer caching for faster builds

#### 3. **Deploy to EC2** (Runs on main branch pushes only)
- SSHs into EC2 instance
- Pulls the latest Docker image
- Stops and removes old container
- Starts new container with docker run
- Performs health check
- Sends Slack notification

## Docker Setup

### Building the Docker Image Locally

```bash
# Build the image
docker build -t first-maven-app:latest .

# Run the container
docker run -d \
  --name first-maven-app \
  -p 8080:8080 \
  first-maven-app:latest

# View logs
docker logs -f first-maven-app

# Stop the container
docker stop first-maven-app
```

### Multi-Stage Build Benefits
- **Stage 1 (Builder)**: Compiles the Maven project
- **Stage 2 (Runtime)**: Contains only the JRE and compiled JAR
- **Result**: Smaller image size (~200MB vs 600MB+)

### Dockerfile Breakdown
```dockerfile
# Builder stage uses Maven to compile
FROM maven:3.9.4-eclipse-temurin-17-alpine AS builder

# Runtime stage uses only JRE
FROM eclipse-temurin:17-jre-alpine

# Health check for container orchestration
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health
```

## EC2 Deployment

### Step 1: Launch EC2 Instance

```bash
# Launch an Amazon Linux 2 EC2 instance with:
- Instance type: t3.micro (or t2.micro for free tier)
- Security Group: Open port 8080 and 22 (SSH)
- AMI: Amazon Linux 2
```

### Step 2: Configure EC2 Instance

```bash
# SSH into your EC2 instance
ssh -i your-key.pem ec2-user@your-ec2-ip

# Download and run setup script
curl -O https://raw.githubusercontent.com/<your-repo>/main/scripts/setup-ec2.sh
chmod +x setup-ec2.sh
./setup-ec2.sh
```

**OR Manually:**

```bash
# Update packages
sudo yum update -y

# Install Docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create app directory
sudo mkdir -p /home/ec2-user/first-maven-app
sudo chown ec2-user:ec2-user /home/ec2-user/first-maven-app
```

### Step 3: Manual Deployment (Before Automation)

```bash
# SSH into EC2
ssh -i your-key.pem ec2-user@your-ec2-ip

# Navigate to app directory
cd /home/ec2-user/first-maven-app

# Pull and run Docker image
docker pull <your-docker-username>/first-maven-app:latest
docker run -d \
  --name first-maven-app \
  -p 8080:8080 \
  --restart always \
  <your-docker-username>/first-maven-app:latest

# Check application status
curl http://localhost:8080/api/health
```

### Step 4: Verify Deployment

```bash
# Check if container is running
docker ps

# View logs
docker logs first-maven-app

# Test the application
curl http://your-ec2-ip:8080/api/hello
curl http://your-ec2-ip:8080/api/health
```

### Stopping and Updating

```bash
# Stop the container
docker stop first-maven-app

# Remove the container
docker rm first-maven-app

# Pull latest image
docker pull <your-docker-username>/first-maven-app:latest

# Run again
docker run -d \
  --name first-maven-app \
  -p 8080:8080 \
  --restart always \
  <your-docker-username>/first-maven-app:latest
```

### Production Best Practices

```bash
# Use docker-compose for easier management
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  app:
    image: <your-docker-username>/first-maven-app:latest
    ports:
      - "8080:8080"
    restart: always
    environment:
      - SPRING_PROFILES_ACTIVE=production
EOF

# Run with compose
docker-compose up -d
```

## GitHub Secrets Configuration

To enable the full CI/CD pipeline, configure these GitHub Secrets:

### Go to: Repository → Settings → Secrets and variables → Actions

#### Required Secrets:

| Secret Name | Description | Example |
|---|---|---|
| `DOCKER_USERNAME` | Docker Hub username | `your-docker-username` |
| `DOCKER_PASSWORD` | Docker Hub password/token | (Create PAT on Docker Hub) |
| `EC2_HOST` | EC2 instance public IP | `54.123.45.678` |
| `EC2_USER` | EC2 SSH user | `ec2-user` |
| `EC2_SSH_KEY` | EC2 private SSH key | (Copy from .pem file) |
| `SLACK_WEBHOOK` | Slack webhook URL (optional) | `https://hooks.slack.com/services/...` |

### Docker Hub Setup
```bash
# 1. Go to Docker Hub → Account Settings → Security
# 2. Create Personal Access Token (PAT)
# 3. Copy the token and save in DOCKER_PASSWORD secret
```

### EC2 SSH Key Setup
```bash
# Get your private key content
cat ~/.ssh/your-ec2-key.pem

# Copy the entire content (including BEGIN/END) to EC2_SSH_KEY secret
```

### EC2 Security Group Setup
```bash
# To allow GitHub Actions to SSH into EC2:
1. Go to EC2 Console → Security Groups
2. Edit Inbound Rules
3. Add SSH (port 22) from GitHub Actions IP range
   - Or allow from your specific IP for testing
```

## Workflow Trigger Rules

The CI/CD pipeline is configured to trigger:

| Trigger | Jobs | Branches |
|---|---|---|
| Push or PR | build-and-test | main, develop |
| Push | build-docker-image | main, develop |
| Push | deploy-to-ec2 | main ONLY |

### Example: How to Trigger

```bash
# Create feature branch
git checkout -b feature/something
# Make changes, commit, and push
git push origin feature/something
# Create PR - build-and-test will run

# Merge to develop
git checkout develop
git merge feature/something
git push origin develop
# build-and-test and build-docker-image will run

# Merge to main
git checkout main
git merge develop
git push origin main
# ALL THREE jobs will run, including deployment to EC2
```

## Monitoring and Troubleshooting

### Check Workflow Status
```bash
# GitHub CLI
gh run list
gh run view <run-id> --log
```

### View EC2 Container Logs
```bash
# SSH to EC2 and view logs
ssh -i your-key.pem ec2-user@your-ec2-ip
docker logs -f first-maven-app
docker logs first-maven-app --tail 50
```

### Common Issues

**1. Docker Hub Push Fails**
```bash
# Check credentials
docker login
docker push <username>/first-maven-app:latest
```

**2. EC2 SSH Connection Failed**
```bash
# Verify security group allows port 22
# Verify SSH key is correct
ssh -i your-key.pem -vvv ec2-user@your-ec2-ip
```

**3. Health Check Fails**
```bash
# SSH to EC2 and test manually
curl http://localhost:8080/actuator/health
docker logs first-maven-app
```

## Learning Path

### Week 1: Local Development
- ✅ Build Maven project locally
- ✅ Run and test the application
- ✅ Build Docker image locally
- ✅ Run with Docker Compose

### Week 2: CI/CD Pipeline
- ✅ Set up GitHub Actions
- ✅ Configure Docker Hub push
- ✅ Run build-and-test workflow
- ✅ Monitor GitHub Actions runs

### Week 3: Cloud Deployment
- ✅ Launch EC2 instance
- ✅ Configure EC2 security groups
- ✅ Set up GitHub Secrets
- ✅ Deploy manually to EC2
- ✅ Verify application on EC2

### Week 4: Full Automation
- ✅ Enable automatic deployment to EC2
- ✅ Push changes to main branch
- ✅ Verify automatic deployment
- ✅ Monitor logs and health checks

## Useful Commands

```bash
# Maven
mvn clean package              # Clean build
mvn test                        # Run tests
mvn spring-boot:run            # Run locally
mvn clean install -DskipTests  # Install without tests

# Docker
docker build -t app:latest .                 # Build image
docker run -d -p 8080:8080 app:latest       # Run container
docker ps                                    # List containers
docker logs -f <container-id>               # View logs
docker exec -it <container-id> /bin/bash    # SSH into container

# Docker Compose
docker-compose up -d           # Start services
docker-compose down            # Stop services
docker-compose logs -f         # View logs

# EC2 SSH
ssh -i key.pem ec2-user@ip     # Connect to EC2
scp -i key.pem file ec2-user@ip:/path  # Copy file to EC2
```

## Resources

- [Maven Documentation](https://maven.apache.org/documentation.html)
- [Spring Boot Guide](https://spring.io/guides/gs/spring-boot/)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)

## Next Steps

1. **Push to GitHub**: Initialize a git repo and push to GitHub
2. **Set GitHub Secrets**: Configure all required secrets
3. **Test Locally**: Run `docker-compose up` to verify
4. **Launch EC2**: Create an EC2 instance
5. **Run Setup**: Execute the EC2 setup script
6. **Enable Deployment**: Push to main branch and watch it deploy!

## Support

For issues or questions:
- Check GitHub Actions logs for build/deploy errors
- Check EC2 application logs: `docker logs first-maven-app`
- Verify all GitHub Secrets are configured correctly

---

**Happy learning! 🚀**
