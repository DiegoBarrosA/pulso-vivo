#!/bin/bash

# Postman Collection API Test Runner
# This script runs automated tests for all endpoints in the Pulso Vivo system

echo "🧪 PULSO VIVO API TEST SUITE"
echo "============================"

# Configuration
BASE_URL="http://localhost"
SALES_PORT="8081"
INVENTORY_PORT="8083"
CONSUMER_PRODUCER_PORT="8084"
PROMOTIONS_PORT="8085"
PRICE_MONITOR_PORT="8082"
SALES_MONITOR_PORT="8086"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
passed=0
failed=0

# Function to test API endpoint
test_api() {
    local name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    local expected_status="$5"
    
    echo -n "Testing $name... "
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$url")
    fi
    
    if [ "$response" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (HTTP $response)"
        ((passed++))
    else
        echo -e "${RED}✗ FAILED${NC} (HTTP $response, expected $expected_status)"
        ((failed++))
    fi
}

# Function to test endpoint with response content
test_api_with_content() {
    local name="$1"
    local method="$2"
    local url="$3"
    local data="$4"
    
    echo -n "Testing $name... "
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s "$url")
        status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    else
        response=$(curl -s -X "$method" -H "Content-Type: application/json" -d "$data" "$url")
        status_code=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$url")
    fi
    
    if [ "$status_code" = "200" ] || [ "$status_code" = "201" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (HTTP $status_code)"
        echo "  Response: ${response:0:100}..."
        ((passed++))
    else
        echo -e "${RED}✗ FAILED${NC} (HTTP $status_code)"
        ((failed++))
    fi
}

echo -e "\n${BLUE}📊 1. HEALTH CHECK TESTS${NC}"
echo "========================="
test_api "Sales Producer Health" "GET" "$BASE_URL:$SALES_PORT/actuator/health" "" "200"
test_api "Inventory Service Health" "GET" "$BASE_URL:$INVENTORY_PORT/actuator/health" "" "200"
test_api "Consumer-Producer Health" "GET" "$BASE_URL:$CONSUMER_PRODUCER_PORT/actuator/health" "" "200"
test_api "Promotions Service Health" "GET" "$BASE_URL:$PROMOTIONS_PORT/actuator/health" "" "200"
test_api "Consumer-Producer API Health" "GET" "$BASE_URL:$CONSUMER_PRODUCER_PORT/api/health" "" "200"
test_api "Inventory API Health" "GET" "$BASE_URL:$INVENTORY_PORT/api/health" "" "200"

echo -e "\n${BLUE}💰 2. SALES PRODUCER TESTS${NC}"
echo "==========================="
test_api_with_content "Get Recent Sales" "GET" "$BASE_URL:$SALES_PORT/api/ventas/recientes" ""

# Create a test sale
SALE_DATA='{
  "codigoProducto": "TEST_'$(date +%s)'",
  "cantidad": 2,
  "precioUnitario": 99.99,
  "clienteId": "API_TEST_CLIENT",
  "canalVenta": "API_TEST",
  "ubicacion": "AUTOMATED_TEST"
}'
test_api_with_content "Create Sale" "POST" "$BASE_URL:$SALES_PORT/api/ventas" "$SALE_DATA"

echo -e "\n${BLUE}📦 3. INVENTORY SERVICE TESTS${NC}"
echo "=============================="
test_api_with_content "Get All Products" "GET" "$BASE_URL:$INVENTORY_PORT/api/inventory/products" ""
test_api_with_content "Get Product by ID" "GET" "$BASE_URL:$INVENTORY_PORT/api/inventory/products/1" ""
test_api_with_content "Get Low Stock Products" "GET" "$BASE_URL:$INVENTORY_PORT/api/inventory/products/low-stock" ""

# Create a test product
PRODUCT_DATA='{
  "name": "API Test Product",
  "description": "Created by API test",
  "price": 149.99,
  "quantity": 50,
  "category": "Test",
  "sku": "API_TEST_'$(date +%s)'",
  "minStockLevel": 5
}'
test_api_with_content "Create Product" "POST" "$BASE_URL:$INVENTORY_PORT/api/inventory/products" "$PRODUCT_DATA"

echo -e "\n${BLUE}🔄 4. CONSUMER-PRODUCER TESTS${NC}"
echo "=============================="
test_api_with_content "Get Recent Stock Movements" "GET" "$BASE_URL:$CONSUMER_PRODUCER_PORT/api/stock/recent" ""
test_api_with_content "Get Stock by Product" "GET" "$BASE_URL:$CONSUMER_PRODUCER_PORT/api/stock/producto/PROD001" ""
test_api_with_content "Get Stock Statistics" "GET" "$BASE_URL:$CONSUMER_PRODUCER_PORT/api/stock/stats/PROD001" ""

echo -e "\n${BLUE}🎯 5. PROMOTIONS SERVICE TESTS${NC}"
echo "==============================="
test_api_with_content "Get Active Promotions" "GET" "$BASE_URL:$PROMOTIONS_PORT/api/promotions/active" ""
test_api_with_content "Get Promotions by Product" "GET" "$BASE_URL:$PROMOTIONS_PORT/api/promotions/product/PROD001" ""
test_api "Get Promotions Health" "GET" "$BASE_URL:$PROMOTIONS_PORT/api/promotions/health" "" "200"

# Generate a promotion
PROMOTION_DATA='{
  "productId": "API_TEST_'$(date +%s)'",
  "requestedBy": "API_TEST",
  "reason": "Automated API testing"
}'
test_api_with_content "Generate Promotion" "POST" "$BASE_URL:$PROMOTIONS_PORT/api/promotions/generate" "$PROMOTION_DATA"

echo -e "\n${BLUE}🔍 6. PRICE MONITORING TESTS${NC}"
echo "============================="
test_api_with_content "Get Monitoring Status" "GET" "$BASE_URL:$PRICE_MONITOR_PORT/api/price-monitoring/status" ""
test_api "Enable Price Monitoring" "POST" "$BASE_URL:$PRICE_MONITOR_PORT/api/price-monitoring/enable" "" "200"
test_api_with_content "Get All Products (Price Monitor)" "GET" "$BASE_URL:$PRICE_MONITOR_PORT/api/monitoring/products" ""

echo -e "\n${BLUE}🔌 7. EXTERNAL SERVICES TESTS${NC}"
echo "=============================="
test_api "Kafka UI Access" "GET" "$BASE_URL:8095" "" "200"
test_api "RabbitMQ Management Access" "GET" "$BASE_URL:15672" "" "200"

echo -e "\n${BLUE}🚀 8. INTEGRATION TESTS${NC}"
echo "======================="
# Test end-to-end flow
E2E_PRODUCT_ID="E2E_TEST_$(date +%s)"
E2E_SALE_DATA='{
  "codigoProducto": "'$E2E_PRODUCT_ID'",
  "cantidad": 1,
  "precioUnitario": 199.99,
  "clienteId": "E2E_CLIENT",
  "canalVenta": "E2E_TEST",
  "ubicacion": "INTEGRATION_TEST"
}'

echo "Creating sale for E2E test..."
test_api_with_content "E2E Sale Creation" "POST" "$BASE_URL:$SALES_PORT/api/ventas" "$E2E_SALE_DATA"

# Wait for Kafka processing
echo "Waiting for Kafka message processing..."
sleep 3

# Check stock movement
test_api_with_content "E2E Stock Movement Check" "GET" "$BASE_URL:$CONSUMER_PRODUCER_PORT/api/stock/recent" ""

# Generate promotion based on sale
E2E_PROMOTION_DATA='{
  "productId": "'$E2E_PRODUCT_ID'",
  "requestedBy": "E2E_TEST",
  "reason": "End-to-end integration test"
}'
test_api_with_content "E2E Promotion Generation" "POST" "$BASE_URL:$PROMOTIONS_PORT/api/promotions/generate" "$E2E_PROMOTION_DATA"

echo -e "\n${BLUE}📊 TEST RESULTS${NC}"
echo "================"
echo -e "Tests passed: ${GREEN}$passed${NC}"
echo -e "Tests failed: ${RED}$failed${NC}"
total=$((passed + failed))
echo -e "Total tests: $total"

if [ $failed -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}✅ Your Pulso Vivo Kafka system is working correctly!${NC}"
else
    echo -e "\n${YELLOW}⚠️  Some tests failed. Please check the services above.${NC}"
fi

echo -e "\n${BLUE}📋 NEXT STEPS${NC}"
echo "=============="
echo "1. Import the Postman collection: Pulso-Vivo-API-Collection.postman_collection.json"
echo "2. Import the environment file: Pulso-Vivo-Environment.postman_environment.json"
echo "3. Access Kafka UI at: http://localhost:8095"
echo "4. Access RabbitMQ Management at: http://localhost:15672"
echo "5. Test individual endpoints using the Postman collection"

echo -e "\n${BLUE}🔗 USEFUL LINKS${NC}"
echo "==============="
echo "• Kafka UI: http://localhost:8095"
echo "• RabbitMQ Management: http://localhost:15672"
echo "• Sales Producer: http://localhost:8081"
echo "• Inventory Service: http://localhost:8083"
echo "• Consumer-Producer: http://localhost:8084"
echo "• Promotions Service: http://localhost:8085"
