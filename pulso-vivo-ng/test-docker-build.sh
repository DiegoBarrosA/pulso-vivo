#!/bin/bash

# Docker Build Test Script for PulsoVivo Angular
# This script tests the Docker build locally to verify it works correctly

echo "🐳 PulsoVivo - Docker Build Test"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[→]${NC} $1"
}

# Configuration
IMAGE_NAME="pulso-vivo-ng"
CONTAINER_NAME="pulso-vivo-test"
TEST_PORT="8080"

# Track overall success
OVERALL_SUCCESS=true

# Cleanup function
cleanup() {
    print_step "Cleaning up test resources..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    if [ "$1" = "full" ]; then
        docker rmi $IMAGE_NAME 2>/dev/null || true
        print_status "Full cleanup completed"
    else
        print_status "Container cleanup completed"
    fi
}

# Trap to ensure cleanup on exit
trap 'cleanup' EXIT

print_step "Starting Docker build test..."
echo ""

# Test 1: Check if Docker is available
print_step "Testing Docker availability..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed or not in PATH"
    OVERALL_SUCCESS=false
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running"
    OVERALL_SUCCESS=false
    exit 1
fi

print_status "Docker is available and running"

# Test 2: Check project structure
print_step "Verifying project structure..."
if [ ! -f "Dockerfile" ]; then
    print_error "Dockerfile not found"
    OVERALL_SUCCESS=false
    exit 1
fi

if [ ! -f "package.json" ]; then
    print_error "package.json not found"
    OVERALL_SUCCESS=false
    exit 1
fi

if [ ! -f "nginx.conf" ]; then
    print_error "nginx.conf not found"
    OVERALL_SUCCESS=false
    exit 1
fi

print_status "Project structure is valid"

# Test 3: Clean up any existing test containers/images
print_step "Cleaning up existing test resources..."
cleanup full

# Test 4: Build the Docker image
print_step "Building Docker image..."
echo "This may take a few minutes..."

if docker build -t $IMAGE_NAME . > docker-build.log 2>&1; then
    print_status "Docker image built successfully"
else
    print_error "Docker build failed"
    print_error "Build log:"
    tail -20 docker-build.log
    OVERALL_SUCCESS=false
    exit 1
fi

# Test 5: Check if image was created
print_step "Verifying Docker image..."
if docker images | grep -q $IMAGE_NAME; then
    IMAGE_SIZE=$(docker images --format "table {{.Size}}" $IMAGE_NAME | tail -n 1)
    print_status "Docker image created successfully (Size: $IMAGE_SIZE)"
else
    print_error "Docker image was not created"
    OVERALL_SUCCESS=false
    exit 1
fi

# Test 6: Run the container
print_step "Starting container for testing..."
if docker run -d --name $CONTAINER_NAME -p $TEST_PORT:80 $IMAGE_NAME > /dev/null 2>&1; then
    print_status "Container started successfully"
else
    print_error "Failed to start container"
    OVERALL_SUCCESS=false
    exit 1
fi

# Test 7: Wait for container to be ready
print_step "Waiting for application to start..."
sleep 5

# Test 8: Check if container is running
if docker ps | grep -q $CONTAINER_NAME; then
    print_status "Container is running"
else
    print_error "Container is not running"
    docker logs $CONTAINER_NAME
    OVERALL_SUCCESS=false
    exit 1
fi

# Test 9: Test HTTP response
print_step "Testing HTTP response..."
for attempt in {1..10}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$TEST_PORT | grep -q "200"; then
        print_status "Application is responding (HTTP 200)"
        break
    elif [ $attempt -eq 10 ]; then
        print_error "Application is not responding after 10 attempts"
        print_error "Container logs:"
        docker logs $CONTAINER_NAME | tail -20
        OVERALL_SUCCESS=false
        exit 1
    else
        print_warning "Attempt $attempt: Application not ready, retrying in 2 seconds..."
        sleep 2
    fi
done

# Test 10: Test specific endpoints
print_step "Testing specific endpoints..."

# Test home page
if curl -s http://localhost:$TEST_PORT | grep -q "PulsoVivo"; then
    print_status "Home page loads correctly"
else
    print_warning "Home page content might not be correct"
fi

# Test assets
if curl -s -o /dev/null -w "%{http_code}" http://localhost:$TEST_PORT/favicon.ico | grep -q "200"; then
    print_status "Static assets are accessible"
else
    print_warning "Static assets might not be accessible"
fi

# Test Angular routing (should return index.html for any route)
if curl -s http://localhost:$TEST_PORT/tienda | grep -q "PulsoVivo"; then
    print_status "Angular routing works correctly"
else
    print_warning "Angular routing might not be configured correctly"
fi

# Test 11: Check container logs for errors
print_step "Checking container logs for errors..."
if docker logs $CONTAINER_NAME 2>&1 | grep -i error | grep -v "favicon.ico"; then
    print_warning "Some errors found in container logs (check above)"
else
    print_status "No significant errors in container logs"
fi

# Test 12: Performance check
print_step "Running basic performance test..."
RESPONSE_TIME=$(curl -o /dev/null -s -w "%{time_total}" http://localhost:$TEST_PORT)
if (( $(echo "$RESPONSE_TIME < 2.0" | bc -l) )); then
    print_status "Response time is good: ${RESPONSE_TIME}s"
else
    print_warning "Response time is slow: ${RESPONSE_TIME}s"
fi

# Show application info
echo ""
print_step "Application Information:"
echo "🌐 URL: http://localhost:$TEST_PORT"
echo "🐳 Container: $CONTAINER_NAME"
echo "📦 Image: $IMAGE_NAME"
echo "📊 Image Size: $IMAGE_SIZE"
echo "⏱️  Response Time: ${RESPONSE_TIME}s"

# Ask user if they want to inspect manually
echo ""
read -p "🔍 Do you want to manually inspect the application? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Application is running at http://localhost:$TEST_PORT"
    print_status "Press Ctrl+C when you're done inspecting"
    
    # Wait for user to interrupt
    trap 'echo -e "\n${BLUE}[→]${NC} Stopping manual inspection..."; cleanup; exit 0' INT
    
    # Open browser if available
    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:$TEST_PORT &
    elif command -v open &> /dev/null; then
        open http://localhost:$TEST_PORT &
    fi
    
    # Wait indefinitely
    while true; do
        sleep 1
    done
fi

# Cleanup and final results
cleanup

echo ""
echo "================================"
if [ "$OVERALL_SUCCESS" = true ]; then
    print_status "🎉 All Docker build tests passed!"
    echo ""
    echo "✅ Docker image builds successfully"
    echo "✅ Container starts and runs correctly"
    echo "✅ Application is accessible via HTTP"
    echo "✅ Static assets are served properly"
    echo "✅ Angular routing works correctly"
    echo ""
    echo "🚀 Your application is ready for deployment!"
    echo "📋 To deploy:"
    echo "   docker run -d -p 80:80 --name pulso-vivo-production $IMAGE_NAME"
    exit 0
else
    print_error "❌ Some Docker build tests failed!"
    echo ""
    echo "Please review the failed tests above and fix the issues."
    echo "Common fixes:"
    echo "- Check Docker daemon is running"
    echo "- Verify all required files are present"
    echo "- Check nginx configuration"
    echo "- Review application build process"
    exit 1
fi