package com.pulsovivo.promotions.dto;

public class PromotionRequest {
    private String productId;
    private String promotionType;
    private String targetAudience;

    // Constructors
    public PromotionRequest() {}

    public PromotionRequest(String productId, String promotionType, String targetAudience) {
        this.productId = productId;
        this.promotionType = promotionType;
        this.targetAudience = targetAudience;
    }

    // Getters and Setters
    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }

    public String getPromotionType() { return promotionType; }
    public void setPromotionType(String promotionType) { this.promotionType = promotionType; }

    public String getTargetAudience() { return targetAudience; }
    public void setTargetAudience(String targetAudience) { this.targetAudience = targetAudience; }
}
