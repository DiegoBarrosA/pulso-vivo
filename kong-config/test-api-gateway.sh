#!/bin/bash

# Script de testing para API Gateway con Azure AD B2C JWT
# =======================================================

source /scripts/azure-ad-b2c.env

echo "🧪 TESTING API GATEWAY CON AZURE AD B2C JWT"
echo "============================================"

# Función para testear endpoint
test_endpoint() {
    local endpoint=$1
    local method=${2:-GET}
    local description=$3
    local jwt_token=$4
    
    echo ""
    echo "🔍 Testing: $description"
    echo "📍 Endpoint: $method $endpoint"
    
    if [ -n "$jwt_token" ]; then
        echo "🔐 Con JWT Token"
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
            -X $method \
            -H "Authorization: Bearer $jwt_token" \
            -H "Content-Type: application/json" \
            "$endpoint")
    else
        echo "🚫 Sin autenticación"
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
            -X $method \
            -H "Content-Type: application/json" \
            "$endpoint")
    fi
    
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    body=$(echo "$response" | sed '/HTTP_CODE:/d')
    
    case $http_code in
        200|201)
            echo "✅ SUCCESS (HTTP $http_code)"
            ;;
        401)
            echo "🔐 UNAUTHORIZED (HTTP $http_code) - JWT requerido o inválido"
            ;;
        403)
            echo "🚫 FORBIDDEN (HTTP $http_code) - JWT válido pero sin permisos"
            ;;
        404)
            echo "❓ NOT FOUND (HTTP $http_code) - Endpoint no encontrado"
            ;;
        429)
            echo "⚡ RATE LIMITED (HTTP $http_code) - Demasiadas requests"
            ;;
        500|502|503)
            echo "💥 SERVER ERROR (HTTP $http_code) - Error del servicio"
            ;;
        *)
            echo "❌ ERROR (HTTP $http_code)"
            ;;
    esac
    
    if [ ${#body} -gt 0 ] && [ ${#body} -lt 1000 ]; then
        echo "📄 Response: $body"
    fi
}

# Test 1: Verificar que Kong está funcionando
echo "🏥 Verificando estado de Kong..."
test_endpoint "http://kong:8001/status" "GET" "Kong Admin API Status"

# Test 2: Verificar endpoints sin autenticación (deberían fallar con 401)
echo ""
echo "🚫 TESTS SIN AUTENTICACIÓN (Esperando 401 Unauthorized)"
echo "--------------------------------------------------------"
test_endpoint "${SALES_API_URL}/health" "GET" "Sales Producer Health Check"
test_endpoint "${INVENTORY_API_URL}/products" "GET" "Inventory Products"
test_endpoint "${PROMOTIONS_API_URL}/active" "GET" "Active Promotions"
test_endpoint "${STOCK_API_URL}/status" "GET" "Stock Status"

# Test 3: Simular token JWT inválido
echo ""
echo "🔐 TESTS CON JWT INVÁLIDO (Esperando 401 Unauthorized)"
echo "------------------------------------------------------"
INVALID_JWT="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.invalid"
test_endpoint "${SALES_API_URL}/health" "GET" "Sales Producer con JWT inválido" "$INVALID_JWT"

# Test 4: Información sobre cómo obtener un JWT válido
echo ""
echo "📋 CÓMO OBTENER UN JWT VÁLIDO DE AZURE AD B2C"
echo "============================================="
echo "Para probar con un JWT válido, necesitas:"
echo ""
echo "1. 🌐 Ir a la URL de autorización:"
echo "   https://pulsovivo.b2clogin.com/tfp/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/b2c_1_pulso_vivo_register_and_login/oauth2/v2.0/authorize?client_id=7549ac9c-9294-4bb3-98d6-752d12b13d81&response_type=id_token&redirect_uri=YOUR_REDIRECT_URI&scope=openid&nonce=random_nonce"
echo ""
echo "2. 🔑 Después del login, obtendrás un id_token que puedes usar como JWT"
echo ""
echo "3. 🧪 Para testear con un JWT real, ejecuta:"
echo "   export VALID_JWT=\"tu_jwt_token_aqui\""
echo "   ./test-with-jwt.sh \$VALID_JWT"
echo ""

# Test 5: Verificar configuración de Kong
echo ""
echo "⚙️ VERIFICANDO CONFIGURACIÓN DE KONG"
echo "===================================="
echo "🔍 Servicios configurados:"
curl -s http://kong:8001/services | jq -r '.data[] | "• \(.name): \(.url)"'

echo ""
echo "🛤️ Rutas configuradas:"
curl -s http://kong:8001/routes | jq -r '.data[] | "• \(.name): \(.paths[0]) -> \(.service.name)"'

echo ""
echo "🔌 Plugins activos:"
curl -s http://kong:8001/plugins | jq -r '.data[] | "• \(.name): \(.config | keys | join(", "))"'

# Test 6: Verificar Rate Limiting (si está configurado)
echo ""
echo "⚡ TEST DE RATE LIMITING"
echo "======================="
echo "Enviando múltiples requests para probar rate limiting..."
for i in {1..5}; do
    echo -n "Request $i: "
    response=$(curl -s -w "%{http_code}" -o /dev/null "${API_GATEWAY_BASE_URL}/api/sales/health")
    case $response in
        401) echo "🔐 Unauthorized (esperado sin JWT)" ;;
        429) echo "⚡ Rate Limited" ;;
        *) echo "HTTP $response" ;;
    esac
done

echo ""
echo "📊 RESUMEN DE CONFIGURACIÓN"
echo "==========================="
echo "🎯 API Gateway: ${API_GATEWAY_BASE_URL}"
echo "🔐 JWT Issuer: ${JWT_ISSUER}"
echo "👥 Audience: ${JWT_AUDIENCE}"
echo "⚡ Rate Limit: ${RATE_LIMIT_MINUTE}/min, ${RATE_LIMIT_HOUR}/hour"
echo ""
echo "✅ Testing completado!"
