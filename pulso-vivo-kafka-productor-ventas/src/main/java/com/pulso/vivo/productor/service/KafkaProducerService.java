package com.pulso.vivo.productor.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class KafkaProducerService {

    private final KafkaTemplate<String, Object> kafkaTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${spring.kafka.topic.ventas}")
    private String ventasTopic;

    @Value("${spring.kafka.topic.stock}")
    private String stockTopic;

    public KafkaProducerService(KafkaTemplate<String, Object> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void enviarVenta(Object venta) {
        try {
            // Debug: Log what we're about to send
            String jsonString = objectMapper.writeValueAsString(venta);
            System.out.println("=== KAFKA PRODUCER DEBUG ===");
            System.out.println("Topic: " + ventasTopic);
            System.out.println("Object type: " + venta.getClass().getName());
            System.out.println("Object toString: " + venta.toString());
            System.out.println("JSON serialization: " + jsonString);
            System.out.println("========================");

        } catch (Exception e) {
            System.out.println("Error serializing venta: " + e.getMessage());
        }

        kafkaTemplate.send(ventasTopic, venta);
    }

    public void enviarStock(String codigoProducto, Integer stockActual) {
        try {
            // Construir el mensaje de stock
            var stockMsg = new java.util.HashMap<String, Object>();
            stockMsg.put("codigoProducto", codigoProducto);
            stockMsg.put("stock", stockActual);
            String jsonString = objectMapper.writeValueAsString(stockMsg);
            System.out.println("=== KAFKA PRODUCER STOCK DEBUG ===");
            System.out.println("Topic: " + stockTopic);
            System.out.println("Mensaje: " + jsonString);
            System.out.println("===============================");
            kafkaTemplate.send(stockTopic, stockMsg);
        } catch (Exception e) {
            System.out.println("Error serializando stock: " + e.getMessage());
        }
    }
}
