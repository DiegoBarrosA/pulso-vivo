package com.pulso.vivo.consumer.producer.listener;

import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class RawJsonDebugListener {

    @KafkaListener(
        topics = "${kafka.topic.ventas:ventas}",
        groupId = "${spring.kafka.consumer.group-id:ventas-stock-processor}-raw-debug",
        containerFactory = "rawKafkaListenerContainerFactory"
    )
    public void debugRawJson(
            @Payload String rawJson,
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
            @Header(KafkaHeaders.OFFSET) long offset,
            Acknowledgment acknowledgment) {

        try {
            log.info("=== RAW JSON DEBUG ===");
            log.info("Topic: {}, Partition: {}, Offset: {}", topic, partition, offset);
            log.info("Raw JSON content: {}", rawJson);
            log.info("Raw JSON length: {}", rawJson != null ? rawJson.length() : "null");

            if (rawJson != null && rawJson.length() > 0) {
                log.info("First 100 chars: {}", rawJson.length() > 100 ? rawJson.substring(0, 100) + "..." : rawJson);
            }

            acknowledgment.acknowledge();

        } catch (Exception e) {
            log.error("Error in raw JSON debug listener", e);
            acknowledgment.acknowledge();
        }
    }
}
