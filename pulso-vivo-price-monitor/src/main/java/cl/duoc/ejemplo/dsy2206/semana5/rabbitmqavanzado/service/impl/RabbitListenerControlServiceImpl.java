package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.impl;

import org.springframework.amqp.rabbit.listener.MessageListenerContainer;
import org.springframework.amqp.rabbit.listener.RabbitListenerEndpointRegistry;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.RabbitListenerControlService;

@Service
public class RabbitListenerControlServiceImpl implements RabbitListenerControlService {

	@Autowired
	private RabbitListenerEndpointRegistry registry;

	@Override
	public void pausarListener(String id) {

		MessageListenerContainer container = registry.getListenerContainer(id);
		if (container != null && container.isRunning()) {
			container.stop();
			System.out.println("Listener pausado: " + id);
		}
	}

	@Override
	public void reanudarListener(String id) {

		MessageListenerContainer container = registry.getListenerContainer(id);
		if (container != null && !container.isRunning()) {
			container.start();
			System.out.println("Listener reanudado: " + id);
		}
	}

	@Override
	public boolean isListenerRunning(String id) {

		MessageListenerContainer container = registry.getListenerContainer(id);
		return container != null && container.isRunning();
	}
}
