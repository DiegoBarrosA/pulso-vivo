package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.controller;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto.BindingDTO;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.AdminRabbitService;

@RestController
@RequestMapping("/rabbit-admin")
public class RabbitMQAdminController {

	private AdminRabbitService service;

	public RabbitMQAdminController(AdminRabbitService service) {

		this.service = service;
	}

	@PostMapping("/colas/{nombrecola}")
	public String crearCola(@PathVariable String nombrecola) {

		service.crearCola(nombrecola);
		return "Cola creada: " + nombrecola;
	}

	@PostMapping("/exchanges/{nombreexchange}")
	public String crearExchange(@PathVariable String nombreexchange) {

		service.crearExchange(nombreexchange);
		return "Exchange creado: " + nombreexchange;
	}

	@PostMapping("/bindings")
	public String crearBinding(@RequestBody BindingDTO request) {

		service.crearBinding(request);
		return "Binding creado en cola: " + request.getNombreCola() + " y exchange: " + request.getNombreExchange();
	}

	@DeleteMapping("/colas/{nombrecola}")
	public String eliminarCola(@PathVariable String nombrecola) {

		service.eliminarCola(nombrecola);
		return "Cola eliminada: " + nombrecola;
	}

	@DeleteMapping("/exchanges/{nombreexchange}")
	public String eliminarExchange(@PathVariable String nombreexchange) {

		service.eliminarExchange(nombreexchange);
		return "Exhange eliminado: " + nombreexchange;
	}
}
