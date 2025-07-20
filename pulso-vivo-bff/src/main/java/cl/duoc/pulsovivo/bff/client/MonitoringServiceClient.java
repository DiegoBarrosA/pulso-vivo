package cl.duoc.pulsovivo.bff.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@FeignClient(
    name = "monitoring-service",
    url = "${services.monitoring.url}",
    configuration = cl.duoc.pulsovivo.bff.config.FeignConfig.class
)
public interface MonitoringServiceClient {

    @GetMapping("/api/monitoring/products")
    ResponseEntity<Object> getAllProductsPriceMonitor();

    @GetMapping("/api/monitoring/products/{id}")
    ResponseEntity<Object> getProductByIdPriceMonitor(@PathVariable("id") String id);

    @PutMapping("/api/monitoring/products/{id}")
    ResponseEntity<Object> updateProductPrice(@PathVariable("id") String id, @RequestBody Object productUpdate);

    @GetMapping("/api/monitoring/products/active")
    ResponseEntity<Object> getActiveProductsForMonitoring();

    @GetMapping("/api/monitoring/products/category/{category}")
    ResponseEntity<Object> getProductsByCategory(@PathVariable("category") String category);

    @GetMapping("/api/price-monitoring/status")
    ResponseEntity<Object> getMonitoringStatus();

    @PostMapping("/api/price-monitoring/enable")
    ResponseEntity<Object> enablePriceMonitoring();

    @PostMapping("/api/price-monitoring/disable")
    ResponseEntity<Object> disablePriceMonitoring();

    @PostMapping("/api/mensajes")
    ResponseEntity<Object> sendMessage(@RequestBody Object message);

    @PostMapping("/api/productos/{id}")
    ResponseEntity<Object> sendProductObject(@PathVariable("id") String id, @RequestBody Object product);
}