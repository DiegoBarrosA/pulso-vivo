package com.pulso.vivo.consumer.producer.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import java.time.LocalDateTime;

public class StockUpdateDTO {
    private String codigoProducto;
    private Integer cantidadVendida;
    private String tipoMovimiento;
    private String ubicacion;
    private Long ventaId;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime fechaMovimiento;

    private String clienteId;
    private String canalVenta;
    private Integer stock; // Add stock field

    // Constructors
    public StockUpdateDTO() {}

    public StockUpdateDTO(String codigoProducto, Integer cantidadVendida, String tipoMovimiento,
                         String ubicacion, Long ventaId, LocalDateTime fechaMovimiento,
                         String clienteId, String canalVenta, Integer stock) {
        this.codigoProducto = codigoProducto;
        this.cantidadVendida = cantidadVendida;
        this.tipoMovimiento = tipoMovimiento;
        this.ubicacion = ubicacion;
        this.ventaId = ventaId;
        this.fechaMovimiento = fechaMovimiento;
        this.clienteId = clienteId;
        this.canalVenta = canalVenta;
        this.stock = stock;
    }

    // Builder pattern methods
    public static StockUpdateDTO builder() {
        return new StockUpdateDTO();
    }

    public StockUpdateDTO codigoProducto(String codigoProducto) {
        this.codigoProducto = codigoProducto;
        return this;
    }

    public StockUpdateDTO cantidadVendida(Integer cantidadVendida) {
        this.cantidadVendida = cantidadVendida;
        return this;
    }

    public StockUpdateDTO tipoMovimiento(String tipoMovimiento) {
        this.tipoMovimiento = tipoMovimiento;
        return this;
    }

    public StockUpdateDTO ubicacion(String ubicacion) {
        this.ubicacion = ubicacion;
        return this;
    }

    public StockUpdateDTO ventaId(Long ventaId) {
        this.ventaId = ventaId;
        return this;
    }

    public StockUpdateDTO fechaMovimiento(LocalDateTime fechaMovimiento) {
        this.fechaMovimiento = fechaMovimiento;
        return this;
    }

    public StockUpdateDTO clienteId(String clienteId) {
        this.clienteId = clienteId;
        return this;
    }

    public StockUpdateDTO canalVenta(String canalVenta) {
        this.canalVenta = canalVenta;
        return this;
    }

    public StockUpdateDTO stock(Integer stock) { // Add stock method
        this.stock = stock;
        return this;
    }

    public StockUpdateDTO build() {
        return this;
    }

    // Getters and Setters
    public String getCodigoProducto() { return codigoProducto; }
    public void setCodigoProducto(String codigoProducto) { this.codigoProducto = codigoProducto; }

    public Integer getCantidadVendida() { return cantidadVendida; }
    public void setCantidadVendida(Integer cantidadVendida) { this.cantidadVendida = cantidadVendida; }

    public String getTipoMovimiento() { return tipoMovimiento; }
    public void setTipoMovimiento(String tipoMovimiento) { this.tipoMovimiento = tipoMovimiento; }

    public String getUbicacion() { return ubicacion; }
    public void setUbicacion(String ubicacion) { this.ubicacion = ubicacion; }

    public Long getVentaId() { return ventaId; }
    public void setVentaId(Long ventaId) { this.ventaId = ventaId; }

    public LocalDateTime getFechaMovimiento() { return fechaMovimiento; }
    public void setFechaMovimiento(LocalDateTime fechaMovimiento) { this.fechaMovimiento = fechaMovimiento; }

    public String getClienteId() { return clienteId; }
    public void setClienteId(String clienteId) { this.clienteId = clienteId; }

    public String getCanalVenta() { return canalVenta; }
    public void setCanalVenta(String canalVenta) { this.canalVenta = canalVenta; }

    public Integer getStock() { return stock; }
    public void setStock(Integer stock) { this.stock = stock; }
}
