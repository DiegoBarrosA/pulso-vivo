export const environment = {
  production: true,

  // Configuración de Azure AD B2C para producción
  azureAd: {
    clientId: "7549ac9c-9294-4bb3-98d6-752d12b13d81", // Tu Client ID de B2C
    authority:
      "https://PulsoVivo.b2clogin.com/PulsoVivo.onmicrosoft.com/B2C_1_pulso_vivo_register_and_login", // B2C tenant y policy correctos
    redirectUri: "http://localhost:4000", // Production URL
    postLogoutRedirectUri: "http://localhost:4000",
    scopes: ["openid", "profile"], // B2C scopes básicos
    // Configuraciones específicas para B2C
    knownAuthorities: ["PulsoVivo.b2clogin.com"], // B2C domain correcto
    cloudDiscoveryMetadata: "",
    authorityMetadata: "",
    navigateToLoginRequestUrl: false,
    clientCapabilities: ["CP1"],
    // B2C specific settings
    validateAuthority: false, // Important for B2C
    authorityDomain: "PulsoVivo.b2clogin.com",
    // Alternative authority formats for issuer validation
    alternativeAuthorities: [
      "https://login.microsoftonline.com/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7", // Regular AAD
      "https://sts.windows.net/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/", // STS issuer
    ],
  },

  // Configuración del API (Production)
  api: {
    baseUrl: "https://erwqz80g2d.execute-api.us-east-1.amazonaws.com/api", // Direct API URL for production
    timeout: 30000, // 30 segundos
    retryAttempts: 3,
    bffScopes: [
      "https://PulsoVivo.onmicrosoft.com/pulso-vivo-api/access",
      "openid",
      "profile",
    ], // B2C API scopes
  },

  // Configuraciones de la aplicación para producción
  app: {
    name: "PulsoVivo",
    version: "1.0.0",
    companyName: "PulsoVivo Medical Supplies",
    supportEmail: "soporte@pulsovivo.com",
    enableLogging: false, // Disable detailed logging in production
    logLevel: "error", // Only log errors in production
  },

  // Configuraciones de la tienda
  store: {
    itemsPerPage: 12,
    enableWishlist: true,
    enableReviews: true,
    defaultCurrency: "EUR",
    currencySymbol: "€",
    enableInventoryAlerts: true,
    lowStockThreshold: 10,
  },

  // Configuraciones de administración
  admin: {
    autoSaveInterval: 60000, // 1 minuto para producción
    exportFormats: ["csv", "excel", "pdf"],
    enableAuditLog: true,
    sessionTimeout: 3600000, // 1 hora en milisegundos
    maxFileUploadSize: 10485760, // 10MB
  },

  // URLs de recursos externos
  external: {
    supportUrl: "https://support.pulsovivo.com",
    documentationUrl: "https://docs.pulsovivo.com",
    termsUrl: "https://pulsovivo.com/terminos",
    privacyUrl: "https://pulsovivo.com/privacidad",
  },

  // Configuraciones de características para producción
  features: {
    enableReports: true,
    enableNotifications: true,
    enableDarkMode: false,
    enableMultiLanguage: false,
    enableOfflineMode: false,
    enablePushNotifications: false,
    enableDebugMode: false, // Disable debug mode in production
    enableMockData: false, // Disable mock data in production
  },

  // Configuraciones específicas para producción
  buildConfig: {
    enableServiceWorker: true,
    enableCompression: true,
    enableCaching: true,
    enableAnalytics: true,
    enableErrorReporting: true,
    enablePerformanceMonitoring: true,
    minifyAssets: true,
    enableSecurityHeaders: true,
  },
};
