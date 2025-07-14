#!/bin/bash

# Build and Deploy RabbitMQ Price Monitor Application with Podman
# This script builds using Podman and handles Docker CLI emulation

set -e  # Exit on any error

echo "🚀 Building RabbitMQ Price Monitor Application with Podman"
echo "========================================================"

# Check if Podman is running
if ! sudo podman info > /dev/null 2>&1; then
    echo "❌ Error: Podman is not running or not properly configured."
    echo "Please ensure Podman is installed and running."
    exit 1
fi

# Check if podman-compose is available, fallback to docker-compose with podman
COMPOSE_CMD=""
if command -v podman-compose > /dev/null 2>&1; then
    COMPOSE_CMD="sudo podman-compose"
    echo "✅ Using podman-compose with sudo"
elif command -v docker-compose > /dev/null 2>&1; then
    COMPOSE_CMD="sudo docker-compose"
    echo "✅ Using docker-compose with Podman emulation and sudo"
    
    # Create Docker CLI emulation if it doesn't exist
    if [ ! -f /etc/containers/nodocker ]; then
        echo "📝 Creating Docker CLI emulation configuration..."
        sudo mkdir -p /etc/containers
        sudo touch /etc/containers/nodocker
    fi
else
    echo "❌ Error: Neither podman-compose nor docker-compose is available."
    echo "Please install podman-compose or docker-compose."
    exit 1
fi

# Clean up previous builds (optional)
echo "🧹 Cleaning up previous builds..."
$COMPOSE_CMD down --remove-orphans --volumes 2>/dev/null || true
sudo podman system prune -f --volumes 2>/dev/null || true

# Check if wallet directory exists
if [ ! -d "src/main/resources/wallet" ]; then
    echo "❌ Error: Oracle wallet directory not found at src/main/resources/wallet"
    echo "Please ensure the Oracle ACI wallet files are in the correct location."
    exit 1
fi

# Check for required wallet files
WALLET_FILES=("tnsnames.ora" "sqlnet.ora" "cwallet.sso" "ewallet.p12")
for file in "${WALLET_FILES[@]}"; do
    if [ ! -f "src/main/resources/wallet/$file" ]; then
        echo "⚠️  Warning: Wallet file $file not found in src/main/resources/wallet/"
    fi
done

# Build the application
echo "🔨 Building Spring Boot application..."
./mvnw clean package -DskipTests

if [ $? -ne 0 ]; then
    echo "❌ Error: Maven build failed. Please check the build output above."
    exit 1
fi

# Build Docker images with Podman
echo "🐳 Building container images with Podman..."
$COMPOSE_CMD build --no-cache

if [ $? -ne 0 ]; then
    echo "❌ Error: Container build failed. Please check the build output above."
    exit 1
fi

# Start the services
echo "🚀 Starting services..."
$COMPOSE_CMD up -d

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to start services. Please check the logs above."
    exit 1
fi

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 15

# Check service health
echo "🔍 Checking service health..."

# Check RabbitMQ
echo "  📡 Checking RabbitMQ..."
timeout 60 bash -c "until $COMPOSE_CMD exec -T rabbitmq rabbitmq-diagnostics ping; do sleep 2; done"
if [ $? -eq 0 ]; then
    echo "  ✅ RabbitMQ is ready"
else
    echo "  ❌ RabbitMQ failed to start properly"
fi

# Check Spring Boot Application
echo "  🍃 Checking Spring Boot application..."
timeout 120 bash -c 'until curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; do sleep 5; done'
if [ $? -eq 0 ]; then
    echo "  ✅ Spring Boot application is ready"
else
    echo "  ❌ Spring Boot application failed to start properly"
    echo "  📋 Showing application logs:"
    $COMPOSE_CMD logs rabbitmq-app --tail=50
fi

echo ""
echo "🎉 Podman deployment completed!"
echo "======================================"
echo "📋 Service URLs:"
echo "  🍃 Spring Boot App:      http://localhost:8080"
echo "  📊 Health Check:         http://localhost:8080/actuator/health"
echo "  🐰 RabbitMQ Management:  http://localhost:15672 (guest/guest)"
echo "  🐰 RabbitMQ Secondary:   http://localhost:15673 (guest/guest)"
echo ""
echo "📚 Useful Podman Commands:"
echo "  View logs:               $COMPOSE_CMD logs -f"
echo "  View app logs:           $COMPOSE_CMD logs -f rabbitmq-app"
echo "  View RabbitMQ logs:      $COMPOSE_CMD logs -f rabbitmq"
echo "  Stop services:           $COMPOSE_CMD down"
echo "  Restart app:             $COMPOSE_CMD restart rabbitmq-app"
echo "  List containers:         podman ps"
echo "  Container stats:         podman stats"
echo ""
echo "🧪 Testing Endpoints:"
echo "  GET /api/products                    - List all products"
echo "  POST /api/products                   - Create a product"
echo "  PATCH /api/products/{id}/price       - Update product price"
echo "  GET /api/products/monitoring/status  - Check monitoring status"
echo ""
echo "💡 To test price changes:"
echo "  1. Create a product: POST /api/products"
echo "  2. Update its price: PATCH /api/products/{id}/price"
echo "  3. Check RabbitMQ queues for price change messages"
echo ""
echo "🔧 Podman-specific tips:"
echo "  - Use 'podman ps' instead of 'docker ps'"
echo "  - Use 'podman logs <container>' instead of 'docker logs'"
echo "  - Podman runs rootless by default for better security"