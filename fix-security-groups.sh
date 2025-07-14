#!/bin/bash

# Script para arreglar Security Groups para microservicios Pulso Vivo
# ===================================================================

set -e

REGION="us-east-1"
VPC_ID="vpc-00625dc06241faa07"
EC2_INSTANCE_IP="172.31.91.107"
SG_ID="sg-0c47f9d4c79369fe5"

# Colores
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

# Función para agregar reglas de ingress
add_security_group_rules() {
    print_status "Agregando reglas de seguridad para microservicios..."
    
    # Puertos necesarios para los microservicios
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
            # Agregar regla para el puerto
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
}

# Función para verificar que los puertos estén abiertos
verify_security_group_rules() {
    print_status "Verificando reglas de seguridad..."
    
    aws ec2 describe-security-groups \
        --group-ids $SG_ID \
        --query 'SecurityGroups[0].IpPermissions[*].[IpProtocol,FromPort,ToPort,IpRanges[*].CidrIp]' \
        --output table \
        --region $REGION
}

# Función para testear conectividad a los puertos
test_microservice_connectivity() {
    print_status "Testeando conectividad a microservicios..."
    
    PORTS=(8081 8083 8084 8085)
    
    for PORT in "${PORTS[@]}"; do
        print_status "Testeando conectividad al puerto $PORT..."
        
        # Usar netcat para testear si el puerto está abierto
        if timeout 5 bash -c "echo >/dev/tcp/$EC2_INSTANCE_IP/$PORT" 2>/dev/null; then
            print_success "Puerto $PORT está accesible"
        else
            print_warning "Puerto $PORT no está accesible (puede ser que el servicio no esté ejecutándose)"
        fi
    done
}

# Función para crear security group específico para microservicios
create_microservices_security_group() {
    print_status "Creando Security Group específico para microservicios..."
    
    # Crear nuevo security group
    MS_SG_ID=$(aws ec2 create-security-group \
        --group-name pulso-vivo-microservices-sg \
        --description "Security Group para microservicios Pulso Vivo" \
        --vpc-id $VPC_ID \
        --query 'GroupId' \
        --output text \
        --region $REGION)
    
    print_success "Security Group creado: $MS_SG_ID"
    
    # Agregar reglas para microservicios
    PORTS=(8081 8083 8084 8085)
    
    for PORT in "${PORTS[@]}"; do
        aws ec2 authorize-security-group-ingress \
            --group-id $MS_SG_ID \
            --protocol tcp \
            --port $PORT \
            --cidr 0.0.0.0/0 \
            --region $REGION
        
        print_success "Regla agregada para puerto $PORT en nuevo SG"
    done
    
    # Agregar reglas para SSH y HTTP
    aws ec2 authorize-security-group-ingress \
        --group-id $MS_SG_ID \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0 \
        --region $REGION
    
    aws ec2 authorize-security-group-ingress \
        --group-id $MS_SG_ID \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 \
        --region $REGION
    
    aws ec2 authorize-security-group-ingress \
        --group-id $MS_SG_ID \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0 \
        --region $REGION
    
    print_success "Security Group configurado completamente: $MS_SG_ID"
    
    return $MS_SG_ID
}

# Función para asignar security group a la instancia EC2
assign_security_group_to_instance() {
    local NEW_SG_ID=$1
    
    print_status "Asignando nuevo Security Group a la instancia EC2..."
    
    # Obtener instance ID
    INSTANCE_ID=$(aws ec2 describe-instances \
        --filters "Name=private-ip-address,Values=$EC2_INSTANCE_IP" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text \
        --region $REGION)
    
    print_status "Instance ID: $INSTANCE_ID"
    
    # Asignar nuevo security group (mantener el existente también)
    aws ec2 modify-instance-attribute \
        --instance-id $INSTANCE_ID \
        --groups $SG_ID $NEW_SG_ID \
        --region $REGION
    
    print_success "Security Group asignado a la instancia"
}

# Función para generar script de instalación de microservicios
generate_microservices_setup() {
    print_status "Generando script de setup para microservicios..."
    
    cat > microservices_setup.sh << 'EOF'
#!/bin/bash

# Script para instalar y ejecutar microservicios Pulso Vivo en EC2
# ================================================================

set -e

echo "🚀 Instalando microservicios Pulso Vivo..."

# Instalar Docker si no está instalado
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    sudo yum update -y
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -a -G docker ec2-user
fi

# Instalar Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Instalando Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Clonar repositorio si no existe
if [ ! -d "pulso-vivo" ]; then
    echo "Clonando repositorio..."
    git clone https://github.com/DiegoBarrosA/pulso-vivo.git
fi

cd pulso-vivo

# Ejecutar microservicios
echo "Ejecutando microservicios..."
docker-compose -f docker-compose-ec2.yml up -d

# Verificar que los servicios estén ejecutándose
echo "Verificando servicios..."
docker-compose -f docker-compose-ec2.yml ps

echo "✅ Microservicios instalados y ejecutándose"
echo ""
echo "🎯 Puertos expuestos:"
echo "• Sales Service: 8081"
echo "• Inventory Service: 8083"
echo "• Stock Service: 8084"
echo "• Promotions Service: 8085"
echo ""
echo "🔍 Para verificar logs:"
echo "docker-compose -f docker-compose-ec2.yml logs -f <service-name>"
EOF

    chmod +x microservices_setup.sh
    print_success "Script de setup generado: microservices_setup.sh"
}

# Función principal
main() {
    print_status "🔧 Arreglando configuración de Security Groups..."
    
    # Opción 1: Agregar reglas al SG existente
    print_status "Opción 1: Agregar reglas al Security Group existente"
    add_security_group_rules
    verify_security_group_rules
    
    echo ""
    print_status "Opción 2: Crear nuevo Security Group específico"
    create_microservices_security_group
    NEW_SG_ID=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=pulso-vivo-microservices-sg" \
        --query 'SecurityGroups[0].GroupId' \
        --output text \
        --region $REGION)
    
    assign_security_group_to_instance $NEW_SG_ID
    
    echo ""
    test_microservice_connectivity
    generate_microservices_setup
    
    print_success "🎉 Security Groups configurados correctamente!"
    
    echo ""
    echo "📋 SIGUIENTE PASO:"
    echo "=================="
    echo "1. Conectar a tu instancia EC2:"
    echo "   ssh -i tu-key.pem ec2-user@<public-ip>"
    echo ""
    echo "2. Ejecutar el script de setup:"
    echo "   ./microservices_setup.sh"
    echo ""
    echo "3. Verificar que los microservicios estén ejecutándose:"
    echo "   curl http://localhost:8081/health"
    echo "   curl http://localhost:8083/health"
    echo "   curl http://localhost:8084/health"
    echo "   curl http://localhost:8085/health"
    echo ""
    echo "4. Una vez que los microservicios estén ejecutándose,"
    echo "   puedes continuar con el script de VPC Link."
}

# Ejecutar función principal
main "$@"
