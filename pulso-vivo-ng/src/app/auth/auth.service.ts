import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { MsalService } from '@azure/msal-angular';
import { AccountInfo, AuthenticationResult, RedirectRequest, SilentRequest } from '@azure/msal-browser';
import { Observable, BehaviorSubject } from 'rxjs';
import { environment } from '../../environments/environment';
import { MsalInitService } from '../services/msal-init.service';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private isAuthenticatedSubject = new BehaviorSubject<boolean>(false);
  public isAuthenticated$ = this.isAuthenticatedSubject.asObservable();

  private userSubject = new BehaviorSubject<AccountInfo | null>(null);
  public user$ = this.userSubject.asObservable();
  
  private platformId = inject(PLATFORM_ID);
  private isBrowser = isPlatformBrowser(this.platformId);
  
  // Prevent multiple concurrent login attempts
  private loginInProgress = false;

  constructor(
    private msalService: MsalService,
    private msalInitService: MsalInitService
  ) {
    if (this.isBrowser) {
      this.initializeAuth();
    }
  }

  private async initializeAuth(): Promise<void> {
    try {
      const initialized = await this.msalInitService.ensureInitialized();
      if (initialized) {
        // Handle redirect first, then check auth status
        await this.handleRedirectPromise();
        this.checkAuthenticationStatus();
      }
    } catch (error) {
      console.error('Error initializing auth:', error);
    }
  }

  private checkAuthenticationStatus(): void {
    if (!this.isBrowser) return;
    
    try {
      const accounts = this.msalService.instance.getAllAccounts();
      if (accounts && accounts.length > 0) {
        this.isAuthenticatedSubject.next(true);
        this.userSubject.next(accounts[0]);
        this.loginInProgress = false; // Reset login in progress flag
        
        if (environment.app.enableLogging) {
          console.log('[Auth Service] User authenticated successfully:', accounts[0].username);
          console.log('[Auth Service] Account details:', {
            username: accounts[0].username,
            homeAccountId: accounts[0].homeAccountId,
            tenantId: accounts[0].tenantId
          });
        }
      } else {
        this.isAuthenticatedSubject.next(false);
        this.userSubject.next(null);
        this.loginInProgress = false; // Reset login in progress flag
        
        if (environment.app.enableLogging) {
          console.log('[Auth Service] No authenticated accounts found');
        }
      }
    } catch (error) {
      console.error('[Auth Service] Error checking authentication status:', error);
      this.loginInProgress = false; // Reset login in progress flag
    }
  }

  /**
   * Inicia el proceso de login con Azure AD
   */
  async login(): Promise<void> {
    if (!this.isBrowser) return;
    
    // Prevent multiple concurrent login attempts
    if (this.loginInProgress) {
      if (environment.app.enableLogging) {
        console.log('Login already in progress, skipping...');
      }
      return;
    }
    
    // Check if user is already authenticated
    if (this.isAuthenticated()) {
      if (environment.app.enableLogging) {
        console.log('User already authenticated, skipping login...');
      }
      return;
    }
    
    const initialized = await this.msalInitService.ensureInitialized();
    if (!initialized) {
      console.error('MSAL not initialized, cannot login');
      return;
    }
    
    try {
      this.loginInProgress = true;
      
      const loginRequest: RedirectRequest = {
        scopes: environment.azureAd.scopes,
        prompt: 'select_account'
      };

      if (environment.app.enableLogging) {
        console.log('[Auth Service] Starting login redirect...');
      }
      
      this.msalService.loginRedirect(loginRequest);
    } catch (error) {
      console.error('[Auth Service] Error during login:', error);
      this.loginInProgress = false;
    }
  }

  /**
   * Handle redirect promise when returning from authentication
   */
  private async handleRedirectPromise(): Promise<void> {
    try {
      if (environment.app.enableLogging) {
        console.log('[Auth Service] Handling redirect promise...');
      }
      
      const response = await this.msalService.handleRedirectObservable().toPromise();
      
      if (response) {
        if (environment.app.enableLogging) {
          console.log('[Auth Service] Redirect handled successfully:', response.account?.username);
        }
        this.loginInProgress = false;
        // Update authentication state
        this.checkAuthenticationStatus();
      } else {
        if (environment.app.enableLogging) {
          console.log('[Auth Service] No redirect response');
        }
      }
    } catch (error) {
      console.error('[Auth Service] Error handling redirect:', error);
      this.loginInProgress = false;
    }
  }

  /**
   * Cierra la sesión del usuario
   */
  async logout(): Promise<void> {
    if (!this.isBrowser) return;
    
    const initialized = await this.msalInitService.ensureInitialized();
    if (!initialized) {
      console.error('MSAL not initialized, cannot logout');
      return;
    }
    
    try {
      this.msalService.logoutRedirect({
        postLogoutRedirectUri: environment.azureAd.postLogoutRedirectUri
      });
    } catch (error) {
      console.error('Error during logout:', error);
    }
  }

  /**
   * Obtiene el token de acceso actual
   */
  async getAccessToken(): Promise<string | null> {
    if (!this.isBrowser) return null;
    
    const initialized = await this.msalInitService.ensureInitialized();
    if (!initialized) {
      console.error('MSAL not initialized, cannot get access token');
      return null;
    }
    
    try {
      const account = this.msalService.instance.getAllAccounts()[0];
      if (!account) {
        return null;
      }

      const silentRequest: SilentRequest = {
        scopes: environment.azureAd.scopes,
        account: account
      };

      const response = await this.msalService.acquireTokenSilent(silentRequest).toPromise();
      return response?.accessToken || null;
    } catch (error) {
      console.error('Error al obtener token de acceso:', error);
      return null;
    }
  }

  /**
   * Obtiene el token JWT para la API del BFF
   */
  async getBffToken(): Promise<string | null> {
    if (!this.isBrowser) return null;
    
    const initialized = await this.msalInitService.ensureInitialized();
    if (!initialized) {
      console.error('MSAL not initialized, cannot get BFF token');
      return null;
    }
    
    try {
      const accounts = this.msalService.instance.getAllAccounts();
      if (!accounts || accounts.length === 0) {
        if (environment.app.enableLogging) {
          console.warn('[Auth Service] No account found, cannot get BFF token');
        }
        return null;
      }

      const account = accounts[0];
      if (environment.app.enableLogging) {
        console.log('[Auth Service] Account found:', account.username);
        console.log('[Auth Service] Requesting scopes:', environment.api.bffScopes);
      }

      // Try with configured BFF scopes first
      let response = await this.tryGetTokenWithScopes(environment.api.bffScopes, account);
      
      // If that fails, try with basic scopes
      if (!response?.accessToken) {
        if (environment.app.enableLogging) {
          console.log('[Auth Service] BFF scopes failed, trying basic scopes...');
        }
        response = await this.tryGetTokenWithScopes(['openid'], account);
      }
      
      // If still no token, try with default Azure AD scopes
      if (!response?.accessToken) {
        if (environment.app.enableLogging) {
          console.log('[Auth Service] Basic scopes failed, trying default scopes...');
        }
        response = await this.tryGetTokenWithScopes(environment.azureAd.scopes, account);
      }
      
      // If still no access token, try to get the ID token as fallback
      let finalToken = response?.accessToken;
      if (!finalToken && account.idToken) {
        if (environment.app.enableLogging) {
          console.log('[Auth Service] No access token available, using ID token as fallback');
        }
        finalToken = account.idToken;
      }
      
      if (environment.app.enableLogging) {
        console.log('[Auth Service] Final token response:', {
          hasAccessToken: !!response?.accessToken,
          hasIdToken: !!response?.idToken,
          usingIdTokenFallback: !response?.accessToken && !!account.idToken,
          tokenLength: finalToken?.length || 0,
          scopes: response?.scopes,
          expiresOn: response?.expiresOn
        });
        
        if (finalToken) {
          console.log('[Auth Service] Token preview (first 50 chars):', finalToken.substring(0, 50) + '...');
        }
      }
      
      return finalToken || null;
    } catch (error) {
      if (environment.app.enableLogging) {
        console.error('[Auth Service] Error acquiring token:', error);
        console.error('[Auth Service] Error name:', error && typeof error === 'object' && 'name' in error ? error.name : 'Unknown');
        console.error('[Auth Service] Error message:', error && typeof error === 'object' && 'message' in error ? error.message : 'No message');
      }
      
      return null;
    }
  }

  /**
   * Helper method to try getting token with specific scopes
   */
  private async tryGetTokenWithScopes(scopes: string[], account: AccountInfo): Promise<AuthenticationResult | null> {
    try {
      const silentRequest: SilentRequest = {
        scopes: scopes,
        account: account
      };

      if (environment.app.enableLogging) {
        console.log('[Auth Service] Trying scopes:', scopes);
      }

      const response = await this.msalService.acquireTokenSilent(silentRequest).toPromise();
      return response || null;
    } catch (error) {
      if (environment.app.enableLogging) {
        console.warn('[Auth Service] Failed to get token with scopes:', scopes, error);
      }
      return null;
    }
  }

  /**
   * Verifica si el usuario está autenticado
   */
  isAuthenticated(): boolean {
    if (!this.isBrowser || !this.msalInitService.initialized) return false;
    
    try {
      const accounts = this.msalService.instance.getAllAccounts();
      return accounts && accounts.length > 0;
    } catch (error) {
      console.error('Error checking authentication:', error);
      return false;
    }
  }

  /**
   * Obtiene la información del usuario actual
   */
  getCurrentUser(): AccountInfo | null {
    if (!this.isBrowser || !this.msalInitService.initialized) return null;
    
    try {
      const accounts = this.msalService.instance.getAllAccounts();
      return accounts && accounts.length > 0 ? accounts[0] : null;
    } catch (error) {
      console.error('Error getting current user:', error);
      return null;
    }
  }

  /**
   * Verifica si el usuario tiene permisos de administrador
   * Esta lógica puede personalizarse según los roles de Azure AD
   */
  isAdmin(): boolean {
    const user = this.getCurrentUser();
    // Implementar lógica de roles según tu configuración de Azure AD
    // Por ejemplo, verificar claims o grupos del usuario
    return user?.username?.includes('admin') || false;
  }
}