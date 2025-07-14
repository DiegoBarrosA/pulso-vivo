# Build stage
FROM docker.io/library/node:18-alpine AS build
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Accept build arguments for environment configuration
ARG INVENTORY_SERVICE_URL=http://localhost:8081/api
ARG API_GATEWAY_URL=https://erwqz80g2d.execute-api.us-east-1.amazonaws.com/api
ARG AZURE_AD_CLIENT_ID=7549ac9c-9294-4bb3-98d6-752d12b13d81
ARG AZURE_AD_AUTHORITY=https://PulsoVivo.b2clogin.com/PulsoVivo.onmicrosoft.com/B2C_1_pulso_vivo_register_and_login
ARG AZURE_AD_REDIRECT_URI=http://localhost:4200
ARG ENABLE_LOGGING=false

# Set environment variables for build
ENV INVENTORY_SERVICE_URL=$INVENTORY_SERVICE_URL
ENV API_GATEWAY_URL=$API_GATEWAY_URL
ENV AZURE_AD_CLIENT_ID=$AZURE_AD_CLIENT_ID
ENV AZURE_AD_AUTHORITY=$AZURE_AD_AUTHORITY
ENV AZURE_AD_REDIRECT_URI=$AZURE_AD_REDIRECT_URI
ENV ENABLE_LOGGING=$ENABLE_LOGGING

# Build the application for Docker (optimized build with proxy support)
RUN npm run build:docker

# Production stage
FROM docker.io/nginx:alpine

# Copy built application from build stage
COPY --from=build /app/dist/docker/browser /usr/share/nginx/html

# Copy nginx configuration template for Angular SPA
COPY nginx.conf.template /etc/nginx/templates/default.conf.template

# Create script to replace environment variables at runtime
RUN echo '#!/bin/sh' > /docker-entrypoint.d/30-envsubst.sh && \
    echo 'envsubst < /usr/share/nginx/html/assets/env.template.js > /usr/share/nginx/html/assets/env.js' >> /docker-entrypoint.d/30-envsubst.sh && \
    chmod +x /docker-entrypoint.d/30-envsubst.sh

# Create environment template file
RUN mkdir -p /usr/share/nginx/html/assets && \
    echo 'window.env = {' > /usr/share/nginx/html/assets/env.template.js && \
    echo '  INVENTORY_SERVICE_URL: "${INVENTORY_SERVICE_URL}",' >> /usr/share/nginx/html/assets/env.template.js && \
    echo '  API_GATEWAY_URL: "${API_GATEWAY_URL}",' >> /usr/share/nginx/html/assets/env.template.js && \
    echo '  AZURE_AD_CLIENT_ID: "${AZURE_AD_CLIENT_ID}",' >> /usr/share/nginx/html/assets/env.template.js && \
    echo '  AZURE_AD_AUTHORITY: "${AZURE_AD_AUTHORITY}",' >> /usr/share/nginx/html/assets/env.template.js && \
    echo '  AZURE_AD_REDIRECT_URI: "${AZURE_AD_REDIRECT_URI}",' >> /usr/share/nginx/html/assets/env.template.js && \
    echo '  ENABLE_LOGGING: "${ENABLE_LOGGING}"' >> /usr/share/nginx/html/assets/env.template.js && \
    echo '};' >> /usr/share/nginx/html/assets/env.template.js

# Set default environment variables
ENV INVENTORY_SERVICE_URL=http://localhost:8081/api
ENV API_GATEWAY_URL=https://erwqz80g2d.execute-api.us-east-1.amazonaws.com/api
ENV AZURE_AD_CLIENT_ID=7549ac9c-9294-4bb3-98d6-752d12b13d81
ENV AZURE_AD_AUTHORITY=https://PulsoVivo.b2clogin.com/PulsoVivo.onmicrosoft.com/B2C_1_pulso_vivo_register_and_login
ENV AZURE_AD_REDIRECT_URI=http://localhost:4200
ENV ENABLE_LOGGING=false

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
