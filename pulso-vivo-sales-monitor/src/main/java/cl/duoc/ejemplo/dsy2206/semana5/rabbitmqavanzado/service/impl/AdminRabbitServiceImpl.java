package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.impl;

import org.springframework.amqp.core.AmqpAdmin;
import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.amqp.core.Queue;
import org.springframework.stereotype.Service;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto.BindingDTO;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.AdminRabbitService;

@Service
public class AdminRabbitServiceImpl implements AdminRabbitService {

	private final AmqpAdmin amqpAdmin;

	public AdminRabbitServiceImpl(AmqpAdmin amqpAdmin) {

		this.amqpAdmin = amqpAdmin;
	}

	@Override
	public void crearCola(String nombreCola) {

		Queue queue = new Queue(nombreCola, true);
		amqpAdmin.declareQueue(queue);
	}

	@Override
	public void crearExchange(String nombreExchange) {

		DirectExchange exchange = new DirectExchange(nombreExchange, true, false);
		amqpAdmin.declareExchange(exchange);
	}

	@Override
	public void crearBinding(BindingDTO request) {

		Binding binding = BindingBuilder.bind(new Queue(request.getNombreCola()))
				.to(new DirectExchange(request.getNombreExchange())).with(request.getRoutingKey());
		amqpAdmin.declareBinding(binding);
	}

	@Override
	public void eliminarCola(String nombreCola) {

		amqpAdmin.deleteQueue(nombreCola);
	}

	@Override
	public void eliminarExchange(String nombreExchange) {

		amqpAdmin.deleteExchange(nombreExchange);
	}
}
