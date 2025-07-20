# PulsoVivo Angular - Development Troubleshooting Guide

## 🔧 Quick Fixes Applied

This document outlines the issues found and fixes applied to get the PulsoVivo Angular application running properly in development.

## 🚨 Issues Identified

### 1. Missing Image Assets (404 Errors)
**Problem:** Medical equipment images were referenced but files didn't exist
```
tensiometro.jpg, estetoscopio.jpg, termometro.jpg, guantes.jpg, 
mascarillas.jpg, jeringuillas.jpg, camilla.jpg, silla-ruedas.jpg
```

**Solution:** Created placeholder copies using the existing `producto-placeholder.jpg`

### 2. CORS Policy Blocking API Calls
**Problem:** Direct calls to AWS API Gateway blocked by browser CORS policy
```
Access to fetch at 'https://erwqz80g2d.execute-api.us-east-1.amazonaws.com/api/inventory/products' 
from origin 'http://localhost:3000' has been blocked by CORS policy
```

**Solution:** Added development proxy configuration

### 3. MSAL Multiple Instance Warning
**Problem:** MSAL was being initialized twice causing warnings
```
Warning - There is already an instance of MSAL.js in the window with the same client id.
```

**Solution:** Removed duplicate initialization from app.config.ts

### 4. Environment Configuration Issues
**Problem:** Single environment file not optimized for development

**Solution:** Created separate development environment file

## 🛠️ Files Modified/Created

### New Files Created:
- `proxy.conf.json` - Development proxy configuration
- `src/environments/environment.development.ts` - Development-specific environment
- `src/app/services/image-utils.service.ts` - Image loading utility service
- `start-dev.sh` - Development startup script
- `public/assets/images/[medical-equipment].jpg` - Placeholder image copies

### Files Modified:
- `angular.json` - Added proxy config and file replacements
- `src/environments/environment.ts` - Updated API baseUrl for proxy
- `src/app/app.config.ts` - Removed duplicate MSAL initialization
- `src/app/services/msal-init.service.ts` - Fixed initialization logic
- `package.json` - Added development scripts

## 🚀 How to Start Development

### Option 1: Using the Startup Script (Recommended)
```bash
./start-dev.sh
```

### Option 2: Using npm Scripts
```bash
npm run start:dev
```

### Option 3: Manual Start
```bash
ng serve --configuration=development --host=0.0.0.0 --port=4200 --open
```

## 🌐 Development URLs

- **Frontend:** http://localhost:4200
- **API (Proxied):** http://localhost:4200/api/*
- **Actual API:** https://erwqz80g2d.execute-api.us-east-1.amazonaws.com/api

## 📋 Environment Configuration

### Development Environment Features:
- ✅ Enhanced logging enabled
- ✅ CORS proxy configured
- ✅ Source maps enabled
- ✅ Longer session timeout (2 hours)
- ✅ Mock data fallback
- ✅ Debug mode enabled

### Production Environment Features:
- ✅ Optimized builds
- ✅ Direct API calls
- ✅ Shorter session timeout (1 hour)
- ✅ Minimal logging

## 🔍 Troubleshooting Common Issues

### Issue: Images Still Not Loading
**Check:**
1. Verify files exist in `public/assets/images/`
2. Check browser network tab for 404s
3. Clear browser cache

**Fix:**
```bash
# Copy placeholder to missing images
cp public/assets/images/producto-placeholder.jpg public/assets/images/missing-image.jpg
```

### Issue: API Calls Still Failing
**Check:**
1. Verify `proxy.conf.json` exists
2. Check Angular serve is using development configuration
3. Check network tab for proxy behavior

**Fix:**
```bash
# Restart with proxy
ng serve --configuration=development
```

### Issue: MSAL Errors
**Check:**
1. B2C tenant configuration
2. Client ID and authority URLs
3. Redirect URIs match development port

**Fix:**
Update `environment.development.ts`:
```typescript
redirectUri: "http://localhost:4200",
postLogoutRedirectUri: "http://localhost:4200",
```

### Issue: Build Failures
**Check:**
1. TypeScript errors
2. Missing dependencies
3. Configuration issues

**Fix:**
```bash
# Clear cache and reinstall
npm run cache:clear
rm -rf node_modules package-lock.json
npm install
```

## 📊 Development Scripts

```bash
# Start development server
npm run start:dev

# Build for development
npm run build:dev

# Build for production  
npm run build:prod

# Clear Angular cache
npm run cache:clear

# Run with custom script
./start-dev.sh

# Analyze bundle size
npm run analyze
```

## 🔐 Authentication Flow

### Development Setup:
1. **B2C Tenant:** PulsoVivo.b2clogin.com
2. **Policy:** B2C_1_pulso_vivo_register_and_login
3. **Redirect URI:** http://localhost:4200
4. **Scopes:** openid, profile

### MSAL Configuration:
- Cache location: localStorage
- Known authorities: PulsoVivo.b2clogin.com
- Client capabilities: CP1
- Validate authority: false (important for B2C)

## 🖼️ Image Management

### Current Images:
All medical equipment images are currently using the placeholder image. To add proper images:

1. **Add images to:** `public/assets/images/`
2. **Required names:**
   - `tensiometro.jpg` (Blood pressure monitor)
   - `estetoscopio.jpg` (Stethoscope)
   - `termometro.jpg` (Thermometer)
   - `guantes.jpg` (Gloves)
   - `mascarillas.jpg` (Masks)
   - `jeringuillas.jpg` (Syringes)
   - `camilla.jpg` (Stretcher)
   - `silla-ruedas.jpg` (Wheelchair)

3. **Image specs:**
   - Format: JPG/PNG
   - Size: 300x300px recommended
   - Max size: 500KB each

## 🚨 Known Issues & Workarounds

### Issue: Hot Reload Sometimes Fails
**Workaround:** Restart development server

### Issue: MSAL Token Expiry in Development
**Workaround:** Extended session timeout to 2 hours in development

### Issue: API Rate Limiting
**Workaround:** Fallback to mock data when API calls fail

## 📞 Getting Help

### Log Files to Check:
1. Browser Console (F12)
2. Network tab for failed requests
3. Angular CLI output

### Common Log Messages:
- `✅ PulsoVivo: MSAL initialized successfully` - Good
- `[MSAL Init] Error during la verificación` - MSAL issue
- `Error loading products` - API/CORS issue
- `404 (Not Found)` for images - Missing image files

### Debug Commands:
```bash
# Verbose Angular serve
ng serve --verbose

# Check environment
ng build --configuration=development --stats-json

# Inspect MSAL state
# Open browser console and check MSAL diagnostic info
```

## 🔄 Regular Maintenance

### Weekly:
- Update dependencies: `npm update`
- Clear cache: `npm run cache:clear`

### Monthly:
- Check for Angular updates: `ng update`
- Review and rotate API keys
- Update B2C policies if needed

---

**Last Updated:** January 2025  
**Version:** 1.0.0-dev  
**Angular Version:** 19.2.0