package com.pulsovivo.promotions.service;

import com.pulsovivo.promotions.dto.PromotionRequest;
import com.pulsovivo.promotions.dto.PromotionResponse;
import com.pulsovivo.promotions.model.Promotion;
import com.pulsovivo.promotions.repository.PromotionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class PromotionService {

    @Autowired
    private PromotionRepository promotionRepository;

    @Autowired
    private KafkaAnalyticsService kafkaAnalyticsService;

    public PromotionResponse generatePromotion(PromotionRequest request) {
        // Get analytics data from Kafka consumers
        var salesData = kafkaAnalyticsService.getSalesDataForProduct(request.getProductId());
        System.out.println("DEBUG: getSalesDataForProduct(" + request.getProductId() + ") = " + salesData);
        var stockData = kafkaAnalyticsService.getStockDataForProduct(request.getProductId());
        System.out.println("DEBUG: getStockDataForProduct(" + request.getProductId() + ") = " + stockData);

        // Generate promotion based on sales and stock data
        Promotion promotion = new Promotion();
        promotion.setId(UUID.randomUUID().toString());
        promotion.setProductId(request.getProductId());
        promotion.setPromotionType(determinePromotionType(salesData, stockData));
        promotion.setDiscountPercentage(calculateDiscountPercentage(salesData, stockData));
        promotion.setDescription(generatePromotionDescription(promotion));
        promotion.setStartDate(LocalDateTime.now());
        promotion.setEndDate(LocalDateTime.now().plusDays(7)); // 7 days promotion
        promotion.setActive(true);
        promotion.setCreatedAt(LocalDateTime.now());

        promotion = promotionRepository.save(promotion);

        return convertToResponse(promotion);
    }

    public List<PromotionResponse> getActivePromotions() {
        List<Promotion> promotions = promotionRepository.findByActiveTrue();
        return promotions.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    public List<PromotionResponse> getPromotionsByProduct(String productId) {
        List<Promotion> promotions = promotionRepository.findByProductIdAndActiveTrue(productId);
        return promotions.stream()
                .map(this::convertToResponse)
                .collect(Collectors.toList());
    }

    private String determinePromotionType(Object salesData, Object stockData) {
        // Logic to determine promotion type based on sales and stock data
        // This could be: CLEARANCE, VOLUME_DISCOUNT, SEASONAL, etc.
        return "DYNAMIC_DISCOUNT";
    }
private Double calculateDiscountPercentage(Object salesData, Object stockData) {
    // Suponiendo que salesData y stockData son Map<String, Object> con claves "totalSales" y "currentStock"
    double totalSales = 0;
    double currentStock = 0;

    if (salesData instanceof java.util.Map && stockData instanceof java.util.Map) {
        Object sales = ((java.util.Map<?, ?>) salesData).get("totalSales");
        Object stock = ((java.util.Map<?, ?>) stockData).get("currentStock");
        if (sales instanceof Number) {
            totalSales = ((Number) sales).doubleValue();
        }
        if (stock instanceof Number) {
            currentStock = ((Number) stock).doubleValue();
        }
    }

    // Log para depuración
    System.out.printf("DEBUG: totalSales=%.2f, currentStock=%.2f%n", totalSales, currentStock);

    // Ejemplo de lógica: si las ventas son bajas y el stock es alto, mayor descuento
    if (totalSales < 10 && currentStock > 100) {
        return 30.0; // 30% descuento
    } else if (totalSales < 50 && currentStock > 50) {
        return 20.0; // 20% descuento
    } else if (totalSales > 100 && currentStock < 20) {
        return 5.0; // 5% descuento
    } else {
        return 15.0; // descuento estándar
    }
}

    private String generatePromotionDescription(Promotion promotion) {
        return String.format("Special %s promotion - %.0f%% off!",
                promotion.getPromotionType(),
                promotion.getDiscountPercentage());
    }

    private PromotionResponse convertToResponse(Promotion promotion) {
        PromotionResponse response = new PromotionResponse();
        response.setId(promotion.getId());
        response.setProductId(promotion.getProductId());
        response.setPromotionType(promotion.getPromotionType());
        response.setDiscountPercentage(promotion.getDiscountPercentage());
        response.setDescription(promotion.getDescription());
        response.setStartDate(promotion.getStartDate());
        response.setEndDate(promotion.getEndDate());
        response.setActive(promotion.getActive());
        return response;
    }
}
