import { ApplicationConfig, provideZoneChangeDetection, PLATFORM_ID, inject, LOCALE_ID } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptorsFromDi, withFetch } from '@angular/common/http';
import { isPlatformBrowser, registerLocaleData } from '@angular/common';
import { BrowserCacheLocation, IPublicClientApplication, InteractionType, PublicClientApplication } from '@azure/msal-browser';
import { MsalService, MSAL_INSTANCE, MSAL_GUARD_CONFIG, MSAL_INTERCEPTOR_CONFIG, MsalGuardConfiguration, MsalInterceptorConfiguration, MsalInterceptor } from '@azure/msal-angular';
import localeEs from '@angular/common/locales/es';

import { routes } from './app.routes';
import { provideClientHydration, withEventReplay } from '@angular/platform-browser';
import { environment } from '../environments/environment';

// Register Spanish locale
registerLocaleData(localeEs, 'es');

// MSAL Configuration
export function MSALInstanceFactory(): IPublicClientApplication {
  const platformId = inject(PLATFORM_ID);
  
  if (isPlatformBrowser(platformId)) {
    try {
      const msalInstance = new PublicClientApplication({
        auth: {
          clientId: environment.azureAd.clientId,
          authority: environment.azureAd.authority,
          redirectUri: environment.azureAd.redirectUri,
          postLogoutRedirectUri: environment.azureAd.postLogoutRedirectUri,
          navigateToLoginRequestUrl: environment.azureAd.navigateToLoginRequestUrl,
          clientCapabilities: environment.azureAd.clientCapabilities,
          knownAuthorities: environment.azureAd.knownAuthorities,
          cloudDiscoveryMetadata: environment.azureAd.cloudDiscoveryMetadata,
          authorityMetadata: environment.azureAd.authorityMetadata
        },
        cache: {
          cacheLocation: BrowserCacheLocation.LocalStorage,
          storeAuthStateInCookie: false,
          secureCookies: false
        },
        system: {
          loggerOptions: {
            loggerCallback: (level: any, message: string, containsPii: boolean) => {
              if (environment.app.enableLogging && !containsPii) {
                console.log(`[MSAL] ${message}`);
              }
            },
            piiLoggingEnabled: false,
            logLevel: environment.app.enableLogging ? 2 : 0 // Info level when logging enabled
          },
          // Custom token validation for B2C issuer handling
          tokenRenewalOffsetSeconds: 300,
          iframeHashTimeout: 6000,
          loadFrameTimeout: 0
        }
      });
      
      // MSAL instance created here - initialization will be handled by MsalInitService
      // This prevents the "multiple instance" warning while ensuring proper initialization flow
      if (environment.app.enableLogging) {
        console.log('✅ PulsoVivo: MSAL initialized successfully');
      }
      
      return msalInstance;
    } catch (error) {
      console.error('Error creating MSAL instance:', error);
      throw error;
    }
  } else {
    // Return a mock instance for SSR
    return {
      initialize: () => Promise.resolve(),
      getAllAccounts: () => [],
      getAccountByHomeId: () => null,
      getAccountByLocalId: () => null,
      getAccountByUsername: () => null,
      acquireTokenSilent: () => Promise.reject('SSR mode'),
      acquireTokenPopup: () => Promise.reject('SSR mode'),
      acquireTokenRedirect: () => Promise.reject('SSR mode'),
      loginPopup: () => Promise.reject('SSR mode'),
      loginRedirect: () => Promise.reject('SSR mode'),
      logout: () => Promise.reject('SSR mode'),
      logoutRedirect: () => Promise.reject('SSR mode'),
      logoutPopup: () => Promise.reject('SSR mode'),
      ssoSilent: () => Promise.reject('SSR mode'),
      addEventCallback: () => '',
      removeEventCallback: () => {},
      getConfiguration: () => ({}),
      getLogger: () => null,
      setLogger: () => {},
      initializeWrapperLibrary: () => {},
      setNavigationClient: () => {},
      getTokenCache: () => ({} as any),
      clearCache: () => Promise.resolve(),
      setActiveAccount: () => {},
      getActiveAccount: () => null,
      hydrateCache: () => Promise.resolve(),
      handleRedirectPromise: () => Promise.resolve(null)
    } as any;
  }
}

export function MSALGuardConfigFactory(): MsalGuardConfiguration {
  return {
    interactionType: InteractionType.Redirect,
    authRequest: {
      scopes: environment.azureAd.scopes
    }
  };
}

export function MSALInterceptorConfigFactory(): MsalInterceptorConfiguration {
  const protectedResourceMap = new Map<string, Array<string>>();
  protectedResourceMap.set('https://graph.microsoft.com/v1.0/me', environment.azureAd.scopes);
  // Match both proxy requests (/api/*) and direct API calls to AWS
  protectedResourceMap.set('/api/*', environment.api.bffScopes);
  protectedResourceMap.set('https://erwqz80g2d.execute-api.us-east-1.amazonaws.com/*', environment.api.bffScopes);

  return {
    interactionType: InteractionType.Redirect,
    protectedResourceMap
  };
}

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }), 
    provideRouter(routes), 
    provideClientHydration(withEventReplay()),
    provideHttpClient(withInterceptorsFromDi(), withFetch()),
    {
      provide: LOCALE_ID,
      useValue: 'es'
    },
    {
      provide: MSAL_INSTANCE,
      useFactory: MSALInstanceFactory,
      deps: [PLATFORM_ID]
    },
    {
      provide: MSAL_GUARD_CONFIG,
      useFactory: MSALGuardConfigFactory
    },
    {
      provide: MSAL_INTERCEPTOR_CONFIG,
      useFactory: MSALInterceptorConfigFactory
    },
    MsalService,
    MsalInterceptor
  ]
};
