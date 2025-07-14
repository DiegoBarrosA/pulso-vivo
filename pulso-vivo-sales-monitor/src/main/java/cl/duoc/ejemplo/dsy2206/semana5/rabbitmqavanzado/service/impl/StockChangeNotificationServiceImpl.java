package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.impl;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto.StockChangeEventDTO;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.StockChangeNotificationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class StockChangeNotificationServiceImpl implements StockChangeNotificationService {
    private static final Logger logger = LoggerFactory.getLogger(StockChangeNotificationServiceImpl.class);

    private final RabbitTemplate rabbitTemplate;

    @Value("${stock.monitoring.queue-name:stock-changes}")
    private String stockChangeQueueName;

    @Value("${stock.monitoring.enabled:true}")
    private boolean notificationsEnabled;

    public StockChangeNotificationServiceImpl(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    @Override
    public void notifyStockChange(StockChangeEventDTO stockChangeEvent) {
        if (!notificationsEnabled) {
            logger.debug("Stock change notifications are disabled. Skipping notification for product ID: {}", stockChangeEvent.getProductId());
            return;
        }
        try {
            logger.info("Sending stock change notification for product ID: {} - {} quantity changed {} new quantity {} sale total {}", stockChangeEvent.getProductId(), stockChangeEvent.getProductName(), stockChangeEvent.getQuantityChanged(), stockChangeEvent.getNewQuantity(), stockChangeEvent.getSaleTotal());
            rabbitTemplate.convertAndSend(stockChangeQueueName, stockChangeEvent);
            logger.info("Stock change notification sent successfully for product ID: {}", stockChangeEvent.getProductId());
        } catch (Exception e) {
            logger.error("Failed to send stock change notification for product ID: {}. Error: {}", stockChangeEvent.getProductId(), e.getMessage(), e);
        }
    }

    @Override
    public void setNotificationsEnabled(boolean enabled) {
        this.notificationsEnabled = enabled;
        logger.info("Stock change notifications {}", enabled ? "enabled" : "disabled");
    }

    @Override
    public boolean isNotificationsEnabled() {
        return notificationsEnabled;
    }
}
