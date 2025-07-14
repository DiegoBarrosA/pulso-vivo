import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { CanActivate, Router } from '@angular/router';
import { Observable, of } from 'rxjs';
import { map, catchError, timeout, first } from 'rxjs/operators';
import { isPlatformBrowser } from '@angular/common';
import { AuthService } from '../auth/auth.service';
import { MsalInitService } from '../services/msal-init.service';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class AuthInitGuard implements CanActivate {
  private platformId = inject(PLATFORM_ID);
  private isBrowser = isPlatformBrowser(this.platformId);

  constructor(
    private authService: AuthService,
    private msalInitService: MsalInitService,
    private router: Router
  ) {}

  canActivate(): Observable<boolean> {
    // Allow access during SSR
    if (!this.isBrowser) {
      return of(true);
    }

    if (environment.app.enableLogging) {
      console.log('[AuthInitGuard] Checking authentication initialization...');
    }

    // Check if MSAL is initialized and handle authentication
    return new Observable<boolean>(observer => {
      this.initializeAuthentication()
        .then(result => {
          observer.next(result);
          observer.complete();
        })
        .catch(error => {
          console.error('[AuthInitGuard] Error during authentication initialization:', error);
          observer.next(true); // Allow access even if auth fails to prevent blocking
          observer.complete();
        });
    }).pipe(
      timeout(15000), // 15 second timeout
      catchError(error => {
        console.error('[AuthInitGuard] Timeout or error in authentication guard:', error);
        return of(true); // Allow access on timeout/error
      })
    );
  }

  private async initializeAuthentication(): Promise<boolean> {
    try {
      // Ensure MSAL is initialized
      const initialized = await this.msalInitService.ensureInitialized();
      if (!initialized) {
        console.warn('[AuthInitGuard] MSAL failed to initialize');
        return true; // Allow access anyway
      }

      if (environment.app.enableLogging) {
        console.log('[AuthInitGuard] MSAL initialized successfully');
      }

      // Check if user is already authenticated
      const isAuthenticated = this.authService.isAuthenticated();
      
      if (isAuthenticated) {
        if (environment.app.enableLogging) {
          console.log('[AuthInitGuard] User is already authenticated');
        }
        return true;
      }

      // Check if we're returning from a redirect (has code/state in URL)
      const urlParams = new URLSearchParams(window.location.hash.substring(1));
      const hasAuthCode = urlParams.has('code') || urlParams.has('access_token');
      
      if (hasAuthCode) {
        if (environment.app.enableLogging) {
          console.log('[AuthInitGuard] Handling authentication redirect...');
        }
        
        // Wait a bit for MSAL to process the redirect
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        // Check authentication status again
        const isAuthenticatedAfterRedirect = this.authService.isAuthenticated();
        
        if (environment.app.enableLogging) {
          console.log('[AuthInitGuard] Authentication status after redirect:', isAuthenticatedAfterRedirect);
        }
        
        return true; // Always allow access after redirect processing
      }

      // For unauthenticated users without auth code, allow access
      // The individual components/services will handle authentication as needed
      if (environment.app.enableLogging) {
        console.log('[AuthInitGuard] User not authenticated, but allowing access');
      }
      
      return true;

    } catch (error) {
      console.error('[AuthInitGuard] Error in authentication initialization:', error);
      return true; // Allow access even on error
    }
  }
}