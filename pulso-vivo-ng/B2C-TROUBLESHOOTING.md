# Azure AD B2C Troubleshooting Guide - MSAL Configuration

## 🚨 Problem Description

You're encountering authentication issues with Azure AD B2C, specifically:

1. **400 Bad Request** errors during authentication
2. **Issuer mismatch** errors (STS vs login.microsoftonline.com)
3. **Authority validation** failures
4. **B2C-specific configuration** problems

## 🔍 B2C vs Regular Azure AD

Azure AD B2C has different configuration requirements than regular Azure AD:

| Aspect | Regular Azure AD | Azure AD B2C |
|--------|------------------|--------------|
| Authority Format | `https://login.microsoftonline.com/{tenant-id}` | `https://{tenant}.b2clogin.com/{tenant}.onmicrosoft.com/{policy}` |
| Validate Authority | `true` (default) | `false` (required) |
| Known Authorities | Optional | Required |
| Scopes Format | `user.read`, `api://app-id/scope` | `openid`, `profile`, `https://{tenant}.onmicrosoft.com/{api}/{scope}` |
| Issuer | `https://sts.windows.net/{tenant-id}/` | Varies, often STS format |

## ⚡ Quick Fix for B2C

### Step 1: Update Environment Configuration

Replace your current environment configuration with B2C-specific settings:

```typescript
// src/environments/environment.ts
export const environment = {
  production: false,
  azureAd: {
    // Your B2C Application ID
    clientId: "e30e27b2-1240-4f61-a8bd-25aacc63ab36",
    
    // B2C Authority (replace placeholders)
    authority: "https://your-tenant-name.b2clogin.com/your-tenant-name.onmicrosoft.com/B2C_1_signupsignin",
    
    // Redirect URIs
    redirectUri: "http://localhost:4200",
    postLogoutRedirectUri: "http://localhost:4200",
    
    // B2C Scopes
    scopes: [
      "openid", 
      "profile",
      "https://your-tenant-name.onmicrosoft.com/your-api-name/access"
    ],
    
    // B2C Required Settings
    validateAuthority: false, // CRITICAL: Must be false for B2C
    knownAuthorities: ["your-tenant-name.b2clogin.com"],
    
    // Standard settings
    navigateToLoginRequestUrl: false,
    clientCapabilities: ["CP1"]
  }
};
```

### Step 2: Configure Azure B2C App Registration

1. Go to [Azure Portal B2C](https://portal.azure.com/#view/Microsoft_AAD_B2CAdmin/TenantManagementMenuBlade/~/Applications)
2. Select your B2C tenant
3. Go to **App registrations** → Select your app
4. Click **Authentication**
5. **Remove** any "Web" platform configurations
6. **Add platform** → **Single-page application**
7. Add redirect URI: `http://localhost:4200`
8. **Save** changes

### Step 3: Handle Issuer Validation Issues

The issuer mismatch (`https://sts.windows.net/` vs `https://login.microsoftonline.com/`) is common in B2C. Add custom validation:

```typescript
// In your token validation or API configuration
const acceptedIssuers = [
  "https://sts.windows.net/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/",
  "https://login.microsoftonline.com/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/v2.0",
  "https://your-tenant-name.b2clogin.com/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/v2.0/"
];
```

## 🧪 B2C Testing Tools

### Option 1: Use B2C Debug Component
Navigate to: `http://localhost:4200/debug/msal`
- Now includes B2C-specific validation
- Shows B2C configuration status
- Validates B2C authority format
- Checks issuer validation settings

### Option 2: B2C Configuration Validator

Use this JavaScript in browser console to validate B2C config:

```javascript
// B2C Configuration Validator
const b2cConfig = {
  clientId: "e30e27b2-1240-4f61-a8bd-25aacc63ab36",
  authority: "https://your-tenant-name.b2clogin.com/your-tenant-name.onmicrosoft.com/B2C_1_signupsignin",
  tenantId: "82c6cf20-e689-4aa9-bedf-7acaf7c4ead7"
};

console.log("🏢 B2C Configuration Validation:");
console.log("Authority format:", /\.b2clogin\.com.*B2C_1_/.test(b2cConfig.authority) ? "✅ Valid" : "❌ Invalid");
console.log("Contains policy:", b2cConfig.authority.includes("B2C_1_") ? "✅ Yes" : "❌ No");
console.log("Client ID format:", /^[0-9a-f-]{36}$/.test(b2cConfig.clientId) ? "✅ Valid GUID" : "❌ Invalid");

// Test B2C endpoint connectivity
fetch(`${b2cConfig.authority}/.well-known/openid_configuration`)
  .then(r => r.ok ? console.log("✅ B2C endpoint reachable") : console.log("❌ B2C endpoint not reachable"))
  .catch(() => console.log("❌ B2C endpoint connection failed"));
```

## 📋 B2C Configuration Checklist

### ✅ Azure B2C Portal Configuration
- [ ] App registered as "Single-page application" in B2C
- [ ] Redirect URI registered: `http://localhost:4200`
- [ ] API permissions configured for your B2C APIs
- [ ] User flows (policies) created and published
- [ ] Custom domains configured (if using custom domains)

### ✅ Application Configuration
- [ ] `validateAuthority: false` is set
- [ ] `knownAuthorities` includes B2C domain
- [ ] Authority URL includes policy name (B2C_1_signupsignin)
- [ ] Scopes use B2C format
- [ ] Client ID matches B2C app registration

### ✅ Environment Variables
- [ ] Replace `your-tenant-name` with actual B2C tenant name
- [ ] Update policy names to match your B2C user flows
- [ ] Configure API scopes to match your B2C API registrations
- [ ] Set correct tenant ID

## 🔧 Common B2C Issues & Solutions

### Issue 1: Authority Validation Error
**Error**: `Authority validation failed`
**Solution**: Set `validateAuthority: false` in MSAL configuration

### Issue 2: Issuer Mismatch
**Error**: Token issuer doesn't match expected issuer
**Solution**: Configure multiple accepted issuers in your API validation:
```javascript
const acceptedIssuers = [
  "https://sts.windows.net/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/",
  "https://your-tenant-name.b2clogin.com/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/v2.0/"
];
```

### Issue 3: Policy Not Found
**Error**: Policy 'B2C_1_signupsignin' not found
**Solution**: 
1. Check policy name in B2C portal
2. Ensure policy is published
3. Update authority URL with correct policy name

### Issue 4: Scope Permission Error
**Error**: AADSTS65001: The user or administrator has not consented
**Solution**: 
1. Check API permissions in B2C app registration
2. Grant admin consent if required
3. Verify scope format: `https://{tenant}.onmicrosoft.com/{api}/{scope}`

### Issue 5: CORS Issues
**Error**: CORS policy blocks request
**Solution**: 
1. Use `b2clogin.com` domain instead of `login.microsoftonline.com`
2. Configure CORS in your API if needed
3. Check redirect URI configuration

## 🎫 B2C JWT Token Structure

B2C tokens have specific claims structure:

```json
{
  "iss": "https://sts.windows.net/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7/",
  "aud": "7549ac9c-9294-4bb3-98d6-752d12b13d81",
  "exp": 1640995200,
  "nbf": 1640991600,
  "sub": "user-object-id",
  "tfp": "B2C_1_signupsignin", // B2C policy
  "ver": "1.0",
  "acr": "b2c_1_signupsignin",
  "azp": "7549ac9c-9294-4bb3-98d6-752d12b13d81",
  "scp": "access", // B2C scope
  "given_name": "User",
  "family_name": "Name"
}
```

Key B2C-specific claims:
- `tfp`: Trust Framework Policy (B2C policy name)
- `acr`: Authentication Context Class Reference
- Different issuer format than regular Azure AD

## 🌐 B2C-Specific URLs

Replace placeholders with your actual values:

- **B2C Tenant Portal**: `https://portal.azure.com/#view/Microsoft_AAD_B2CAdmin/TenantManagementMenuBlade/~/overview/tenantId/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7`
- **App Registrations**: `https://portal.azure.com/#view/Microsoft_AAD_B2CAdmin/TenantManagementMenuBlade/~/Applications/tenantId/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7`
- **User Flows**: `https://portal.azure.com/#view/Microsoft_AAD_B2CAdmin/TenantManagementMenuBlade/~/UserFlows/tenantId/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7`
- **Your App**: `https://portal.azure.com/#view/Microsoft_AAD_B2CAdmin/ApplicationMenuBlade/~/Overview/appId/7549ac9c-9294-4bb3-98d6-752d12b13d81/tenantId/82c6cf20-e689-4aa9-bedf-7acaf7c4ead7`

## 📝 B2C Configuration Template

Here's a complete working template:

```typescript
export const environment = {
  production: false,
  azureAd: {
    // Your B2C app registration ID
    clientId: "7549ac9c-9294-4bb3-98d6-752d12b13d81",
    
    // B2C authority with policy
    authority: "https://yourtenant.b2clogin.com/yourtenant.onmicrosoft.com/B2C_1_signupsignin",
    
    // Redirect URIs
    redirectUri: "http://localhost:4200",
    postLogoutRedirectUri: "http://localhost:4200",
    
    // B2C scopes
    scopes: [
      "openid",
      "profile", 
      "https://yourtenant.onmicrosoft.com/yourapi/access"
    ],
    
    // B2C specific settings - REQUIRED
    validateAuthority: false,
    knownAuthorities: ["yourtenant.b2clogin.com"],
    
    // Standard MSAL settings
    navigateToLoginRequestUrl: false,
    clientCapabilities: ["CP1"],
    
    // Additional B2C settings
    cloudDiscoveryMetadata: "",
    authorityMetadata: ""
  }
};
```

## 🚀 Testing Your B2C Configuration

1. **Replace placeholders** in configuration template
2. **Clear browser cache** completely
3. **Navigate to debug page**: `http://localhost:4200/debug/msal`
4. **Check B2C validation** status
5. **Test login flow** with B2C user account
6. **Examine JWT tokens** for B2C-specific claims
7. **Test API calls** with B2C access tokens

## 📞 Still Having B2C Issues?

If you're still experiencing problems:

1. **Double-check B2C tenant name** in all configurations
2. **Verify user flow (policy) is published** and working
3. **Test B2C login** directly in Azure portal
4. **Check B2C app registration** platform configuration
5. **Verify API scopes** are correctly defined in B2C
6. **Test with B2C test accounts**
7. **Enable B2C diagnostic logging**
8. **Check network connectivity** to b2clogin.com

## 📚 B2C Resources

- [Azure AD B2C Documentation](https://docs.microsoft.com/en-us/azure/active-directory-b2c/)
- [MSAL.js B2C Configuration](https://docs.microsoft.com/en-us/azure/active-directory/develop/msal-js-initializing-client-applications#configuration-options)
- [B2C User Flows](https://docs.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview)
- [B2C Token Claims](https://docs.microsoft.com/en-us/azure/active-directory-b2c/tokens-overview)
- [B2C Troubleshooting](https://docs.microsoft.com/en-us/azure/active-directory-b2c/troubleshoot)