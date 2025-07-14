#!/usr/bin/env node

/**
 * Test script to verify proxy configuration for PulsoVivo Angular app
 * This script tests if the proxy is correctly routing API calls
 */

const http = require('http');
const https = require('https');

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

function log(color, message) {
  console.log(`${color}${message}${colors.reset}`);
}

function testEndpoint(url, description) {
  return new Promise((resolve) => {
    const protocol = url.startsWith('https') ? https : http;
    
    log(colors.blue, `\n🔍 Testing: ${description}`);
    log(colors.cyan, `📡 URL: ${url}`);
    
    const startTime = Date.now();
    
    const req = protocol.get(url, (res) => {
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      log(colors.yellow, `📊 Status: ${res.statusCode}`);
      log(colors.yellow, `⏱️  Duration: ${duration}ms`);
      log(colors.yellow, `📋 Headers:`);
      
      // Check for CORS headers
      const corsHeaders = {
        'access-control-allow-origin': res.headers['access-control-allow-origin'],
        'access-control-allow-methods': res.headers['access-control-allow-methods'],
        'access-control-allow-headers': res.headers['access-control-allow-headers']
      };
      
      Object.entries(corsHeaders).forEach(([key, value]) => {
        if (value) {
          log(colors.green, `   ✅ ${key}: ${value}`);
        } else {
          log(colors.red, `   ❌ ${key}: Not present`);
        }
      });
      
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          log(colors.green, `✅ SUCCESS: ${description}`);
          try {
            const jsonData = JSON.parse(data);
            log(colors.green, `📦 Response: ${Array.isArray(jsonData) ? jsonData.length : 'Object'} items`);
          } catch (e) {
            log(colors.yellow, `📦 Response: ${data.length} characters (non-JSON)`);
          }
        } else {
          log(colors.red, `❌ FAILED: ${description} (Status: ${res.statusCode})`);
          if (data) {
            log(colors.red, `💬 Error: ${data.substring(0, 200)}...`);
          }
        }
        resolve({ success: res.statusCode === 200, status: res.statusCode, duration, corsHeaders });
      });
    });
    
    req.on('error', (error) => {
      const endTime = Date.now();
      const duration = endTime - startTime;
      
      log(colors.red, `💥 ERROR: ${description}`);
      log(colors.red, `🚨 Message: ${error.message}`);
      log(colors.yellow, `⏱️  Duration: ${duration}ms`);
      
      resolve({ success: false, error: error.message, duration, corsHeaders: {} });
    });
    
    req.setTimeout(10000, () => {
      req.destroy();
      log(colors.red, `⏰ TIMEOUT: ${description}`);
      resolve({ success: false, error: 'Timeout', duration: 10000, corsHeaders: {} });
    });
  });
}

async function runTests() {
  log(colors.bright + colors.magenta, '🏥 PulsoVivo Proxy Test Suite');
  log(colors.bright + colors.magenta, '==============================\n');
  
  const tests = [
    {
      url: 'http://localhost:4000/api/inventory/products',
      description: 'Local proxy endpoint (should work)'
    },
    {
      url: 'https://erwqz80g2d.execute-api.us-east-1.amazonaws.com/api/inventory/products',
      description: 'Direct AWS API Gateway (may have CORS issues)'
    }
  ];
  
  const results = [];
  
  for (const test of tests) {
    const result = await testEndpoint(test.url, test.description);
    results.push({ ...test, ...result });
    await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second between tests
  }
  
  // Summary
  log(colors.bright + colors.magenta, '\n📊 Test Results Summary');
  log(colors.bright + colors.magenta, '=======================');
  
  results.forEach((result, index) => {
    const status = result.success ? '✅ PASS' : '❌ FAIL';
    const color = result.success ? colors.green : colors.red;
    
    log(color, `${status} Test ${index + 1}: ${result.description}`);
    if (result.status) {
      log(colors.yellow, `      Status: ${result.status}, Duration: ${result.duration}ms`);
    }
    if (result.error) {
      log(colors.red, `      Error: ${result.error}`);
    }
    
    // CORS Analysis
    const hasCors = Object.values(result.corsHeaders).some(value => value);
    if (hasCors) {
      log(colors.green, '      CORS: ✅ Headers present');
    } else {
      log(colors.red, '      CORS: ❌ Headers missing');
    }
  });
  
  // Recommendations
  log(colors.bright + colors.cyan, '\n💡 Recommendations');
  log(colors.bright + colors.cyan, '==================');
  
  const proxyTest = results[0];
  const directTest = results[1];
  
  if (proxyTest.success && !directTest.success) {
    log(colors.green, '✅ Proxy is working correctly!');
    log(colors.yellow, '⚠️  Direct API calls fail due to CORS (this is expected)');
    log(colors.blue, '🔧 Make sure your app uses /api/* endpoints, not direct AWS URLs');
  } else if (!proxyTest.success && !directTest.success) {
    log(colors.red, '❌ Both proxy and direct API calls are failing');
    log(colors.yellow, '🔧 Check if your Angular dev server is running on port 4000');
    log(colors.yellow, '🔧 Verify proxy.conf.json configuration');
  } else if (proxyTest.success && directTest.success) {
    log(colors.green, '✅ Both endpoints are working');
    log(colors.blue, '💡 Consider using proxy for consistency in development');
  } else {
    log(colors.yellow, '⚠️  Unexpected result pattern');
    log(colors.blue, '🔧 Review your configuration');
  }
  
  log(colors.bright + colors.magenta, '\n🏁 Test Complete!\n');
}

// Check if Angular dev server is likely running
function checkDevServer() {
  return new Promise((resolve) => {
    const req = http.get('http://localhost:4000', (res) => {
      resolve(true);
    });
    
    req.on('error', () => {
      resolve(false);
    });
    
    req.setTimeout(2000, () => {
      req.destroy();
      resolve(false);
    });
  });
}

async function main() {
  log(colors.bright + colors.blue, '🔍 Checking if Angular dev server is running...');
  
  const serverRunning = await checkDevServer();
  
  if (!serverRunning) {
    log(colors.red, '❌ Angular dev server doesn\'t appear to be running on port 4000');
    log(colors.yellow, '💡 Please run: npm run start:local');
    log(colors.yellow, '💡 Or: npx ng serve --port=4000 --proxy-config=proxy.conf.json');
    process.exit(1);
  }
  
  log(colors.green, '✅ Angular dev server detected on port 4000');
  await runTests();
}

if (require.main === module) {
  main().catch(console.error);
}