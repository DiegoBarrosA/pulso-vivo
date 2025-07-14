#!/bin/bash

# PulsoVivo - Debug Environment Configuration
# This script helps debug environment configuration issues

echo "🔍 PulsoVivo - Environment Configuration Debug"
echo "=============================================="

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

# Check if we're in the correct directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found. Please run this script from the project root directory."
    exit 1
fi

# Check environment files
print_step "Checking environment files..."
ENVIRONMENT_FILES=(
    "src/environments/environment.ts"
    "src/environments/environment.development.ts"
    "src/environments/environment.production.ts"
    "src/environments/environment.docker.ts"
)

for env_file in "${ENVIRONMENT_FILES[@]}"; do
    if [ -f "$env_file" ]; then
        print_info "✓ $env_file exists"
        
        # Check API baseUrl in each environment file
        if grep -q "baseUrl" "$env_file"; then
            BASE_URL=$(grep -o '"baseUrl":[^,]*' "$env_file" | cut -d'"' -f4)
            echo "    API baseUrl: $BASE_URL"
        else
            print_warning "    No baseUrl found in $env_file"
        fi
    else
        print_error "✗ $env_file missing"
    fi
done

echo ""

# Check Angular configuration
print_step "Checking Angular configuration..."
if [ -f "angular.json" ]; then
    print_info "✓ angular.json exists"
    
    # Check build configurations
    if grep -q '"docker"' angular.json; then
        print_info "✓ Docker configuration found in angular.json"
    else
        print_warning "✗ Docker configuration missing in angular.json"
    fi
    
    if grep -q '"static"' angular.json; then
        print_info "✓ Static configuration found in angular.json"
    else
        print_warning "✗ Static configuration missing in angular.json"
    fi
else
    print_error "✗ angular.json missing"
fi

echo ""

# Check proxy configuration
print_step "Checking proxy configuration..."
if [ -f "proxy.conf.json" ]; then
    print_info "✓ proxy.conf.json exists"
    echo "    Content:"
    cat proxy.conf.json | sed 's/^/    /'
else
    print_error "✗ proxy.conf.json missing"
fi

echo ""

# Check nginx configuration
print_step "Checking nginx configuration..."
if [ -f "nginx.conf" ]; then
    print_info "✓ nginx.conf exists"
    if grep -q "proxy_pass.*api" nginx.conf; then
        PROXY_TARGET=$(grep -o 'proxy_pass [^;]*' nginx.conf | cut -d' ' -f2)
        echo "    Proxy target: $PROXY_TARGET"
    else
        print_warning "    No API proxy configuration found"
    fi
else
    print_warning "✗ nginx.conf missing"
fi

if [ -f "nginx.conf.template" ]; then
    print_info "✓ nginx.conf.template exists"
    if grep -q "proxy_pass.*API_GATEWAY_URL" nginx.conf.template; then
        print_info "    Template uses API_GATEWAY_URL variable"
    else
        print_warning "    Template doesn't use API_GATEWAY_URL variable"
    fi
else
    print_warning "✗ nginx.conf.template missing"
fi

echo ""

# Check Dockerfile
print_step "Checking Dockerfile..."
if [ -f "Dockerfile" ]; then
    print_info "✓ Dockerfile exists"
    
    # Check build command
    if grep -q "build:docker" Dockerfile; then
        print_info "✓ Uses build:docker command"
    elif grep -q "build:static" Dockerfile; then
        print_warning "⚠ Uses build:static command (should use build:docker for proxy support)"
    else
        print_warning "⚠ Build command not clearly identified"
    fi
    
    # Check environment variables
    if grep -q "API_GATEWAY_URL" Dockerfile; then
        print_info "✓ API_GATEWAY_URL environment variable configured"
    else
        print_warning "✗ API_GATEWAY_URL environment variable missing"
    fi
else
    print_error "✗ Dockerfile missing"
fi

echo ""

# Check package.json scripts
print_step "Checking package.json scripts..."
if [ -f "package.json" ]; then
    print_info "✓ package.json exists"
    
    # Check for build scripts
    if grep -q '"build:docker"' package.json; then
        print_info "✓ build:docker script found"
    else
        print_warning "✗ build:docker script missing"
    fi
    
    if grep -q '"build:static"' package.json; then
        print_info "✓ build:static script found"
    else
        print_warning "✗ build:static script missing"
    fi
else
    print_error "✗ package.json missing"
fi

echo ""

# Check dist directories
print_step "Checking build output directories..."
if [ -d "dist" ]; then
    print_info "✓ dist directory exists"
    
    # List subdirectories
    for dist_dir in dist/*/; do
        if [ -d "$dist_dir" ]; then
            dir_name=$(basename "$dist_dir")
            print_info "  - $dir_name"
        fi
    done
else
    print_warning "✗ dist directory not found (no builds yet)"
fi

echo ""

# Check Docker-related files
print_step "Checking Docker-related files..."
DOCKER_FILES=(
    "docker-compose.yml"
    ".dockerignore"
    "run-docker-with-proxy.sh"
)

for docker_file in "${DOCKER_FILES[@]}"; do
    if [ -f "$docker_file" ]; then
        print_info "✓ $docker_file exists"
    else
        print_warning "✗ $docker_file missing"
    fi
done

echo ""

# Check if Podman is available
print_step "Checking Podman availability..."
if command -v podman &> /dev/null; then
    print_info "✓ Podman is installed"
    
    # Check for existing containers
    if podman ps -a --format "table {{.Names}}\t{{.Status}}" | grep -q "pulso"; then
        print_info "Existing PulsoVivo containers:"
        podman ps -a --format "table {{.Names}}\t{{.Status}}" | grep "pulso" | sed 's/^/    /'
    else
        print_info "No existing PulsoVivo containers found"
    fi
else
    print_error "✗ Podman is not installed"
fi

echo ""

# Summary and recommendations
print_highlight "📋 SUMMARY & RECOMMENDATIONS"
print_highlight "============================"

echo ""
print_step "Current CORS Issue Analysis:"
echo "The CORS errors indicate that your Angular app is making direct calls to:"
echo "  https://erwqz80g2d.execute-api.us-east-1.amazonaws.com/api/inventory/products"
echo ""
echo "Instead of using the proxy at:"
echo "  /api/inventory/products"
echo ""

print_step "Recommended Actions:"
echo "1. 🔧 Rebuild Podman image with new environment configuration:"
echo "   ./run-docker-with-proxy.sh"
echo ""
echo "2. 🌐 Verify nginx proxy is working by checking container logs:"
echo "   podman logs -f pulso-vivo-frontend"
echo ""
echo "3. 🔍 Test the proxy directly:"
echo "   curl -I http://localhost:4000/api/inventory/products"
echo ""
echo "4. 🐛 Check browser dev tools for actual API calls being made"
echo ""

print_step "Environment Configuration Status:"
if [ -f "src/environments/environment.docker.ts" ]; then
    if grep -q 'baseUrl.*"/api"' "src/environments/environment.docker.ts"; then
        print_info "✓ Docker environment configured to use proxy"
    else
        print_warning "✗ Docker environment not configured for proxy"
    fi
else
    print_error "✗ Docker environment file missing"
fi

echo ""
print_highlight "🎯 Next Steps:"
echo "1. Run: ./run-docker-with-proxy.sh"
echo "2. Check browser dev tools Network tab"
echo "3. Verify API calls go to /api/* not https://erwqz80g2d.execute-api.us-east-1.amazonaws.com/*"
echo "4. If still failing, check Podman container logs"
echo ""