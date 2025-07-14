package com.pulso.vivo.productor;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
@EntityScan(basePackages = "com.pulso.vivo.productor.model")
@EnableJpaRepositories(basePackages = "com.pulso.vivo.productor.repository")
public class PulsoVivoKafkaProductorVentasApplication {
    public static void main(String[] args) {
        SpringApplication.run(PulsoVivoKafkaProductorVentasApplication.class, args);
    }
}
