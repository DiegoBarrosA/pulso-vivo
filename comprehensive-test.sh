#!/bin/bash

# Comprehensive test suite for Pulso Vivo Kafka System
echo "=== Comprehensive Test Suite for Pulso Vivo Kafka System ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test function
run_test() {
    local test_name=$1
    local test_command=$2
    local expected_result=$3
    
    echo -n "Testing $test_name... "
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command" > /dev/null 2>&1; then
        if [ "$expected_result" = "pass" ]; then
            echo -e "${GREEN}PASS${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "${RED}FAIL${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        if [ "$expected_result" = "fail" ]; then
            echo -e "${GREEN}PASS${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            echo -e "${RED}FAIL${NC}"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    fi
}

# Test function for response codes
test_http_response() {
    local test_name=$1
    local url=$2
    local expected_code=$3
    
    echo -n "Testing $test_name... "
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response_code" = "$expected_code" ]; then
        echo -e "${GREEN}PASS${NC} (HTTP $response_code)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}FAIL${NC} (HTTP $response_code, expected $expected_code)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Test function for JSON API responses
test_json_api() {
    local test_name=$1
    local method=$2
    local url=$3
    local data=$4
    local expected_field=$5
    
    echo -n "Testing $test_name... "
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s "$url" 2>/dev/null)
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -X POST -H "Content-Type: application/json" -d "$data" "$url" 2>/dev/null)
    fi
    
    if echo "$response" | grep -q "$expected_field"; then
        echo -e "${GREEN}PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}FAIL${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "  Response: $response"
    fi
}

# Test Kafka topic operations
test_kafka_topic() {
    local test_name=$1
    local topic_name=$2
    
    echo -n "Testing $test_name... "
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if docker exec kafka-1 kafka-topics --list --bootstrap-server kafka-1:29092 2>/dev/null | grep -q "$topic_name"; then
        echo -e "${GREEN}PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}FAIL${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Test message production and consumption
test_kafka_message_flow() {
    local test_name=$1
    local topic=$2
    local message=$3
    
    echo -n "Testing $test_name... "
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Produce message
    echo "$message" | docker exec -i kafka-1 kafka-console-producer --topic "$topic" --bootstrap-server kafka-1:29092 2>/dev/null
    
    # Wait a bit for message to be produced
    sleep 2
    
    # Try to consume message
    consumed=$(timeout 5 docker exec kafka-1 kafka-console-consumer --topic "$topic" --bootstrap-server kafka-1:29092 --from-beginning --max-messages 1 2>/dev/null)
    
    if echo "$consumed" | grep -q "$message"; then
        echo -e "${GREEN}PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}FAIL${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

echo -e "${YELLOW}=== REQUIREMENT 1: Kafka Cluster Configuration ===${NC}"
echo "Testing 3 Kafka brokers and 3 Zookeeper instances..."

run_test "Zookeeper-1 container" "docker ps | grep -q zookeeper-1" "pass"
run_test "Zookeeper-2 container" "docker ps | grep -q zookeeper-2" "pass"
run_test "Zookeeper-3 container" "docker ps | grep -q zookeeper-3" "pass"
run_test "Kafka-1 container" "docker ps | grep -q kafka-1" "pass"
run_test "Kafka-2 container" "docker ps | grep -q kafka-2" "pass"
run_test "Kafka-3 container" "docker ps | grep -q kafka-3" "pass"
run_test "Kafka-UI container" "docker ps | grep -q kafka-ui" "pass"

echo -e "${YELLOW}=== REQUIREMENT 2: Topic Configuration ===${NC}"
echo "Testing ventas and stock topics..."

test_kafka_topic "Ventas topic exists" "ventas"
test_kafka_topic "Stock topic exists" "stock"

echo -e "${YELLOW}=== REQUIREMENT 3: Message Flow Testing ===${NC}"
echo "Testing message production and consumption..."

test_kafka_message_flow "Ventas topic message flow" "ventas" '{"id":1,"producto":"test","cantidad":10}'
test_kafka_message_flow "Stock topic message flow" "stock" '{"id":1,"producto":"test","stock":100}'

echo -e "${YELLOW}=== REQUIREMENT 4: Microservices Testing ===${NC}"
echo "Testing microservices endpoints..."

# Test sales producer service
test_http_response "Sales Producer Health" "http://localhost:8081/actuator/health" "200"
test_json_api "Sales Producer Sales Endpoint" "GET" "http://localhost:8081/api/ventas/recientes" "" "[]"

# Test consumer-producer service
test_http_response "Consumer-Producer Health" "http://localhost:8084/actuator/health" "200"

# Test inventory service
test_http_response "Inventory Service Health" "http://localhost:8083/actuator/health" "200"

# Test promotions service
test_http_response "Promotions Service Health" "http://localhost:8085/api/promotions/health" "200"
test_json_api "Promotions Active Endpoint" "GET" "http://localhost:8085/api/promotions/active" "" "[]"

echo -e "${YELLOW}=== REQUIREMENT 5: Integration Testing ===${NC}"
echo "Testing end-to-end integration..."

# Test complete flow: produce sale -> consume -> produce stock update -> consume for promotions
test_sale_data='{"codigoProducto":"TEST001","cantidad":5,"precioUnitario":100.00,"clienteId":"CLIENT001","canalVenta":"WEB","ubicacion":"ONLINE"}'

test_json_api "Create Sale Integration" "POST" "http://localhost:8081/api/ventas" "$test_sale_data" "TEST001"

echo -e "${YELLOW}=== REQUIREMENT 6: UI and Monitoring ===${NC}"
echo "Testing Kafka UI and monitoring..."

test_http_response "Kafka UI Access" "http://localhost:8095" "200"

echo -e "${YELLOW}=== REQUIREMENT 7: System Health ===${NC}"
echo "Testing overall system health..."

# Test all services are responding
run_test "All Kafka brokers healthy" "docker exec kafka-1 kafka-broker-api-versions --bootstrap-server kafka-1:29092,kafka-2:29093,kafka-3:29094" "pass"

# Test topic replication
if docker exec kafka-1 kafka-topics --describe --topic ventas --bootstrap-server kafka-1:29092 2>/dev/null | grep -q "ReplicationFactor:.*3"; then
    echo -e "Topic replication factor: ${GREEN}PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "Topic replication factor: ${RED}FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo -e "${YELLOW}=== Test Summary ===${NC}"
echo "Total tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo -e "Success rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}All tests passed! System meets all requirements.${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please check the system configuration.${NC}"
    exit 1
fi
