#!/bin/bash

# Script para obtener y configurar las claves públicas de Azure AD B2C
# =====================================================================

source /scripts/azure-ad-b2c.env

echo "🔑 Obteniendo claves públicas de Azure AD B2C..."

# Obtener el JWKS (JSON Web Key Set) de Azure AD B2C
JWKS_RESPONSE=$(curl -s "${JWKS_URI}")

if [ $? -eq 0 ]; then
    echo "✅ JWKS obtenido exitosamente de Azure AD B2C"
    echo "📄 JWKS Response:"
    echo "${JWKS_RESPONSE}" | jq .
    
    # Extraer la primera clave pública (normalmente la activa)
    PUBLIC_KEY=$(echo "${JWKS_RESPONSE}" | jq -r '.keys[0].x5c[0]')
    
    if [ "$PUBLIC_KEY" != "null" ] && [ "$PUBLIC_KEY" != "" ]; then
        echo "🔐 Clave pública extraída exitosamente"
        
        # Convertir la clave X.509 a formato PEM
        echo "-----BEGIN CERTIFICATE-----" > /tmp/azure_ad_b2c_cert.pem
        echo "$PUBLIC_KEY" >> /tmp/azure_ad_b2c_cert.pem
        echo "-----END CERTIFICATE-----" >> /tmp/azure_ad_b2c_cert.pem
        
        # Extraer la clave pública del certificado
        openssl x509 -in /tmp/azure_ad_b2c_cert.pem -pubkey -noout > /tmp/azure_ad_b2c_public_key.pem
        
        if [ $? -eq 0 ]; then
            echo "🎯 Clave pública RSA extraída y guardada en /tmp/azure_ad_b2c_public_key.pem"
            cat /tmp/azure_ad_b2c_public_key.pem
        else
            echo "❌ Error al extraer la clave pública del certificado"
        fi
    else
        echo "❌ No se pudo extraer la clave pública del JWKS"
    fi
else
    echo "❌ Error al obtener JWKS de Azure AD B2C"
fi

# Verificar la configuración OpenID Connect
echo ""
echo "🔍 Verificando configuración OpenID Connect..."
OPENID_CONFIG=$(curl -s "${OPENID_DISCOVERY_URL}")

if [ $? -eq 0 ]; then
    echo "✅ Configuración OpenID Connect obtenida:"
    echo "${OPENID_CONFIG}" | jq '{
        issuer: .issuer,
        authorization_endpoint: .authorization_endpoint,
        token_endpoint: .token_endpoint,
        jwks_uri: .jwks_uri,
        response_types_supported: .response_types_supported,
        subject_types_supported: .subject_types_supported,
        id_token_signing_alg_values_supported: .id_token_signing_alg_values_supported
    }'
else
    echo "❌ Error al obtener la configuración OpenID Connect"
fi

echo ""
echo "📋 INFORMACIÓN DE CONFIGURACIÓN:"
echo "================================"
echo "🏢 Tenant: ${AZURE_AD_B2C_TENANT_NAME}"
echo "🆔 Tenant ID: ${AZURE_AD_B2C_TENANT_ID}"
echo "📝 Policy: ${AZURE_AD_B2C_POLICY}"
echo "🔗 Issuer: ${JWT_ISSUER}"
echo "👥 Audience: ${JWT_AUDIENCE}"
echo "🔐 Algorithm: ${JWT_ALGORITHM}"
echo "🔑 JWKS URI: ${JWKS_URI}"
