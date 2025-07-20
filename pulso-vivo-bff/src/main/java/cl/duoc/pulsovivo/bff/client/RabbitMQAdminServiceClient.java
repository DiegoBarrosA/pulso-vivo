package cl.duoc.pulsovivo.bff.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@FeignClient(
    name = "rabbitmq-admin-service",
    url = "${services.monitoring.url}",
    configuration = cl.duoc.pulsovivo.bff.config.FeignConfig.class
)
public interface RabbitMQAdminServiceClient {

    @PostMapping("/rabbit-admin/colas/{queueName}")
    ResponseEntity<Object> createRabbitMQQueue(@PathVariable("queueName") String queueName);

    @PostMapping("/rabbit-admin/exchanges/{exchangeName}")
    ResponseEntity<Object> createRabbitMQExchange(@PathVariable("exchangeName") String exchangeName);
}