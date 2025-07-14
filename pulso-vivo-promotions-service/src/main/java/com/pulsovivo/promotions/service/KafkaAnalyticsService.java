package com.pulsovivo.promotions.service;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.HashMap;

@Service
public class KafkaAnalyticsService {

    private static final Logger logger = LoggerFactory.getLogger(KafkaAnalyticsService.class);
    private final Map<String, Map<String, Object>> salesAnalytics = new ConcurrentHashMap<>();
    private final Map<String, Map<String, Object>> stockAnalytics = new ConcurrentHashMap<>();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @KafkaListener(topics = "ventas", groupId = "promotions-group")
    public void consumeVentasMessage(String message) {
        logger.info("Received ventas message: {}", message);
        try {
            Map<String, Object> data = objectMapper.readValue(message, HashMap.class);
            String productId = (String) (data.get("productId") != null ? data.get("productId") : data.get("codigoProducto"));
            Number quantity = (Number) (data.get("quantity") != null ? data.get("quantity") : data.get("cantidad"));
            Map<String, Object> productSales = salesAnalytics.getOrDefault(productId, new HashMap<>());
            double totalSales = ((Number) productSales.getOrDefault("totalSales", 0)).doubleValue() + (quantity != null ? quantity.doubleValue() : 0);
            productSales.put("totalSales", totalSales);
            salesAnalytics.put(productId, productSales);
        } catch (Exception e) {
            logger.error("Error parsing ventas message: {}", e.getMessage());
        }
    }

    @KafkaListener(topics = "stock", groupId = "promotions-group")
    public void consumeStockMessage(String message) {
        logger.info("Received stock message: {}", message);
        try {
            Map<String, Object> data = objectMapper.readValue(message, HashMap.class);
            String productId = (String) (data.get("productId") != null ? data.get("productId") : data.get("codigoProducto"));
            Number currentStock = (Number) (data.get("currentStock") != null ? data.get("currentStock") : data.get("stock"));
            Map<String, Object> productStock = stockAnalytics.getOrDefault(productId, new HashMap<>());
            productStock.put("currentStock", currentStock);
            stockAnalytics.put(productId, productStock);
        } catch (Exception e) {
            logger.error("Error parsing stock message: {}", e.getMessage());
        }
    }

    public Object getSalesDataForProduct(String productId) {
        Map<String, Object> data = salesAnalytics.getOrDefault(productId, new HashMap<>());
        System.out.println("DEBUG: getSalesDataForProduct(" + productId + ") = " + data);
        return data;
    }

    public Object getStockDataForProduct(String productId) {
        Map<String, Object> data = stockAnalytics.getOrDefault(productId, new HashMap<>());
        System.out.println("DEBUG: getStockDataForProduct(" + productId + ") = " + data);
        return data;
    }

    public Map<String, Object> getAllSalesAnalytics() {
        return new ConcurrentHashMap<>(salesAnalytics);
    }

    public Map<String, Object> getAllStockAnalytics() {
        return new ConcurrentHashMap<>(stockAnalytics);
    }
}
