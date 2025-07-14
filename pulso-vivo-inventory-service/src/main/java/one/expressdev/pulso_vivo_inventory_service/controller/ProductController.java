package one.expressdev.pulso_vivo_inventory_service.controller;

import java.util.List;
import java.util.Map;
import java.util.HashMap;
import one.expressdev.pulso_vivo_inventory_service.dto.InventoryUpdateRequest;
import one.expressdev.pulso_vivo_inventory_service.dto.ProductDTO;
import one.expressdev.pulso_vivo_inventory_service.service.ProductService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/inventory")
@CrossOrigin(origins = "*")
public class ProductController {

    private static final Logger logger = LoggerFactory.getLogger(ProductController.class);

    @Autowired
    private ProductService productService;

    @GetMapping("/products")
    public ResponseEntity<?> getAllProducts() {
        try {
            logger.info("Getting all products");
            List<ProductDTO> products = productService.getAllProducts();
            logger.info("Found {} products", products.size());
            return ResponseEntity.ok(products);
        } catch (Exception e) {
            logger.error("Error getting all products", e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Internal server error");
            errorResponse.put("message", "Could not retrieve products");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @GetMapping("/products/{id}")
    public ResponseEntity<ProductDTO> getProductById(@PathVariable Long id) {
        try {
            logger.info("Getting product by id: {}", id);
            ProductDTO product = productService.getProductById(id);
            if (product == null) {
                logger.warn("Product not found with id: {}", id);
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok(product);
        } catch (Exception e) {
            logger.error("Error getting product by id: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @PostMapping("/products")
    public ResponseEntity<?> createProduct(
        @RequestBody ProductDTO dto
    ) {
        try {
            logger.info("Creating product: {}", dto.getName());
            ProductDTO product = productService.createProduct(dto);
            return ResponseEntity.status(HttpStatus.CREATED).body(product);
        } catch (RuntimeException e) {
            logger.error("Error creating product", e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to create product");
            errorResponse.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
        } catch (Exception e) {
            logger.error("Error creating product", e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Internal server error");
            errorResponse.put("message", "Could not create product");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @PutMapping("/products/{id}")
    public ResponseEntity<?> updateProduct(
        @PathVariable Long id,
        @RequestBody ProductDTO dto
    ) {
        try {
            logger.info("Updating product with id: {}", id);
            ProductDTO product = productService.updateProduct(id, dto);
            return ResponseEntity.ok(product);
        } catch (RuntimeException e) {
            logger.error("Error updating product with id: {}", id, e);
            Map<String, String> errorResponse = new HashMap<>();
            if (e.getMessage().contains("not found")) {
                errorResponse.put("error", "Product not found");
                errorResponse.put("message", e.getMessage());
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
            } else if (e.getMessage().contains("modified by another user")) {
                errorResponse.put("error", "Concurrent modification");
                errorResponse.put("message", e.getMessage());
                return ResponseEntity.status(HttpStatus.CONFLICT).body(errorResponse);
            } else {
                errorResponse.put("error", "Failed to update product");
                errorResponse.put("message", e.getMessage());
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
            }
        } catch (Exception e) {
            logger.error("Error updating product with id: {}", id, e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Internal server error");
            errorResponse.put("message", "Could not update product");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @PatchMapping("/products/{id}/stock")
    public ResponseEntity<?> updateStock(
        @PathVariable Long id,
        @RequestBody InventoryUpdateRequest request
    ) {
        try {
            logger.info("Updating stock for product id: {}", id);
            productService.updateStock(id, request);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            logger.error("Error updating stock for product id: {}", id, e);
            Map<String, String> errorResponse = new HashMap<>();
            if (e.getMessage().contains("not found")) {
                errorResponse.put("error", "Product not found");
                errorResponse.put("message", e.getMessage());
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(errorResponse);
            } else if (e.getMessage().contains("Insufficient stock")) {
                errorResponse.put("error", "Insufficient stock");
                errorResponse.put("message", e.getMessage());
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
            } else if (e.getMessage().contains("modified by another user")) {
                errorResponse.put("error", "Concurrent modification");
                errorResponse.put("message", e.getMessage());
                return ResponseEntity.status(HttpStatus.CONFLICT).body(errorResponse);
            } else {
                errorResponse.put("error", "Failed to update stock");
                errorResponse.put("message", e.getMessage());
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
            }
        } catch (Exception e) {
            logger.error("Error updating stock for product id: {}", id, e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Internal server error");
            errorResponse.put("message", "Could not update stock");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @GetMapping("/low-stock")
    public ResponseEntity<?> getLowStockProducts() {
        try {
            logger.info("Getting low stock products");
            List<ProductDTO> products = productService.getLowStockProducts();
            logger.info("Found {} low stock products", products.size());
            return ResponseEntity.ok(products);
        } catch (Exception e) {
            logger.error("Error getting low stock products", e);
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Internal server error");
            errorResponse.put("message", "Could not retrieve low stock products");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @PostMapping("/products/{id}/buy")
    public ResponseEntity<?> buyProduct(@PathVariable Long id, @RequestParam int quantity) {
        try {
            if (quantity <= 0) {
                return ResponseEntity.badRequest().body(Map.of("error", "Quantity must be greater than zero"));
            }
            InventoryUpdateRequest request = new InventoryUpdateRequest();
            request.setQuantityChanged(-quantity); // Reduce stock
            productService.updateStock(id, request);
            ProductDTO updatedProduct = productService.getProductById(id);
            return ResponseEntity.ok(updatedProduct);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", "Failed to buy product"));
        }
    }

}
