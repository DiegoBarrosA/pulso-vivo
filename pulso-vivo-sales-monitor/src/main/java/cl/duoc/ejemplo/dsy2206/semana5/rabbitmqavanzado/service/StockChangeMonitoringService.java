package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.StockChangeNotificationService;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto.StockChangeEventDTO;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.entity.Product;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.repository.ProductRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
@ConditionalOnProperty(value = "stock.monitoring.enabled", havingValue = "true", matchIfMissing = true)
public class StockChangeMonitoringService {
    private static final Logger logger = LoggerFactory.getLogger(StockChangeMonitoringService.class);

    private final ProductRepository productRepository;
    private final StockChangeNotificationService stockChangeNotificationService;
    private final Map<Long, Integer> lastKnownQuantities = new ConcurrentHashMap<>();

    @Value("${stock.monitoring.poll-interval:30000}")
    private long pollIntervalMs;

    private LocalDateTime lastPollTime;

    public StockChangeMonitoringService(ProductRepository productRepository, StockChangeNotificationService stockChangeNotificationService) {
        this.productRepository = productRepository;
        this.stockChangeNotificationService = stockChangeNotificationService;
        this.lastPollTime = LocalDateTime.now().minusMinutes(5);
    }

    @Scheduled(fixedRateString = "${stock.monitoring.poll-interval:30000}")
    @Transactional(readOnly = true)
    public void monitorStockChanges() {
        if (!stockChangeNotificationService.isNotificationsEnabled()) {
            logger.debug("Stock monitoring is disabled, skipping poll");
            return;
        }
        try {
            logger.debug("Starting stock change monitoring poll");
            List<Product> products = productRepository.findActiveProducts();
            for (Product product : products) {
                int currentQuantity = product.getQuantity();
                Long productId = product.getId();
                Integer lastQuantity = lastKnownQuantities.get(productId);
                if (lastQuantity != null && currentQuantity < lastQuantity) {
                    int quantityChanged = lastQuantity - currentQuantity;
                    BigDecimal saleTotal = product.getPrice() != null ? product.getPrice().multiply(BigDecimal.valueOf(quantityChanged)) : BigDecimal.ZERO;
                    StockChangeEventDTO event = StockChangeEventDTO.builder()
                        .productId(productId)
                        .productName(product.getName())
                        .productCategory(product.getCategory())
                        .quantityChanged(quantityChanged)
                        .newQuantity(currentQuantity)
                        .saleTotal(saleTotal)
                        .changeTimestamp(LocalDateTime.now())
                        .build();
                    stockChangeNotificationService.notifyStockChange(event);
                    logger.info("Stock decreased for product ID {}: -{} (new quantity: {})", productId, quantityChanged, currentQuantity);
                }
                lastKnownQuantities.put(productId, currentQuantity);
            }
        } catch (Exception e) {
            logger.error("Error during stock monitoring poll: {}", e.getMessage(), e);
        }
    }
}
