package com.pulso.vivo.consumer.producer.controller;

import com.pulso.vivo.consumer.producer.model.StockMovement;
import com.pulso.vivo.consumer.producer.repository.StockMovementRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class HealthController {

    @Autowired
    private StockMovementRepository stockMovementRepository;

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("service", "pulso-vivo-kafka-consumidor-ventas-productor-stock");
        health.put("timestamp", LocalDateTime.now());

        try {
            long totalMovements = stockMovementRepository.count();
            health.put("totalStockMovements", totalMovements);
            health.put("database", "Connected");
        } catch (Exception e) {
            health.put("database", "Error: " + e.getMessage());
        }

        return ResponseEntity.ok(health);
    }

    @GetMapping("/stock/recent")
    public ResponseEntity<List<StockMovement>> getRecentStockMovements() {
        LocalDateTime desde = LocalDateTime.now().minusHours(24);
        List<StockMovement> recentMovements = stockMovementRepository.findRecentMovements(desde);
        return ResponseEntity.ok(recentMovements);
    }

    @GetMapping("/stock/producto/{codigoProducto}")
    public ResponseEntity<List<StockMovement>> getStockMovementsByProduct(@PathVariable String codigoProducto) {
        List<StockMovement> movements = stockMovementRepository.findByProductCodeOrderByFechaMovimientoDesc(codigoProducto);
        return ResponseEntity.ok(movements);
    }

    @GetMapping("/stock/stats/{codigoProducto}")
    public ResponseEntity<Map<String, Object>> getProductStats(@PathVariable String codigoProducto) {
        Map<String, Object> stats = new HashMap<>();

        try {
            Integer totalVentas = stockMovementRepository.getTotalVentasByProductCode(codigoProducto);
            List<StockMovement> movements = stockMovementRepository.findByProductCodeOrderByFechaMovimientoDesc(codigoProducto);

            stats.put("codigoProducto", codigoProducto);
            stats.put("totalVentas", totalVentas != null ? totalVentas : 0);
            stats.put("totalMovimientos", movements.size());
            stats.put("ultimoMovimiento", movements.isEmpty() ? null : movements.get(0).getFechaMovimiento());

        } catch (Exception e) {
            stats.put("error", e.getMessage());
        }

        return ResponseEntity.ok(stats);
    }
}
