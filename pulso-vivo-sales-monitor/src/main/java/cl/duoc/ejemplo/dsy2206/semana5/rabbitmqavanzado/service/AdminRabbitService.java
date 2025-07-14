package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto.BindingDTO;

public interface AdminRabbitService {

	public void crearCola(String nombreCola);

	public void crearExchange(String nombreExchange);

	public void crearBinding(BindingDTO request);

	public void eliminarCola(String nombreCola);

	public void eliminarExchange(String nombreExchange);
}
