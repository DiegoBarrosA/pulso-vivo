#!/bin/bash

# Configuración de Kong API Gateway para Azure AD B2C JWT
# Configuración específica para Pulso Vivo

KONG_ADMIN_URL="http://kong:8001"

echo "🚀 Configurando Kong API Gateway para Azure AD B2C..."

# Esperar a que Kong esté listo
while ! curl -s ${KONG_ADMIN_URL}/status > /dev/null; do
    echo "Esperando que Kong esté listo..."
    sleep 5
done

echo "✅ Kong está listo. Configurando servicios y rutas..."

# 1. Crear Consumer para JWT
echo "📝 Creando consumer para JWT..."
curl -X POST ${KONG_ADMIN_URL}/consumers \
  -H "Content-Type: application/json" \
  -d '{
    "username": "azure-ad-b2c-users",
    "custom_id": "azure-ad-b2c"
  }'

# 2. Configurar JWT Consumer con Azure AD B2C
echo "🔐 Configurando JWT consumer con Azure AD B2C..."
curl -X POST ${KONG_ADMIN_URL}/consumers/azure-ad-b2c-users/jwt \
  -H "Content-Type: application/json" \
  -d '{
    "key": "7549ac9c-9294-4bb3-98d6-752d12b13d81",
    "algorithm": "RS256",
    "rsa_public_key": "",
    "secret": ""
  }'

# 3. Crear servicio para Sales Producer
echo "🏢 Creando servicio Sales Producer..."
curl -X POST ${KONG_ADMIN_URL}/services \
  -H "Content-Type: application/json" \
  -d '{
    "name": "sales-producer-service",
    "url": "http://pulso-vivo-kafka-productor-ventas:8081"
  }'

# 4. Crear ruta para Sales Producer
echo "🛤️ Creando ruta Sales Producer..."
curl -X POST ${KONG_ADMIN_URL}/services/sales-producer-service/routes \
  -H "Content-Type: application/json" \
  -d '{
    "name": "sales-producer-route",
    "paths": ["/api/sales"],
    "methods": ["GET", "POST", "PUT", "DELETE"],
    "strip_path": false
  }'

# 5. Crear servicio para Inventory Service
echo "🏢 Creando servicio Inventory..."
curl -X POST ${KONG_ADMIN_URL}/services \
  -H "Content-Type: application/json" \
  -d '{
    "name": "inventory-service",
    "url": "http://pulso-vivo-inventory-service:8083"
  }'

# 6. Crear ruta para Inventory Service
echo "🛤️ Creando ruta Inventory..."
curl -X POST ${KONG_ADMIN_URL}/services/inventory-service/routes \
  -H "Content-Type: application/json" \
  -d '{
    "name": "inventory-route",
    "paths": ["/api/inventory"],
    "methods": ["GET", "POST", "PUT", "DELETE"],
    "strip_path": false
  }'

# 7. Crear servicio para Promotions Service
echo "🏢 Creando servicio Promotions..."
curl -X POST ${KONG_ADMIN_URL}/services \
  -H "Content-Type: application/json" \
  -d '{
    "name": "promotions-service",
    "url": "http://pulso-vivo-promotions-service:8085"
  }'

# 8. Crear ruta para Promotions Service
echo "🛤️ Creando ruta Promotions..."
curl -X POST ${KONG_ADMIN_URL}/services/promotions-service/routes \
  -H "Content-Type: application/json" \
  -d '{
    "name": "promotions-route",
    "paths": ["/api/promotions"],
    "methods": ["GET", "POST", "PUT", "DELETE"],
    "strip_path": false
  }'

# 9. Crear servicio para Consumer-Producer Service
echo "🏢 Creando servicio Consumer-Producer..."
curl -X POST ${KONG_ADMIN_URL}/services \
  -H "Content-Type: application/json" \
  -d '{
    "name": "consumer-producer-service",
    "url": "http://pulso-vivo-kafka-consumidor-ventas-productor-stock:8084"
  }'

# 10. Crear ruta para Consumer-Producer Service
echo "🛤️ Creando ruta Consumer-Producer..."
curl -X POST ${KONG_ADMIN_URL}/services/consumer-producer-service/routes \
  -H "Content-Type: application/json" \
  -d '{
    "name": "consumer-producer-route",
    "paths": ["/api/stock"],
    "methods": ["GET", "POST", "PUT", "DELETE"],
    "strip_path": false
  }'

# 11. Configurar JWT Plugin globalmente con Azure AD B2C
echo "🔐 Configurando plugin JWT global con Azure AD B2C..."
curl -X POST ${KONG_ADMIN_URL}/plugins \
  -H "Content-Type: application/json" \
  -d '{
    "name": "jwt",
    "config": {
      "uri_param_names": ["jwt"],
      "header_names": ["Authorization"],
      "claims_to_verify": ["exp", "aud", "iss"],
      "key_claim_name": "aud",
      "anonymous": null,
      "run_on_preflight": true,
      "maximum_expiration": 3600,
      "algorithm": "RS256",
      "issuer": "https://pulsovivo.b2clogin.com/tfp/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/b2c_1_pulso_vivo_register_and_login/v2.0/",
      "audience": "7549ac9c-9294-4bb3-98d6-752d12b13d81"
    }
  }'

# 12. Configurar Rate Limiting
echo "⚡ Configurando rate limiting..."
curl -X POST ${KONG_ADMIN_URL}/plugins \
  -H "Content-Type: application/json" \
  -d '{
    "name": "rate-limiting",
    "config": {
      "minute": 100,
      "hour": 1000,
      "policy": "redis",
      "redis_host": "redis",
      "redis_port": 6379,
      "redis_database": 0,
      "fault_tolerant": true
    }
  }'

# 13. Configurar CORS
echo "🌐 Configurando CORS..."
curl -X POST ${KONG_ADMIN_URL}/plugins \
  -H "Content-Type: application/json" \
  -d '{
    "name": "cors",
    "config": {
      "origins": ["*"],
      "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
      "headers": ["Accept", "Accept-Version", "Content-Length", "Content-MD5", "Content-Type", "Date", "X-Auth-Token", "Authorization"],
      "exposed_headers": ["X-Auth-Token"],
      "credentials": true,
      "max_age": 3600
    }
  }'

# 14. Configurar Request Logging
echo "📊 Configurando logging..."
curl -X POST ${KONG_ADMIN_URL}/plugins \
  -H "Content-Type: application/json" \
  -d '{
    "name": "file-log",
    "config": {
      "path": "/tmp/access.log",
      "reopen": true
    }
  }'

# 15. Configurar Health Check para servicios
echo "🏥 Configurando health checks..."
curl -X POST ${KONG_ADMIN_URL}/services/sales-producer-service/plugins \
  -H "Content-Type: application/json" \
  -d '{
    "name": "http-log",
    "config": {
      "http_endpoint": "http://localhost:8001/health-check",
      "method": "POST",
      "timeout": 1000,
      "keepalive": 1000
    }
  }'

echo "✅ Configuración de Kong completada!"
echo ""
echo "🎯 ENDPOINTS CONFIGURADOS:"
echo "================================"
echo "🔗 API Gateway: http://localhost:8000"
echo "🔗 Kong Admin: http://localhost:8001"
echo "🔗 Kong GUI: http://localhost:8002"
echo ""
echo "📋 SERVICIOS EXPUESTOS:"
echo "• Sales Producer: http://localhost:8000/api/sales"
echo "• Inventory Service: http://localhost:8000/api/inventory"
echo "• Promotions Service: http://localhost:8000/api/promotions"
echo "• Consumer-Producer: http://localhost:8000/api/stock"
echo ""
echo "🔐 AUTENTICACIÓN:"
echo "• Issuer: https://pulsovivo.b2clogin.com/tfp/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/b2c_1_pulso_vivo_register_and_login/v2.0/"
echo "• Audience: 7549ac9c-9294-4bb3-98d6-752d12b13d81"
echo "• Header: Authorization: Bearer <JWT_TOKEN>"
echo ""
echo "⚡ RATE LIMITING:"
echo "• 100 requests/minute"
echo "• 1000 requests/hour"
echo ""
echo "🌐 CORS habilitado para todos los orígenes"
echo "📊 Logging habilitado en /tmp/access.log"
