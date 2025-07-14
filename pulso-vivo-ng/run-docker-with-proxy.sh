#!/bin/bash

# PulsoVivo - Rebuild and Run Podman Container with API Proxy
# This script rebuilds the Podman image and runs it with proper proxy configuration

echo "🏥 PulsoVivo - Podman Build and Run with API Proxy"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_highlight() {
    echo -e "${CYAN}$1${NC}"
}

# Configuration
CONTAINER_NAME="pulso-vivo-frontend"
IMAGE_NAME="pulso-vivo-ng"
PORT=4000
API_GATEWAY_URL="https://erwqz80g2d.execute-api.us-east-1.amazonaws.com/api"
AZURE_AD_CLIENT_ID="7549ac9c-9294-4bb3-98d6-752d12b13d81"
AZURE_AD_AUTHORITY="https://PulsoVivo.b2clogin.com/PulsoVivo.onmicrosoft.com/B2C_1_pulso_vivo_register_and_login"
AZURE_AD_REDIRECT_URI="http://localhost:${PORT}"

# Check if we're in the correct directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found. Please run this script from the project root directory."
    exit 1
fi

# Check if Podman is available
if ! command -v podman &> /dev/null; then
    print_error "Podman is not installed or not in PATH."
    exit 1
fi

print_info "Podman is available ✓"

# Stop and remove existing container if it exists
print_step "Stopping and removing existing container..."
if podman ps -a | grep -q "$CONTAINER_NAME"; then
    podman stop "$CONTAINER_NAME" 2>/dev/null || true
    podman rm "$CONTAINER_NAME" 2>/dev/null || true
    print_info "Existing container removed"
else
    print_info "No existing container found"
fi

# Remove existing image if it exists
print_step "Removing existing image..."
if podman images | grep -q "$IMAGE_NAME"; then
    podman rmi "$IMAGE_NAME" 2>/dev/null || true
    print_info "Existing image removed"
else
    print_info "No existing image found"
fi

# Build the Podman image
print_step "Building Podman image with proxy configuration..."
print_highlight "This may take a few minutes..."

podman build \
    --build-arg INVENTORY_SERVICE_URL="/api" \
    --build-arg API_GATEWAY_URL="$API_GATEWAY_URL" \
    --build-arg AZURE_AD_CLIENT_ID="$AZURE_AD_CLIENT_ID" \
    --build-arg AZURE_AD_AUTHORITY="$AZURE_AD_AUTHORITY" \
    --build-arg AZURE_AD_REDIRECT_URI="$AZURE_AD_REDIRECT_URI" \
    --build-arg ENABLE_LOGGING="true" \
    -t "$IMAGE_NAME" .

if [ $? -ne 0 ]; then
    print_error "Podman build failed!"
    exit 1
fi

print_info "Podman image built successfully ✓"

# Check if port is available
print_step "Checking if port $PORT is available..."
if netstat -tulpn 2>/dev/null | grep -q ":$PORT "; then
    print_warning "Port $PORT is already in use. Attempting to find the process..."
    if command -v lsof >/dev/null 2>&1; then
        PROCESS=$(lsof -ti:$PORT)
        if [ ! -z "$PROCESS" ]; then
            print_warning "Process using port $PORT: $PROCESS"
            read -p "Do you want to kill the process and continue? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                kill -9 $PROCESS 2>/dev/null || true
                print_info "Process killed"
            else
                print_error "Cannot continue with port $PORT in use"
                exit 1
            fi
        fi
    fi
fi

# Run the Podman container
print_step "Starting Podman container..."

podman run -d \
    --name "$CONTAINER_NAME" \
    -p "$PORT:80" \
    -e INVENTORY_SERVICE_URL="/api" \
    -e API_GATEWAY_URL="$API_GATEWAY_URL" \
    -e AZURE_AD_CLIENT_ID="$AZURE_AD_CLIENT_ID" \
    -e AZURE_AD_AUTHORITY="$AZURE_AD_AUTHORITY" \
    -e AZURE_AD_REDIRECT_URI="$AZURE_AD_REDIRECT_URI" \
    -e ENABLE_LOGGING="true" \
    --restart unless-stopped \
    "$IMAGE_NAME"

if [ $? -ne 0 ]; then
    print_error "Failed to start Podman container!"
    exit 1
fi

print_info "Podman container started successfully ✓"

# Wait for container to be ready
print_step "Waiting for container to be ready..."
sleep 5

# Check if container is running
if podman ps | grep -q "$CONTAINER_NAME"; then
    print_info "Container is running ✓"
else
    print_error "Container failed to start!"
    print_error "Container logs:"
    podman logs "$CONTAINER_NAME"
    exit 1
fi

# Test the health endpoint
print_step "Testing health endpoint..."
if curl -f "http://localhost:$PORT/health" > /dev/null 2>&1; then
    print_info "Health check passed ✓"
else
    print_warning "Health check failed, but container is running"
fi

# Display configuration summary
echo ""
print_highlight "🎉 PulsoVivo is now running!"
print_highlight "================================"
echo ""
print_info "🌐 Application URL: http://localhost:$PORT"
print_info "🔗 API Proxy: /api/* → $API_GATEWAY_URL"
print_info "🔐 Azure AD Redirect: $AZURE_AD_REDIRECT_URI"
print_info "📝 Logging: Enabled"
print_info "🐳 Container Name: $CONTAINER_NAME"
echo ""
print_highlight "📋 Useful Commands:"
echo "  • View logs: podman logs $CONTAINER_NAME"
echo "  • Follow logs: podman logs -f $CONTAINER_NAME"
echo "  • Stop container: podman stop $CONTAINER_NAME"
echo "  • Remove container: podman rm $CONTAINER_NAME"
echo "  • Shell into container: podman exec -it $CONTAINER_NAME sh"
echo ""
print_info "✨ The application should now work without CORS errors!"
print_info "🚀 Open http://localhost:$PORT in your browser"
echo ""

# Ask if user wants to view logs
read -p "🔍 Do you want to view the container logs? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    print_info "📋 Container logs (press Ctrl+C to exit):"
    echo "================================"
    podman logs -f "$CONTAINER_NAME"
fi