#!/bin/bash

# Simple test script for Pulso Vivo Kafka System
echo "=== Testing Pulso Vivo Kafka System ==="

# Function to test connectivity to a port
test_port() {
    local service_name=$1
    local port=$2
    echo -n "Testing $service_name (port $port)... "
    
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/localhost/$port" 2>/dev/null; then
        echo "✓ Service responding"
        return 0
    else
        echo "✗ Service not responding"
        return 1
    fi
}

# Function to test HTTP endpoint
test_http() {
    local service_name=$1
    local url=$2
    echo -n "Testing $service_name HTTP... "
    
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    if [ "$response" = "200" ]; then
        echo "✓ HTTP endpoint responding"
        return 0
    else
        echo "✗ HTTP endpoint not responding (status: $response)"
        return 1
    fi
}

# Check all services
echo "=== Testing Infrastructure Services ==="
test_port "Zookeeper 1" 2181
test_port "Zookeeper 2" 2182
test_port "Zookeeper 3" 2183
test_port "Kafka Broker 1" 9092
test_port "Kafka Broker 2" 9093
test_port "Kafka Broker 3" 9094
test_http "Kafka UI" "http://localhost:8095"
test_http "RabbitMQ Management" "http://localhost:15672"

echo ""
echo "=== Testing Microservices ==="
test_http "Sales Producer" "http://localhost:8081/actuator/health"
test_http "Inventory Service" "http://localhost:8083/actuator/health"
test_http "Consumer-Producer Service" "http://localhost:8084/actuator/health"
test_http "Promotions Service" "http://localhost:8085/actuator/health"

echo ""
echo "=== Testing Functional Endpoints ==="
test_http "Sales Data" "http://localhost:8081/sales"
test_http "Promotions Data" "http://localhost:8085/promotions"

echo ""
echo "=== Testing Integration ==="
echo "Creating a test sale..."
response=$(curl -s -X POST "http://localhost:8081/sales" \
    -H "Content-Type: application/json" \
    -d '{
        "productId": "test-product",
        "quantity": 1,
        "price": 99.99,
        "customerName": "Test Customer"
    }' 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✓ Sale created successfully"
    echo "  Response: $response"
else
    echo "✗ Failed to create sale"
fi

echo ""
echo "=== Test Complete ==="
