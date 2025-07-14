package com.pulso.vivo.productor.controller;

import com.pulso.vivo.productor.model.Venta;
import com.pulso.vivo.productor.service.VentaService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/ventas")
public class VentaController {

    private final VentaService ventaService;

    public VentaController(VentaService ventaService) {
        this.ventaService = ventaService;
    }

    @PostMapping
    public ResponseEntity<Venta> registrarVenta(@RequestBody Venta venta) {
        return ResponseEntity.ok(ventaService.registrarVenta(venta));
    }

    @GetMapping("/recientes")
    public ResponseEntity<List<Venta>> obtenerVentasRecientes() {
        return ResponseEntity.ok(ventaService.obtenerVentasRecientes());
    }
}
