package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class RabbitmqavanzadoApplication {

	public static void main(String[] args) {
		SpringApplication.run(RabbitmqavanzadoApplication.class, args);
	}

}
