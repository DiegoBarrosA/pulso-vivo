#!/bin/bash

# PulsoVivo Angular Development Startup Script
# This script sets up the development environment and starts the Angular dev server

echo "🏥 PulsoVivo - Starting Development Environment"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
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

# Check if Node.js is installed
print_step "Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 18 or higher."
    exit 1
fi

NODE_VERSION=$(node --version)
print_status "Node.js version: $NODE_VERSION"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install npm."
    exit 1
fi

NPM_VERSION=$(npm --version)
print_status "npm version: $NPM_VERSION"

# Check if we're in the correct directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found. Please run this script from the project root directory."
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    print_step "Installing dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        print_error "Failed to install dependencies"
        exit 1
    fi
    print_status "Dependencies installed successfully"
else
    print_status "Dependencies already installed"
fi

# Check if environment files exist
print_step "Checking environment configuration..."
if [ ! -f "src/environments/environment.ts" ]; then
    print_error "Environment file not found: src/environments/environment.ts"
    exit 1
fi

if [ ! -f "src/environments/environment.development.ts" ]; then
    print_warning "Development environment file not found: src/environments/environment.development.ts"
    print_warning "Using default environment.ts"
fi

# Check if proxy configuration exists
if [ ! -f "proxy.conf.json" ]; then
    print_warning "Proxy configuration not found: proxy.conf.json"
    print_warning "API calls may fail due to CORS issues"
else
    print_status "Proxy configuration found"
fi

# Check if images exist
print_step "Checking image assets..."
IMAGES_DIR="public/assets/images"
if [ ! -d "$IMAGES_DIR" ]; then
    print_error "Images directory not found: $IMAGES_DIR"
    exit 1
fi

REQUIRED_IMAGES=(
    "tensiometro.jpg"
    "estetoscopio.jpg"
    "termometro.jpg"
    "guantes.jpg"
    "mascarillas.jpg"
    "jeringuillas.jpg"
    "camilla.jpg"
    "silla-ruedas.jpg"
    "producto-placeholder.jpg"
)

MISSING_IMAGES=()
for img in "${REQUIRED_IMAGES[@]}"; do
    if [ ! -f "$IMAGES_DIR/$img" ]; then
        MISSING_IMAGES+=("$img")
    fi
done

if [ ${#MISSING_IMAGES[@]} -gt 0 ]; then
    print_warning "Missing image files:"
    for img in "${MISSING_IMAGES[@]}"; do
        echo "  - $img"
    done
    print_warning "Placeholder images will be used"
else
    print_status "All required images found"
fi

# Clear Angular cache
print_step "Clearing Angular cache..."
npx ng cache clean 2>/dev/null || true

# Set development environment
export NODE_ENV=development
export NG_ENV=development

print_step "Environment variables set:"
echo "  - NODE_ENV: $NODE_ENV"
echo "  - NG_ENV: $NG_ENV"

# Display configuration summary
echo ""
echo "📋 Configuration Summary:"
echo "========================"
echo "🔧 Environment: Development"
echo "🌐 Server URL: http://localhost:4200"
echo "🔗 API Proxy: Enabled (proxy.conf.json)"
echo "🖼️  Images: $IMAGES_DIR"
echo "📝 Logging: Enabled (debug level)"
echo "🔐 MSAL B2C: Configured"
echo ""

# Ask user if they want to open browser automatically
read -p "🌐 Open browser automatically when ready? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    OPEN_BROWSER="--open"
else
    OPEN_BROWSER=""
fi

# Start the development server
print_step "Starting Angular development server..."
echo ""
print_status "🚀 Starting PulsoVivo on http://localhost:4200"
print_status "📱 Press Ctrl+C to stop the server"
echo ""

# Start ng serve with development configuration and proxy
npx ng serve --configuration=development --host=0.0.0.0 --port=4200 --proxy-config=proxy.conf.json $OPEN_BROWSER

# Cleanup on exit
trap 'echo -e "\n${YELLOW}👋 Shutting down PulsoVivo development server...${NC}"; exit 0' INT TERM