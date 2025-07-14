# Pulso Vivo Kafka System - API Testing Guide

This guide provides comprehensive testing resources for the Pulso Vivo Kafka microservices system.

## 📁 Files Included

1. **`Pulso-Vivo-API-Collection.postman_collection.json`** - Complete Postman collection with all API endpoints
2. **`Pulso-Vivo-Environment.postman_environment.json`** - Environment variables for easy configuration
3. **`api-test-runner.sh`** - Automated test script for all endpoints
4. **`final-validation.sh`** - System validation script
5. **`simple-test.sh`** - Basic connectivity test script

## 🚀 Quick Start

### Option 1: Using Postman (Recommended)

1. **Import the Collection:**
   ```
   - Open Postman
   - Click "Import" button
   - Select "Pulso-Vivo-API-Collection.postman_collection.json"
   ```

2. **Import the Environment:**
   ```
   - Click "Import" button
   - Select "Pulso-Vivo-Environment.postman_environment.json"
   - Select "Pulso Vivo Local Environment" in the environment dropdown
   ```

3. **Start Testing:**
   - All endpoints are organized in folders
   - Variables are pre-configured
   - Run individual requests or entire folders

### Option 2: Using the Automated Test Script

```bash
# Run comprehensive API tests
./api-test-runner.sh

# Run system validation
./final-validation.sh

# Run basic connectivity test
./simple-test.sh
```

## 📊 API Endpoints Overview

### 1. Health Checks
- Sales Producer: `GET /actuator/health`
- Inventory Service: `GET /actuator/health`
- Consumer-Producer: `GET /actuator/health`
- Promotions Service: `GET /actuator/health`

### 2. Sales Producer Service (Port 8081)
- `POST /api/ventas` - Create new sale
- `GET /api/ventas/recientes` - Get recent sales

### 3. Inventory Service (Port 8083)
- `GET /api/inventory/products` - Get all products
- `GET /api/inventory/products/{id}` - Get product by ID
- `POST /api/inventory/products` - Create new product
- `PUT /api/inventory/products/{id}` - Update product
- `DELETE /api/inventory/products/{id}` - Delete product
- `GET /api/inventory/products/low-stock` - Get low stock products
- `POST /api/inventory/update` - Update product inventory

### 4. Consumer-Producer Service (Port 8084)
- `GET /api/health` - Service health check
- `GET /api/stock/recent` - Get recent stock movements
- `GET /api/stock/producto/{code}` - Get stock by product code
- `GET /api/stock/stats/{code}` - Get stock statistics

### 5. Promotions Service (Port 8085)
- `POST /api/promotions/generate` - Generate new promotion
- `GET /api/promotions/active` - Get active promotions
- `GET /api/promotions/product/{productId}` - Get promotions by product
- `GET /api/promotions/health` - Service health check

### 6. Price Monitoring Service (Port 8082)
- `POST /api/price-monitoring/enable` - Enable price monitoring
- `POST /api/price-monitoring/disable` - Disable price monitoring
- `GET /api/price-monitoring/status` - Get monitoring status
- `GET /api/monitoring/products` - Get all products
- `PUT /api/monitoring/products/{id}` - Update product price

### 7. External Services
- Kafka UI: `http://localhost:8095`
- RabbitMQ Management: `http://localhost:15672`

## 🔧 Configuration

### Environment Variables
The environment file includes these pre-configured variables:
- `baseUrl`: http://localhost
- `salesPort`: 8081
- `inventoryPort`: 8083
- `consumerProducerPort`: 8084
- `promotionsPort`: 8085
- `kafkaUIPort`: 8095
- `rabbitMQPort`: 15672

### Test Data Examples

#### Create Sale
```json
{
  "codigoProducto": "PROD001",
  "cantidad": 5,
  "precioUnitario": 199.99,
  "clienteId": "CLIENT001",
  "canalVenta": "ONLINE",
  "ubicacion": "STORE_CENTRAL"
}
```

#### Create Product
```json
{
  "name": "New Product",
  "description": "Product description",
  "price": 99.99,
  "quantity": 100,
  "category": "Electronics",
  "sku": "SKU001",
  "minStockLevel": 10
}
```

#### Generate Promotion
```json
{
  "productId": "PROD001",
  "requestedBy": "SYSTEM",
  "reason": "Low sales and high stock"
}
```

## 🧪 Testing Workflow

### 1. Basic Health Check
Run the health check requests to ensure all services are running:
- Sales Producer Health
- Inventory Service Health
- Consumer-Producer Health
- Promotions Service Health

### 2. Data Setup
1. Create test products in the inventory service
2. Verify products are created successfully

### 3. End-to-End Testing
1. **Create a Sale**: Use the Sales Producer to create a new sale
2. **Check Stock Movement**: Verify the Consumer-Producer processed the sale
3. **Generate Promotion**: Create a promotion based on the sale data
4. **Verify Integration**: Check that all services communicated correctly

### 4. Kafka Message Flow Testing
1. Create a sale → triggers message to `ventas` topic
2. Consumer-Producer processes `ventas` message → sends to `stock` topic
3. Promotions service analyzes both topics → generates promotions

## 🐛 Troubleshooting

### Common Issues

1. **Connection Refused**: Ensure all services are running via docker-compose
2. **404 Not Found**: Check that the correct ports are being used
3. **Kafka Topics**: Verify topics exist using Kafka UI at http://localhost:8095
4. **Database Issues**: Check Oracle database connectivity

### Debug Commands
```bash
# Check running containers
docker-compose ps

# Check logs for a specific service
docker-compose logs pulso-vivo-sales-producer

# Restart a service
docker-compose restart pulso-vivo-sales-producer

# Check Kafka topics
docker-compose exec kafka-1 kafka-topics --list --bootstrap-server localhost:9092
```

## 🔍 Monitoring

### Kafka UI (http://localhost:8095)
- View topics: `ventas`, `stock`
- Monitor message flow
- Check consumer groups

### RabbitMQ Management (http://localhost:15672)
- Default credentials: guest/guest
- Monitor queues and exchanges
- View message rates

## 📈 Advanced Testing

### Load Testing
Use the Postman collection's "Integration Tests" folder to:
1. Create multiple sales simultaneously
2. Generate bulk promotions
3. Test system under load

### Performance Testing
- Monitor response times in Postman
- Check Kafka message throughput in Kafka UI
- Monitor database connections

## 🔐 Security Notes

- All endpoints currently accept requests without authentication
- For production, implement proper authentication and authorization
- Use HTTPS in production environments
- Secure database connections with proper credentials

## 📋 Test Checklist

### Pre-Test Setup
- [ ] Docker containers are running
- [ ] Kafka UI is accessible
- [ ] RabbitMQ Management is accessible
- [ ] Database is connected

### Basic Functionality
- [ ] All health checks pass
- [ ] Can create and retrieve products
- [ ] Can create sales
- [ ] Can generate promotions

### Integration Testing
- [ ] Sale creation triggers Kafka message
- [ ] Stock movements are recorded
- [ ] Promotions are generated based on analytics
- [ ] All services communicate correctly

### Performance Testing
- [ ] Response times are acceptable
- [ ] System handles concurrent requests
- [ ] Kafka message processing is timely
- [ ] Database performance is adequate

## 🆘 Support

If you encounter issues:
1. Check the service logs using `docker-compose logs [service-name]`
2. Verify all containers are running with `docker-compose ps`
3. Test connectivity with the simple test scripts
4. Check Kafka UI for topic and message status

## 📚 Additional Resources

- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [Spring Boot Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Postman Documentation](https://learning.postman.com/docs/getting-started/introduction/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

**Happy Testing! 🎉**
