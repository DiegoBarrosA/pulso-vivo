#!/bin/bash

# Script completo para desplegar AWS API Gateway con Pulso Vivo
# =============================================================
# Este script hace todo en una sola ejecución:
# 1. Limpia recursos fallidos
# 2. Arregla Security Groups
# 3. Crea NLB con configuración correcta
# 4. Crea VPC Link
# 5. Despliega API Gateway
# 6. Testea endpoints

set -e

# Configuración
REGION="us-east-1"
VPC_ID="vpc-00625dc06241faa07"
EC2_INSTANCE_IP="172.31.91.107"
STACK_NAME="pulso-vivo-api-gateway"

# ARNs de recursos fallidos a limpiar
OLD_NLB_ARN="arn:aws:elasticloadbalancing:us-east-1:602863085974:loadbalancer/net/pulso-vivo-nlb/0113a0e8809fac13"
OLD_VPC_LINK_ID="gpmt8d"

# Nuevos recursos creados que pueden fallar
NEW_NLB_ARN="arn:aws:elasticloadbalancing:us-east-1:602863085974:loadbalancer/net/pulso-vivo-nlb-complete/b29beb85594fae66"
NEW_VPC_LINK_ID="0p81ek"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# ==========================================
# FASE 1: LIMPIEZA DE RECURSOS FALLIDOS
# ==========================================

cleanup_failed_resources() {
    print_status "🧹 FASE 1: Limpiando recursos fallidos..."
    
    # Limpiar VPC Link fallido (old)
    print_status "Eliminando VPC Link fallido (old)..."
    aws apigateway delete-vpc-link \
        --vpc-link-id $OLD_VPC_LINK_ID \
        --region $REGION 2>/dev/null || true
    
    # Limpiar VPC Link fallido (new)
    print_status "Eliminando VPC Link fallido (new)..."
    aws apigateway delete-vpc-link \
        --vpc-link-id $NEW_VPC_LINK_ID \
        --region $REGION 2>/dev/null || true
    
    # Limpiar todos los VPC Links relacionados con pulso-vivo
    print_status "Eliminando todos los VPC Links de pulso-vivo..."
    VPC_LINKS=$(aws apigateway get-vpc-links \
        --query 'items[?contains(name, `pulso-vivo`)].id' \
        --output text \
        --region $REGION 2>/dev/null) || true
    
    for VPC_LINK in $VPC_LINKS; do
        if [ ! -z "$VPC_LINK" ] && [ "$VPC_LINK" != "None" ]; then
            print_status "Eliminando VPC Link: $VPC_LINK"
            aws apigateway delete-vpc-link \
                --vpc-link-id $VPC_LINK \
                --region $REGION 2>/dev/null || true
        fi
    done
    
    # Esperar a que se eliminen los VPC Links
    print_status "Esperando que se eliminen los VPC Links..."
    sleep 20
    
    # Limpiar NLB fallido (old)
    print_status "Eliminando Network Load Balancer fallido (old)..."
    aws elbv2 delete-load-balancer \
        --load-balancer-arn $OLD_NLB_ARN \
        --region $REGION 2>/dev/null || true
    
    # Limpiar NLB fallido (new)
    print_status "Eliminando Network Load Balancer fallido (new)..."
    aws elbv2 delete-load-balancer \
        --load-balancer-arn $NEW_NLB_ARN \
        --region $REGION 2>/dev/null || true
    
    # Limpiar todos los NLBs relacionados con pulso-vivo
    print_status "Eliminando todos los NLBs de pulso-vivo..."
    NLB_ARNS=$(aws elbv2 describe-load-balancers \
        --query 'LoadBalancers[?contains(LoadBalancerName, `pulso-vivo`)].LoadBalancerArn' \
        --output text \
        --region $REGION 2>/dev/null) || true
    
    for NLB_ARN in $NLB_ARNS; do
        if [ ! -z "$NLB_ARN" ] && [ "$NLB_ARN" != "None" ]; then
            print_status "Eliminando NLB: $NLB_ARN"
            aws elbv2 delete-load-balancer \
                --load-balancer-arn $NLB_ARN \
                --region $REGION 2>/dev/null || true
        fi
    done
    
    # Limpiar target groups antiguos
    print_status "Eliminando target groups antiguos..."
    OLD_TG_NAMES=("pulso-vivo-sales-tg" "pulso-vivo-inventory-tg" "pulso-vivo-promotions-tg" "pulso-vivo-stock-tg")
    
    for TG_NAME in "${OLD_TG_NAMES[@]}"; do
        TG_ARN=$(aws elbv2 describe-target-groups \
            --names $TG_NAME \
            --query 'TargetGroups[0].TargetGroupArn' \
            --output text \
            --region $REGION 2>/dev/null) || true
        
        if [ "$TG_ARN" != "None" ] && [ ! -z "$TG_ARN" ]; then
            aws elbv2 delete-target-group \
                --target-group-arn $TG_ARN \
                --region $REGION 2>/dev/null || true
        fi
    done
    
    # Limpiar target groups con nombres largos fallidos
    print_status "Eliminando target groups con nombres largos fallidos..."
    FAILED_TG_ARNS=$(aws elbv2 describe-target-groups \
        --query 'TargetGroups[?contains(TargetGroupName, `pulso-vivo-`) && contains(TargetGroupName, `-tg-complete`)].TargetGroupArn' \
        --output text \
        --region $REGION 2>/dev/null) || true
    
    for TG_ARN in $FAILED_TG_ARNS; do
        if [ ! -z "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
            aws elbv2 delete-target-group \
                --target-group-arn $TG_ARN \
                --region $REGION 2>/dev/null || true
            print_status "Target group fallido eliminado: $TG_ARN"
        fi
    done
    
    # Limpiar target groups con nuevos nombres fallidos
    print_status "Eliminando target groups con nuevos nombres fallidos..."
    NEW_TG_ARNS=$(aws elbv2 describe-target-groups \
        --query 'TargetGroups[?contains(TargetGroupName, `pv-`) && contains(TargetGroupName, `-tg-v2`)].TargetGroupArn' \
        --output text \
        --region $REGION 2>/dev/null) || true
    
    for TG_ARN in $NEW_TG_ARNS; do
        if [ ! -z "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
            aws elbv2 delete-target-group \
                --target-group-arn $TG_ARN \
                --region $REGION 2>/dev/null || true
            print_status "Target group nuevo fallido eliminado: $TG_ARN"
        fi
    done
    
    # Limpiar CloudFormation stack si existe
    print_status "Eliminando CloudFormation stack si existe..."
    aws cloudformation delete-stack \
        --stack-name $STACK_NAME \
        --region $REGION 2>/dev/null || true
    
    print_success "Recursos fallidos limpiados"
    sleep 10  # Esperar que se complete la limpieza
}

# ==========================================
# FASE 2: CONFIGURACIÓN DE SECURITY GROUPS
# ==========================================

fix_security_groups() {
    print_status "🔒 FASE 2: Configurando Security Groups..."
    
    # Obtener Security Group de la instancia EC2
    SG_ID=$(aws ec2 describe-instances \
        --filters "Name=private-ip-address,Values=$EC2_INSTANCE_IP" \
        --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
        --output text \
        --region $REGION)
    
    print_status "Security Group actual: $SG_ID"
    
    # Puertos necesarios para microservicios
    PORTS=(8081 8083 8084 8085)
    
    for PORT in "${PORTS[@]}"; do
        print_status "Agregando regla para puerto $PORT..."
        
        # Verificar si la regla ya existe
        EXISTING_RULE=$(aws ec2 describe-security-groups \
            --group-ids $SG_ID \
            --query "SecurityGroups[0].IpPermissions[?FromPort==\`$PORT\` && ToPort==\`$PORT\` && IpProtocol==\`tcp\`]" \
            --output text \
            --region $REGION)
        
        if [ -z "$EXISTING_RULE" ]; then
            aws ec2 authorize-security-group-ingress \
                --group-id $SG_ID \
                --protocol tcp \
                --port $PORT \
                --cidr 0.0.0.0/0 \
                --region $REGION
            print_success "Regla agregada para puerto $PORT"
        else
            print_warning "Regla para puerto $PORT ya existe"
        fi
    done
    
    # Verificar configuración final
    print_status "Verificando configuración de Security Groups..."
    aws ec2 describe-security-groups \
        --group-ids $SG_ID \
        --query 'SecurityGroups[0].IpPermissions[*].[IpProtocol,FromPort,ToPort,IpRanges[*].CidrIp]' \
        --output table \
        --region $REGION
    
    print_success "Security Groups configurados correctamente"
}

# ==========================================
# FASE 3: CREACIÓN DE NETWORK LOAD BALANCER
# ==========================================

create_network_load_balancer() {
    print_status "🏗️  FASE 3: Creando Network Load Balancer..."
    
    # Obtener subnets disponibles
    SUBNET_LIST=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
        --query 'Subnets[*].SubnetId' \
        --output text \
        --region $REGION)
    
    # Convertir a array y seleccionar hasta 3 subnets
    SUBNET_ARRAY=($SUBNET_LIST)
    SELECTED_SUBNETS=""
    
    for i in "${!SUBNET_ARRAY[@]}"; do
        if [ $i -lt 3 ]; then
            if [ -z "$SELECTED_SUBNETS" ]; then
                SELECTED_SUBNETS="${SUBNET_ARRAY[$i]}"
            else
                SELECTED_SUBNETS="$SELECTED_SUBNETS ${SUBNET_ARRAY[$i]}"
            fi
        fi
    done
    
    print_status "Usando subnets: $SELECTED_SUBNETS"
    
    # Crear NLB con timestamp para evitar conflictos
    TIMESTAMP=$(date +%s)
    NLB_NAME="pulso-vivo-nlb-$TIMESTAMP"
    
    print_status "Creando NLB con nombre único: $NLB_NAME"
    
    # Crear NLB
    NLB_ARN=$(aws elbv2 create-load-balancer \
        --name "$NLB_NAME" \
        --scheme internal \
        --type network \
        --subnets $SELECTED_SUBNETS \
        --tags Key=Name,Value=$NLB_NAME Key=Environment,Value=production \
        --query 'LoadBalancers[0].LoadBalancerArn' \
        --output text \
        --region $REGION)
    
    print_success "NLB creado: $NLB_ARN"
    
    # Esperar a que el NLB esté activo
    print_status "Esperando que NLB esté activo..."
    while true; do
        STATE=$(aws elbv2 describe-load-balancers \
            --load-balancer-arns $NLB_ARN \
            --query 'LoadBalancers[0].State.Code' \
            --output text \
            --region $REGION)
        
        if [ "$STATE" = "active" ]; then
            print_success "NLB está activo"
            break
        elif [ "$STATE" = "failed" ]; then
            print_error "NLB falló en la creación"
            exit 1
        else
            print_status "NLB state: $STATE, esperando..."
            sleep 15
        fi
    done
}

# ==========================================
# FASE 4: CREACIÓN DE TARGET GROUPS
# ==========================================

create_target_groups() {
    print_status "🎯 FASE 4: Creando Target Groups..."
    
    # Crear target groups para cada microservicio
    declare -A SERVICES=(
        ["sales"]="8081"
        ["inventory"]="8083"
        ["promotions"]="8085"
        ["stock"]="8084"
    )
    
    declare -A TARGET_GROUP_ARNS
    
    for SERVICE in "${!SERVICES[@]}"; do
        PORT=${SERVICES[$SERVICE]}
        
        print_status "Creando target group para $SERVICE (puerto $PORT)..."
        
        # Crear target group con timestamp para evitar conflictos
        TG_NAME="pv-$SERVICE-$TIMESTAMP"
        
        TG_ARN=$(aws elbv2 create-target-group \
            --name "$TG_NAME" \
            --protocol TCP \
            --port $PORT \
            --vpc-id $VPC_ID \
            --target-type ip \
            --health-check-enabled \
            --health-check-interval-seconds 30 \
            --health-check-timeout-seconds 10 \
            --healthy-threshold-count 2 \
            --unhealthy-threshold-count 2 \
            --query 'TargetGroups[0].TargetGroupArn' \
            --output text \
            --region $REGION)
        
        TARGET_GROUP_ARNS[$SERVICE]=$TG_ARN
        print_success "$SERVICE Target Group creado: $TG_ARN"
        
        # Registrar target (IP de EC2)
        aws elbv2 register-targets \
            --target-group-arn $TG_ARN \
            --targets Id=$EC2_INSTANCE_IP,Port=$PORT \
            --region $REGION
        
        print_success "Target registrado para $SERVICE"
    done
    
    # Crear listeners en el NLB
    print_status "Creando listeners en NLB..."
    
    for SERVICE in "${!SERVICES[@]}"; do
        PORT=${SERVICES[$SERVICE]}
        TG_ARN=${TARGET_GROUP_ARNS[$SERVICE]}
        
        aws elbv2 create-listener \
            --load-balancer-arn $NLB_ARN \
            --protocol TCP \
            --port $PORT \
            --default-actions Type=forward,TargetGroupArn=$TG_ARN \
            --region $REGION
        
        print_success "Listener creado para $SERVICE (puerto $PORT)"
    done
}

# ==========================================
# FASE 5: CREACIÓN DE VPC LINK
# ==========================================

create_vpc_link() {
    print_status "🔗 FASE 5: Creando VPC Link..."
    
    # Crear VPC Link con timestamp para evitar conflictos
    VPC_LINK_NAME="pulso-vivo-vpc-link-$TIMESTAMP"
    
    print_status "Creando VPC Link con nombre único: $VPC_LINK_NAME"
    
    # Crear VPC Link
    VPC_LINK_ID=$(aws apigateway create-vpc-link \
        --name "$VPC_LINK_NAME" \
        --description "VPC Link para Pulso Vivo microservices - Complete Setup $TIMESTAMP" \
        --target-arns $NLB_ARN \
        --query 'id' \
        --output text \
        --region $REGION)
    
    print_success "VPC Link creado: $VPC_LINK_ID"
    
    # Esperar a que el VPC Link esté disponible
    print_status "Esperando que VPC Link esté disponible (puede tomar 5-10 minutos)..."
    ATTEMPTS=0
    MAX_ATTEMPTS=40
    
    while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
        STATUS=$(aws apigateway get-vpc-link \
            --vpc-link-id $VPC_LINK_ID \
            --query 'status' \
            --output text \
            --region $REGION)
        
        if [ "$STATUS" = "AVAILABLE" ]; then
            print_success "VPC Link está disponible"
            break
        elif [ "$STATUS" = "FAILED" ]; then
            print_error "VPC Link falló en la creación"
            
            ERROR_MSG=$(aws apigateway get-vpc-link \
                --vpc-link-id $VPC_LINK_ID \
                --query 'statusMessage' \
                --output text \
                --region $REGION)
            
            print_error "Error message: $ERROR_MSG"
            exit 1
        else
            print_status "VPC Link status: $STATUS, esperando... (Intento $((ATTEMPTS+1))/$MAX_ATTEMPTS)"
            sleep 30
            ATTEMPTS=$((ATTEMPTS+1))
        fi
    done
    
    if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
        print_error "Timeout esperando que VPC Link esté disponible"
        exit 1
    fi
}

# ==========================================
# FASE 6: DESPLIEGUE DE API GATEWAY
# ==========================================

deploy_api_gateway() {
    print_status "🚀 FASE 6: Desplegando API Gateway..."
    
    # Verificar que el template existe
    if [ ! -f "aws-api-gateway.yml" ]; then
        print_error "Template aws-api-gateway.yml no encontrado"
        exit 1
    fi
    
    # Desplegar CloudFormation stack
    aws cloudformation deploy \
        --template-file aws-api-gateway.yml \
        --stack-name $STACK_NAME \
        --parameter-overrides \
            EC2InstanceIP=$EC2_INSTANCE_IP \
            VPCLinkId=$VPC_LINK_ID \
        --capabilities CAPABILITY_IAM \
        --region $REGION
    
    if [ $? -eq 0 ]; then
        print_success "API Gateway desplegado exitosamente"
    else
        print_error "Error al desplegar API Gateway"
        exit 1
    fi
}

# ==========================================
# FASE 7: OBTENER INFORMACIÓN DEL DEPLOYMENT
# ==========================================

get_deployment_info() {
    print_status "📋 FASE 7: Obteniendo información del deployment..."
    
    # Obtener outputs del stack
    API_GATEWAY_URL=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --query 'Stacks[0].Outputs[?OutputKey==`APIGatewayURL`].OutputValue' \
        --output text \
        --region $REGION)
    
    API_GATEWAY_ID=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --query 'Stacks[0].Outputs[?OutputKey==`APIGatewayId`].OutputValue' \
        --output text \
        --region $REGION)
    
    WAF_WEB_ACL_ARN=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --query 'Stacks[0].Outputs[?OutputKey==`WebACLArn`].OutputValue' \
        --output text \
        --region $REGION)
    
    print_success "Información del deployment obtenida"
}

# ==========================================
# FASE 8: VERIFICACIÓN DE HEALTH CHECKS
# ==========================================

check_target_health() {
    print_status "🏥 FASE 8: Verificando health de targets..."
    
    # Listar todos los target groups
    TG_ARNS=$(aws elbv2 describe-target-groups \
        --query 'TargetGroups[?contains(TargetGroupName, `pv-`) && contains(TargetGroupName, `'$TIMESTAMP'`)].TargetGroupArn' \
        --output text \
        --region $REGION)
    
    for TG_ARN in $TG_ARNS; do
        TG_NAME=$(aws elbv2 describe-target-groups \
            --target-group-arns $TG_ARN \
            --query 'TargetGroups[0].TargetGroupName' \
            --output text \
            --region $REGION)
        
        print_status "Verificando health para: $TG_NAME"
        
        aws elbv2 describe-target-health \
            --target-group-arn $TG_ARN \
            --query 'TargetHealthDescriptions[*].[Target.Id,Target.Port,TargetHealth.State,TargetHealth.Description]' \
            --output table \
            --region $REGION
    done
}

# ==========================================
# FASE 9: TESTING DE ENDPOINTS
# ==========================================

test_endpoints() {
    print_status "🧪 FASE 9: Testeando endpoints..."
    
    # Test endpoints sin autenticación (debería devolver 401)
    ENDPOINTS=("sales" "inventory" "promotions" "stock")
    
    for ENDPOINT in "${ENDPOINTS[@]}"; do
        print_status "Testing $ENDPOINT endpoint..."
        
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$API_GATEWAY_URL/$ENDPOINT" || echo "000")
        
        if [ "$RESPONSE" = "401" ]; then
            print_success "$ENDPOINT: 401 Unauthorized (correcto - requiere JWT)"
        elif [ "$RESPONSE" = "403" ]; then
            print_success "$ENDPOINT: 403 Forbidden (correcto - WAF bloqueando)"
        else
            print_warning "$ENDPOINT: $RESPONSE (verificar configuración)"
        fi
    done
}

# ==========================================
# FASE 10: GENERAR DOCUMENTACIÓN
# ==========================================

generate_documentation() {
    print_status "📚 FASE 10: Generando documentación..."
    
    cat > deployment_summary.md << EOF
# Pulso Vivo API Gateway - Deployment Summary
============================================

## 🎉 Deployment Completado Exitosamente

**Fecha:** $(date)
**Región:** $REGION

## 📋 Información del Deployment

### API Gateway
- **URL:** $API_GATEWAY_URL
- **ID:** $API_GATEWAY_ID
- **Stage:** prod

### Infraestructura
- **VPC ID:** $VPC_ID
- **VPC Link ID:** $VPC_LINK_ID
- **NLB ARN:** $NLB_ARN
- **WAF Web ACL ARN:** $WAF_WEB_ACL_ARN

### Instancia EC2
- **IP Privada:** $EC2_INSTANCE_IP
- **Security Groups:** Configurados para puertos 8081, 8083, 8084, 8085

## 🎯 Endpoints Disponibles

| Servicio | URL | Puerto |
|----------|-----|--------|
| Sales Producer | $API_GATEWAY_URL/sales | 8081 |
| Inventory Service | $API_GATEWAY_URL/inventory | 8083 |
| Promotions Service | $API_GATEWAY_URL/promotions | 8085 |
| Stock Service | $API_GATEWAY_URL/stock | 8084 |

## 🔐 Autenticación

- **Tipo:** JWT (Azure AD B2C)
- **Issuer:** https://pulsovivo.b2clogin.com/tfp/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/b2c_1_pulso_vivo_register_and_login/v2.0/
- **Audience:** 7549ac9c-9294-4bb3-98d6-752d12b13d81
- **Header:** Authorization: Bearer <JWT_TOKEN>

## 🛡️ Seguridad

- **WAF:** Habilitado con rate limiting (1000 req/5min)
- **CORS:** Configurado para todos los orígenes
- **Security Groups:** Puertos de microservicios abiertos

## 📊 Monitoreo

- **CloudWatch Logs:** /aws/apigateway/$API_GATEWAY_ID
- **CloudWatch Metrics:** Habilitadas
- **X-Ray Tracing:** Habilitado

## 🧪 Testing

### Sin Autenticación (Debe devolver 401)
\`\`\`bash
curl -X GET "$API_GATEWAY_URL/sales"
\`\`\`

### Con JWT Token
\`\`\`bash
curl -X GET "$API_GATEWAY_URL/sales" \\
  -H "Authorization: Bearer <JWT_TOKEN>"
\`\`\`

## 📝 Próximos Pasos

1. **Configurar microservicios en EC2:**
   - Conectar a la instancia EC2
   - Ejecutar \`docker-compose -f docker-compose-ec2.yml up -d\`

2. **Obtener JWT Token de Azure AD B2C:**
   - Registrar usuario en Azure AD B2C
   - Hacer login y obtener token
   - Usar token para autenticar requests

3. **Configurar dominio personalizado (opcional):**
   - Crear certificado SSL en ACM
   - Configurar dominio personalizado en API Gateway

4. **Configurar CI/CD:**
   - Configurar GitHub Actions para deployments automáticos
   - Configurar monitoring y alertas

## 🆘 Troubleshooting

### VPC Link Issues
\`\`\`bash
aws apigateway get-vpc-link --vpc-link-id $VPC_LINK_ID --region $REGION
\`\`\`

### Target Health Issues
\`\`\`bash
aws elbv2 describe-target-health --target-group-arn <target-group-arn> --region $REGION
\`\`\`

### CloudWatch Logs
\`\`\`bash
aws logs tail /aws/apigateway/$API_GATEWAY_ID --follow --region $REGION
\`\`\`

---
Generated by: Pulso Vivo Complete Deployment Script
EOF

    print_success "Documentación generada: deployment_summary.md"
}

# ==========================================
# FUNCIÓN PRINCIPAL
# ==========================================

main() {
    echo "🚀 PULSO VIVO - AWS API GATEWAY COMPLETE DEPLOYMENT"
    echo "=================================================="
    echo "Fecha: $(date)"
    echo "Región: $REGION"
    echo "VPC: $VPC_ID"
    echo "EC2 Instance: $EC2_INSTANCE_IP"
    echo ""
    
    # Verificar AWS CLI y credenciales
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI no está instalado"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "Credenciales AWS no están configuradas"
        exit 1
    fi
    
    # Ejecutar todas las fases
    cleanup_failed_resources
    fix_security_groups
    create_network_load_balancer
    create_target_groups
    create_vpc_link
    deploy_api_gateway
    get_deployment_info
    check_target_health
    test_endpoints
    generate_documentation
    
    # Resumen final
    echo ""
    echo "🎉 DEPLOYMENT COMPLETADO EXITOSAMENTE!"
    echo "====================================="
    echo ""
    echo "🔗 API Gateway URL: $API_GATEWAY_URL"
    echo "🔗 API Gateway ID: $API_GATEWAY_ID"
    echo "🔗 VPC Link ID: $VPC_LINK_ID"
    echo "🔗 NLB ARN: $NLB_ARN"
    echo ""
    echo "🎯 ENDPOINTS DISPONIBLES:"
    echo "• Sales Service: $API_GATEWAY_URL/sales"
    echo "• Inventory Service: $API_GATEWAY_URL/inventory"
    echo "• Promotions Service: $API_GATEWAY_URL/promotions"
    echo "• Stock Service: $API_GATEWAY_URL/stock"
    echo ""
    echo "🔐 AUTENTICACIÓN:"
    echo "• Header: Authorization: Bearer <JWT_TOKEN>"
    echo "• Audience: 7549ac9c-9294-4bb3-98d6-752d12b13d81"
    echo ""
    echo "📚 Ver deployment_summary.md para más detalles"
    echo ""
    echo "🚀 ¡Listo para usar!"
}

# Ejecutar script principal
main "$@"
