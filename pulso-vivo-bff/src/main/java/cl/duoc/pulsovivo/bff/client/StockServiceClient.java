package cl.duoc.pulsovivo.bff.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@FeignClient(
    name = "stock-service",
    url = "${services.stock.url}",
    configuration = cl.duoc.pulsovivo.bff.config.FeignConfig.class
)
public interface StockServiceClient {

    @GetMapping("/api/stock/producto/{productCode}")
    ResponseEntity<Object> getStockByProductCode(@PathVariable("productCode") String productCode);

    @GetMapping("/api/stock/recent")
    ResponseEntity<Object> getRecentStockMovements();

    @GetMapping("/api/stock/stats/{productCode}")
    ResponseEntity<Object> getStockStatistics(@PathVariable("productCode") String productCode);
}