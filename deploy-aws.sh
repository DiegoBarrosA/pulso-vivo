#!/bin/bash

# 🚀 Script de despliegue completo para Pulso Vivo en AWS
# ======================================================

set -e  # Salir si cualquier comando falla

echo "🚀 INICIANDO DESPLIEGUE DE PULSO VIVO EN AWS"
echo "============================================"

# Verificar prerequisitos
echo "🔍 Verificando prerequisitos..."

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado. Por favor instalar Docker primero."
    exit 1
fi

# Verificar Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose no está instalado. Por favor instalar Docker Compose primero."
    exit 1
fi

echo "✅ Docker y Docker Compose encontrados"

# Verificar si estamos en el directorio correcto
if [ ! -f "docker-compose-aws.yml" ]; then
    echo "❌ Archivo docker-compose-aws.yml no encontrado. Ejecutar desde el directorio raíz del proyecto."
    exit 1
fi

echo "✅ Archivos de configuración encontrados"

# Crear directorios necesarios
echo "📁 Creando directorios necesarios..."
mkdir -p logs
mkdir -p data/postgres
mkdir -p data/oracle
mkdir -p data/redis

# Configurar variables de entorno si no existen
if [ ! -f ".env" ]; then
    echo "⚙️ Creando archivo .env desde plantilla..."
    cp kong-config/azure-ad-b2c.env .env
fi

# Mostrar información del sistema
echo ""
echo "📋 INFORMACIÓN DEL SISTEMA"
echo "=========================="
echo "🖥️ SO: $(uname -s)"
echo "🏗️ Arquitectura: $(uname -m)"
echo "🐳 Docker: $(docker --version)"
echo "🏗️ Docker Compose: $(docker-compose --version)"
echo "💾 Espacio disponible: $(df -h . | tail -1 | awk '{print $4}')"
echo "🧠 Memoria disponible: $(free -h | grep '^Mem:' | awk '{print $7}')"

# Verificar recursos mínimos
available_space=$(df . | tail -1 | awk '{print $4}')
if [ "$available_space" -lt 10000000 ]; then  # 10GB en KB
    echo "⚠️ ADVERTENCIA: Espacio en disco bajo. Se recomiendan al menos 10GB libres."
fi

# Preguntar si continuar
echo ""
read -p "¿Continuar con el despliegue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Despliegue cancelado por el usuario"
    exit 1
fi

# Limpiar contenedores anteriores si existen
echo ""
echo "🧹 Limpiando contenedores anteriores..."
docker-compose -f docker-compose-aws.yml down -v 2>/dev/null || true

# Construir imágenes
echo ""
echo "🏗️ Construyendo imágenes Docker..."
docker-compose -f docker-compose-aws.yml build --no-cache

# Iniciar servicios de base de datos primero
echo ""
echo "🗄️ Iniciando servicios de base de datos..."
docker-compose -f docker-compose-aws.yml up -d kong-database oracle redis

# Esperar a que las bases de datos estén listas
echo "⏳ Esperando que las bases de datos estén listas..."
sleep 30

# Verificar que las bases de datos estén funcionando
echo "🔍 Verificando estado de las bases de datos..."
if ! docker-compose -f docker-compose-aws.yml exec kong-database pg_isready -U kong; then
    echo "❌ PostgreSQL (Kong) no está listo"
    exit 1
fi

echo "✅ Bases de datos listas"

# Ejecutar migraciones de Kong
echo ""
echo "🔄 Ejecutando migraciones de Kong..."
docker-compose -f docker-compose-aws.yml up kong-migrations

# Iniciar servicios de infraestructura
echo ""
echo "🏗️ Iniciando servicios de infraestructura..."
docker-compose -f docker-compose-aws.yml up -d zookeeper-1 zookeeper-2 zookeeper-3

# Esperar a que Zookeeper esté listo
echo "⏳ Esperando que Zookeeper esté listo..."
sleep 15

# Iniciar Kafka
echo ""
echo "📡 Iniciando cluster Kafka..."
docker-compose -f docker-compose-aws.yml up -d kafka-1 kafka-2 kafka-3

# Esperar a que Kafka esté listo
echo "⏳ Esperando que Kafka esté listo..."
sleep 20

# Crear topics de Kafka
echo ""
echo "📝 Creando topics de Kafka..."
docker-compose -f docker-compose-aws.yml up kafka-init

# Iniciar Kong
echo ""
echo "🦍 Iniciando Kong API Gateway..."
docker-compose -f docker-compose-aws.yml up -d kong

# Esperar a que Kong esté listo
echo "⏳ Esperando que Kong esté listo..."
sleep 15

# Iniciar microservicios
echo ""
echo "🔧 Iniciando microservicios..."
docker-compose -f docker-compose-aws.yml up -d \
    pulso-vivo-kafka-productor-ventas \
    pulso-vivo-inventory-service \
    pulso-vivo-kafka-consumidor-ventas-productor-stock \
    pulso-vivo-promotions-service

# Iniciar servicios de monitoreo
echo ""
echo "📊 Iniciando servicios de monitoreo..."
docker-compose -f docker-compose-aws.yml up -d kafka-ui rabbitmq

# Configurar Kong
echo ""
echo "⚙️ Configurando Kong API Gateway..."
docker-compose -f docker-compose-aws.yml up kong-config

# Esperar a que todos los servicios estén listos
echo ""
echo "⏳ Esperando que todos los servicios estén completamente listos..."
sleep 30

# Verificar estado de todos los servicios
echo ""
echo "🔍 Verificando estado de los servicios..."
docker-compose -f docker-compose-aws.yml ps

# Ejecutar tests de validación
echo ""
echo "🧪 Ejecutando tests de validación..."
if [ -f "./final-validation.sh" ]; then
    ./final-validation.sh
else
    echo "⚠️ Script de validación no encontrado, ejecutando test básico..."
    if [ -f "./simple-test.sh" ]; then
        ./simple-test.sh
    fi
fi

# Mostrar información de acceso
echo ""
echo "🎉 ¡DESPLIEGUE COMPLETADO!"
echo "========================="
echo ""
echo "🔗 ENDPOINTS DISPONIBLES:"
echo "• API Gateway: http://localhost:8000"
echo "• Kong Admin GUI: http://localhost:8002"
echo "• Kong Admin API: http://localhost:8001"
echo "• Kafka UI: http://localhost:8095"
echo "• RabbitMQ Management: http://localhost:15672"
echo ""
echo "🎯 APIS PROTEGIDAS (requieren JWT de Azure AD B2C):"
echo "• Sales: http://localhost:8000/api/sales"
echo "• Inventory: http://localhost:8000/api/inventory"
echo "• Promotions: http://localhost:8000/api/promotions"
echo "• Stock: http://localhost:8000/api/stock"
echo ""
echo "🔐 AUTENTICACIÓN:"
echo "• Issuer: https://pulsovivo.b2clogin.com/tfp/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/b2c_1_pulso_vivo_register_and_login/v2.0/"
echo "• Audience: 7549ac9c-9294-4bb3-98d6-752d12b13d81"
echo "• Header: Authorization: Bearer <JWT_TOKEN>"
echo ""
echo "📚 DOCUMENTACIÓN:"
echo "• Ver AWS-DEPLOYMENT.md para instrucciones detalladas"
echo "• Ejecutar kong-config/test-api-gateway.sh para testing"
echo ""
echo "🚀 ¡Sistema listo para usar en AWS!"

# Mostrar logs en tiempo real (opcional)
echo ""
read -p "¿Ver logs en tiempo real? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📊 Mostrando logs en tiempo real (Ctrl+C para salir)..."
    docker-compose -f docker-compose-aws.yml logs -f
fi
