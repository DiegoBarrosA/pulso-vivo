# PulsoVivo Angular - Build Troubleshooting Guide

## 🔧 Build Issues Fixed

This document outlines the Docker build issues encountered and the fixes applied to resolve them.

## 🚨 Build Error Analysis

### Original Error:
```
❯ Building...
✔ Building...
Browser bundles
[... bundle output ...]

Prerendered 3 static routes.
Application bundle generation failed. [11.371 seconds]

✘ [ERROR] An error occurred while prerendering route '/tienda'.
Unable to handle request: '/api/inventory/products'.

✘ [ERROR] An error occurred while prerendering route '/'.
Terminating worker thread

✘ [ERROR] An error occurred while prerendering route '/administracion'.
Terminating worker thread

Error: building at STEP "RUN npm run build": while running runtime: exit status 1
```

### Root Cause:
The Angular SSR (Server-Side Rendering) prerendering process was trying to make HTTP API calls during the build phase, but:
1. API endpoints are not available during Docker build
2. The proxy configuration doesn't work during SSR prerendering
3. Components were loading data during initialization (which happens during prerendering)

## ✅ Fixes Applied

### 1. **SSR-Safe API Service**
Updated `src/app/services/api.service.ts`:
- Added platform detection using `isPlatformBrowser()`
- Return mock data during SSR builds
- Prevent HTTP calls during server-side rendering

```typescript
// SSR-safe API calls
if (!this.isBrowser) {
  return of(this.getMockProducts()); // Return mock data for SSR
}
```

### 2. **Component Lifecycle Updates**
Updated components (`tienda.component.ts`, `administracion.component.ts`):
- Added `AfterViewInit` lifecycle hook
- Defer API calls until after view initialization in browser
- Load mock data immediately for SSR

```typescript
ngOnInit(): void {
  // Load sample data immediately for SSR
  if (!this.isBrowser) {
    this.cargarProductosMuestra();
  }
}

ngAfterViewInit(): void {
  // Load real data only in browser after view initialization
  if (this.isBrowser) {
    this.cargarProductos();
  }
}
```

### 3. **MSAL SSR Compatibility**
Updated `src/app/services/msal-init.service.ts`:
- Skip MSAL initialization during SSR
- Handle `window` and `navigator` objects safely
- Prevent browser-specific code from running on server

### 4. **Angular Configuration**
Updated `angular.json`:
- **Disabled prerendering**: `"prerender": false`
- Removed conflicting `outputMode` setting
- Added environment file replacements for production
- Configured different build targets

### 5. **Environment Configuration**
Created separate environment files:
- `environment.development.ts` - Development with proxy
- `environment.production.ts` - Production with direct API calls
- **Fixed duplicate `production` key issue** by renaming to `buildConfig`
- Proper SSR handling in both environments

### 6. **Build Scripts**
Added comprehensive build scripts in `package.json`:
```json
{
  "build": "ng build --configuration=production",
  "build:dev": "ng build --configuration=development", 
  "build:prod": "ng build --configuration=production",
  "build:ssr": "ng build --configuration=production --ssr",
  "build:static": "ng build --configuration=static"
}
```

### 7. **Fixed TypeScript Errors**
- Resolved duplicate object key error in environment files
- Renamed conflicting `production` property to `buildConfig`
- Verified TypeScript compilation passes without errors

### 8. **Fixed Docker nginx Issue**
- **Problem**: nginx showing "Welcome to nginx" instead of Angular app
- **Root Cause**: SSR build generates `index.csr.html` instead of `index.html`
- **Solution**: Created static build configuration for Docker deployment
- Added `static` configuration in `angular.json` that generates proper `index.html`
- Updated Dockerfile to use `npm run build:static` instead of `npm run build`

## 🚀 Build Instructions

### For Docker Production Build:
```bash
# This will now work without errors
docker build -t pulso-vivo-ng .
```

### For Local Development Build:
```bash
npm run build:dev
```

### For Production Build (Local):
```bash
npm run build:prod
```

### For Static Build (Docker-ready):
```bash
npm run build:static
```

### For SSR Build (if needed):
```bash
npm run build:ssr
```

## 📋 Build Configurations

### Development Build:
- ✅ Source maps enabled
- ✅ Optimization disabled
- ✅ Uses proxy for API calls
- ✅ Enhanced logging
- ✅ Mock data fallback

### Production Build:
- ✅ Optimization enabled
- ✅ Bundle hashing
- ✅ Direct API calls
- ✅ Minimal logging
- ✅ No prerendering (for now)

## 🔍 Key Changes Made

### Files Modified:
1. **`src/app/services/api.service.ts`**
   - Added SSR-safe API calls
   - Added mock data for SSR builds
   - Platform detection for browser vs server

2. **`src/app/components/tienda/tienda.component.ts`**
   - Added `AfterViewInit` lifecycle
   - Deferred API calls to browser environment
   - SSR-safe initialization

3. **`src/app/components/administracion/administracion.component.ts`**
   - Added `AfterViewInit` lifecycle
   - Deferred API calls to browser environment
   - SSR-safe initialization

4. **`src/app/services/msal-init.service.ts`**
   - Added SSR safety checks
   - Safe handling of browser-only objects

5. **`angular.json`**
   - Disabled prerendering
   - Added environment file replacements
   - Added `static` build configuration for Docker
   - Updated build configurations

6. **`package.json`**
   - Added comprehensive build scripts
   - Different build targets for different needs

7. **`Dockerfile`**
   - Updated to use `npm run build:static`
   - Changed copy path to `dist/static/browser`
   - Removed index.csr.html workaround

### Files Created:
1. **`src/environments/environment.development.ts`**
   - Development-specific configuration
   - Proxy-based API calls

2. **`src/environments/environment.production.ts`**
   - Production-specific configuration
   - Direct API calls

3. **`test-docker-build.sh`**
   - Comprehensive Docker build testing script
   - Automated verification of build and deployment

## 🚨 Important Notes

### Prerendering Status:
- **Currently DISABLED** to fix build issues
- Routes are rendered client-side only
- Can be re-enabled later with proper API mocking

### SSR Behavior:
- Components load mock data during SSR
- Real API calls happen only in browser
- Seamless transition from SSR to client-side

### Docker Build:
- No longer fails during prerendering
- Builds successfully with static configuration
- Generates proper `index.html` file for nginx
- All routes work correctly at runtime
- nginx serves Angular app instead of default page

## 🔄 Future Improvements

### 1. Re-enable Prerendering:
```typescript
// Option 1: Create API mock server for build
// Option 2: Configure selective prerendering
// Option 3: Use Angular Universal with proper API mocking
```

### 2. Enhanced SSR:
```typescript
// Add proper HTTP interceptors for SSR
// Implement state transfer for smoother hydration
// Add loading states for better UX
```

### 3. Build Optimization:
```bash
# Add bundle analysis
npm run analyze

# Add performance monitoring
# Add error tracking
```

## 🐛 Common Build Issues & Solutions

### Issue: "Unable to handle request" during build
**Solution:** Disable prerendering or add SSR-safe API calls

### Issue: "window is not defined" during SSR
**Solution:** Add platform detection and safe object access

### Issue: MSAL errors during build
**Solution:** Skip MSAL initialization during SSR

### Issue: HTTP calls failing during build
**Solution:** Return mock data for SSR builds

## 📞 Build Debugging

### Debug Commands:
```bash
# Verbose build output
ng build --verbose

# Development build for debugging
ng build --configuration=development

# Check bundle sizes
ng build --stats-json
npx webpack-bundle-analyzer dist/pulso-vivo-ng/stats.json
```

### Log Analysis:
- Check for SSR-related errors
- Look for HTTP request failures during build
- Monitor prerendering status

## ✅ Verification Steps

After implementing fixes:
1. ✅ Docker build completes successfully
2. ✅ nginx serves Angular app correctly (no more "Welcome to nginx")
3. ✅ All routes load without errors
4. ✅ API calls work in browser
5. ✅ Mock data loads during SSR
6. ✅ No console errors during build
7. ✅ Bundle sizes are reasonable
8. ✅ Static assets (images, CSS, JS) load properly
9. ✅ Angular routing works correctly in nginx

## 🧪 Testing the Fix

Use the provided test script to verify everything works:
```bash
./test-docker-build.sh
```

This script will:
- Build the Docker image
- Start a test container
- Verify HTTP responses
- Test Angular routing
- Check static assets
- Provide performance metrics

---

**Last Updated:** January 2025  
**Build Status:** ✅ Working  
**SSR Status:** ✅ Compatible  
**Docker Status:** ✅ Builds Successfully  
**nginx Status:** ✅ Serves Angular App Correctly