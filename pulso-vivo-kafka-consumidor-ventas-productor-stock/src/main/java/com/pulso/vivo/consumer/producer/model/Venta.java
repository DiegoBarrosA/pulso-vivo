// src/main/java/com/pulso/vivo/consumer/producer/model/Venta.java
package com.pulso.vivo.consumer.producer.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class Venta {
    private Long id;
    private String codigoProducto;
    private Integer cantidad;
    private BigDecimal precioUnitario;
    private BigDecimal total;
    private String clienteId;  // Make sure this field exists
    private LocalDateTime fechaVenta;
    private String canalVenta;
    private String ubicacion;

    // Default constructor
    public Venta() {}

    // Getters and setters for ALL fields
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

    public String getClienteId() { return clienteId; }  // Make sure this getter exists
    public void setClienteId(String clienteId) { this.clienteId = clienteId; }  // And this setter

    public LocalDateTime getFechaVenta() { return fechaVenta; }
    public void setFechaVenta(LocalDateTime fechaVenta) { this.fechaVenta = fechaVenta; }

    public String getCanalVenta() { return canalVenta; }
    public void setCanalVenta(String canalVenta) { this.canalVenta = canalVenta; }

    public String getUbicacion() { return ubicacion; }
    public void setUbicacion(String ubicacion) { this.ubicacion = ubicacion; }
}
