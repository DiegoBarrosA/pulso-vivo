#!/bin/bash

# PulsoVivo - Quick Rebuild and Test Script
# This script quickly rebuilds and tests the Docker container

echo "🔧 PulsoVivo - Quick Rebuild and Test"
echo "===================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Configuration
CONTAINER_NAME="pulso-vivo-frontend"
IMAGE_NAME="pulso-vivo-ng"
PORT=4000

# Check if Podman is available
if ! command -v podman &> /dev/null; then
    print_error "Podman is not installed or not in PATH"
    exit 1
fi

# Stop and remove existing container
print_step "Stopping existing container..."
podman stop $CONTAINER_NAME 2>/dev/null || true
podman rm $CONTAINER_NAME 2>/dev/null || true

# Remove existing image
print_step "Removing existing image..."
podman rmi $IMAGE_NAME 2>/dev/null || true

# Build new image
print_step "Building new Podman image..."
podman build -t $IMAGE_NAME . \
    --build-arg API_GATEWAY_URL="https://erwqz80g2d.execute-api.us-east-1.amazonaws.com/api" \
    --build-arg AZURE_AD_REDIRECT_URI="http://localhost:$PORT"

if [ $? -ne 0 ]; then
    print_error "Podman build failed!"
    exit 1
fi

# Run container
print_step "Starting new container..."
podman run -d \
    --name $CONTAINER_NAME \
    -p $PORT:80 \
    -e API_GATEWAY_URL="https://erwqz80g2d.execute-api.us-east-1.amazonaws.com/api" \
    -e AZURE_AD_REDIRECT_URI="http://localhost:$PORT" \
    $IMAGE_NAME

if [ $? -ne 0 ]; then
    print_error "Failed to start container!"
    exit 1
fi

# Wait for container to start
print_step "Waiting for container to start..."
sleep 3

# Test health endpoint
print_step "Testing health endpoint..."
if curl -f "http://localhost:$PORT/health" >/dev/null 2>&1; then
    print_info "✅ Health check passed"
else
    print_warning "⚠️ Health check failed"
fi

# Test API proxy
print_step "Testing API proxy..."
PROXY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/api/inventory/products")
if [ "$PROXY_STATUS" = "401" ]; then
    print_info "✅ API proxy working (401 = authentication required)"
elif [ "$PROXY_STATUS" = "200" ]; then
    print_info "✅ API proxy working (200 = success)"
else
    print_warning "⚠️ API proxy returned status: $PROXY_STATUS"
fi

echo ""
print_info "🎉 Container is running!"
print_info "🌐 URL: http://localhost:$PORT"
print_info "📋 Container logs: podman logs -f $CONTAINER_NAME"
print_info "🛑 Stop container: podman stop $CONTAINER_NAME"
echo ""

# Ask if user wants to see logs
read -p "📋 View container logs? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    print_info "📋 Container logs (press Ctrl+C to exit):"
    echo "========================================"
    podman logs -f $CONTAINER_NAME
fi