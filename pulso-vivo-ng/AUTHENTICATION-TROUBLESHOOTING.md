# PulsoVivo Authentication Troubleshooting Guide

## 🎯 Current Status

Based on the recent fixes, your CORS issues are **completely resolved** and the proxy is working correctly. The current challenge is completing the authentication flow to get valid API tokens.

## ✅ What's Working

- ✅ **CORS Fixed**: API calls now go to `/api/*` instead of direct AWS URLs
- ✅ **Proxy Working**: nginx successfully forwards requests to AWS API Gateway
- ✅ **MSAL Initialization**: Azure AD B2C authentication system loads correctly
- ✅ **Login Flow**: User can access B2C login page
- ✅ **401 Responses**: Getting proper authentication errors instead of CORS errors

## ⚠️ Current Issue: 401 Unauthorized

The `401 Unauthorized` errors indicate that API calls are being made without valid authentication tokens. This is the final step to resolve.

## 🔧 Quick Fixes

### 1. Update Azure AD B2C Redirect URI

Your app is now running on **port 4001**, but Azure AD B2C might still be configured for port 4000.

**Action Required:**
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to Azure AD B2C → App registrations
3. Find your app: `7549ac9c-9294-4bb3-98d6-752d12b13d81`
4. Go to Authentication → Redirect URIs
5. Update/Add: `http://localhost:4001`
6. Save changes

### 2. Clear Browser State

Authentication tokens might be cached for the wrong port.

```bash
# Clear browser data for localhost:4000 AND localhost:4001
# In browser: Developer Tools → Application → Storage → Clear storage
```

### 3. Test Authentication Flow

1. Open: `http://localhost:4001`
2. Open browser Developer Tools (F12)
3. Go to Console tab
4. Look for authentication logs starting with `[Auth Service]` and `[API Service]`

## 🐛 Debugging Steps

### Step 1: Check Authentication Logs

Look for these log messages in the browser console:

**✅ Good Signs:**
```
[Auth Service] User authenticated successfully: [username]
[Auth Service] BFF token acquired successfully
[API Service] Token added to headers successfully
```

**⚠️ Warning Signs:**
```
[Auth Service] No authenticated accounts found
[Auth Service] Error al obtener token del BFF
[API Service] No token available
```

### Step 2: Verify Redirect Handling

After login, check the URL in the address bar:
- Should briefly show authentication parameters (`#code=...&state=...`)
- Should then clean up to just `http://localhost:4001`

### Step 3: Check Network Tab

In Developer Tools → Network:
1. Look for calls to `/api/inventory/products`
2. Check if `Authorization: Bearer [token]` header is present
3. Verify the response is 401 (not CORS error)

## 🔍 Common Issues & Solutions

### Issue: "interaction_in_progress" Error

**Symptoms:**
```
BrowserAuthError: interaction_in_progress: Interaction is currently in progress
```

**Solution:**
```bash
# Clear all browser data for localhost
# Restart the application
```

### Issue: Token Not Acquired

**Symptoms:**
```
[Auth Service] No account found, cannot get BFF token
```

**Solution:**
1. Verify Azure AD B2C redirect URI matches port 4001
2. Clear browser cache and localStorage
3. Try login flow again

### Issue: Wrong Port in Logs

**Symptoms:**
```
Error: ... url: "http://localhost:4000/api/..."
```

**Solution:**
You have another instance running on port 4000. Stop it:
```bash
# Check what's using port 4000
lsof -i :4000

# Stop any containers on port 4000
podman --cgroup-manager=cgroupfs ps -a | grep 4000
podman --cgroup-manager=cgroupfs stop [container-name]
```

## 🚀 Complete Resolution Steps

### Step 1: Ensure Correct Configuration

```bash
# Stop any existing containers
podman --cgroup-manager=cgroupfs stop pulso-vivo-simple 2>/dev/null || true
podman --cgroup-manager=cgroupfs rm pulso-vivo-simple 2>/dev/null || true

# Rebuild with correct configuration
npm run build:docker

# Start container on port 4001
./run-with-podman-simple.sh
```

### Step 2: Update Azure AD B2C

1. **Azure Portal** → **Azure AD B2C** → **App registrations**
2. **Find your app**: `PulsoVivo` (Client ID: `7549ac9c-9294-4bb3-98d6-752d12b13d81`)
3. **Authentication** → **Redirect URIs**
4. **Add**: `http://localhost:4001`
5. **Save**

### Step 3: Test Complete Flow

1. **Clear browser data** for all localhost ports
2. **Open**: `http://localhost:4001`
3. **Login** when prompted
4. **Check console** for authentication success messages
5. **Verify** API calls include Authorization headers

## 📋 Verification Checklist

- [ ] Container running on port 4001
- [ ] Azure AD B2C redirect URI updated to port 4001  
- [ ] Browser cache cleared
- [ ] Authentication logs show successful token acquisition
- [ ] API calls include Authorization headers
- [ ] No CORS errors in console
- [ ] Getting 401 initially, then successful API responses after login

## 🔧 Container Management Commands

```bash
# Check container status
podman --cgroup-manager=cgroupfs ps

# View container logs
podman --cgroup-manager=cgroupfs logs -f pulso-vivo-simple

# Stop container
podman --cgroup-manager=cgroupfs stop pulso-vivo-simple

# Remove container
podman --cgroup-manager=cgroupfs rm pulso-vivo-simple

# Cleanup
rm -rf ./tmp-nginx
```

## 🌐 API Testing Commands

```bash
# Test health endpoint
curl -I http://localhost:4001/health

# Test API proxy (should return 401)
curl -I http://localhost:4001/api/inventory/products

# Test with authentication (after getting token from browser)
curl -H "Authorization: Bearer [your-token]" http://localhost:4001/api/inventory/products
```

## 📞 Next Steps if Issues Persist

1. **Share browser console logs** showing authentication flow
2. **Verify Azure AD B2C configuration** screenshots
3. **Check container logs** for any nginx errors
4. **Test API directly** with manual token from browser dev tools

## 🎉 Success Indicators

You'll know everything is working when:

1. **No CORS errors** in browser console ✅
2. **Authentication completes** without redirect loops
3. **API calls return data** instead of 401 errors
4. **Console shows**: `[API Service] Token added to headers successfully`
5. **Products and categories load** in the application

---

**Last Updated**: June 27, 2025  
**Status**: CORS Fixed ✅ | Authentication In Progress 🔄  
**Current Focus**: Token acquisition and Azure AD B2C redirect URI configuration