export const environment = {
  production: true,

  // Configuración de Azure AD B2C para Docker
  azureAd: {
    clientId: "7549ac9c-9294-4bb3-98d6-752d12b13d81", // Tu Client ID de B2C
    authority:
      "https://PulsoVivo.b2clogin.com/PulsoVivo.onmicrosoft.com/B2C_1_pulso_vivo_register_and_login", // B2C tenant y policy correctos
    redirectUri: "http://localhost:4000", // Docker port
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

  // Configuración del API (usando proxy nginx para evitar CORS)
  api: {
    baseUrl: "/api", // Use nginx proxy for Docker deployment
    timeout: 30000, // 30 segundos
    retryAttempts: 3,
    bffScopes: [
      "openid",
      "profile",
      "offline_access"
    ], // B2C API scopes - simplified for initial testing
  },

  // Configuraciones de la aplicación para Docker
  app: {
    name: "PulsoVivo (Docker)",
    version: "1.0.0",
    companyName: "PulsoVivo Medical Supplies",
    supportEmail: "soporte@pulsovivo.com",
    enableLogging: true, // Enable logging for Docker debugging
    logLevel: "info", // More verbose logging for Docker environment
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
    autoSaveInterval: 30000, // 30 segundos para Docker (balance entre dev y prod)
    exportFormats: ["csv", "excel", "pdf"],
    enableAuditLog: true,
    sessionTimeout: 7200000, // 2 horas para Docker
    maxFileUploadSize: 10485760, // 10MB
  },

  // URLs de recursos externos
  external: {
    supportUrl: "https://support.pulsovivo.com",
    documentationUrl: "https://docs.pulsovivo.com",
    termsUrl: "https://pulsovivo.com/terminos",
    privacyUrl: "https://pulsovivo.com/privacidad",
  },

  // Configuraciones de características para Docker
  features: {
    enableReports: true,
    enableNotifications: true,
    enableDarkMode: true,
    enableMultiLanguage: false,
    enableOfflineMode: false,
    enablePushNotifications: false,
    enableDebugMode: true, // Enable debug mode for Docker debugging
    enableMockData: false, // Use real API in Docker
  },

  // Configuraciones específicas para Docker
  docker: {
    enableServiceWorker: false, // Disable for easier debugging
    enableCompression: true,
    enableCaching: true,
    enableAnalytics: false, // Disable for local Docker
    enableErrorReporting: true,
    enablePerformanceMonitoring: true,
    minifyAssets: true,
    enableSecurityHeaders: true,
    nginxProxy: true, // Indicates we're using nginx proxy
    apiProxyPath: "/api", // Path that nginx will proxy
  },
};