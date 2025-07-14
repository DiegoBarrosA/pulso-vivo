package com.pulso.vivo.consumer.producer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.kafka.annotation.EnableKafka;

@SpringBootApplication
@EnableKafka
public class PulsoVivoKafkaConsumidorVentasProductorStockApplication {

    public static void main(String[] args) {
        SpringApplication.run(PulsoVivoKafkaConsumidorVentasProductorStockApplication.class, args);
    }
}
