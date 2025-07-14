package com.pulso.vivo.consumer.producer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "STOCK_MOVEMENTS")
public class StockMovement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "product_id")
    private Long productId;

    @Column(name = "codigo_producto")
    private String productCode;

    @Column(name = "cantidad", nullable = false)
    private Integer cantidad;

    @Column(name = "tipo_movimiento", nullable = false)
    private String tipoMovimiento;

    @Column(name = "ubicacion")
    private String ubicacion;

    @Column(name = "venta_id")
    private Long ventaId;

    @Column(name = "fecha_movimiento", nullable = false)
    private LocalDateTime fechaMovimiento;

    @Column(name = "cliente_id")
    private String clienteId;

    @Column(name = "canal_venta")
    private String canalVenta;

    // Constructors
    public StockMovement() {}

    public StockMovement(Long productId, String productCode, Integer cantidad, String tipoMovimiento,
                        String ubicacion, Long ventaId, LocalDateTime fechaMovimiento,
                        String clienteId, String canalVenta) {
        this.productId = productId;
        this.productCode = productCode;
        this.cantidad = cantidad;
        this.tipoMovimiento = tipoMovimiento;
        this.ubicacion = ubicacion;
        this.ventaId = ventaId;
        this.fechaMovimiento = fechaMovimiento;
        this.clienteId = clienteId;
        this.canalVenta = canalVenta;
    }

    // Builder pattern
    public static StockMovement builder() {
        return new StockMovement();
    }

    public StockMovement productId(Long productId) {
        this.productId = productId;
        return this;
    }

    public StockMovement productCode(String productCode) {
        this.productCode = productCode;
        return this;
    }

    public StockMovement cantidad(Integer cantidad) {
        this.cantidad = cantidad;
        return this;
    }

    public StockMovement tipoMovimiento(String tipoMovimiento) {
        this.tipoMovimiento = tipoMovimiento;
        return this;
    }

    public StockMovement ubicacion(String ubicacion) {
        this.ubicacion = ubicacion;
        return this;
    }

    public StockMovement ventaId(Long ventaId) {
        this.ventaId = ventaId;
        return this;
    }

    public StockMovement fechaMovimiento(LocalDateTime fechaMovimiento) {
        this.fechaMovimiento = fechaMovimiento;
        return this;
    }

    public StockMovement clienteId(String clienteId) {
        this.clienteId = clienteId;
        return this;
    }

    public StockMovement canalVenta(String canalVenta) {
        this.canalVenta = canalVenta;
        return this;
    }

    public StockMovement build() {
        return this;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getProductId() { return productId; }
    public void setProductId(Long productId) { this.productId = productId; }

    public String getProductCode() { return productCode; }
    public void setProductCode(String productCode) { this.productCode = productCode; }

    public Integer getCantidad() { return cantidad; }
    public void setCantidad(Integer cantidad) { this.cantidad = cantidad; }

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

    @PrePersist
    protected void onCreate() {
        if (fechaMovimiento == null) {
            fechaMovimiento = LocalDateTime.now();
        }
    }
}
