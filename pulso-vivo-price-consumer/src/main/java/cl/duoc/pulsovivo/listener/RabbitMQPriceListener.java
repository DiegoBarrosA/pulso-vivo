package cl.duoc.pulsovivo.listener;

import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.UUID;

@Component
public class RabbitMQPriceListener {
    private static final String OUTPUT_DIR = "/data";

    @RabbitListener(queues = "price-changes")
    public void receiveMessage(String message) {
        try {
            Files.createDirectories(Paths.get(OUTPUT_DIR));
            String filename = OUTPUT_DIR + "/" + UUID.randomUUID() + ".json";
            try (FileWriter writer = new FileWriter(filename)) {
                writer.write(message);
            }
            System.out.println("Mensaje guardado en: " + filename);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
