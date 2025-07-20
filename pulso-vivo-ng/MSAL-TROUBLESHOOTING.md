# MSAL Troubleshooting Guide - 400 Bad Request Error

## 🚨 Problem Description

You're encountering a **400 Bad Request** error when trying to authenticate with Microsoft Azure AD:

```
POST https://login.microsoftonline.com/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/oauth2/v2.0/token 400 (Bad Request)
```

## 🔍 Root Cause Analysis

The 400 Bad Request error typically occurs due to one of these issues:

1. **Application Configuration Issue** (Most Common): Your Azure AD application is not configured as a Single-Page Application (SPA)
2. **Redirect URI Mismatch**: The redirect URI in your code doesn't match what's registered in Azure AD
3. **Invalid Client Configuration**: Client ID or Tenant ID issues
4. **Incorrect Scopes**: Requesting scopes that aren't available or configured

## ⚡ Quick Fix (Most Common Solution)

### Step 1: Configure Your App as SPA in Azure AD

1. Go to [Azure Portal App Registrations](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps)
2. Find your application with Client ID: `7549ac9c-9294-4bb3-98d6-752d12b13d81`
3. Click on **Authentication** in the left menu
4. Under **Platform configurations**:
   - **Remove** any "Web" platform configuration if it exists
   - Click **"Add a platform"** → Select **"Single-page application"**
   - Add redirect URI: `http://localhost:4200` (or your current port)
   - **Save** the changes

### Step 2: Verify Redirect URI Matches

Ensure your environment configuration matches your current development setup:

```typescript
// src/environments/environment.ts
redirectUri: "http://localhost:4200", // Must match your current port
postLogoutRedirectUri: "http://localhost:4200",
```

## 🧪 Testing Tools

### Option 1: Use the Debug Component
Navigate to: `http://localhost:4200/debug/msal` in your Angular app
- Includes JWT token display and copy functionality
- Shows both raw JWT and decoded payload
- Interactive configuration validation

### Option 2: Use the Standalone Test Page
Open `msal-test.html` in your browser for isolated testing
- Independent of Angular application
- Real-time token acquisition and display
- Copy tokens to clipboard for testing

### Option 3: Browser Console Debug Script
Copy and paste the content of `debug-msal.js` into your browser console
- Quick configuration validation
- Token utilities for copying and decoding JWTs

## 📋 Complete Troubleshooting Checklist

### ✅ Azure AD Configuration
- [ ] App is configured as "Single-page application" (not "Web")
- [ ] Redirect URI is registered exactly as: `http://localhost:4200`
- [ ] Client ID matches: `7549ac9c-9294-4bb3-98d6-752d12b13d81`
- [ ] Tenant ID is correct: `82c6cf20-e689-4aa9-bedf-7acaf7c4ead7`
- [ ] API permissions include required scopes (e.g., `user.read`)

### ✅ Application Configuration
- [ ] Environment redirect URI matches current development port
- [ ] Client capabilities include `["CP1"]` for SPA
- [ ] `navigateToLoginRequestUrl` is set to `false`
- [ ] Scopes are properly configured: `["user.read"]`

### ✅ Network & Browser
- [ ] Clear browser cache and cookies
- [ ] No ad blockers or extensions blocking requests
- [ ] Firewall/corporate proxy not blocking Azure AD endpoints
- [ ] Internet connectivity to `login.microsoftonline.com`

## 🔧 Advanced Debugging

### Check Azure AD Endpoint Connectivity
```bash
curl -s "https://login.microsoftonline.com/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/.well-known/openid_configuration" | jq .
```

### MSAL Browser Console Testing
```javascript
// Test MSAL configuration
if (window.msalInstance) {
  window.msalInstance.getAllAccounts().forEach(account => {
    console.log('Account:', account.username);
  });
  
  // Get and display JWT tokens
  const accounts = window.msalInstance.getAllAccounts();
  if (accounts.length > 0) {
    window.msalInstance.acquireTokenSilent({
      scopes: ['user.read'],
      account: accounts[0]
    }).then(response => {
      console.log('Access Token:', response.accessToken);
      console.log('ID Token:', response.idToken);
      
      // Decode JWT (function available in debug script)
      if (typeof decodeJWT === 'function') {
        console.log('Decoded Access Token:', decodeJWT(response.accessToken));
        if (response.idToken) {
          console.log('Decoded ID Token:', decodeJWT(response.idToken));
        }
      }
    });
  }
} else {
  console.log('MSAL instance not found');
}

// Copy token to clipboard (from debug script)
// copyTokenToClipboard('access') or copyTokenToClipboard('id')
```

## 🚀 Common Error Codes & Solutions

| Error Code | Description | Solution |
|------------|-------------|----------|
| `AADSTS9002326` | Cross-origin token redemption | Configure app as SPA |
| `AADSTS50011` | Redirect URI mismatch | Register correct redirect URI |
| `AADSTS70011` | Invalid scope | Check scope configuration |
| `AADSTS700016` | Invalid client | Verify Client ID |
| `AADSTS90002` | Tenant not found | Check Tenant ID |

## 📞 Azure Portal Quick Links

- [Your App Registration](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/7549ac9c-9294-4bb3-98d6-752d12b13d81)
- [Authentication Settings](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Authentication/appId/7549ac9c-9294-4bb3-98d6-752d12b13d81)
- [API Permissions](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/7549ac9c-9294-4bb3-98d6-752d12b13d81)
- [All App Registrations](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps)

## ⏱️ Important Notes

- **Propagation Time**: Azure AD changes can take 2-5 minutes to propagate
- **Cache Issues**: Clear browser cache after making Azure AD changes
- **Development vs Production**: Ensure different redirect URIs for different environments
- **HTTPS Requirement**: Production apps must use HTTPS redirect URIs

## 🛠️ Step-by-Step Visual Guide

### 1. Access Azure Portal
![Azure Portal](https://portal.azure.com) → Azure Active Directory → App registrations

### 2. Find Your App
Search for Client ID: `7549ac9c-9294-4bb3-98d6-752d12b13d81`

### 3. Configure Authentication
- Click "Authentication" in left menu
- Remove any "Web" platform
- Add "Single-page application" platform
- Add redirect URI: `http://localhost:4200`
- Save changes

### 4. Verify Configuration
- Platform type: "Single-page application"
- Redirect URIs: `http://localhost:4200`
- Supported account types: (as configured)

## 🎫 JWT Token Debugging

All debugging tools now include JWT token functionality:

- **View Raw JWT**: Copy the complete token string for external validation
- **View Decoded Payload**: See all claims and their values
- **Token Expiration**: Human-readable expiration times
- **Copy to Clipboard**: One-click copying for testing with other tools

### JWT Token Validation Tools
- [jwt.io](https://jwt.io) - Decode and validate JWT tokens online
- [jwt.ms](https://jwt.ms) - Microsoft's JWT decoder
- Browser extensions for JWT debugging

### Common JWT Claims to Check
- `aud` (audience): Should match your application
- `iss` (issuer): Should be your Azure AD tenant
- `exp` (expiration): Token validity period
- `scp` (scopes): Permissions granted
- `roles`: User roles (if configured)

## 📞 Still Having Issues?

If you're still experiencing problems after following this guide:

1. **Double-check all configuration values**
2. **Wait 5 minutes after Azure AD changes**
3. **Clear all browser data and restart**
4. **Try the standalone test page** (`msal-test.html`)
5. **Check browser developer tools** for detailed error messages
6. **Run the debug component** at `http://localhost:4200/debug/msal`
7. **Examine JWT tokens** using the token display features
8. **Validate tokens externally** using jwt.io or similar tools

## 📚 Additional Resources

- [Microsoft MSAL.js Documentation](https://docs.microsoft.com/en-us/azure/active-directory/develop/msal-js-initializing-client-applications)
- [SPA Application Registration](https://docs.microsoft.com/en-us/azure/active-directory/develop/scenario-spa-app-registration)
- [Common MSAL Errors](https://docs.microsoft.com/en-us/azure/active-directory/develop/msal-handling-exceptions)