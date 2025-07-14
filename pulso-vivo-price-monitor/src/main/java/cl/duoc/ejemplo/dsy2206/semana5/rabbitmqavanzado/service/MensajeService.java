package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service;

import java.io.IOException;

import org.springframework.amqp.core.Message;

import com.rabbitmq.client.Channel;

public interface MensajeService {

	void enviarMensaje(String mensaje);

	public void enviarObjeto(Object objeto);

	void recibirMensaje(Object mensaje);

	void recibirDeadLetter(Object mensaje);

	void recibirMensajeConAckManual(Message mensaje, Channel canal) throws IOException;
}
