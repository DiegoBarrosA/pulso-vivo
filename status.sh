#!/bin/bash

# Quick status check
echo "=== Pulso Vivo Kafka System Status ==="
echo "Current time: $(date)"
echo

# Check if build process is running
if pgrep -f "docker-compose" > /dev/null; then
    echo "🔄 Build process: RUNNING"
else
    echo "✅ Build process: COMPLETED"
fi

# Check containers
echo
echo "📦 Containers:"
container_count=$(docker ps -a | wc -l)
if [ $container_count -eq 1 ]; then
    echo "  No containers created yet"
else
    echo "  Total containers: $((container_count - 1))"
    docker ps -a --format "table {{.Names}}\t{{.Status}}" | head -10
fi

# Check images
echo
echo "🖼️  Images:"
image_count=$(docker images | grep -v "REPOSITORY" | wc -l)
echo "  Total images: $image_count"

# Check network
echo
echo "🌐 Networks:"
docker network ls | grep pulso-vivo || echo "  No pulso-vivo networks found"

# Check volumes
echo
echo "💾 Volumes:"
docker volume ls | grep pulso-vivo | wc -l | xargs echo "  Pulso-vivo volumes:"

echo
echo "To monitor build progress run: ./monitor-build.sh"
echo "To run comprehensive tests: ./comprehensive-test.sh"
