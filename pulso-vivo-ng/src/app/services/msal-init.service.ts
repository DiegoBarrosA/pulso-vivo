import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { MsalService } from '@azure/msal-angular';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { environment } from '../../environments/environment';


@Injectable({
  providedIn: 'root'
})
export class MsalInitService {
  private platformId = inject(PLATFORM_ID);
  private isBrowser = isPlatformBrowser(this.platformId);
  
  private initializationSubject = new BehaviorSubject<boolean>(false);
  public isInitialized$ = this.initializationSubject.asObservable();
  
  private initializationPromise: Promise<void> | null = null;
  private isInitialized = false;

  constructor(
    private msalService: MsalService
  ) {
    if (this.isBrowser) {
      this.initialize();
    }
  }

  /**
   * Inicializa MSAL de forma segura (sin reinitializar la instancia)
   */
  private async initialize(): Promise<void> {
    if (this.initializationPromise) {
      return this.initializationPromise;
    }

    this.initializationPromise = this.performInitialization();
    return this.initializationPromise;
  }

  private async performInitialization(): Promise<void> {
    try {
      // Skip MSAL initialization during SSR
      if (!this.isBrowser) {
        if (environment.app.enableLogging) {
          console.log('[MSAL Init] Skipping MSAL initialization during SSR');
        }
        this.isInitialized = true;
        this.initializationSubject.next(false);
        return;
      }

      if (environment.app.enableLogging) {
        console.log('[MSAL Init] Verificando estado de MSAL...');
      }

      // Initialize MSAL instance first - required in MSAL v2+
      if (environment.app.enableLogging) {
        console.log('[MSAL Init] Initializing MSAL instance...');
      }

      await this.msalService.instance.initialize();

      if (environment.app.enableLogging) {
        console.log('[MSAL Init] MSAL instance initialized successfully');
      }

      // Manejar promesas de redirección
      const response = await this.msalService.instance.handleRedirectPromise();
      
      if (response) {
        if (environment.app.enableLogging) {
          console.log('[MSAL Init] Respuesta de redirección recibida:', response);
        }
      }

      // Marcar como inicializado
      this.isInitialized = true;
      this.initializationSubject.next(true);

      if (environment.app.enableLogging) {
        console.log('[MSAL Init] Inicialización completa');
        
        // Log de información de cuentas
        const accounts = this.msalService.instance.getAllAccounts();
        console.log(`[MSAL Init] Cuentas encontradas: ${accounts.length}`);
        
        if (accounts.length > 0) {
          console.log(`[MSAL Init] Usuario actual: ${accounts[0].username || 'Sin nombre'}`);
        }
      }

    } catch (error) {
      console.error('[MSAL Init] Error durante la verificación:', error);
      
      // Log detallado del error para debugging adicional
      this.logDetailedError(error);
      
      // Marcar como inicializado incluso si hay error para evitar bucles
      this.isInitialized = true;
      this.initializationSubject.next(false);
      
      throw error;
    }
  }

  /**
   * Asegura que MSAL esté inicializado antes de continuar
   */
  async ensureInitialized(): Promise<boolean> {
    if (!this.isBrowser) {
      return false;
    }

    if (this.isInitialized) {
      return true;
    }

    try {
      await this.initialize();
      return this.isInitialized;
    } catch (error) {
      console.error('[MSAL Init] Error asegurando inicialización:', error);
      return false;
    }
  }

  /**
   * Verifica si MSAL está inicializado
   */
  get initialized(): boolean {
    return this.isInitialized && this.isBrowser;
  }

  /**
   * Obtiene el estado de inicialización como Observable
   */
  get initializationStatus$(): Observable<boolean> {
    return this.isInitialized$;
  }

  /**
   * Reinicia el estado del servicio (útil para debugging)
   */
  async restart(): Promise<void> {
    if (!this.isBrowser) {
      return;
    }

    this.isInitialized = false;
    this.initializationPromise = null;
    this.initializationSubject.next(false);

    // No reinicializar MSAL, solo nuestro estado interno
    await this.initialize();
  }

  /**
   * Obtiene información de diagnóstico
   */
  getDiagnosticInfo(): any {
    if (!this.isBrowser) {
      return {
        platform: 'server',
        initialized: false
      };
    }

    try {
      const accounts = this.msalService.instance.getAllAccounts();
      const config = this.msalService.instance.getConfiguration();
      
      return {
        platform: 'browser',
        initialized: this.isInitialized,
        accountsCount: accounts.length,
        activeAccount: this.msalService.instance.getActiveAccount()?.username || null,
        clientId: config.auth.clientId,
        authority: config.auth.authority,
        redirectUri: config.auth.redirectUri,
        cacheLocation: config.cache?.cacheLocation || 'unknown',
        // Información adicional para debugging
        navigateToLoginRequestUrl: config.auth.navigateToLoginRequestUrl,
        clientCapabilities: config.auth.clientCapabilities || [],
        knownAuthorities: config.auth.knownAuthorities || [],
        storeAuthStateInCookie: config.cache?.storeAuthStateInCookie,
        currentUrl: typeof window !== 'undefined' ? window.location.href : 'SSR',
        userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : 'SSR'
      };
    } catch (error) {
      return {
        platform: 'browser',
        initialized: this.isInitialized,
        error: error instanceof Error ? error.message : 'Unknown error',
        currentUrl: typeof window !== 'undefined' ? window.location.href : 'SSR',
        userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : 'SSR'
      };
    }
  }

  /**
   * Log de información de diagnóstico
   */
  logDiagnosticInfo(): void {
    if (environment.app.enableLogging) {
      const info = this.getDiagnosticInfo();
      console.group('[MSAL Init] Información de diagnóstico');
      Object.entries(info).forEach(([key, value]) => {
        console.log(`${key}:`, value);
      });
      console.groupEnd();
      

    }
  }

  /**
   * Log detallado de error para debugging
   */
  private logDetailedError(error: any): void {
    console.group('[MSAL Init] Detalles del Error:');
    console.error('Error completo:', error);
    
    if (error && typeof error === 'object') {
      console.error('Error name:', error.name);
      console.error('Error message:', error.message);
      console.error('Error code:', error.errorCode);
      console.error('Error description:', error.errorMessage);
      console.error('Error stack:', error.stack);
      
      // Log detalles específicos para errores de red
      if (error.status) {
        console.error('HTTP Status:', error.status);
      }
      if (error.response) {
        console.error('HTTP Response:', error.response);
      }
    }
    console.groupEnd();
  }

  /**
   * Ejecuta diagnóstico completo de MSAL
   */
  runFullDiagnostic(): void {
    console.group('[MSAL Init] Diagnóstico Completo');
    
    // Información general
    this.logDiagnosticInfo();
    
    console.groupEnd();
  }
}