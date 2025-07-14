import { Component, OnInit, inject, PLATFORM_ID } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { MsalInitService } from './services/msal-init.service';
import { AuthService } from './auth/auth.service';
import { environment } from '../environments/environment';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, CommonModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.less'
})
export class AppComponent implements OnInit {
  title = 'pulso-vivo-ng';
  private platformId = inject(PLATFORM_ID);
  private isBrowser = isPlatformBrowser(this.platformId);
  
  // Authentication state
  public isInitializing = true;
  public authError: string | null = null;
  
  // Window reference for template
  public window = window;

  constructor(
    private msalInitService: MsalInitService,
    private authService: AuthService
  ) {}

  async ngOnInit(): Promise<void> {
    if (this.isBrowser) {
      try {
        // Ensure MSAL is initialized
        const initialized = await this.msalInitService.ensureInitialized();
        
        if (initialized) {
          console.log('✅ PulsoVivo: MSAL initialized successfully');
          // Log diagnostic information
          this.msalInitService.logDiagnosticInfo();
          
          // Handle authentication redirect if present
          await this.handleAuthenticationRedirect();
          
        } else {
          console.warn('⚠️ PulsoVivo: MSAL initialization failed');
          this.authError = 'Authentication system failed to initialize';
        }
      } catch (error) {
        console.error('❌ PulsoVivo: Error during MSAL initialization:', error);
        this.authError = 'Authentication initialization error';
      } finally {
        // Always mark initialization as complete
        this.isInitializing = false;
      }
    } else {
      // For SSR, skip initialization
      this.isInitializing = false;
    }
  }

  private async handleAuthenticationRedirect(): Promise<void> {
    try {
      // Check if we're returning from authentication redirect
      const urlParams = new URLSearchParams(window.location.hash.substring(1));
      const hasAuthCode = urlParams.has('code') || urlParams.has('access_token') || urlParams.has('state');
      
      if (hasAuthCode) {
        if (environment.app.enableLogging) {
          console.log('[AppComponent] Handling authentication redirect...');
        }
        
        // Give MSAL time to process the redirect
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        // Check if authentication completed successfully
        const isAuthenticated = this.authService.isAuthenticated();
        
        if (isAuthenticated) {
          if (environment.app.enableLogging) {
            console.log('[AppComponent] Authentication completed successfully');
          }
          
          // Clean up URL by removing auth parameters
          this.cleanupUrl();
        } else {
          if (environment.app.enableLogging) {
            console.warn('[AppComponent] Authentication redirect processed but user not authenticated');
          }
        }
      }
    } catch (error) {
      console.error('[AppComponent] Error handling authentication redirect:', error);
    }
  }

  private cleanupUrl(): void {
    try {
      // Remove authentication parameters from URL
      const url = new URL(window.location.href);
      const hash = url.hash.substring(1);
      const params = new URLSearchParams(hash);
      
      // Remove auth-related parameters
      const authParams = ['code', 'state', 'client_info', 'access_token', 'token_type', 'expires_in', 'scope'];
      let paramsChanged = false;
      
      authParams.forEach(param => {
        if (params.has(param)) {
          params.delete(param);
          paramsChanged = true;
        }
      });
      
      if (paramsChanged) {
        const newHash = params.toString();
        const newUrl = newHash ? `${url.origin}${url.pathname}#${newHash}` : `${url.origin}${url.pathname}`;
        window.history.replaceState({}, document.title, newUrl);
        
        if (environment.app.enableLogging) {
          console.log('[AppComponent] URL cleaned up after authentication');
        }
      }
    } catch (error) {
      console.error('[AppComponent] Error cleaning up URL:', error);
    }
  }
}
