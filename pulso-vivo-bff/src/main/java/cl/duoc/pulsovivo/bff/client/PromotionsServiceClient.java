package cl.duoc.pulsovivo.bff.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@FeignClient(
    name = "promotions-service",
    url = "${services.promotions.url}",
    configuration = cl.duoc.pulsovivo.bff.config.FeignConfig.class
)
public interface PromotionsServiceClient {

    @GetMapping("/api/promotions/active")
    ResponseEntity<Object> getActivePromotions();

    @GetMapping("/api/promotions/product/{productId}")
    ResponseEntity<Object> getPromotionsByProduct(@PathVariable("productId") String productId);

    @PostMapping("/api/promotions/generate")
    ResponseEntity<Object> generatePromotion(@RequestBody Object promotion);

    @GetMapping("/api/promotions/health")
    ResponseEntity<Object> getPromotionsHealth();
}