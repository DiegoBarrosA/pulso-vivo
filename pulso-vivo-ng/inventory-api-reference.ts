// Pulso Vivo Inventory API Endpoints
// Base URL: https://puicky4br7.execute-api.us-east-1.amazonaws.com/prod

/**
 * INVENTORY ENDPOINTS
 * All endpoints require Azure AD B2C authentication
 * Authorization: Bearer <JWT_TOKEN>
 */

export const INVENTORY_ENDPOINTS = {
  // Get all products
  GET_ALL_PRODUCTS: {
    method: 'GET',
    path: '/api/inventory/products',
    description: 'Retrieve all products from inventory'
  },

  // Get product by ID
  GET_PRODUCT_BY_ID: {
    method: 'GET',
    path: '/api/inventory/products/{id}',
    description: 'Retrieve a specific product by ID',
    params: ['id']
  },

  // Create new product
  CREATE_PRODUCT: {
    method: 'POST',
    path: '/api/inventory/products',
    description: 'Create a new product in inventory',
    requiresBody: true
  },

  // Update product
  UPDATE_PRODUCT: {
    method: 'PUT',
    path: '/api/inventory/products/{id}',
    description: 'Update an existing product',
    params: ['id'],
    requiresBody: true
  },

  // Delete product
  DELETE_PRODUCT: {
    method: 'DELETE',
    path: '/api/inventory/products/{id}',
    description: 'Delete a product from inventory',
    params: ['id']
  },

  // Get low stock products
  GET_LOW_STOCK: {
    method: 'GET',
    path: '/api/inventory/products/low-stock',
    description: 'Retrieve products with low stock levels'
  },

  // Update inventory
  UPDATE_INVENTORY: {
    method: 'POST',
    path: '/api/inventory/update',
    description: 'Update inventory levels',
    requiresBody: true
  }
};

/**
 * Example usage in Angular service:
 * 
 * const baseUrl = 'https://puicky4br7.execute-api.us-east-1.amazonaws.com/prod';
 * 
 * // Get all products
 * this.http.get(`${baseUrl}/api/inventory/products`, { headers: authHeaders })
 * 
 * // Get product by ID
 * this.http.get(`${baseUrl}/api/inventory/products/123`, { headers: authHeaders })
 * 
 * // Create product
 * this.http.post(`${baseUrl}/api/inventory/products`, productData, { headers: authHeaders })
 * 
 * // Update product
 * this.http.put(`${baseUrl}/api/inventory/products/123`, updateData, { headers: authHeaders })
 * 
 * // Delete product
 * this.http.delete(`${baseUrl}/api/inventory/products/123`, { headers: authHeaders })
 * 
 * // Get low stock products
 * this.http.get(`${baseUrl}/api/inventory/products/low-stock`, { headers: authHeaders })
 * 
 * // Update inventory
 * this.http.post(`${baseUrl}/api/inventory/update`, inventoryData, { headers: authHeaders })
 */

/**
 * Authentication headers required:
 * {
 *   'Authorization': 'Bearer <JWT_TOKEN>',
 *   'Content-Type': 'application/json'
 * }
 * 
 * The JWT token should be obtained from Azure B2C authentication
 * Client ID: e30e27b2-1240-4f61-a8bd-25aacc63ab36
 * Tenant ID: 82c6cf20-e689-4aa9-bedf-7acaf7c4ead7
 */
