package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.entity;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto.PriceChangeEventDTO;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.PriceChangeNotificationService;
import jakarta.persistence.PostUpdate;
import jakarta.persistence.PreUpdate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

@Component
public class ProductPriceChangeListener {

    @Autowired
    private PriceChangeNotificationService priceChangeNotificationService;

    @PreUpdate
    public void preUpdate(Product product) {
        // Store the original price before update for comparison
        // This will be handled by the Product entity itself in preUpdate method
    }

    @PostUpdate
    public void postUpdate(Product product) {
        if (product.hasPriceChanged()) {
            PriceChangeEventDTO priceChangeEvent = PriceChangeEventDTO.fromProduct(
                    product.getId(),
                    product.getName(),
                    product.getCategory(),
                    product.getPreviousPrice(),
                    product.getPrice()
            );

            // Send the price change event to RabbitMQ
            if (priceChangeNotificationService != null) {
                priceChangeNotificationService.notifyPriceChange(priceChangeEvent);
            }
        }
    }
}