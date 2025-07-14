package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto.ProductoDTO;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto.UsuarioDTO;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.MensajeService;

@RestController
@RequestMapping("/api")
public class MensajeController {

	private final MensajeService mensajeService;

	public MensajeController(MensajeService mensajeService) {

		this.mensajeService = mensajeService;
	}

	@PostMapping("/mensajes")
	public ResponseEntity<String> enviar(@RequestBody String mensaje) {

		mensajeService.enviarMensaje(mensaje);
		return ResponseEntity.ok("Mensaje enviado: " + mensaje);
	}

	@PostMapping("/usuarios")
	public ResponseEntity<String> enviarObjetoUsuario(@RequestBody UsuarioDTO usuario) {

		mensajeService.enviarObjeto(usuario);
		return ResponseEntity.ok("Mensaje enviado: " + usuario.toString());
	}

	@PostMapping("/prodductos")
	public ResponseEntity<String> enviarObjetoProducto(@RequestBody ProductoDTO producto) {

		mensajeService.enviarObjeto(producto);
		return ResponseEntity.ok("Mensaje enviado: " + producto.toString());
	}
}
