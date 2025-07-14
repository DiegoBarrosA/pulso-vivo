const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

// Cliente JWKS para obtener claves públicas de Azure AD B2C
const client = jwksClient({
  jwksUri: process.env.AZURE_JWKS_URI,
  requestHeaders: {}, // Default headers
  timeout: 30000, // Defaults to 30s
});

function getKey(header, callback) {
  client.getSigningKey(header.kid, (err, key) => {
    if (err) {
      callback(err);
      return;
    }
    const signingKey = key.publicKey || key.rsaPublicKey;
    callback(null, signingKey);
  });
}

// Función para generar policy IAM
function generatePolicy(principalId, effect, resource) {
  const authResponse = {};
  
  authResponse.principalId = principalId;
  
  if (effect && resource) {
    const policyDocument = {};
    policyDocument.Version = '2012-10-17';
    policyDocument.Statement = [];
    
    const statementOne = {};
    statementOne.Action = 'execute-api:Invoke';
    statementOne.Effect = effect;
    statementOne.Resource = resource;
    
    policyDocument.Statement[0] = statementOne;
    authResponse.policyDocument = policyDocument;
  }
  
  return authResponse;
}

// Main handler function
exports.handler = async (event, context) => {
  console.log('Event:', JSON.stringify(event, null, 2));
  
  const token = event.authorizationToken;
  
  if (!token) {
    console.log('No token provided');
    throw new Error('Unauthorized');
  }
  
  // Remover "Bearer " si existe
  const cleanToken = token.replace('Bearer ', '');
  
  try {
    // Decodificar el token sin verificar para obtener el header
    const decoded = jwt.decode(cleanToken, { complete: true });
    
    if (!decoded || !decoded.header) {
      console.log('Invalid token format');
      throw new Error('Unauthorized');
    }
    
    console.log('Token header:', decoded.header);
    console.log('Token payload:', decoded.payload);
    
    // Verificar el token
    const verifyOptions = {
      algorithms: ['RS256'],
      audience: process.env.AZURE_AUDIENCE,
      issuer: process.env.AZURE_ISSUER,
      clockTolerance: 60, // 60 segundos de tolerancia
    };
    
    const verifiedToken = await new Promise((resolve, reject) => {
      jwt.verify(cleanToken, getKey, verifyOptions, (err, decoded) => {
        if (err) {
          console.log('Token verification failed:', err);
          reject(err);
        } else {
          console.log('Token verified successfully');
          resolve(decoded);
        }
      });
    });
    
    // Extraer información del usuario
    const principalId = verifiedToken.sub || verifiedToken.oid || 'user';
    const userInfo = {
      userId: principalId,
      email: verifiedToken.email || verifiedToken.emails?.[0],
      name: verifiedToken.name || verifiedToken.given_name,
      tenantId: verifiedToken.tid,
      clientId: verifiedToken.aud,
    };
    
    console.log('User info:', userInfo);
    
    // Generar policy de acceso
    const policy = generatePolicy(principalId, 'Allow', event.methodArn);
    
    // Agregar contexto del usuario
    policy.context = {
      userId: userInfo.userId,
      email: userInfo.email || '',
      name: userInfo.name || '',
      tenantId: userInfo.tenantId || '',
      clientId: userInfo.clientId || '',
    };
    
    console.log('Generated policy:', JSON.stringify(policy, null, 2));
    
    return policy;
    
  } catch (error) {
    console.log('Authorization failed:', error.message);
    
    // Para debugging en desarrollo
    if (process.env.NODE_ENV === 'development') {
      console.log('Full error:', error);
    }
    
    throw new Error('Unauthorized');
  }
};

// Función helper para validar claims específicos
function validateClaims(payload) {
  const now = Math.floor(Date.now() / 1000);
  
  // Verificar expiración
  if (payload.exp && payload.exp < now) {
    throw new Error('Token expired');
  }
  
  // Verificar not before
  if (payload.nbf && payload.nbf > now) {
    throw new Error('Token not yet valid');
  }
  
  // Verificar issued at
  if (payload.iat && payload.iat > now + 300) { // 5 minutos de tolerancia
    throw new Error('Token issued in the future');
  }
  
  // Verificar audience
  if (payload.aud !== process.env.AZURE_AUDIENCE) {
    throw new Error('Invalid audience');
  }
  
  // Verificar issuer
  if (payload.iss !== process.env.AZURE_ISSUER) {
    throw new Error('Invalid issuer');
  }
  
  return true;
}
