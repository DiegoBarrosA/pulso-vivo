const https = require('https');
const http = require('http');

// Configuración de los microservicios
const MICROSERVICES = {
  sales: {
    host: process.env.EC2_INSTANCE_IP || '10.0.1.100',
    port: 8081,
    path: '/sales'
  },
  inventory: {
    host: process.env.EC2_INSTANCE_IP || '10.0.1.100',
    port: 8083,
    path: '/inventory'
  },
  promotions: {
    host: process.env.EC2_INSTANCE_IP || '10.0.1.100',
    port: 8085,
    path: '/promotions'
  },
  stock: {
    host: process.env.EC2_INSTANCE_IP || '10.0.1.100',
    port: 8084,
    path: '/stock'
  }
};

// Función helper para hacer proxy requests
async function proxyRequest(service, event) {
  const serviceConfig = MICROSERVICES[service];
  
  if (!serviceConfig) {
    throw new Error(`Service ${service} not found`);
  }
  
  const options = {
    hostname: serviceConfig.host,
    port: serviceConfig.port,
    path: event.path.replace(`/${service}`, serviceConfig.path),
    method: event.httpMethod,
    headers: {
      ...event.headers,
      'Host': `${serviceConfig.host}:${serviceConfig.port}`,
      'X-Forwarded-For': event.requestContext.identity.sourceIp,
      'X-Forwarded-Proto': 'https',
      'X-Forwarded-Port': '443',
      'X-User-Id': event.requestContext.authorizer?.userId || 'unknown',
      'X-User-Email': event.requestContext.authorizer?.email || 'unknown',
    }
  };
  
  // Remover headers que pueden causar problemas
  delete options.headers['Authorization'];
  delete options.headers['Host'];
  delete options.headers['X-Forwarded-For'];
  delete options.headers['X-Forwarded-Port'];
  delete options.headers['X-Forwarded-Proto'];
  delete options.headers['X-Amz-Cf-Id'];
  delete options.headers['X-Amzn-Trace-Id'];
  
  console.log('Proxy request options:', JSON.stringify(options, null, 2));
  
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const response = {
            statusCode: res.statusCode,
            headers: {
              'Content-Type': res.headers['content-type'] || 'application/json',
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
              'Access-Control-Allow-Credentials': 'true',
              ...res.headers
            },
            body: data
          };
          
          console.log('Proxy response:', JSON.stringify(response, null, 2));
          resolve(response);
        } catch (error) {
          console.error('Error processing response:', error);
          reject(error);
        }
      });
    });
    
    req.on('error', (error) => {
      console.error('Proxy request error:', error);
      reject(error);
    });
    
    req.on('timeout', () => {
      console.error('Proxy request timeout');
      req.abort();
      reject(new Error('Request timeout'));
    });
    
    // Configurar timeout
    req.setTimeout(30000);
    
    // Enviar body si existe
    if (event.body) {
      req.write(event.body);
    }
    
    req.end();
  });
}

// Función helper para manejar errores
function handleError(error, service) {
  console.error(`Error in ${service} proxy:`, error);
  
  return {
    statusCode: 500,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
    },
    body: JSON.stringify({
      error: 'Internal Server Error',
      message: `Error connecting to ${service} service`,
      timestamp: new Date().toISOString()
    })
  };
}

// Función helper para manejar CORS preflight
function handleCORS() {
  return {
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With, X-Amz-Date, X-Api-Key, X-Amz-Security-Token',
      'Access-Control-Allow-Credentials': 'true',
      'Access-Control-Max-Age': '86400'
    },
    body: ''
  };
}

// Handler para Sales Service
exports.salesHandler = async (event, context) => {
  console.log('Sales handler event:', JSON.stringify(event, null, 2));
  
  // Manejar CORS preflight
  if (event.httpMethod === 'OPTIONS') {
    return handleCORS();
  }
  
  try {
    return await proxyRequest('sales', event);
  } catch (error) {
    return handleError(error, 'sales');
  }
};

// Handler para Inventory Service
exports.inventoryHandler = async (event, context) => {
  console.log('Inventory handler event:', JSON.stringify(event, null, 2));
  
  // Manejar CORS preflight
  if (event.httpMethod === 'OPTIONS') {
    return handleCORS();
  }
  
  try {
    return await proxyRequest('inventory', event);
  } catch (error) {
    return handleError(error, 'inventory');
  }
};

// Handler para Promotions Service
exports.promotionsHandler = async (event, context) => {
  console.log('Promotions handler event:', JSON.stringify(event, null, 2));
  
  // Manejar CORS preflight
  if (event.httpMethod === 'OPTIONS') {
    return handleCORS();
  }
  
  try {
    return await proxyRequest('promotions', event);
  } catch (error) {
    return handleError(error, 'promotions');
  }
};

// Handler para Stock Service
exports.stockHandler = async (event, context) => {
  console.log('Stock handler event:', JSON.stringify(event, null, 2));
  
  // Manejar CORS preflight
  if (event.httpMethod === 'OPTIONS') {
    return handleCORS();
  }
  
  try {
    return await proxyRequest('stock', event);
  } catch (error) {
    return handleError(error, 'stock');
  }
};

// Handler genérico para cualquier servicio
exports.genericHandler = async (event, context) => {
  console.log('Generic handler event:', JSON.stringify(event, null, 2));
  
  // Manejar CORS preflight
  if (event.httpMethod === 'OPTIONS') {
    return handleCORS();
  }
  
  // Extraer el servicio del path
  const pathParts = event.path.split('/');
  const service = pathParts[1]; // Asumiendo que el path es /service/...
  
  if (!MICROSERVICES[service]) {
    return {
      statusCode: 404,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({
        error: 'Service not found',
        message: `Service ${service} is not available`,
        availableServices: Object.keys(MICROSERVICES)
      })
    };
  }
  
  try {
    return await proxyRequest(service, event);
  } catch (error) {
    return handleError(error, service);
  }
};

// Health check handler
exports.healthHandler = async (event, context) => {
  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
    body: JSON.stringify({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: '1.0.0',
      services: Object.keys(MICROSERVICES)
    })
  };
};
