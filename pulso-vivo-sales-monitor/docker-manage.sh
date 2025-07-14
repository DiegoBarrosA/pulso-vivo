#!/bin/bash

# Container Management Script for RabbitMQ Price Monitor Application
# Provides utilities for managing Docker/Podman environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect container runtime and compose command
CONTAINER_CMD=""
COMPOSE_CMD=""

if command -v podman > /dev/null 2>&1 && sudo podman info > /dev/null 2>&1; then
    CONTAINER_CMD="sudo podman"
    if command -v podman-compose > /dev/null 2>&1; then
        COMPOSE_CMD="sudo podman-compose"
    elif command -v docker-compose > /dev/null 2>&1; then
        COMPOSE_CMD="sudo docker-compose"
        # Ensure Docker CLI emulation for Podman
        if [ ! -f /etc/containers/nodocker ]; then
            print_status "Setting up Docker CLI emulation for Podman..."
            sudo mkdir -p /etc/containers 2>/dev/null || true
            sudo touch /etc/containers/nodocker 2>/dev/null || true
        fi
    fi
elif command -v docker > /dev/null 2>&1 && docker info > /dev/null 2>&1; then
    CONTAINER_CMD="docker"
    COMPOSE_CMD="docker-compose"
else
    print_error "Neither Docker nor Podman is available or running."
    exit 1
fi

print_status "Using container runtime: $CONTAINER_CMD"
print_status "Using compose command: $COMPOSE_CMD"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "🐳 Container Management Script for RabbitMQ Price Monitor"
    echo "======================================================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start         - Start all services"
    echo "  stop          - Stop all services"
    echo "  restart       - Restart all services"
    echo "  restart-app   - Restart only the Spring Boot application"
    echo "  logs          - Show logs for all services"
    echo "  logs-app      - Show logs for Spring Boot application only"
    echo "  logs-rabbitmq - Show logs for RabbitMQ only"
    echo "  status        - Show status of all services"
    echo "  health        - Check health of all services"
    echo "  clean         - Clean up containers, images, and volumes"
    echo "  rebuild       - Clean and rebuild everything"
    echo "  shell-app     - Open shell in application container"
    echo "  shell-rabbitmq - Open shell in RabbitMQ container"
    echo "  monitor       - Monitor resource usage"
    echo "  backup        - Backup RabbitMQ data"
    echo "  help          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs-app"
    echo "  $0 restart-app"
    echo "  $0 health"
}

# Function to check if container runtime is running
check_container_runtime() {
    if [ -z "$CONTAINER_CMD" ] || [ -z "$COMPOSE_CMD" ]; then
        print_error "Container runtime is not available or not properly configured."
        exit 1
    fi
}

# Function to check if compose file exists
check_compose_file() {
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found in current directory."
        exit 1
    fi
}

# Function to start services
start_services() {
    print_status "Starting all services..."
    $COMPOSE_CMD up -d
    print_success "Services started successfully!"
    
    print_status "Waiting for services to be ready..."
    sleep 10
    check_health
}

# Function to stop services
stop_services() {
    print_status "Stopping all services..."
    $COMPOSE_CMD down
    print_success "Services stopped successfully!"
}

# Function to restart services
restart_services() {
    print_status "Restarting all services..."
    $COMPOSE_CMD restart
    print_success "Services restarted successfully!"
}

# Function to restart only the app
restart_app() {
    print_status "Restarting Spring Boot application..."
    $COMPOSE_CMD restart rabbitmq-app
    print_success "Application restarted successfully!"
    
    print_status "Waiting for application to be ready..."
    sleep 15
    check_app_health
}

# Function to show logs
show_logs() {
    print_status "Showing logs for all services (Press Ctrl+C to exit)..."
    $COMPOSE_CMD logs -f
}

# Function to show app logs
show_app_logs() {
    print_status "Showing logs for Spring Boot application (Press Ctrl+C to exit)..."
    $COMPOSE_CMD logs -f rabbitmq-app
}

# Function to show RabbitMQ logs
show_rabbitmq_logs() {
    print_status "Showing logs for RabbitMQ (Press Ctrl+C to exit)..."
    $COMPOSE_CMD logs -f rabbitmq
}

# Function to show service status
show_status() {
    print_status "Service Status:"
    echo ""
    $COMPOSE_CMD ps
    echo ""
    
    print_status "Container Resources:"
    $CONTAINER_CMD stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Function to check health
check_health() {
    print_status "Checking service health..."
    
    # Check RabbitMQ
    print_status "Checking RabbitMQ..."
    if $COMPOSE_CMD exec -T rabbitmq rabbitmq-diagnostics ping > /dev/null 2>&1; then
        print_success "RabbitMQ is healthy"
    else
        print_error "RabbitMQ is not responding"
    fi
    
    # Check Spring Boot App
    check_app_health
}

# Function to check app health
check_app_health() {
    print_status "Checking Spring Boot application..."
    if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
        print_success "Spring Boot application is healthy"
        
        # Show health details
        echo ""
        print_status "Health Details:"
        curl -s http://localhost:8080/actuator/health | jq '.' 2>/dev/null || curl -s http://localhost:8080/actuator/health
    else
        print_error "Spring Boot application is not responding"
        print_warning "You can check the logs with: $0 logs-app"
    fi
}

# Function to clean up
clean_up() {
    print_warning "This will remove all containers, images, and volumes. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_status "Stopping services..."
        $COMPOSE_CMD down --remove-orphans --volumes
        
        print_status "Removing unused container resources..."
        $CONTAINER_CMD system prune -af --volumes
        
        print_success "Cleanup completed!"
    else
        print_status "Cleanup cancelled."
    fi
}

# Function to rebuild everything
rebuild() {
    print_status "Rebuilding everything..."
    
    print_status "Stopping services..."
    $COMPOSE_CMD down --remove-orphans
    
    print_status "Building application..."
    ./mvnw clean package -DskipTests
    
    print_status "Building container images..."
    $COMPOSE_CMD build --no-cache
    
    print_status "Starting services..."
    $COMPOSE_CMD up -d
    
    print_success "Rebuild completed!"
    
    print_status "Waiting for services to be ready..."
    sleep 15
    check_health
}

# Function to open shell in app container
shell_app() {
    print_status "Opening shell in application container..."
    $COMPOSE_CMD exec rabbitmq-app /bin/bash
}

# Function to open shell in RabbitMQ container
shell_rabbitmq() {
    print_status "Opening shell in RabbitMQ container..."
    $COMPOSE_CMD exec rabbitmq /bin/bash
}

# Function to monitor resources
monitor_resources() {
    print_status "Monitoring resource usage (Press Ctrl+C to exit)..."
    $CONTAINER_CMD stats
}

# Function to backup RabbitMQ data
backup_rabbitmq() {
    BACKUP_DIR="./backups"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="rabbitmq_backup_${TIMESTAMP}.tar.gz"
    
    print_status "Creating backup of RabbitMQ data..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Create backup
    $CONTAINER_CMD run --rm -v rabbitmqavanzado_rabbitmq_data:/data -v "$(pwd)/$BACKUP_DIR":/backup docker.io/library/alpine tar czf "/backup/$BACKUP_FILE" -C /data .
    
    if [ $? -eq 0 ]; then
        print_success "Backup created: $BACKUP_DIR/$BACKUP_FILE"
    else
        print_error "Backup failed!"
    fi
}

# Main script logic
check_container_runtime
check_compose_file

case "${1:-help}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    restart-app)
        restart_app
        ;;
    logs)
        show_logs
        ;;
    logs-app)
        show_app_logs
        ;;
    logs-rabbitmq)
        show_rabbitmq_logs
        ;;
    status)
        show_status
        ;;
    health)
        check_health
        ;;
    clean)
        clean_up
        ;;
    rebuild)
        rebuild
        ;;
    shell-app)
        shell_app
        ;;
    shell-rabbitmq)
        shell_rabbitmq
        ;;
    monitor)
        monitor_resources
        ;;
    backup)
        backup_rabbitmq
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac