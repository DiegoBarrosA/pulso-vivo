import { Injectable } from '@angular/core';
import { environment } from '../../environments/environment';

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
}

@Injectable({
  providedIn: 'root'
})
export class EnvironmentValidatorService {

  constructor() {}

  /**
   * Valida la configuración del entorno
   */
  validateEnvironment(): ValidationResult {
    const result: ValidationResult = {
      isValid: true,
      errors: [],
      warnings: []
    };

    // Validar configuración de Azure AD
    this.validateAzureAdConfig(result);
    
    // Validar configuración de API
    this.validateApiConfig(result);
    
    // Validar configuración de la aplicación
    this.validateAppConfig(result);

    // Determinar si la configuración es válida
    result.isValid = result.errors.length === 0;

    return result;
  }

  /**
   * Valida la configuración de Azure AD
   */
  private validateAzureAdConfig(result: ValidationResult): void {
    const azureAd = environment.azureAd;

    // Validar Client ID
    if (!azureAd.clientId || azureAd.clientId === 'your-azure-ad-client-id' || azureAd.clientId === 'REEMPLAZAR_CON_TU_CLIENT_ID') {
      result.errors.push('Azure AD Client ID no está configurado correctamente');
    } else if (!this.isValidGuid(azureAd.clientId)) {
      result.errors.push('Azure AD Client ID no tiene un formato válido (debe ser un GUID)');
    }

    // Validar Authority
    if (!azureAd.authority || azureAd.authority.includes('your-tenant-id') || azureAd.authority.includes('REEMPLAZAR_CON_TU_TENANT_ID')) {
      result.errors.push('Azure AD Authority no está configurado correctamente');
    } else if (!azureAd.authority.startsWith('https://login.microsoftonline.com/')) {
      result.errors.push('Azure AD Authority debe empezar con "https://login.microsoftonline.com/"');
    }

    // Validar Redirect URI
    if (!azureAd.redirectUri) {
      result.errors.push('Azure AD Redirect URI no está configurado');
    } else if (!azureAd.redirectUri.startsWith('http')) {
      result.errors.push('Azure AD Redirect URI debe ser una URL válida');
    }

    // Validar Post Logout Redirect URI
    if (!azureAd.postLogoutRedirectUri) {
      result.errors.push('Azure AD Post Logout Redirect URI no está configurado');
    } else if (!azureAd.postLogoutRedirectUri.startsWith('http')) {
      result.errors.push('Azure AD Post Logout Redirect URI debe ser una URL válida');
    }

    // Validar Scopes
    if (!azureAd.scopes || azureAd.scopes.length === 0) {
      result.errors.push('Azure AD Scopes no están configurados');
    }

    // Advertencias para desarrollo
    if (!environment.production) {
      if (azureAd.redirectUri.startsWith('http://')) {
        result.warnings.push('Usando HTTP en Redirect URI (solo recomendado para desarrollo)');
      }
      if (azureAd.postLogoutRedirectUri.startsWith('http://')) {
        result.warnings.push('Usando HTTP en Post Logout Redirect URI (solo recomendado para desarrollo)');
      }
    }
  }

  /**
   * Valida la configuración de la API
   */
  private validateApiConfig(result: ValidationResult): void {
    const api = environment.api;

    // Validar Base URL
    if (!api.baseUrl || api.baseUrl === 'https://your-bff-api-domain.com/api' || api.baseUrl === 'https://tu-bff-api-domain.com/api') {
      result.errors.push('API Base URL no está configurado correctamente');
    } else if (!api.baseUrl.startsWith('https://') && environment.production) {
      result.errors.push('API Base URL debe usar HTTPS en producción');
    } else if (!api.baseUrl.startsWith('http')) {
      result.errors.push('API Base URL debe ser una URL válida');
    }

    // Validar BFF Scopes
    if (!api.bffScopes || api.bffScopes.length === 0) {
      result.errors.push('BFF Scopes no están configurados');
    } else {
      api.bffScopes.forEach(scope => {
        if (scope.includes('your-api-client-id') || scope.includes('TU_API_CLIENT_ID')) {
          result.errors.push('BFF Scope contiene valores de placeholder sin reemplazar');
        }
      });
    }

    // Validar Timeout
    if (!api.timeout || api.timeout <= 0) {
      result.warnings.push('API Timeout no está configurado o es inválido');
    } else if (api.timeout < 5000) {
      result.warnings.push('API Timeout muy bajo (menos de 5 segundos)');
    }

    // Validar Retry Attempts
    if (!api.retryAttempts || api.retryAttempts <= 0) {
      result.warnings.push('API Retry Attempts no está configurado');
    } else if (api.retryAttempts > 5) {
      result.warnings.push('API Retry Attempts muy alto (más de 5 intentos)');
    }
  }

  /**
   * Valida la configuración de la aplicación
   */
  private validateAppConfig(result: ValidationResult): void {
    const app = environment.app;

    // Validar nombre de la aplicación
    if (!app.name || app.name.trim() === '') {
      result.warnings.push('Nombre de la aplicación no está configurado');
    }

    // Validar versión
    if (!app.version || !this.isValidSemanticVersion(app.version)) {
      result.warnings.push('Versión de la aplicación no está configurada o no es válida');
    }

    // Validar email de soporte
    if (!app.supportEmail || !this.isValidEmail(app.supportEmail)) {
      result.warnings.push('Email de soporte no está configurado o no es válido');
    }

    // Validar configuración de logging
    if (environment.production && app.enableLogging) {
      result.warnings.push('Logging habilitado en producción - considera deshabilitarlo por rendimiento');
    }

    if (app.logLevel && !['debug', 'info', 'warn', 'error'].includes(app.logLevel)) {
      result.warnings.push('Nivel de log no es válido');
    }
  }

  /**
   * Valida si una cadena es un GUID válido
   */
  private isValidGuid(value: string): boolean {
    const guidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    return guidRegex.test(value);
  }

  /**
   * Valida si una cadena es un email válido
   */
  private isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * Valida si una cadena es una versión semántica válida
   */
  private isValidSemanticVersion(version: string): boolean {
    const semverRegex = /^\d+\.\d+\.\d+(?:-[a-zA-Z0-9-]+)?(?:\+[a-zA-Z0-9-]+)?$/;
    return semverRegex.test(version);
  }

  /**
   * Obtiene un resumen de la configuración actual
   */
  getConfigurationSummary(): any {
    return {
      environment: environment.production ? 'production' : 'development',
      azureAd: {
        clientIdConfigured: environment.azureAd.clientId && !environment.azureAd.clientId.includes('your-azure-ad-client-id'),
        authorityConfigured: environment.azureAd.authority && !environment.azureAd.authority.includes('your-tenant-id'),
        redirectUriConfigured: !!environment.azureAd.redirectUri,
        scopesCount: environment.azureAd.scopes?.length || 0
      },
      api: {
        baseUrlConfigured: environment.api.baseUrl && !environment.api.baseUrl.includes('your-bff-api-domain'),
        bffScopesConfigured: environment.api.bffScopes?.length > 0 && !environment.api.bffScopes.some(s => s.includes('your-api-client-id')),
        timeout: environment.api.timeout,
        retryAttempts: environment.api.retryAttempts
      },
      app: {
        name: environment.app.name,
        version: environment.app.version,
        loggingEnabled: environment.app.enableLogging
      },
      features: environment.features
    };
  }

  /**
   * Imprime el resultado de la validación en la consola
   */
  logValidationResult(result: ValidationResult): void {
    if (!environment.app.enableLogging) {
      return;
    }

    console.group('🔧 Validación de Configuración del Entorno');
    
    if (result.isValid) {
      console.log('✅ Configuración válida');
    } else {
      console.log('❌ Configuración inválida');
    }

    if (result.errors.length > 0) {
      console.group('❌ Errores que deben ser corregidos:');
      result.errors.forEach(error => console.error(`• ${error}`));
      console.groupEnd();
    }

    if (result.warnings.length > 0) {
      console.group('⚠️  Advertencias:');
      result.warnings.forEach(warning => console.warn(`• ${warning}`));
      console.groupEnd();
    }

    console.groupEnd();
  }

  /**
   * Valida la configuración al inicializar la aplicación
   */
  validateOnStartup(): void {
    const result = this.validateEnvironment();
    this.logValidationResult(result);

    if (!result.isValid) {
      console.error('🚨 La aplicación no puede iniciarse correctamente debido a errores de configuración');
      console.info('📖 Consulta el archivo README.md para instrucciones de configuración');
      console.info('📋 Usa environment.sample.ts como referencia para la configuración');
    }
  }
}