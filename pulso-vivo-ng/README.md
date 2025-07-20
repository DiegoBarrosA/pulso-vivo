# PulsoVivo - Tienda de Implementos Médicos

Una aplicación web moderna desarrollada en Angular 19 para la gestión y venta de implementos médicos, con autenticación Azure AD y administración de inventario.

## 🏥 Características Principales

### Tienda Online
- **Catálogo de productos médicos** con filtros por categoría
- **Búsqueda avanzada** de productos
- **Interfaz en español chileno** completamente localizada
- **Diseño responsive** optimizado para móviles y escritorio
- **Sistema de estado de stock** (disponible, últimas unidades, agotado)

### Administración de Stock (Protegida)
- **Gestión completa de inventario** con CRUD de productos
- **Movimientos de stock** (entradas, salidas, ajustes)
- **Alertas de stock bajo** y productos agotados
- **Dashboard con estadísticas** en tiempo real
- **Exportación de datos** a CSV/Excel
- **Historial de movimientos** con auditoria

### Seguridad
- **Autenticación Azure AD** con MSAL
- **Protección de rutas** con guards
- **Tokens JWT** para comunicación con BFF
- **Interceptor HTTP** automático para autenticación

## 🛠️ Tecnologías Utilizadas

- **Angular 19** - Framework principal
- **TypeScript** - Lenguaje de programación
- **LESS** - Preprocesador CSS
- **Azure MSAL** - Autenticación Microsoft
- **Bootstrap Icons** - Iconografía
- **RxJS** - Programación reactiva

## 📋 Requisitos Previos

- Node.js (versión 18 o superior)
- Angular CLI 19.2.3
- Cuenta de Azure Active Directory
- Acceso a un BFF (Backend for Frontend) API

## 🚀 Instalación y Configuración

### 1. Clonar el repositorio
```bash
git clone <repository-url>
cd pulso-vivo-ng
```

### 2. Instalar dependencias
```bash
npm install
```

### 3. Configurar Azure AD

Edita el archivo `src/app/app.config.ts` y actualiza los siguientes valores:

```typescript
export function MSALInstanceFactory(): IPublicClientApplication {
  return new PublicClientApplication({
    auth: {
      clientId: 'TU_AZURE_AD_CLIENT_ID',           // Reemplazar
      authority: 'https://login.microsoftonline.com/TU_TENANT_ID', // Reemplazar
      redirectUri: 'http://localhost:4200',
      postLogoutRedirectUri: 'http://localhost:4200'
    },
    // ...
  });
}
```

### 4. Configurar URL del BFF

Edita el archivo `src/app/services/api.service.ts`:

```typescript
private readonly baseUrl = 'https://tu-bff-api-domain.com/api'; // Reemplazar
```

### 5. Configurar scopes del BFF

En `src/app/app.config.ts`, actualiza los scopes:

```typescript
protectedResourceMap.set('https://tu-api-domain.com/api/*', ['api://tu-api-client-id/access_as_user']);
```

## 🖥️ Desarrollo

### Servidor de desarrollo
```bash
ng serve
```

Navega a `http://localhost:4200/`. La aplicación se recargará automáticamente si cambias algún archivo fuente.

### Construir para producción
```bash
ng build --prod
```

Los artefactos de construcción se almacenarán en el directorio `dist/`.

## 📱 Estructura del Proyecto

```
src/
├── app/
│   ├── auth/                    # Servicios de autenticación
│   │   ├── auth.service.ts      # Servicio principal de Azure AD
│   │   └── auth.guard.ts        # Guard para proteger rutas
│   ├── components/
│   │   ├── tienda/              # Componente de la tienda
│   │   └── administracion/      # Componente de administración
│   ├── services/
│   │   └── api.service.ts       # Servicio para comunicación con BFF
│   ├── app.config.ts            # Configuración de la aplicación
│   └── app.routes.ts            # Definición de rutas
├── assets/
│   └── images/                  # Imágenes de productos
└── styles.less                  # Estilos globales
```

## 🔐 Configuración de Azure AD

### 1. Crear App Registration en Azure
1. Ve al [Portal de Azure](https://portal.azure.com)
2. Navega a "Azure Active Directory" > "App registrations"
3. Crea una nueva aplicación
4. Configura la URI de redirección: `http://localhost:4200`

### 2. Configurar Permisos
- Microsoft Graph: `User.Read`
- Tu API personalizada: `access_as_user`

### 3. Obtener Valores de Configuración
- **Client ID**: ID de la aplicación
- **Tenant ID**: ID del directorio
- **Authority**: `https://login.microsoftonline.com/{tenant-id}`

## 🏪 Uso de la Aplicación

### Tienda Pública
- Acceso libre a la vista de productos
- Filtros por categoría y búsqueda
- Información detallada de cada producto
- Estado de stock en tiempo real

### Administración (Requiere Login)
1. Hacer clic en "Iniciar Sesión"
2. Autenticarse con Azure AD
3. Acceder al panel de administración
4. Gestionar inventario y movimientos

### Funcionalidades de Administración
- **Inventario**: Crear, editar, eliminar productos
- **Movimientos**: Registrar entradas, salidas y ajustes
- **Reportes**: Estadísticas y exportación de datos
- **Alertas**: Productos con stock bajo

## 🔧 Personalización

### Agregar Nuevas Categorías
Edita los datos de muestra en `tienda.component.ts` y `administracion.component.ts`

### Modificar Estilos
Los estilos están en archivos LESS:
- `styles.less` - Estilos globales
- `tienda.component.less` - Estilos de la tienda
- `administracion.component.less` - Estilos de administración

### Agregar Nuevos Campos
Actualiza las interfaces en:
- `ProductoMedico` en `tienda.component.ts`
- `ProductoStock` en `administracion.component.ts`
- `ProductoApi` en `api.service.ts`

## 🌐 API del BFF

### Endpoints Esperados

```
GET    /api/productos                    # Obtener todos los productos
POST   /api/productos                    # Crear producto
PUT    /api/productos/{id}               # Actualizar producto
DELETE /api/productos/{id}               # Eliminar producto
GET    /api/productos/buscar?q={termino} # Buscar productos
GET    /api/movimientos                  # Obtener movimientos
POST   /api/movimientos                  # Registrar movimiento
GET    /api/categorias                   # Obtener categorías
GET    /api/reportes/estadisticas        # Estadísticas
GET    /api/reportes/exportar-inventario # Exportar CSV
```

### Formato de Respuesta
```json
{
  "data": { /* contenido */ },
  "success": true,
  "message": "Operación exitosa",
  "errors": []
}
```

## 🧪 Testing

### Ejecutar tests unitarios
```bash
ng test
```

### Ejecutar tests e2e
```bash
ng e2e
```

## 🚀 Despliegue

### Producción
1. Configurar variables de entorno de producción
2. Actualizar URLs de Azure AD y BFF
3. Construir la aplicación: `ng build --prod`
4. Desplegar el contenido de `dist/` en tu servidor web

### Variables de Entorno
Considera usar archivos de entorno para diferentes configuraciones:
- `environment.development.ts`
- `environment.production.ts`

## 📝 Notas Importantes

- **Seguridad**: Nunca hardcodees credenciales en el código
- **Tokens**: Los tokens JWT se manejan automáticamente
- **Errores**: Revisa la consola del navegador para debugging
- **CORS**: Asegúrate de que tu BFF permita el origen de tu aplicación

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 🆘 Soporte

Para soporte técnico o preguntas:
- Crear un issue en GitHub
- Contactar al equipo de desarrollo
- Revisar la documentación de Angular: https://angular.dev

## 📚 Recursos Adicionales

- [Angular Documentation](https://angular.dev)
- [Azure AD MSAL Documentation](https://docs.microsoft.com/en-us/azure/active-directory/develop/msal-overview)
- [Bootstrap Icons](https://icons.getbootstrap.com/)
- [LESS CSS](https://lesscss.org/)

---

Desarrollado con ❤️ para el sector médico