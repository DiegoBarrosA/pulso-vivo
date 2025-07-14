package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.impl;

import java.io.IOException;

import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

import com.rabbitmq.client.Channel;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.config.RabbitMQConfig;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.MensajeService;

@Service
public class MensajeServiceImpl implements MensajeService {

	private final RabbitTemplate rabbitTemplate;

	public MensajeServiceImpl(RabbitTemplate rabbitTemplate) {
		this.rabbitTemplate = rabbitTemplate;
	}

	@Override
	public void enviarMensaje(String mensaje) {

		rabbitTemplate.convertAndSend(RabbitMQConfig.MAIN_QUEUE, mensaje);
	}

	@Override
	public void enviarObjeto(Object objeto) {

		rabbitTemplate.convertAndSend(RabbitMQConfig.MAIN_QUEUE, objeto);
	}

//	@RabbitListener(id = "listener-myQueue", queues = RabbitMQConfig.MAIN_QUEUE)
	@Override
	public void recibirMensaje(Object objeto) {

		System.out.println("Mensaje recibido en myQueue: " + objeto);
	}

	@RabbitListener(id = "listener-dlx-queue", queues = RabbitMQConfig.DLX_QUEUE)
	@Override
	public void recibirDeadLetter(Object objeto) {

		System.out.println("Mensaje recibido en DLQ: " + objeto);
	}

	@RabbitListener(id = "listener-myQueue", queues = RabbitMQConfig.MAIN_QUEUE, ackMode = "MANUAL")
	@Override
	public void recibirMensajeConAckManual(Message mensaje, Channel canal) throws IOException {

		try {
			System.out.println("Mensaje recibido: " + new String(mensaje.getBody()));
			Thread.sleep(10000);

			canal.basicAck(mensaje.getMessageProperties().getDeliveryTag(), false);
			System.out.println("Acknowledge OK enviado");
		} catch (Exception e) {
			canal.basicNack(mensaje.getMessageProperties().getDeliveryTag(), false, false);
			System.out.println("Acknowledge NO OK enviado");
		}
	}

//	@RabbitListener(id = "listener-price-changes", queues = RabbitMQConfig.PRICE_CHANGE_QUEUE)
//	public void recibirCambioPrecio(PriceChangeEventDTO priceChangeEvent) {
//		try {
//			System.out.println("=== CAMBIO DE PRECIO DETECTADO ===");
//			System.out.println("Producto ID: " + priceChangeEvent.getProductId());
//			System.out.println("Nombre: " + priceChangeEvent.getProductName());
//			System.out.println("Categoría: " + priceChangeEvent.getProductCategory());
//			System.out.println("Precio anterior: $" + priceChangeEvent.getOldPrice());
//			System.out.println("Precio nuevo: $" + priceChangeEvent.getNewPrice());
//			System.out.println("Cambio: $" + priceChangeEvent.getChangeAmount());
//			System.out.println("Porcentaje de cambio: " + String.format("%.2f%%", priceChangeEvent.getChangePercentage()));
//			System.out.println("Tipo de cambio: " + priceChangeEvent.getChangeTimestamp());
//			System.out.println("Fecha/Hora: " + priceChangeEvent.getChangeTimestamp());
//			System.out.println("Razón: " + priceChangeEvent.getChangeReason());
//			System.out.println("=====================================");
//			
//			// Here you could implement business logic like:
//			// - Notify inventory management system
//			// - Update pricing analytics
//			// - Send notifications to customers
//			// - Log for audit purposes
//			// - Trigger price optimization algorithms
//			
//		} catch (Exception e) {
//			System.err.println("Error procesando cambio de precio: " + e.getMessage());
//			e.printStackTrace();
//		}
//	}

}
