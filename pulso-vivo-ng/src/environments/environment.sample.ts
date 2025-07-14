export const environment = {
  production: false,
  
  // Configuración de Azure AD
  // Para obtener estos valores, ve a Azure Portal > Azure Active Directory > App registrations
  azureAd: {
    clientId: 'REEMPLAZAR_CON_TU_CLIENT_ID', // Client ID de tu aplicación en Azure AD
    authority: 'https://login.microsoftonline.com/REEMPLAZAR_CON_TU_TENANT_ID', // Tenant ID de tu organización
    redirectUri: 'http://localhost:4000', // URL de redirección después del login
    postLogoutRedirectUri: 'http://localhost:4000', // URL de redirección después del logout
    scopes: ['user.read'] // Permisos que solicita la aplicación
  },
  
  // Configuración del BFF API
  // Reemplaza con la URL de tu Backend for Frontend
  api: {
    baseUrl: 'https://tu-bff-api-domain.com/api', // URL base de tu API
    timeout: 30000, // Timeout en milisegundos (30 segundos)
    retryAttempts: 3, // Número de reintentos en caso de error
    bffScopes: ['api://TU_API_CLIENT_ID/access_as_user'] // Scope para acceder a tu BFF
  },
  
  // Configuraciones de la aplicación
  app: {
    name: 'PulsoVivo',
    version: '1.0.0',
    companyName: 'PulsoVivo Medical Supplies',
    supportEmail: 'soporte@pulsovivo.com',
    enableLogging: true, // Habilitar logs en desarrollo
    logLevel: 'debug' // Nivel de log: 'debug' | 'info' | 'warn' | 'error'
  },
  
  // Configuraciones de la tienda
  store: {
    itemsPerPage: 12, // Productos por página
    enableWishlist: true, // Habilitar lista de deseos
    enableReviews: true, // Habilitar reseñas de productos
    defaultCurrency: 'EUR', // Moneda por defecto
    currencySymbol: '€', // Símbolo de la moneda
    enableInventoryAlerts: true, // Alertas de inventario
    lowStockThreshold: 10 // Umbral de stock bajo
  },
  
  // Configuraciones de administración
  admin: {
    autoSaveInterval: 30000, // Intervalo de autoguardado en ms (30 segundos)
    exportFormats: ['csv', 'excel', 'pdf'], // Formatos de exportación disponibles
    enableAuditLog: true, // Habilitar log de auditoría
    sessionTimeout: 3600000, // Timeout de sesión en ms (1 hora)
    maxFileUploadSize: 10485760 // Tamaño máximo de archivo en bytes (10MB)
  },
  
  // URLs de recursos externos
  external: {
    supportUrl: 'https://support.pulsovivo.com',
    documentationUrl: 'https://docs.pulsovivo.com',
    termsUrl: 'https://pulsovivo.com/terminos',
    privacyUrl: 'https://pulsovivo.com/privacidad'
  },
  
  // Configuraciones de características (feature flags)
  features: {
    enableReports: true, // Habilitar reportes avanzados
    enableNotifications: true, // Habilitar notificaciones
    enableDarkMode: false, // Tema oscuro (futuro)
    enableMultiLanguage: false, // Múltiples idiomas (futuro)
    enableOfflineMode: false, // Modo offline (futuro)
    enablePushNotifications: false // Notificaciones push (futuro)
  }
};

/*
INSTRUCCIONES DE CONFIGURACIÓN:

1. Copia este archivo como 'environment.ts' para desarrollo
2. Crea también 'environment.prod.ts' para producción
3. Actualiza los valores marcados con "REEMPLAZAR_CON_TU_..."

CONFIGURACIÓN DE AZURE AD:
- Ve a https://portal.azure.com
- Azure Active Directory > App registrations
- Crea una nueva aplicación o usa una existente
- Copia el "Application (client) ID" como clientId
- Copia el "Directory (tenant) ID" del directorio
- Configura las URI de redirección en "Authentication"

CONFIGURACIÓN DEL BFF:
- Reemplaza la URL base con la de tu Backend for Frontend
- Asegúrate de que el BFF esté configurado para aceptar tokens de Azure AD
- El scope debe coincidir con el configurado en tu BFF

CONFIGURACIÓN DE PRODUCCIÓN:
- En producción, cambia production: true
- Usa URLs HTTPS para redirectUri y postLogoutRedirectUri
- Considera timeouts más conservadores
- Deshabilita logging detallado
*/