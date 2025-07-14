#!/bin/bash

# PulsoVivo - Simple Podman Run Script
# This script runs the app using existing build artifacts and a simple nginx container

echo "🏥 PulsoVivo - Simple Podman Setup"
echo "=================================="

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
CONTAINER_NAME="pulso-vivo-simple"
PORT=4000

# Check if Podman is available
if ! command -v podman &> /dev/null; then
    print_error "Podman is not installed or not in PATH"
    exit 1
fi

# Check if build exists
if [ ! -d "dist/docker/browser" ]; then
    print_error "Build not found. Please run: npm run build:docker"
    exit 1
fi

print_info "Build artifacts found ✓"

# Stop and remove existing container
print_step "Stopping existing container..."
podman --cgroup-manager=cgroupfs stop $CONTAINER_NAME 2>/dev/null || true
podman --cgroup-manager=cgroupfs rm $CONTAINER_NAME 2>/dev/null || true

# Create nginx config
print_step "Creating nginx configuration..."
mkdir -p ./tmp-nginx
cat > ./tmp-nginx/nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json
        image/svg+xml;

    # API proxy to local inventory service
    location /api/ {
        proxy_pass http://host.docker.internal:8081/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Origin $scheme://$host;
        
        # Pass through authentication headers
        proxy_pass_header Authorization;
        
        # Timeout settings
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # CORS headers
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;
        
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }

    # Handle Angular routing - all routes should serve index.html
    location / {
        try_files $uri $uri/ /index.html;
        
        # No cache for HTML files
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Error pages
    error_page 404 /index.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

# Run nginx container with volume mounts
print_step "Starting nginx container..."
podman --cgroup-manager=cgroupfs run -d \
    --name $CONTAINER_NAME \
    -p $PORT:80 \
    -v "$(pwd)/dist/docker/browser:/usr/share/nginx/html:ro,Z" \
    -v "$(pwd)/tmp-nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro,Z" \
    docker.io/nginx:alpine

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
print_info "📋 Container logs: podman --cgroup-manager=cgroupfs logs -f $CONTAINER_NAME"
print_info "🛑 Stop container: podman --cgroup-manager=cgroupfs stop $CONTAINER_NAME"
print_info "🧹 Cleanup: podman --cgroup-manager=cgroupfs rm $CONTAINER_NAME && rm -rf ./tmp-nginx"
echo ""

# Ask if user wants to see logs
read -p "📋 View container logs? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    print_info "📋 Container logs (press Ctrl+C to exit):"
    echo "========================================"
    podman --cgroup-manager=cgroupfs logs -f $CONTAINER_NAME
fi