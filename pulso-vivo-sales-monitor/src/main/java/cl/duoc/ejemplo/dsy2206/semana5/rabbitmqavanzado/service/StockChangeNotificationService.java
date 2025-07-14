package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto.StockChangeEventDTO;

public interface StockChangeNotificationService {
    void notifyStockChange(StockChangeEventDTO stockChangeEvent);
    void setNotificationsEnabled(boolean enabled);
    boolean isNotificationsEnabled();
}
