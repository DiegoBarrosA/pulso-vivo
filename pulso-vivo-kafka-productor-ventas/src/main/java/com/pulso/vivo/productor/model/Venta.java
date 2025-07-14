package com.pulso.vivo.productor.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "VENTAS")
public class Venta {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "codigo_producto")
    private String codigoProducto;

    private Integer cantidad;

    @Column(name = "precio_unitario")
    private BigDecimal precioUnitario;

    private BigDecimal total;

    @Column(name = "cliente_id")
    private String clienteId;

    @Column(name = "fecha_venta")
    private LocalDateTime fechaVenta;

    @Column(name = "canal_venta")
    private String canalVenta;

    private String ubicacion;

    // Constructors
    public Venta() {}

    // ALL GETTERS AND SETTERS
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCodigoProducto() { return codigoProducto; }
    public void setCodigoProducto(String codigoProducto) { this.codigoProducto = codigoProducto; }

    public Integer getCantidad() { return cantidad; }
    public void setCantidad(Integer cantidad) { this.cantidad = cantidad; }

    public BigDecimal getPrecioUnitario() { return precioUnitario; }
    public void setPrecioUnitario(BigDecimal precioUnitario) { this.precioUnitario = precioUnitario; }

    public BigDecimal getTotal() { return total; }
    public void setTotal(BigDecimal total) { this.total = total; }

    public String getClienteId() { return clienteId; }
    public void setClienteId(String clienteId) { this.clienteId = clienteId; }

    public LocalDateTime getFechaVenta() { return fechaVenta; }
    public void setFechaVenta(LocalDateTime fechaVenta) { this.fechaVenta = fechaVenta; }

    public String getCanalVenta() { return canalVenta; }
    public void setCanalVenta(String canalVenta) { this.canalVenta = canalVenta; }

    public String getUbicacion() { return ubicacion; }
    public void setUbicacion(String ubicacion) { this.ubicacion = ubicacion; }

    @PrePersist
    protected void onCreate() {
        if (fechaVenta == null) {
            fechaVenta = LocalDateTime.now();
        }
        if (total == null && cantidad != null && precioUnitario != null) {
            total = precioUnitario.multiply(BigDecimal.valueOf(cantidad));
        }
    }

    @Override
    public String toString() {
        return "Venta{" +
                "id=" + id +
                ", codigoProducto='" + codigoProducto + '\'' +
                ", cantidad=" + cantidad +
                ", precioUnitario=" + precioUnitario +
                ", total=" + total +
                ", clienteId='" + clienteId + '\'' +
                ", fechaVenta=" + fechaVenta +
                ", canalVenta='" + canalVenta + '\'' +
                ", ubicacion='" + ubicacion + '\'' +
                '}';
    }
}
