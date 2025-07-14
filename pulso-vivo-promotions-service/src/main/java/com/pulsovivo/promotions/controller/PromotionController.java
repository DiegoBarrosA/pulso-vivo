package com.pulsovivo.promotions.controller;

import com.pulsovivo.promotions.dto.PromotionRequest;
import com.pulsovivo.promotions.dto.PromotionResponse;
import com.pulsovivo.promotions.service.PromotionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/promotions")
@CrossOrigin(origins = "*")
public class PromotionController {

    @Autowired
    private PromotionService promotionService;

    @PostMapping("/generate")
    public ResponseEntity<PromotionResponse> generatePromotion(@RequestBody PromotionRequest request) {
        PromotionResponse response = promotionService.generatePromotion(request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/active")
    public ResponseEntity<List<PromotionResponse>> getActivePromotions() {
        List<PromotionResponse> promotions = promotionService.getActivePromotions();
        return ResponseEntity.ok(promotions);
    }

    @GetMapping("/product/{productId}")
    public ResponseEntity<List<PromotionResponse>> getPromotionsByProduct(@PathVariable String productId) {
        List<PromotionResponse> promotions = promotionService.getPromotionsByProduct(productId);
        return ResponseEntity.ok(promotions);
    }

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Promotions service is running!");
    }
}
