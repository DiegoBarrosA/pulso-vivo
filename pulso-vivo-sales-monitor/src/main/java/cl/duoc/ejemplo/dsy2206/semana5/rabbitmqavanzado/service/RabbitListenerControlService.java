package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service;

public interface RabbitListenerControlService {

	void pausarListener(String id);

	void reanudarListener(String id);

	boolean isListenerRunning(String id);
}
