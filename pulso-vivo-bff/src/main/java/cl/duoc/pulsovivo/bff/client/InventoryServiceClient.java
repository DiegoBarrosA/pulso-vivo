package cl.duoc.pulsovivo.bff.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@FeignClient(
    name = "inventory-service",
    url = "${services.inventory.url}",
    configuration = cl.duoc.pulsovivo.bff.config.FeignConfig.class
)
public interface InventoryServiceClient {

    @GetMapping("/api/inventory/products")
    ResponseEntity<Object> getAllProducts();

    @GetMapping("/api/inventory/products/{id}")
    ResponseEntity<Object> getProductById(@PathVariable("id") String id);

    @PostMapping("/api/inventory/products")
    ResponseEntity<Object> createProduct(@RequestBody Object product);

    @PutMapping("/api/inventory/products/{id}")
    ResponseEntity<Object> updateProduct(@PathVariable("id") String id, @RequestBody Object product);

    @DeleteMapping("/api/inventory/products/{id}")
    ResponseEntity<Object> deleteProduct(@PathVariable("id") String id);

    @GetMapping("/api/inventory/products/low-stock")
    ResponseEntity<Object> getLowStockProducts();

    @PostMapping("/api/inventory/update")
    ResponseEntity<Object> updateProductInventory(@RequestBody Object inventoryUpdate);

    @GetMapping("/api/health")
    ResponseEntity<Object> getHealthStatus();
}