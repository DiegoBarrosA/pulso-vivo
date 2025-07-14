package com.pulso.vivo.consumer.producer.listener;

import com.pulso.vivo.consumer.producer.dto.VentaDTO;
import com.pulso.vivo.consumer.producer.service.StockService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class VentaKafkaListener {

    @Autowired
    private StockService stockService;

    @KafkaListener(
        topics = "${kafka.topic.ventas:ventas}",
        groupId = "${spring.kafka.consumer.group-id:ventas-stock-processor}",
        containerFactory = "kafkaListenerContainerFactory"
    )
    public void processVenta(
            @Payload VentaDTO venta,
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
            @Header(KafkaHeaders.OFFSET) long offset,
            Acknowledgment acknowledgment) {

        try {
            log.info("=== KAFKA MESSAGE RECEIVED ===");
            log.info("Topic: {}, Partition: {}, Offset: {}", topic, partition, offset);
            log.info("Raw VentaDTO object: {}", venta);
            log.info("VentaDTO.toString(): {}", venta.toString());

            // Log additional fields to see what the producer is actually sending
            log.info("Additional fields received: {}", venta.getAdditionalFields());

            // Log each field individually to debug null values
            log.info("Mapped fields:");
            log.info("  - ID: {}", venta.getId());
            log.info("  - codigoProducto: '{}'", venta.getCodigoProducto());
            log.info("  - cantidad: {}", venta.getCantidad());
            log.info("  - precioUnitario: {}", venta.getPrecioUnitario());
            log.info("  - clienteId: '{}'", venta.getClienteId());
            log.info("  - canalVenta: '{}'", venta.getCanalVenta());
            log.info("  - ubicacion: '{}'", venta.getUbicacion());
            log.info("  - fechaVenta: {}", venta.getFechaVenta());
            log.info("  - total: {}", venta.getTotal());

            // Validate required fields
            if (venta.getCantidad() == null) {
                log.error("CRITICAL: cantidad is NULL after mapping!");
                log.error("Raw additional fields: {}", venta.getAdditionalFields());
                acknowledgment.acknowledge();
                return;
            }

            if (venta.getCodigoProducto() == null || "null".equals(venta.getCodigoProducto())) {
                log.error("CRITICAL: codigoProducto is NULL or 'null' after mapping!");
                log.error("Raw additional fields: {}", venta.getAdditionalFields());
                acknowledgment.acknowledge();
                return;
            }

            log.info("=== PROCESSING VENTA ===");

            // Process the sale and update stock
            stockService.processVentaAndUpdateStock(venta);

            // Acknowledge message processing
            acknowledgment.acknowledge();

            log.info("Successfully processed venta: {} for product: {}",
                     venta.getId(), venta.getCodigoProducto());

        } catch (Exception e) {
            log.error("Error processing venta: {} for product: {}",
                      venta.getId(), venta.getCodigoProducto(), e);

            // In production, you might want to send to a dead letter queue
            // For now, we'll acknowledge to prevent infinite retries
            acknowledgment.acknowledge();
        }
    }
}
