# 🚀 Pulso Vivo - Sistema Kafka Distribuido

## 📋 Descripción

**Pulso Vivo** es un sistema completo de microservicios basado en Apache Kafka que implementa un flujo de mensajería distribuida para el manejo de ventas, inventario y promociones. El sistema está diseñado con arquitectura de microservicios utilizando Spring Boot y desplegado con Docker Compose.

## 🏗️ Arquitectura del Sistema

### Componentes Principales

- **Cluster Kafka**: 3 brokers para alta disponibilidad
- **Zookeeper Ensemble**: 3 nodos para coordinación distribuida
- **Kafka UI**: Interface web para monitoreo de topics y mensajes
- **4 Microservicios Spring Boot**:
  - **Productor de Ventas** (puerto 8081)
  - **Servicio de Inventario** (puerto 8083)
  - **Consumidor-Productor** (puerto 8084)
  - **Servicio de Promociones** (puerto 8085)

### Flujo de Mensajes

```
Frontend → Productor Ventas → Topic 'ventas' → Consumidor-Productor → Topic 'stock'
Frontend → Servicio Promociones → Base de Datos
```

## 🔧 Tecnologías Utilizadas

- **Apache Kafka**: Plataforma de streaming distribuida
- **Spring Boot**: Framework para microservicios
- **Docker & Docker Compose**: Containerización y orquestación
- **Oracle Database**: Base de datos principal
- **RabbitMQ**: Mensajería adicional
- **Maven**: Gestión de dependencias
- **Angular**: Frontend (en desarrollo)

## 🚀 Inicio Rápido

### Prerrequisitos

- Docker y Docker Compose instalados
- Git
- Java 11+ (para desarrollo)
- Maven 3.6+ (para desarrollo)

### Despliegue

1. **Clonar el repositorio**:
```bash
git clone https://github.com/DiegoBarrosA/pulso-vivo.git
cd pulso-vivo
```

2. **Levantar todos los servicios**:
```bash
docker-compose up --build
```

3. **Verificar el estado del sistema**:
```bash
./final-validation.sh
```

### Servicios Disponibles

Una vez desplegado, los servicios estarán disponibles en:

- **Kafka UI**: http://localhost:8095
- **RabbitMQ Management**: http://localhost:15672
- **Productor de Ventas**: http://localhost:8081
- **Servicio de Inventario**: http://localhost:8083
- **Consumidor-Productor**: http://localhost:8084
- **Servicio de Promociones**: http://localhost:8085

## 📊 Monitoreo y Testing

### Scripts de Validación

- **`final-validation.sh`**: Validación completa del sistema
- **`simple-test.sh`**: Pruebas básicas de conectividad
- **`test-system.sh`**: Pruebas detalladas con integración

### Colección de APIs

El proyecto incluye especificaciones completas para testing:

- **Bruno Collection**: `pulso-vivo-api-spec/`
- **Postman Collection**: Disponible en la carpeta raíz

## 🐳 Arquitectura Docker

### Servicios Orquestados

```yaml
servicios:
  zookeeper: 3 nodos (puertos 2181-2183)
  kafka: 3 brokers (puertos 9092-9094)
  kafka-ui: Interface web (puerto 8095)
  microservicios: 4 servicios Spring Boot
  rabbitmq: Broker de mensajes
  oracle: Base de datos
```

### Topics Kafka

- **`ventas`**: Mensajes de ventas del frontend
- **`stock`**: Actualizaciones de inventario
- **Configuración**: 3 particiones, factor de replicación 3

## 🔄 Flujo de Trabajo

### Proceso de Ventas

1. **Frontend** envía venta al **Productor de Ventas**
2. **Productor** publica mensaje en topic `ventas`
3. **Consumidor-Productor** consume de `ventas`
4. **Consumidor-Productor** procesa y publica en topic `stock`
5. **Servicio de Inventario** actualiza el stock

### Proceso de Promociones

1. **Frontend** solicita promociones al **Servicio de Promociones**
2. **Servicio** consulta la base de datos
3. **Servicio** retorna promociones activas

## 📖 Documentación de APIs

### Endpoints Principales

#### Productor de Ventas (8081)
- `POST /sales` - Crear nueva venta
- `GET /actuator/health` - Health check

#### Servicio de Inventario (8083)
- `GET /inventory` - Consultar inventario
- `PUT /inventory/{id}` - Actualizar stock
- `GET /actuator/health` - Health check

#### Servicio de Promociones (8085)
- `GET /promotions` - Obtener promociones activas
- `POST /promotions` - Crear promoción
- `GET /actuator/health` - Health check

## 🛠️ Desarrollo

### Estructura del Proyecto

```
pulso-vivo/
├── docker-compose.yml              # Orquestación de servicios
├── pulso-vivo-api-spec/           # Especificaciones de API
├── pulso-vivo-inventory-service/   # Microservicio de inventario
├── pulso-vivo-kafka-*/            # Microservicios Kafka
├── pulso-vivo-promotions-service/ # Microservicio de promociones
├── pulso-vivo-ng/                 # Frontend Angular
└── scripts/                       # Scripts de testing
```

### Comandos Útiles

```bash
# Reconstruir servicios
docker-compose up --build

# Ver logs de un servicio
docker-compose logs -f [servicio]

# Escalar un servicio
docker-compose up --scale kafka-1=2

# Detener todos los servicios
docker-compose down

# Limpiar volúmenes
docker-compose down -v
```

## 🧪 Testing

### Ejecutar Pruebas Completas

```bash
# Validación completa del sistema
./final-validation.sh

# Pruebas de conectividad
./simple-test.sh

# Pruebas de integración
./test-system.sh
```

### Resultados Esperados

- ✅ **13/13 pruebas exitosas**
- ✅ **Todos los servicios respondiendo**
- ✅ **Flujo de mensajes Kafka operativo**
- ✅ **Integración base de datos funcional**

## 🔧 Configuración

### Variables de Entorno

El sistema utiliza las siguientes configuraciones por defecto:

```properties
# Kafka
KAFKA_BROKERS=kafka-1:9092,kafka-2:9093,kafka-3:9094
ZOOKEEPER_CONNECT=zookeeper-1:2181,zookeeper-2:2182,zookeeper-3:2183

# Database
SPRING_DATASOURCE_URL=jdbc:oracle:thin:@oracle:1521:XE
SPRING_DATASOURCE_USERNAME=system
SPRING_DATASOURCE_PASSWORD=oracle

# RabbitMQ
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672
```

## 📋 Requisitos Cumplidos

- ✅ **Cluster Kafka con 3 brokers**
- ✅ **Ensemble Zookeeper con 3 nodos**
- ✅ **Kafka UI para monitoreo**
- ✅ **Topics 'ventas' y 'stock'**
- ✅ **Microservicio productor a topic 'ventas'**
- ✅ **Microservicio consumidor de 'ventas' y productor a 'stock'**
- ✅ **Microservicio de promociones**
- ✅ **Integración con base de datos**
- ✅ **Containerización con Docker**
- ✅ **Alta disponibilidad y escalabilidad**

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## 📝 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 📞 Contacto

- **Desarrollador**: Diego Barros A.
- **Email**: diego.barros@example.com
- **LinkedIn**: [DiegoBarrosA](https://linkedin.com/in/diegobarrosa)

## 🎯 Roadmap

- [ ] Implementar métricas con Prometheus
- [ ] Agregar alertas con Grafana
- [ ] Implementar autenticación JWT
- [ ] Agregar tests unitarios y de integración
- [ ] Implementar CI/CD con GitHub Actions
- [ ] Dockerizar el frontend Angular
- [ ] Implementar circuit breakers
- [ ] Agregar documentación OpenAPI/Swagger

---

**¡Gracias por usar Pulso Vivo!** 🚀

Si encuentras algún problema o tienes sugerencias, no dudes en abrir un issue o contactarnos.
