#!/bin/bash

# Build and Deploy RabbitMQ Price Monitor Application
# This script builds the Docker image and starts the services

set -e  # Exit on any error

echo "🚀 Building RabbitMQ Price Monitor Application"
echo "=============================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    echo "❌ Error: docker-compose is not installed. Please install docker-compose and try again."
    exit 1
fi

# Clean up previous builds (optional)
echo "🧹 Cleaning up previous builds..."
docker-compose down --remove-orphans --volumes 2>/dev/null || true
docker system prune -f --volumes 2>/dev/null || true

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

# Build Docker images
echo "🐳 Building Docker images..."
docker-compose build --no-cache

if [ $? -ne 0 ]; then
    echo "❌ Error: Docker build failed. Please check the build output above."
    exit 1
fi

# Start the services
echo "🚀 Starting services..."
docker-compose up -d

if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to start services. Please check the logs above."
    exit 1
fi

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service health
echo "🔍 Checking service health..."

# Check RabbitMQ
echo "  📡 Checking RabbitMQ..."
timeout 60 bash -c 'until docker-compose exec -T rabbitmq rabbitmq-diagnostics ping; do sleep 2; done'
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
    docker-compose logs rabbitmq-app --tail=50
fi

echo ""
echo "🎉 Deployment completed!"
echo "======================================"
echo "📋 Service URLs:"
echo "  🍃 Spring Boot App:      http://localhost:8080"
echo "  📊 Health Check:         http://localhost:8080/actuator/health"
echo "  🐰 RabbitMQ Management:  http://localhost:15672 (guest/guest)"
echo "  🐰 RabbitMQ Secondary:   http://localhost:15673 (guest/guest)"
echo ""
echo "📚 Useful Commands:"
echo "  View logs:               docker-compose logs -f"
echo "  View app logs:           docker-compose logs -f rabbitmq-app"
echo "  View RabbitMQ logs:      docker-compose logs -f rabbitmq"
echo "  Stop services:           docker-compose down"
echo "  Restart app:             docker-compose restart rabbitmq-app"
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