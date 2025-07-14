#!/bin/bash

# PulsoVivo - Start Development Server with Proxy
# This script starts the Angular development server with proxy configuration
# to avoid CORS issues when calling AWS API Gateway

echo "🏥 PulsoVivo - Starting Development Server with Proxy"
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

# Check if we're in the correct directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found. Please run this script from the project root directory."
    exit 1
fi

# Check if proxy configuration exists
if [ ! -f "proxy.conf.json" ]; then
    print_error "proxy.conf.json not found!"
    exit 1
fi

print_info "Proxy configuration found ✓"

# Display proxy configuration
print_step "Current proxy configuration:"
cat proxy.conf.json | sed 's/^/  /'

# Check if port 4000 is available
print_step "Checking if port 4000 is available..."

if command -v lsof >/dev/null 2>&1; then
    if lsof -Pi :4000 -sTCP:LISTEN -t >/dev/null ; then
        print_warning "Port 4000 is already in use. Attempting to find alternative port..."
        PORT=4001
        while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; do
            PORT=$((PORT + 1))
            if [ $PORT -gt 4010 ]; then
                print_error "No available ports found between 4000-4010"
                exit 1
            fi
        done
        print_info "Using port $PORT instead"
    else
        PORT=4000
        print_info "Port 4000 is available ✓"
    fi
else
    PORT=4000
    print_info "Port availability check skipped (lsof not available)"
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    print_step "Installing dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        print_error "Failed to install dependencies"
        exit 1
    fi
fi

# Clear Angular cache
print_step "Clearing Angular cache..."
npx ng cache clean 2>/dev/null || true

echo ""
print_highlight "🚀 Starting Angular development server..."
print_highlight "📍 Server will be available at: http://localhost:$PORT"
print_highlight "🔗 API calls to /api/* will be proxied to AWS API Gateway"
print_highlight "🛡️  This avoids CORS issues during development"
echo ""
print_info "Press Ctrl+C to stop the server"
echo ""

# Start the development server with proxy
npx ng serve --configuration=development --port=$PORT --proxy-config=proxy.conf.json --open

# Cleanup message on exit
echo ""
print_info "👋 Development server stopped"