package com.pulso.vivo.consumer.producer.service;

import com.pulso.vivo.consumer.producer.dto.StockUpdateDTO;
import com.pulso.vivo.consumer.producer.dto.VentaDTO;
import com.pulso.vivo.consumer.producer.model.StockMovement;
import com.pulso.vivo.consumer.producer.repository.ProductRepository;
import com.pulso.vivo.consumer.producer.repository.StockMovementRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.time.LocalDateTime;
import java.util.Optional;

@Slf4j
@Service
public class StockService {

    @Autowired
    private StockMovementRepository stockMovementRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private KafkaTemplate<String, Object> kafkaTemplate;

    @Value("${kafka.topic.stock:stock}")
    private String stockTopic;

    @Value("${inventario.service.base-url:http://pulso-vivo-inventory:8081/api/inventory}")
    private String inventarioBaseUrl;

    private final RestTemplate restTemplate = new RestTemplate();

    @Transactional
    public void processVentaAndUpdateStock(VentaDTO venta) {
        try {
            log.info("Processing venta {} for stock update", venta.getId());

            // 1. Look up the product ID from the product code
            Long productId = null;
            String productCode = venta.getCodigoProducto();

            if (productCode != null) {
                Optional<Long> productIdOpt = productRepository.findProductIdByCode(productCode);
                if (productIdOpt.isPresent()) {
                    productId = productIdOpt.get();
                    log.info("Found product ID {} for code {}", productId, productCode);
                } else {
                    log.warn("Product not found for code: {}", productCode);
                    // For now, we'll create the stock movement anyway
                    // You might want to handle this differently in production
                }
            }

            // 2. Create stock movement record
            StockMovement stockMovement = StockMovement.builder()
                    .productId(productId)
                    .productCode(productCode)
                    .cantidad(venta.getCantidad())
                    .tipoMovimiento("VENTA")
                    .ubicacion(venta.getUbicacion())
                    .ventaId(venta.getId())
                    .fechaMovimiento(LocalDateTime.now())
                    .clienteId(venta.getClienteId())
                    .canalVenta(venta.getCanalVenta())
                    .build();

            // 3. Save to database
            StockMovement savedMovement = stockMovementRepository.save(stockMovement);
            log.info("Saved stock movement: {} for product: {} (ID: {})",
                     savedMovement.getId(), productCode, productId);

            // 4. Get current stock after the sale
            Integer currentStock = getCurrentStockForProduct(productCode);
            
            // 5. Create stock update message with current stock
            StockUpdateDTO stockUpdate = StockUpdateDTO.builder()
                    .codigoProducto(productCode)
                    .cantidadVendida(venta.getCantidad())
                    .tipoMovimiento("VENTA")
                    .ubicacion(venta.getUbicacion())
                    .ventaId(venta.getId())
                    .fechaMovimiento(LocalDateTime.now())
                    .clienteId(venta.getClienteId())
                    .canalVenta(venta.getCanalVenta())
                    .stock(currentStock) // Add current stock field
                    .build();

            // 6. Send to stock topic
            publishStockUpdate(stockUpdate);

        } catch (Exception e) {
            log.error("Error processing venta {} for stock update", venta.getId(), e);
            throw e; // Re-throw to trigger transaction rollback
        }
    }

    private void publishStockUpdate(StockUpdateDTO stockUpdate) {
        try {
            log.info("Publishing stock update for product: {} with stock: {} to topic: {}",
                     stockUpdate.getCodigoProducto(), stockUpdate.getStock(), stockTopic);

            kafkaTemplate.send(stockTopic, stockUpdate.getCodigoProducto(), stockUpdate)
                    .whenComplete((result, throwable) -> {
                        if (throwable == null) {
                            log.info("Successfully published stock update for product: {} (stock: {}) to partition: {} at offset: {}",
                                     stockUpdate.getCodigoProducto(),
                                     stockUpdate.getStock(),
                                     result.getRecordMetadata().partition(),
                                     result.getRecordMetadata().offset());
                        } else {
                            log.error("Failed to publish stock update for product: {}",
                                      stockUpdate.getCodigoProducto(), throwable);
                        }
                    });

        } catch (Exception e) {
            log.error("Error publishing stock update for product: {}", stockUpdate.getCodigoProducto(), e);
            throw e;
        }
    }

    private Integer getCurrentStockForProduct(String productCode) {
        try {
            Long id = Long.parseLong(productCode);
            String url = inventarioBaseUrl + "/products/" + id;
            ProductDTO product = restTemplate.getForObject(url, ProductDTO.class);
            return product != null ? product.getQuantity() : 0;
        } catch (NumberFormatException e) {
            log.error("codigoProducto no es un ID numérico: {}", productCode);
            return 0;
        } catch (Exception e) {
            log.error("Error getting current stock for product: {}", productCode, e);
            return 0;
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ProductDTO {
        private int quantity;
        public int getQuantity() { return quantity; }
        public void setQuantity(int quantity) { this.quantity = quantity; }
    }
}
