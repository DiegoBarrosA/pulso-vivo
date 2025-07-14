package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.controller;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.entity.Product;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.repository.ProductRepository;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.PriceChangeMonitoringService;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.PriceChangeNotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/monitoring")
public class ProductController {

    private final ProductRepository productRepository;
    private final PriceChangeNotificationService priceChangeNotificationService;
    private final PriceChangeMonitoringService priceChangeMonitoringService;

    public ProductController(ProductRepository productRepository,
                           PriceChangeNotificationService priceChangeNotificationService,
                           PriceChangeMonitoringService priceChangeMonitoringService) {
        this.productRepository = productRepository;
        this.priceChangeNotificationService = priceChangeNotificationService;
        this.priceChangeMonitoringService = priceChangeMonitoringService;
    }

    // Price change monitoring endpoints
    @PostMapping("/enable")
    public ResponseEntity<String> enablePriceMonitoring() {
        priceChangeNotificationService.setNotificationsEnabled(true);
        return ResponseEntity.ok("Price change monitoring enabled");
    }

    @PostMapping("/disable")
    public ResponseEntity<String> disablePriceMonitoring() {
        priceChangeNotificationService.setNotificationsEnabled(false);
        return ResponseEntity.ok("Price change monitoring disabled");
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getMonitoringStatus() {
        Map<String, Object> status = priceChangeMonitoringService.getMonitoringStatus();
        return ResponseEntity.ok(status);
    }

    @PostMapping("/force-scan")
    public ResponseEntity<String> forceFullScan() {
        priceChangeMonitoringService.forceFullScan();
        return ResponseEntity.ok("Full scan initiated");
    }

    // Read-only endpoints for monitoring purposes
    @GetMapping("/products/with-price-changes")
    public ResponseEntity<List<Product>> getProductsWithPriceChanges() {
        List<Product> products = productRepository.findProductsWithPriceChanges();
        return ResponseEntity.ok(products);
    }

    @GetMapping("/products/active")
    public ResponseEntity<List<Product>> getActiveProductsForMonitoring() {
        List<Product> products = productRepository.findActiveProducts();
        return ResponseEntity.ok(products);
    }

    @GetMapping("/products/{id}")
    public ResponseEntity<Product> getProductForMonitoring(@PathVariable Long id) {
        Optional<Product> product = productRepository.findById(id);
        return product.map(ResponseEntity::ok)
                     .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/products/category/{category}")
    public ResponseEntity<List<Product>> getProductsByCategoryForMonitoring(@PathVariable String category) {
        List<Product> products = productRepository.findActiveProductsByCategory(category);
        return ResponseEntity.ok(products);
    }

    // Test endpoints for price change functionality (for development/testing only)
    @PostMapping("/test/price-increase/{id}")
    public ResponseEntity<String> testPriceIncrease(@PathVariable Long id, @RequestParam double percentage) {
        Optional<Product> optionalProduct = productRepository.findById(id);
        
        if (optionalProduct.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        Product product = optionalProduct.get();
        BigDecimal currentPrice = product.getPrice();
        
        if (currentPrice == null) {
            return ResponseEntity.badRequest().body("Product has no current price set");
        }

        BigDecimal increaseAmount = currentPrice.multiply(BigDecimal.valueOf(percentage / 100));
        BigDecimal newPrice = currentPrice.add(increaseAmount);
        
        product.updatePrice(newPrice);
        productRepository.save(product);
        
        return ResponseEntity.ok(String.format("Price increased by %.2f%% from $%.2f to $%.2f", 
                                              percentage, currentPrice, newPrice));
    }

    @PostMapping("/test/price-decrease/{id}")
    public ResponseEntity<String> testPriceDecrease(@PathVariable Long id, @RequestParam double percentage) {
        Optional<Product> optionalProduct = productRepository.findById(id);
        
        if (optionalProduct.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        Product product = optionalProduct.get();
        BigDecimal currentPrice = product.getPrice();
        
        if (currentPrice == null) {
            return ResponseEntity.badRequest().body("Product has no current price set");
        }

        BigDecimal decreaseAmount = currentPrice.multiply(BigDecimal.valueOf(percentage / 100));
        BigDecimal newPrice = currentPrice.subtract(decreaseAmount);
        
        if (newPrice.compareTo(BigDecimal.ZERO) < 0) {
            newPrice = BigDecimal.ZERO;
        }
        
        product.updatePrice(newPrice);
        productRepository.save(product);
        
        return ResponseEntity.ok(String.format("Price decreased by %.2f%% from $%.2f to $%.2f", 
                                              percentage, currentPrice, newPrice));
    }

    @PostMapping("/test/set-price/{id}")
    public ResponseEntity<String> testSetPrice(@PathVariable Long id, @RequestParam BigDecimal newPrice) {
        Optional<Product> optionalProduct = productRepository.findById(id);
        
        if (optionalProduct.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        Product product = optionalProduct.get();
        BigDecimal oldPrice = product.getPrice();
        
        product.updatePrice(newPrice);
        productRepository.save(product);
        
        return ResponseEntity.ok(String.format("Price changed from $%.2f to $%.2f", 
                                              oldPrice != null ? oldPrice : BigDecimal.ZERO, newPrice));
    }

    // Offer monitoring endpoints
    @GetMapping("/offers/current")
    public ResponseEntity<List<Product>> getCurrentOffers() {
        // Products with recent price decreases could be considered offers
        List<Product> products = productRepository.findProductsWithPriceChanges();
        List<Product> offers = products.stream()
                .filter(p -> p.getPriceChangeAmount().compareTo(BigDecimal.ZERO) < 0) // Price decreased
                .toList();
        return ResponseEntity.ok(offers);
    }

    @GetMapping("/price-alerts/recent")
    public ResponseEntity<List<Product>> getRecentPriceAlerts() {
        List<Product> products = productRepository.findProductsWithPriceChanges();
        return ResponseEntity.ok(products);
    }
}