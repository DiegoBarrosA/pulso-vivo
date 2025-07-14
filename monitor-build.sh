#!/bin/bash

# Monitor build progress for Pulso Vivo Kafka System
echo "=== Monitoring Pulso Vivo Kafka System Build ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Function to check build status
check_build_status() {
    echo -e "${BLUE}=== Build Status Check at $(date) ===${NC}"
    
    # Check if docker-compose is still running
    if pgrep -f "docker-compose" > /dev/null; then
        echo -e "${YELLOW}Build process is still running...${NC}"
        
        # Check container status
        container_count=$(docker ps -a | grep -E "(kafka|zookeeper|producer|consumer|promotions|pulso)" | wc -l)
        echo -e "Containers created: ${GREEN}$container_count${NC}"
        
        # Check running containers
        running_count=$(docker ps | grep -E "(kafka|zookeeper|producer|consumer|promotions|pulso)" | wc -l)
        echo -e "Running containers: ${GREEN}$running_count${NC}"
        
        # Show container statuses
        echo -e "${BLUE}Container Status:${NC}"
        docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(kafka|zookeeper|producer|consumer|promotions|pulso)" 2>/dev/null || echo "No containers found yet"
        
        # Show images being built
        echo -e "${BLUE}Images:${NC}"
        docker images | grep -E "(kafka|zookeeper|producer|consumer|promotions|pulso)" 2>/dev/null || echo "No images built yet"
        
        return 0
    else
        echo -e "${GREEN}Build process completed!${NC}"
        return 1
    fi
}

# Function to check system health once built
check_system_health() {
    echo -e "${BLUE}=== System Health Check ===${NC}"
    
    # Check all expected services
    services=(
        "zookeeper-1:2181"
        "zookeeper-2:2182"
        "zookeeper-3:2183"
        "kafka-1:9092"
        "kafka-2:9093"
        "kafka-3:9094"
        "kafka-ui:8095"
        "pulso-vivo-producer:8081"
        "pulso-vivo-consumer:8084"
        "pulso-vivo-inventory:8083"
        "pulso-vivo-promotions:8085"
    )
    
    echo -e "${BLUE}Expected Services:${NC}"
    for service in "${services[@]}"; do
        service_name=$(echo "$service" | cut -d':' -f1)
        port=$(echo "$service" | cut -d':' -f2)
        
        if docker ps | grep -q "$service_name"; then
            echo -e "  $service_name: ${GREEN}RUNNING${NC}"
        else
            echo -e "  $service_name: ${RED}NOT RUNNING${NC}"
        fi
    done
    
    # Check logs for any errors
    echo -e "${BLUE}Recent Logs (last 10 lines):${NC}"
    docker-compose logs --tail=10 2>/dev/null || echo "No logs available yet"
}

# Main monitoring loop
echo "Starting build monitoring..."
echo "Press Ctrl+C to stop monitoring"

while true; do
    if check_build_status; then
        echo -e "${YELLOW}Waiting 30 seconds before next check...${NC}"
        sleep 30
    else
        echo -e "${GREEN}Build completed! Checking system health...${NC}"
        check_system_health
        
        echo -e "${GREEN}System is ready! You can now run the comprehensive tests:${NC}"
        echo -e "${BLUE}./comprehensive-test.sh${NC}"
        break
    fi
done
