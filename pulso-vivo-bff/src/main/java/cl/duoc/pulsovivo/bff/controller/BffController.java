package cl.duoc.pulsovivo.bff.controller;

import cl.duoc.pulsovivo.bff.client.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class BffController {

    @Autowired
    private InventoryServiceClient inventoryServiceClient;

    @Autowired
    private SalesServiceClient salesServiceClient;

    @Autowired
    private MonitoringServiceClient monitoringServiceClient;

    @Autowired
    private StockServiceClient stockServiceClient;

    @Autowired
    private PromotionsServiceClient promotionsServiceClient;

    @Autowired
    private RabbitMQAdminServiceClient rabbitMQAdminServiceClient;

    // Inventory Service Endpoints
    @GetMapping("/inventory/products")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> getAllProducts() {
        return inventoryServiceClient.getAllProducts();
    }

    @GetMapping("/inventory/products/{id}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> getProductById(@PathVariable String id) {
        return inventoryServiceClient.getProductById(id);
    }

    @PostMapping("/inventory/products")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> createProduct(@RequestBody Object product) {
        return inventoryServiceClient.createProduct(product);
    }

    @PutMapping("/inventory/products/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> updateProduct(@PathVariable String id, @RequestBody Object product) {
        return inventoryServiceClient.updateProduct(id, product);
    }

    @DeleteMapping("/inventory/products/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> deleteProduct(@PathVariable String id) {
        return inventoryServiceClient.deleteProduct(id);
    }

    @GetMapping("/inventory/products/low-stock")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> getLowStockProducts() {
        return inventoryServiceClient.getLowStockProducts();
    }

    @PostMapping("/inventory/update")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> updateProductInventory(@RequestBody Object inventoryUpdate) {
        return inventoryServiceClient.updateProductInventory(inventoryUpdate);
    }

    // Sales Service Endpoints
    @PostMapping("/ventas")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> createSale(@RequestBody Object sale) {
        return salesServiceClient.createSale(sale);
    }

    @GetMapping("/ventas/recientes")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> getRecentSales() {
        return salesServiceClient.getRecentSales();
    }

    // Monitoring Service Endpoints
    @GetMapping("/monitoring/products")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> getAllProductsPriceMonitor() {
        return monitoringServiceClient.getAllProductsPriceMonitor();
    }

    @GetMapping("/monitoring/products/{id}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> getProductByIdPriceMonitor(@PathVariable String id) {
        return monitoringServiceClient.getProductByIdPriceMonitor(id);
    }

    @PutMapping("/monitoring/products/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> updateProductPrice(@PathVariable String id, @RequestBody Object productUpdate) {
        return monitoringServiceClient.updateProductPrice(id, productUpdate);
    }

    @GetMapping("/monitoring/products/active")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> getActiveProductsForMonitoring() {
        return monitoringServiceClient.getActiveProductsForMonitoring();
    }

    @GetMapping("/monitoring/products/category/{category}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> getProductsByCategory(@PathVariable String category) {
        return monitoringServiceClient.getProductsByCategory(category);
    }

    @GetMapping("/price-monitoring/status")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> getMonitoringStatus() {
        return monitoringServiceClient.getMonitoringStatus();
    }

    @PostMapping("/price-monitoring/enable")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> enablePriceMonitoring() {
        return monitoringServiceClient.enablePriceMonitoring();
    }

    @PostMapping("/price-monitoring/disable")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> disablePriceMonitoring() {
        return monitoringServiceClient.disablePriceMonitoring();
    }

    @PostMapping("/mensajes")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> sendMessage(@RequestBody Object message) {
        return monitoringServiceClient.sendMessage(message);
    }

    @PostMapping("/productos/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> sendProductObject(@PathVariable String id, @RequestBody Object product) {
        return monitoringServiceClient.sendProductObject(id, product);
    }

    // Stock Service Endpoints
    @GetMapping("/stock/producto/{productCode}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> getStockByProductCode(@PathVariable String productCode) {
        return stockServiceClient.getStockByProductCode(productCode);
    }

    @GetMapping("/stock/recent")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> getRecentStockMovements() {
        return stockServiceClient.getRecentStockMovements();
    }

    @GetMapping("/stock/stats/{productCode}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> getStockStatistics(@PathVariable String productCode) {
        return stockServiceClient.getStockStatistics(productCode);
    }

    // Promotions Service Endpoints
    @GetMapping("/promotions/active")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> getActivePromotions() {
        return promotionsServiceClient.getActivePromotions();
    }

    @GetMapping("/promotions/product/{productId}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<Object> getPromotionsByProduct(@PathVariable String productId) {
        return promotionsServiceClient.getPromotionsByProduct(productId);
    }

    @PostMapping("/promotions/generate")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> generatePromotion(@RequestBody Object promotion) {
        return promotionsServiceClient.generatePromotion(promotion);
    }

    // RabbitMQ Admin Endpoints
    @PostMapping("/rabbit-admin/colas/{queueName}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> createRabbitMQQueue(@PathVariable String queueName) {
        return rabbitMQAdminServiceClient.createRabbitMQQueue(queueName);
    }

    @PostMapping("/rabbit-admin/exchanges/{exchangeName}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> createRabbitMQExchange(@PathVariable String exchangeName) {
        return rabbitMQAdminServiceClient.createRabbitMQExchange(exchangeName);
    }

    // Health Check Endpoints
    @GetMapping("/health")
    public ResponseEntity<Object> getBffHealth() {
        return ResponseEntity.ok().body("{\"status\":\"UP\",\"service\":\"pulso-vivo-bff\"}");
    }

    @GetMapping("/inventory/health")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> getInventoryHealth() {
        return inventoryServiceClient.getHealthStatus();
    }

    @GetMapping("/sales/health")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> getSalesHealth() {
        return salesServiceClient.getHealthStatus();
    }

    @GetMapping("/promotions/health")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Object> getPromotionsHealth() {
        return promotionsServiceClient.getPromotionsHealth();
    }
}