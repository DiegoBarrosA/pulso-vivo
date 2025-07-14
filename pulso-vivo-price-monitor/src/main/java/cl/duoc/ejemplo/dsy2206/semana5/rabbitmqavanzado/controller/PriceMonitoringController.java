package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.controller;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto.PriceChangeEventDTO;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.entity.Product;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.repository.ProductRepository;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.PriceChangeMonitoringService;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.PriceChangeNotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/price-monitoring")
@CrossOrigin(origins = "*")
public class PriceMonitoringController {

    private final ProductRepository productRepository;
    private final PriceChangeNotificationService priceChangeNotificationService;
    private final PriceChangeMonitoringService priceChangeMonitoringService;

    public PriceMonitoringController(ProductRepository productRepository,
                                   PriceChangeNotificationService priceChangeNotificationService,
                                   PriceChangeMonitoringService priceChangeMonitoringService) {
        this.productRepository = productRepository;
        this.priceChangeNotificationService = priceChangeNotificationService;
        this.priceChangeMonitoringService = priceChangeMonitoringService;
    }

    // Core monitoring controls
    @PostMapping("/enable")
    public ResponseEntity<Map<String, Object>> enablePriceMonitoring() {
        priceChangeNotificationService.setNotificationsEnabled(true);
        return ResponseEntity.ok(Map.of(
            "status", "enabled",
            "message", "Price change monitoring enabled",
            "timestamp", LocalDateTime.now()
        ));
    }

    @PostMapping("/disable")
    public ResponseEntity<Map<String, Object>> disablePriceMonitoring() {
        priceChangeNotificationService.setNotificationsEnabled(false);
        return ResponseEntity.ok(Map.of(
            "status", "disabled",
            "message", "Price change monitoring disabled",
            "timestamp", LocalDateTime.now()
        ));
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getMonitoringStatus() {
        Map<String, Object> status = priceChangeMonitoringService.getMonitoringStatus();
        return ResponseEntity.ok(status);
    }

    @PostMapping("/force-scan")
    public ResponseEntity<Map<String, Object>> forceFullScan() {
        priceChangeMonitoringService.forceFullScan();
        return ResponseEntity.ok(Map.of(
            "message", "Full scan initiated",
            "timestamp", LocalDateTime.now(),
            "scanType", "manual"
        ));
    }

    // Price change analysis endpoints
    @GetMapping("/price-changes")
    public ResponseEntity<List<PriceChangeEventDTO>> getRecentPriceChanges() {
        List<Product> products = productRepository.findProductsWithPriceChanges();
        List<PriceChangeEventDTO> priceChanges = products.stream()
                .filter(Product::hasPriceChanged)
                .map(product -> PriceChangeEventDTO.fromProduct(
                    product.getId(),
                    product.getName(),
                    product.getCategory(),
                    product.getPreviousPrice(),
                    product.getPrice()
                ))
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(priceChanges);
    }

    @GetMapping("/price-changes/{productId}")
    public ResponseEntity<PriceChangeEventDTO> getProductPriceChange(@PathVariable Long productId) {
        Optional<Product> productOpt = productRepository.findById(productId);
        
        if (productOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        
        Product product = productOpt.get();
        if (!product.hasPriceChanged()) {
            return ResponseEntity.noContent().build();
        }
        
        PriceChangeEventDTO priceChange = PriceChangeEventDTO.fromProduct(
            product.getId(),
            product.getName(),
            product.getCategory(),
            product.getPreviousPrice(),
            product.getPrice()
        );
        
        return ResponseEntity.ok(priceChange);
    }

    // Offer detection and monitoring
    @GetMapping("/offers")
    public ResponseEntity<List<PriceChangeEventDTO>> getCurrentOffers() {
        List<Product> products = productRepository.findProductsWithPriceChanges();
        List<PriceChangeEventDTO> offers = products.stream()
                .filter(product -> product.hasPriceChanged() && 
                        product.getPriceChangeAmount().compareTo(BigDecimal.ZERO) < 0) // Price decreased
                .map(product -> PriceChangeEventDTO.fromProduct(
                    product.getId(),
                    product.getName(),
                    product.getCategory(),
                    product.getPreviousPrice(),
                    product.getPrice()
                ))
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(offers);
    }

    @GetMapping("/offers/category/{category}")
    public ResponseEntity<List<PriceChangeEventDTO>> getOffersByCategory(@PathVariable String category) {
        List<Product> products = productRepository.findActiveProductsByCategory(category);
        List<PriceChangeEventDTO> offers = products.stream()
                .filter(product -> product.hasPriceChanged() && 
                        product.getPriceChangeAmount().compareTo(BigDecimal.ZERO) < 0)
                .map(product -> PriceChangeEventDTO.fromProduct(
                    product.getId(),
                    product.getName(),
                    product.getCategory(),
                    product.getPreviousPrice(),
                    product.getPrice()
                ))
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(offers);
    }

    // Price alert endpoints
    @GetMapping("/alerts/price-increases")
    public ResponseEntity<List<PriceChangeEventDTO>> getPriceIncreases() {
        List<Product> products = productRepository.findProductsWithPriceChanges();
        List<PriceChangeEventDTO> increases = products.stream()
                .filter(product -> product.hasPriceChanged() && 
                        product.getPriceChangeAmount().compareTo(BigDecimal.ZERO) > 0) // Price increased
                .map(product -> PriceChangeEventDTO.fromProduct(
                    product.getId(),
                    product.getName(),
                    product.getCategory(),
                    product.getPreviousPrice(),
                    product.getPrice()
                ))
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(increases);
    }

    @GetMapping("/alerts/significant-changes")
    public ResponseEntity<List<PriceChangeEventDTO>> getSignificantPriceChanges(@RequestParam(defaultValue = "10.0") double threshold) {
        List<Product> products = productRepository.findProductsWithPriceChanges();
        List<PriceChangeEventDTO> significantChanges = products.stream()
                .filter(product -> product.hasPriceChanged() && 
                        Math.abs(product.getPriceChangePercentage()) >= threshold)
                .map(product -> PriceChangeEventDTO.fromProduct(
                    product.getId(),
                    product.getName(),
                    product.getCategory(),
                    product.getPreviousPrice(),
                    product.getPrice()
                ))
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(significantChanges);
    }

    // Statistics and analytics
    @GetMapping("/statistics")
    public ResponseEntity<Map<String, Object>> getPriceChangeStatistics() {
        List<Product> allProducts = productRepository.findAll();
        List<Product> productsWithChanges = productRepository.findProductsWithPriceChanges();
        
        long totalProducts = allProducts.size();
        long productsWithPriceChanges = productsWithChanges.size();
        long priceIncreases = productsWithChanges.stream()
                .filter(p -> p.getPriceChangeAmount().compareTo(BigDecimal.ZERO) > 0)
                .count();
        long priceDecreases = productsWithChanges.stream()
                .filter(p -> p.getPriceChangeAmount().compareTo(BigDecimal.ZERO) < 0)
                .count();
        
        double avgPriceChangePercentage = productsWithChanges.stream()
                .mapToDouble(Product::getPriceChangePercentage)
                .average()
                .orElse(0.0);
        
        Map<String, Object> statistics = Map.of(
            "totalProducts", totalProducts,
            "productsWithPriceChanges", productsWithPriceChanges,
            "priceIncreases", priceIncreases,
            "priceDecreases", priceDecreases,
            "averagePriceChangePercentage", Math.round(avgPriceChangePercentage * 100.0) / 100.0,
            "lastUpdated", LocalDateTime.now()
        );
        
        return ResponseEntity.ok(statistics);
    }

    // Configuration endpoints
    @PostMapping("/config/notification-threshold")
    public ResponseEntity<Map<String, Object>> setNotificationThreshold(@RequestParam double threshold) {
        // This would typically update a configuration service
        return ResponseEntity.ok(Map.of(
            "message", "Notification threshold updated",
            "threshold", threshold,
            "timestamp", LocalDateTime.now()
        ));
    }

    @GetMapping("/config")
    public ResponseEntity<Map<String, Object>> getMonitoringConfiguration() {
        // Return current monitoring configuration
        return ResponseEntity.ok(Map.of(
            "notificationsEnabled", true, // This should come from actual config
            "scanInterval", 30, // seconds
            "priceChangeThreshold", 5.0, // percentage
            "maxRetries", 3,
            "queueStatus", "active"
        ));
    }

    // Health check for monitoring service
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> getMonitoringHealth() {
        boolean isHealthy = true; // Implement actual health checks
        
        return ResponseEntity.ok(Map.of(
            "status", isHealthy ? "healthy" : "unhealthy",
            "timestamp", LocalDateTime.now(),
            "services", Map.of(
                "priceMonitoring", "active",
                "rabbitMQ", "connected",
                "database", "connected"
            )
        ));
    }
}