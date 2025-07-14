package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.impl;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto.PriceChangeEventDTO;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.PriceChangeNotificationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class PriceChangeNotificationServiceImpl implements PriceChangeNotificationService {

    private static final Logger logger = LoggerFactory.getLogger(PriceChangeNotificationServiceImpl.class);

    private final RabbitTemplate rabbitTemplate;
    
    @Value("${price.monitoring.queue-name:price-changes}")
    private String priceChangeQueueName;
    
    @Value("${price.monitoring.enabled:true}")
    private boolean notificationsEnabled;

    public PriceChangeNotificationServiceImpl(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    @Override
    public void notifyPriceChange(PriceChangeEventDTO priceChangeEvent) {
        if (!notificationsEnabled) {
            logger.debug("Price change notifications are disabled. Skipping notification for product ID: {}", 
                    priceChangeEvent.getProductId());
            return;
        }

        try {
            logger.info("Sending price change notification for product ID: {} - {} from {} to {}", 
                    priceChangeEvent.getProductId(),
                    priceChangeEvent.getProductName(),
                    priceChangeEvent.getOldPrice(),
                    priceChangeEvent.getNewPrice());

            rabbitTemplate.convertAndSend(priceChangeQueueName, priceChangeEvent);
            
            logger.info("Price change notification sent successfully for product ID: {}", 
                    priceChangeEvent.getProductId());
                    
        } catch (Exception e) {
            logger.error("Failed to send price change notification for product ID: {}. Error: {}", 
                    priceChangeEvent.getProductId(), e.getMessage(), e);
            // You might want to implement retry logic or dead letter queue handling here
        }
    }

    @Override
    public void setNotificationsEnabled(boolean enabled) {
        this.notificationsEnabled = enabled;
        logger.info("Price change notifications {}", enabled ? "enabled" : "disabled");
    }

    @Override
    public boolean isNotificationsEnabled() {
        return notificationsEnabled;
    }
}