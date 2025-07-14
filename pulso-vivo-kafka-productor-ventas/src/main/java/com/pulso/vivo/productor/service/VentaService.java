package com.pulso.vivo.productor.service;

import com.pulso.vivo.productor.model.Venta;
import com.pulso.vivo.productor.repository.VentaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
public class VentaService {

    private final VentaRepository ventaRepository;
    private final KafkaProducerService kafkaProducerService;

    public VentaService(VentaRepository ventaRepository, KafkaProducerService kafkaProducerService) {
        this.ventaRepository = ventaRepository;
        this.kafkaProducerService = kafkaProducerService;
    }

    @Transactional
    public Venta registrarVenta(Venta venta) {
        System.out.println("=== VENTA SERVICE DEBUG ===");
        System.out.println("Received venta: " + venta);
        System.out.println("Received venta fields:");
        System.out.println("  - codigoProducto: " + venta.getCodigoProducto());
        System.out.println("  - cantidad: " + venta.getCantidad());
        System.out.println("  - precioUnitario: " + venta.getPrecioUnitario());
        System.out.println("  - clienteId: " + venta.getClienteId());

        Venta ventaGuardada = ventaRepository.save(venta);

        System.out.println("Saved venta: " + ventaGuardada);
        System.out.println("Saved venta fields:");
        System.out.println("  - ID: " + ventaGuardada.getId());
        System.out.println("  - codigoProducto: " + ventaGuardada.getCodigoProducto());
        System.out.println("  - cantidad: " + ventaGuardada.getCantidad());
        System.out.println("  - precioUnitario: " + ventaGuardada.getPrecioUnitario());
        System.out.println("  - clienteId: " + ventaGuardada.getClienteId());
        System.out.println("==========================");

        kafkaProducerService.enviarVenta(ventaGuardada);
        return ventaGuardada;
    }

    public List<Venta> obtenerVentasRecientes() {
        return ventaRepository.findTop10ByOrderByFechaVentaDesc();
    }
}
