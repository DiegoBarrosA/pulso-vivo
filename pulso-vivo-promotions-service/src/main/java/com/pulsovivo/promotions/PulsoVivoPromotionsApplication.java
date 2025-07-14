package com.pulsovivo.promotions;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.kafka.annotation.EnableKafka;

@SpringBootApplication
@EnableKafka
public class PulsoVivoPromotionsApplication {

    public static void main(String[] args) {
        SpringApplication.run(PulsoVivoPromotionsApplication.class, args);
    }
}