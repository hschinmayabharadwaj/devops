# AWS Deployment Guide for Drum Kit Application

## Option 1: AWS EC2 (Virtual Machine)

### Prerequisites
- AWS Account
- SSH key pair created in AWS EC2

### Steps:

1. **Launch an EC2 Instance:**
   - Go to AWS EC2 Console
   - Click "Launch Instance"
   - Choose Amazon Linux 2023 or Ubuntu Server
   - Select instance type (t2.micro for free tier)
   - Configure security group to allow:
     - SSH (Port 22) from your IP
     - HTTP (Port 80) from anywhere (0.0.0.0/0)
     - Custom TCP (Port 8080) from anywhere (0.0.0.0/0)
   - Launch with your key pair

2. **Connect to EC2 Instance:**
   ```bash
   ssh -i your-key.pem ec2-user@your-ec2-public-ip
   ```

3. **Install Docker on EC2:**
   ```bash
   # For Amazon Linux 2023
   sudo yum update -y
   sudo yum install docker -y
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo usermod -a -G docker ec2-user
   
   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   
   # Logout and login again for group changes to take effect
   exit
   ```

4. **Deploy Your Application:**
   ```bash
   # Clone your repository
   git clone https://github.com/hschinmayabharadwaj/devops.git
   cd devops
   
   # Build and run
   docker-compose up -d
   ```

5. **Access Your Application:**
   - Navigate to: `http://your-ec2-public-ip:8080`

---

## Option 2: AWS Elastic Container Service (ECS) with Fargate

### Prerequisites
- AWS CLI installed and configured
- Docker Hub account or AWS ECR

### Steps:

1. **Push Image to Amazon ECR:**
   ```bash
   # Create ECR repository
   aws ecr create-repository --repository-name drumkit-app --region us-east-1
   
   # Authenticate Docker to ECR
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
   
   # Build and tag image
   docker build -t drumkit-app .
   docker tag drumkit-app:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/drumkit-app:latest
   
   # Push to ECR
   docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/drumkit-app:latest
   ```

2. **Create ECS Task Definition:**
   - Go to AWS ECS Console
   - Create new Task Definition (Fargate)
   - Add container with your ECR image
   - Set container port: 80
   - Allocate 0.5 vCPU and 1GB memory

3. **Create ECS Cluster:**
   - Create a new cluster with Fargate
   - Create a service using your task definition
   - Configure Application Load Balancer (ALB)
   - Set target port: 80

4. **Access Your Application:**
   - Use the ALB DNS name provided

---

## Option 3: AWS Elastic Beanstalk (Easiest)

### Prerequisites
- AWS CLI and EB CLI installed

### Steps:

1. **Install EB CLI:**
   ```bash
   pip install awsebcli
   ```

2. **Initialize Elastic Beanstalk:**
   ```bash
   eb init -p docker drumkit-app --region us-east-1
   ```

3. **Create Environment and Deploy:**
   ```bash
   eb create drumkit-env
   ```

4. **Access Application:**
   ```bash
   eb open
   ```

5. **Update Application:**
   ```bash
   eb deploy
   ```

---

## Option 4: AWS Lightsail (Simplest for Containers)

### Steps:

1. **Go to AWS Lightsail Console**
2. **Create Container Service:**
   - Choose "Containers"
   - Select nano (cheapest) or micro plan
   - Upload your container image or use public image

3. **Configure Deployment:**
   - Set container port: 80
   - Set public endpoint port: 80

4. **Deploy from local machine:**
   ```bash
   # Install Lightsail plugin
   aws lightsail push-container-image --service-name drumkit-service --label drumkit-app --image drumkit-app:latest --region us-east-1
   ```

---

## Option 5: AWS App Runner (Fully Managed)

### Steps:

1. **Push to ECR** (same as ECS steps above)

2. **Create App Runner Service:**
   - Go to AWS App Runner Console
   - Click "Create service"
   - Select "Container registry" → "Amazon ECR"
   - Choose your image
   - Set port: 80
   - Deploy

3. **Access Application:**
   - Use the App Runner URL provided

---

## Option 6: AWS Amplify Hosting (For Static Sites)

Since your application is static (HTML/CSS/JS), you can also use Amplify:

### Steps:

1. **Go to AWS Amplify Console**
2. **Connect your GitHub repository**
3. **Configure build settings:**
   ```yaml
   version: 1
   frontend:
     phases:
       build:
         commands:
           - echo "No build required for static site"
     artifacts:
       baseDirectory: /
       files:
         - '**/*'
   ```
4. **Deploy automatically on git push**

---

## Recommended Approach for Your Use Case

### For Learning/Development:
**EC2** - Most control, easy to understand, costs ~$5-10/month (t2.micro)

### For Production:
**ECS with Fargate** or **App Runner** - Scalable, managed, no server maintenance

### For Simplicity:
**Elastic Beanstalk** or **Lightsail** - Quick setup, minimal configuration

---

## Cost Considerations

- **EC2 t2.micro**: Free tier eligible (750 hours/month for 12 months)
- **Lightsail**: Starts at $7/month for containers
- **ECS Fargate**: ~$15/month for minimal resources
- **App Runner**: Pay per use, ~$5-20/month depending on traffic
- **Amplify**: Free tier available, then pay per GB served

---

## Security Best Practices

1. **Use HTTPS**: Set up SSL/TLS certificate with AWS Certificate Manager (free)
2. **Restrict SSH**: Only allow SSH from your IP address
3. **Use IAM roles**: Don't hardcode AWS credentials
4. **Enable CloudWatch**: Monitor logs and metrics
5. **Regular updates**: Keep Docker and system packages updated
