package cl.duoc.pulsovivo.bff.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@FeignClient(
    name = "sales-service",
    url = "${services.sales.url}",
    configuration = cl.duoc.pulsovivo.bff.config.FeignConfig.class
)
public interface SalesServiceClient {

    @PostMapping("/api/ventas")
    ResponseEntity<Object> createSale(@RequestBody Object sale);

    @GetMapping("/api/ventas/recientes")
    ResponseEntity<Object> getRecentSales();

    @GetMapping("/actuator/health")
    ResponseEntity<Object> getHealthStatus();
}