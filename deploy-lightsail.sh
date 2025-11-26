#!/bin/bash

# AWS Lightsail Container Deployment Script for Drum Kit App

echo "=== Drum Kit - AWS Lightsail Deployment ==="
echo ""

# Configuration
SERVICE_NAME="drumkit-service"
CONTAINER_NAME="drumkit-app"
REGION="us-east-1"
IMAGE_NAME="drumkit-app"
IMAGE_TAG="latest"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed."
    echo "Please install it from: https://aws.amazon.com/cli/"
    exit 1
fi

echo "✅ AWS CLI is installed"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured."
    echo "Please run: aws configure"
    exit 1
fi

echo "✅ AWS credentials configured"
echo ""

# Build Docker image
echo "📦 Building Docker image..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed"
    exit 1
fi

echo "✅ Docker image built successfully"
echo ""

# Check if Lightsail service exists
echo "🔍 Checking if Lightsail service exists..."
SERVICE_EXISTS=$(aws lightsail get-container-services --service-name ${SERVICE_NAME} --region ${REGION} 2>/dev/null)

if [ -z "$SERVICE_EXISTS" ]; then
    echo "📝 Creating new Lightsail container service..."
    echo "Service: ${SERVICE_NAME}"
    echo "Power: nano (512 MB RAM, 0.25 vCPU)"
    echo "Scale: 1"
    echo ""
    
    aws lightsail create-container-service \
        --service-name ${SERVICE_NAME} \
        --power nano \
        --scale 1 \
        --region ${REGION}
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to create Lightsail service"
        exit 1
    fi
    
    echo "⏳ Waiting for service to be ready (this may take 2-3 minutes)..."
    sleep 30
else
    echo "✅ Lightsail service already exists"
fi

echo ""
echo "🚀 Pushing container image to Lightsail..."

aws lightsail push-container-image \
    --service-name ${SERVICE_NAME} \
    --label ${CONTAINER_NAME} \
    --image ${IMAGE_NAME}:${IMAGE_TAG} \
    --region ${REGION}

if [ $? -ne 0 ]; then
    echo "❌ Failed to push image to Lightsail"
    exit 1
fi

echo "✅ Image pushed successfully"
echo ""

# Get the image tag from Lightsail
echo "📋 Getting container image reference..."
IMAGE_REFERENCE=$(aws lightsail get-container-images --service-name ${SERVICE_NAME} --region ${REGION} | grep -o "${SERVICE_NAME}.${CONTAINER_NAME}.[0-9]*" | head -1)

if [ -z "$IMAGE_REFERENCE" ]; then
    echo "⚠️  Could not automatically get image reference."
    echo "Please check AWS Lightsail console to deploy manually."
    echo "Go to: https://lightsail.aws.amazon.com/ls/webapp/home/containers"
    exit 0
fi

echo "✅ Image reference: ${IMAGE_REFERENCE}"
echo ""

# Create deployment configuration
echo "⚙️  Creating deployment configuration..."

cat > lightsail-deployment.json <<EOF
{
  "containers": {
    "${CONTAINER_NAME}": {
      "image": ":${SERVICE_NAME}.${IMAGE_REFERENCE}",
      "ports": {
        "80": "HTTP"
      }
    }
  },
  "publicEndpoint": {
    "containerName": "${CONTAINER_NAME}",
    "containerPort": 80,
    "healthCheck": {
      "path": "/"
    }
  }
}
EOF

# Deploy to Lightsail
echo "🚢 Deploying to Lightsail..."

aws lightsail create-container-service-deployment \
    --service-name ${SERVICE_NAME} \
    --region ${REGION} \
    --cli-input-json file://lightsail-deployment.json

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed"
    exit 1
fi

echo ""
echo "✅ Deployment initiated successfully!"
echo ""
echo "⏳ Deployment in progress... This may take 2-5 minutes."
echo ""
echo "🌐 To check deployment status:"
echo "   aws lightsail get-container-services --service-name ${SERVICE_NAME} --region ${REGION}"
echo ""
echo "🔗 To get your application URL:"
echo "   aws lightsail get-container-services --service-name ${SERVICE_NAME} --region ${REGION} --query 'containerServices[0].url' --output text"
echo ""
echo "📊 View in AWS Console:"
echo "   https://lightsail.aws.amazon.com/ls/webapp/${REGION}/container-services/${SERVICE_NAME}/deployments"
echo ""

# Clean up
rm -f lightsail-deployment.json

echo "✨ Deployment script completed!"
