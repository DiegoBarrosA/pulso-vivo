export const environment = {
  production: false,

  // Configuración de Azure AD B2C
  azureAd: {
    // B2C Application (client) ID from Azure Portal
    clientId: "7549ac9c-9294-4bb3-98d6-752d12b13d81", // Replace with your B2C app client ID
    
    // B2C Authority URL format: https://{tenant-name}.b2clogin.com/{tenant-name}.onmicrosoft.com/{policy-name}
    authority: "https://your-tenant-name.b2clogin.com/your-tenant-name.onmicrosoft.com/B2C_1_signupsignin",
    
    // Redirect URIs
    redirectUri: "http://localhost:4000",
    postLogoutRedirectUri: "http://localhost:4000",
    
    // B2C Scopes - Format: https://{tenant-name}.onmicrosoft.com/{api-name}/{scope}
    scopes: [
      "openid", 
      "profile",
      "https://your-tenant-name.onmicrosoft.com/your-api-name/access"
    ],
    
    // B2C Specific Configuration
    knownAuthorities: ["your-tenant-name.b2clogin.com"], // Your B2C domain
    validateAuthority: false, // Important: Set to false for B2C
    authorityDomain: "your-tenant-name.b2clogin.com",
    
    // Standard SPA settings
    navigateToLoginRequestUrl: false,
    clientCapabilities: ["CP1"],
    
    // Optional: Cloud discovery and authority metadata (usually empty for B2C)
    cloudDiscoveryMetadata: "",
    authorityMetadata: "",
    
    // B2C Tenant Information
    tenantId: "82c6cf20-e689-4aa9-bedf-7acaf7c4ead7", // Your actual tenant ID
    tenantName: "your-tenant-name", // Your B2C tenant name
    
    // Policy Names (if you have multiple policies)
    policies: {
      signUpSignIn: "B2C_1_signupsignin",
      editProfile: "B2C_1_profileediting",
      resetPassword: "B2C_1_passwordreset"
    },
    
    // Issuer validation settings to handle STS vs login.microsoftonline.com
    issuerValidation: {
      // Accept both STS and login.microsoftonline.com issuers
      acceptedIssuers: [
        "https://sts.windows.net/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/",
        "https://login.microsoftonline.com/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/v2.0",
        "https://your-tenant-name.b2clogin.com/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/v2.0/"
      ],
      validateIssuer: true
    }
  },

  // Configuración del BFF API
  api: {
    baseUrl: "https://your-bff-api-domain.com/api", // Replace with your BFF URL
    timeout: 30000,
    retryAttempts: 3,
    // B2C API scopes format
    bffScopes: ["https://your-tenant-name.onmicrosoft.com/your-api-name/access"]
  },

  // Configuraciones de la aplicación
  app: {
    name: "PulsoVivo",
    version: "1.0.0",
    companyName: "PulsoVivo Medical Supplies",
    supportEmail: "soporte@pulsovivo.com",
    enableLogging: true,
    logLevel: "debug",
    // B2C specific logging
    enableB2CLogging: true
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
    autoSaveInterval: 30000,
    exportFormats: ["csv", "excel", "pdf"],
    enableAuditLog: true,
    sessionTimeout: 3600000,
    maxFileUploadSize: 10485760,
  },

  // URLs de recursos externos
  external: {
    supportUrl: "https://support.pulsovivo.com",
    documentationUrl: "https://docs.pulsovivo.com",
    termsUrl: "https://pulsovivo.com/terminos",
    privacyUrl: "https://pulsovivo.com/privacidad",
  },

  // Configuraciones de características
  features: {
    enableReports: true,
    enableNotifications: true,
    enableDarkMode: false,
    enableMultiLanguage: false,
    enableOfflineMode: false,
    enablePushNotifications: false,
    // B2C specific features
    enableB2CProfileEditing: true,
    enableB2CPasswordReset: true,
  },

  // B2C Configuration Instructions
  b2cInstructions: {
    setup: [
      "1. Replace 'your-tenant-name' with your actual B2C tenant name",
      "2. Update the clientId with your B2C application ID",
      "3. Configure the authority URL with your tenant and policy",
      "4. Update scopes to match your B2C API configuration",
      "5. Add your redirect URI to B2C app registration",
      "6. Set validateAuthority to false for B2C",
      "7. Configure knownAuthorities with your B2C domain"
    ],
    notes: [
      "B2C uses different URL format than regular Azure AD",
      "Authority includes policy name (e.g., B2C_1_signupsignin)",
      "Scopes use tenant.onmicrosoft.com format",
      "validateAuthority must be false for B2C",
      "Issuer validation may need custom handling"
    ]
  }
};