package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto.PriceChangeEventDTO;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.entity.Product;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.repository.ProductRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;

@Service
@ConditionalOnProperty(value = "price.monitoring.enabled", havingValue = "true", matchIfMissing = true)
public class PriceChangeMonitoringService {

    private static final Logger logger = LoggerFactory.getLogger(PriceChangeMonitoringService.class);

    private final ProductRepository productRepository;
    private final PriceChangeNotificationService priceChangeNotificationService;
    
    // Cache to store last known prices for comparison
    private final Map<Long, ProductPriceSnapshot> lastKnownPrices = new ConcurrentHashMap<>();
    
    @Value("${price.monitoring.poll-interval:30000}")
    private long pollIntervalMs;
    
    @Value("${price.monitoring.max-products-per-batch:100}")
    private int maxProductsPerBatch;
    
    private LocalDateTime lastPollTime;

    public PriceChangeMonitoringService(ProductRepository productRepository, 
                                       PriceChangeNotificationService priceChangeNotificationService) {
        this.productRepository = productRepository;
        this.priceChangeNotificationService = priceChangeNotificationService;
        this.lastPollTime = LocalDateTime.now().minusMinutes(5); // Start with 5 minutes ago
    }

    @Scheduled(fixedRateString = "${price.monitoring.poll-interval:30000}")
    @Transactional(readOnly = true)
    public void monitorPriceChanges() {
        if (!priceChangeNotificationService.isNotificationsEnabled()) {
            logger.debug("Price monitoring is disabled, skipping poll");
            return;
        }

        try {
            logger.debug("Starting price change monitoring poll");
            
            LocalDateTime currentPollTime = LocalDateTime.now();
            
            // Get products updated since last poll
            List<Product> updatedProducts = productRepository.findProductsUpdatedAfter(lastPollTime);
            
            logger.info("Found {} products updated since {}", updatedProducts.size(), lastPollTime);
            
            int processedCount = 0;
            int notificationsSent = 0;
            
            for (Product product : updatedProducts) {
                if (processedCount >= maxProductsPerBatch) {
                    logger.warn("Reached maximum batch size of {}. {} products will be processed in next poll", 
                              maxProductsPerBatch, updatedProducts.size() - processedCount);
                    break;
                }
                
                try {
                    if (processProductPriceChange(product)) {
                        notificationsSent++;
                    }
                    processedCount++;
                } catch (Exception e) {
                    logger.error("Error processing price change for product ID {}: {}", 
                               product.getId(), e.getMessage(), e);
                }
            }
            
            lastPollTime = currentPollTime;
            
            logger.info("Price monitoring poll completed. Processed: {}, Notifications sent: {}", 
                       processedCount, notificationsSent);
            
        } catch (Exception e) {
            logger.error("Error during price monitoring poll: {}", e.getMessage(), e);
        }
    }

    private boolean processProductPriceChange(Product product) {
        ProductPriceSnapshot lastSnapshot = lastKnownPrices.get(product.getId());
        ProductPriceSnapshot currentSnapshot = new ProductPriceSnapshot(product);
        
        // Update cache with current snapshot
        lastKnownPrices.put(product.getId(), currentSnapshot);
        
        // If we don't have a previous snapshot, this is the first time we see this product
        if (lastSnapshot == null) {
            logger.debug("First time seeing product ID {}, storing initial price snapshot", product.getId());
            return false;
        }
        
        // Check if price has changed
        if (lastSnapshot.hasPrice() && currentSnapshot.hasPrice() && 
            lastSnapshot.getPrice().compareTo(currentSnapshot.getPrice()) != 0) {
            
            PriceChangeEventDTO priceChangeEvent = PriceChangeEventDTO.fromProduct(
                product.getId(),
                product.getName(),
                product.getCategory(),
                lastSnapshot.getPrice(),
                currentSnapshot.getPrice()
            );
            
            priceChangeEvent.setChangeReason("External price change detected via polling");
            
            logger.info("Price change detected for product ID {}: {} -> {}", 
                       product.getId(), lastSnapshot.getPrice(), currentSnapshot.getPrice());
            
            priceChangeNotificationService.notifyPriceChange(priceChangeEvent);
            return true;
        }
        
        return false;
    }

    @Scheduled(fixedRate = 300000) // Every 5 minutes
    public void cleanupCache() {
        int initialSize = lastKnownPrices.size();
        LocalDateTime cutoffTime = LocalDateTime.now().minusHours(24);
        
        lastKnownPrices.entrySet().removeIf(entry -> 
            entry.getValue().getTimestamp().isBefore(cutoffTime));
        
        int removedEntries = initialSize - lastKnownPrices.size();
        if (removedEntries > 0) {
            logger.debug("Cleaned up {} stale cache entries", removedEntries);
        }
    }

    public void forceFullScan() {
        logger.info("Starting forced full scan of all products");
        
        try {
            List<Product> allProducts = productRepository.findActiveProducts();
            logger.info("Found {} active products for full scan", allProducts.size());
            
            for (Product product : allProducts) {
                lastKnownPrices.put(product.getId(), new ProductPriceSnapshot(product));
            }
            
            logger.info("Full scan completed, cached {} product snapshots", allProducts.size());
            
        } catch (Exception e) {
            logger.error("Error during forced full scan: {}", e.getMessage(), e);
        }
    }

    public Map<String, Object> getMonitoringStatus() {
        Map<String, Object> status = new ConcurrentHashMap<>();
        status.put("enabled", priceChangeNotificationService.isNotificationsEnabled());
        status.put("lastPollTime", lastPollTime);
        status.put("pollIntervalMs", pollIntervalMs);
        status.put("cachedProducts", lastKnownPrices.size());
        status.put("maxProductsPerBatch", maxProductsPerBatch);
        return status;
    }

    // Inner class to store product price snapshots
    private static class ProductPriceSnapshot {
        private final java.math.BigDecimal price;
        private final LocalDateTime timestamp;
        private final Long version;
        
        public ProductPriceSnapshot(Product product) {
            this.price = product.getPrice();
            this.timestamp = LocalDateTime.now();
            this.version = product.getVersion();
        }
        
        public java.math.BigDecimal getPrice() {
            return price;
        }
        
        public LocalDateTime getTimestamp() {
            return timestamp;
        }
        
        public Long getVersion() {
            return version;
        }
        
        public boolean hasPrice() {
            return price != null;
        }
    }
}