#!/bin/bash

# Test script for Pulso Vivo Kafka System
echo "=== Testing Pulso Vivo Kafka System ==="

# Function to check if service is running
check_service() {
    local service_name=$1
    local container_name=$2
    local port=$3
    
    echo -n "Checking $service_name... "
    
    # Check if container exists and is running via docker-compose
    if docker-compose ps | grep -q "$container_name.*Up"; then
        echo "✓ Container running"
        
        # Check if port is responding
        if timeout 5 bash -c "cat < /dev/null > /dev/tcp/localhost/$port" 2>/dev/null; then
            echo "  ✓ Port $port responding"
        else
            echo "  ✗ Port $port not responding"
        fi
    else
        echo "✗ Container not running"
    fi
}

# Check infrastructure services
echo "=== Infrastructure Services ==="
check_service "Zookeeper-1" "zookeeper-1" "2181"
check_service "Zookeeper-2" "zookeeper-2" "2182"
check_service "Zookeeper-3" "zookeeper-3" "2183"
check_service "Kafka-1" "kafka-1" "9092"
check_service "Kafka-2" "kafka-2" "9093"
check_service "Kafka-3" "kafka-3" "9094"
check_service "Kafka-UI" "kafka-ui" "8095"
check_service "RabbitMQ" "pulso-vivo-rabbitmq" "5672"

# Check microservices
echo "=== Microservices ==="
check_service "Producer (Ventas)" "pulso-vivo-producer" "8081"
check_service "Consumer-Producer (Ventas->Stock)" "pulso-vivo-kafka-consumidor-ventas-productor-stock" "8084"
check_service "Promotions Service" "pulso-vivo-promotions" "8085"
check_service "Inventory Service" "pulso-vivo-inventory" "8083"

# Check Kafka topics
echo "=== Kafka Topics ==="
if docker-compose ps | grep -q "kafka-1.*Up"; then
    echo "Checking Kafka topics..."
    docker-compose exec -T kafka-1 kafka-topics --list --bootstrap-server kafka-1:29092,kafka-2:29093,kafka-3:29094 2>/dev/null || echo "Could not list topics"
else
    echo "Kafka not running - cannot check topics"
fi

# Test basic connectivity
echo "=== Testing Basic Connectivity ==="
echo "Testing Kafka UI..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}" http://localhost:8095 || echo "Failed to connect to Kafka UI"
echo ""

echo "Testing RabbitMQ Management..."
curl -s -o /dev/null -w "HTTP Status: %{http_code}" http://localhost:15672 || echo "Failed to connect to RabbitMQ Management"
echo ""

# Test API endpoints
echo "=== Testing API Endpoints ==="

echo "Testing Sales Producer API..."
response=$(curl -s -w "%{http_code}" http://localhost:8081/actuator/health)
if [[ "${response: -3}" == "200" ]]; then
    echo "  ✓ Sales Producer health endpoint responding"
else
    echo "  ✗ Sales Producer health endpoint failed"
fi

echo "Testing Inventory Service API..."
response=$(curl -s -w "%{http_code}" http://localhost:8083/actuator/health)
if [[ "${response: -3}" == "200" ]]; then
    echo "  ✓ Inventory Service health endpoint responding"
else
    echo "  ✗ Inventory Service health endpoint failed"
fi

echo "Testing Consumer-Producer Service API..."
response=$(curl -s -w "%{http_code}" http://localhost:8084/actuator/health)
if [[ "${response: -3}" == "200" ]]; then
    echo "  ✓ Consumer-Producer Service health endpoint responding"
else
    echo "  ✗ Consumer-Producer Service health endpoint failed"
fi

echo "Testing Promotions Service API..."
response=$(curl -s -w "%{http_code}" http://localhost:8085/api/promotions/health)
if [[ "${response: -3}" == "200" ]]; then
    echo "  ✓ Promotions Service health endpoint responding"
else
    echo "  ✗ Promotions Service health endpoint failed"
fi

# Test functional endpoints
echo "=== Testing Functional Endpoints ==="

echo "Testing Sales Data Retrieval..."
sales_response=$(curl -s http://localhost:8081/api/ventas/recientes)
if [[ ${#sales_response} -gt 10 ]]; then
    echo "  ✓ Sales data retrieved successfully"
    echo "  ℹ $(echo "$sales_response" | jq '. | length' 2>/dev/null || echo "Multiple") sales records found"
else
    echo "  ✗ Failed to retrieve sales data"
fi

echo "Testing Promotions Data Retrieval..."
promotions_response=$(curl -s http://localhost:8085/api/promotions/active)
if [[ ${#promotions_response} -gt 10 ]]; then
    echo "  ✓ Promotions data retrieved successfully"
    echo "  ℹ $(echo "$promotions_response" | jq '. | length' 2>/dev/null || echo "Multiple") active promotions found"
else
    echo "  ✗ Failed to retrieve promotions data"
fi

# Test integration by creating a sale
echo "=== Testing Integration ==="
echo "Testing end-to-end sale creation..."

test_sale='{
    "codigoProducto": "SYSTEM_TEST_'$(date +%s)'",
    "cantidad": 1,
    "precioUnitario": 99.99,
    "clienteId": "INTEGRATION_TEST",
    "canalVenta": "API_TEST",
    "ubicacion": "AUTOMATED_TESTING"
}'

sale_result=$(curl -s -X POST "http://localhost:8081/api/ventas" \
    -H "Content-Type: application/json" \
    -d "$test_sale")

if echo "$sale_result" | jq -e '.id' >/dev/null 2>&1; then
    sale_id=$(echo "$sale_result" | jq -r '.id')
    echo "  ✓ Sale created successfully with ID: $sale_id"
    echo "  ℹ This should trigger Kafka message flow to stock topic"
else
    echo "  ✗ Failed to create test sale"
    echo "  Response: $sale_result"
fi

echo "=== System Test Complete ==="
