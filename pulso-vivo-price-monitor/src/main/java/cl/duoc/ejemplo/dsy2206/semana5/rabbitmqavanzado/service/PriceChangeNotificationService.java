package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto.PriceChangeEventDTO;

public interface PriceChangeNotificationService {
    
    /**
     * Notifies about a price change by sending a message to RabbitMQ
     * @param priceChangeEvent The price change event details
     */
    void notifyPriceChange(PriceChangeEventDTO priceChangeEvent);
    
    /**
     * Enables or disables price change notifications
     * @param enabled true to enable notifications, false to disable
     */
    void setNotificationsEnabled(boolean enabled);
    
    /**
     * Checks if price change notifications are currently enabled
     * @return true if notifications are enabled, false otherwise
     */
    boolean isNotificationsEnabled();
}