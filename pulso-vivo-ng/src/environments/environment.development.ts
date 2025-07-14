export const environment = {
  production: false,

  // Configuración de Azure AD B2C para desarrollo
  azureAd: {
    clientId: "7549ac9c-9294-4bb3-98d6-752d12b13d81", // Tu Client ID de B2C
    authority:
      "https://PulsoVivo.b2clogin.com/PulsoVivo.onmicrosoft.com/B2C_1_pulso_vivo_register_and_login", // B2C tenant y policy correctos
    redirectUri: "http://localhost:4000", // Updated to use port 4000
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

  // Configuración del API (usando proxy local para evitar CORS)
  api: {
    baseUrl: "/api", // Use proxy for development to avoid CORS issues
    timeout: 30000, // 30 segundos
    retryAttempts: 3,
    bffScopes: [
      "https://PulsoVivo.onmicrosoft.com/pulso-vivo-api/access",
      "openid",
      "profile",
    ], // B2C API scopes
  },

  // Configuraciones de la aplicación para desarrollo
  app: {
    name: "PulsoVivo (Development)",
    version: "1.0.0-dev",
    companyName: "PulsoVivo Medical Supplies",
    supportEmail: "soporte@pulsovivo.com",
    enableLogging: true, // Enable detailed logging in development
    logLevel: "debug", // 'debug' | 'info' | 'warn' | 'error'
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
    autoSaveInterval: 10000, // 10 segundos para desarrollo (más rápido)
    exportFormats: ["csv", "excel", "pdf"],
    enableAuditLog: true,
    sessionTimeout: 7200000, // 2 horas para desarrollo (más tiempo)
    maxFileUploadSize: 10485760, // 10MB
  },

  // URLs de recursos externos
  external: {
    supportUrl: "https://support.pulsovivo.com",
    documentationUrl: "https://docs.pulsovivo.com",
    termsUrl: "https://pulsovivo.com/terminos",
    privacyUrl: "https://pulsovivo.com/privacidad",
  },

  // Configuraciones de características para desarrollo
  features: {
    enableReports: true,
    enableNotifications: true,
    enableDarkMode: true, // Enable for testing
    enableMultiLanguage: false,
    enableOfflineMode: false,
    enablePushNotifications: false,
    enableDebugMode: true, // Development-specific
    enableMockData: true, // Use mock data when API is unavailable
  },

  // Configuraciones específicas para desarrollo
  development: {
    enableHotReload: true,
    enableSourceMaps: true,
    enableConsoleLogging: true,
    mockApiDelay: 500, // Simulate API delay in milliseconds
    enablePerformanceMonitoring: true,
  },
};