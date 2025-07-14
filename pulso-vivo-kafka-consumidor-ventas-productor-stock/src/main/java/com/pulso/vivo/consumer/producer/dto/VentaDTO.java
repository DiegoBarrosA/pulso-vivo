package com.pulso.vivo.consumer.producer.dto;

import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAnySetter;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.JsonDeserializer;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.datatype.jsr310.deser.LocalDateTimeDeserializer;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
public class VentaDTO {

    // Standard fields with proper JSON property mapping
    private Long id;
    private String codigoProducto;
    private Integer cantidad;
    private BigDecimal precioUnitario;
    private BigDecimal total;
    private String clienteId;

    @JsonDeserialize(using = LocalDateTimeDeserializer.class)
    private LocalDateTime fechaVenta;

    private String canalVenta;
    private String ubicacion;

    // Capture any additional fields
    private Map<String, Object> additionalFields = new HashMap<>();

    public VentaDTO() {}

    // JsonAnyGetter and JsonAnySetter to capture unknown fields
    @JsonAnyGetter
    public Map<String, Object> getAdditionalFields() {
        return additionalFields;
    }

    @JsonAnySetter
    public void setAdditionalField(String key, Object value) {
        additionalFields.put(key, value);

        // Handle the array-format fechaVenta specifically
        if ("fechaVenta".equals(key) && value instanceof List) {
            try {
                List<?> dateArray = (List<?>) value;
                if (dateArray.size() >= 6) {
                    int year = ((Number) dateArray.get(0)).intValue();
                    int month = ((Number) dateArray.get(1)).intValue();
                    int day = ((Number) dateArray.get(2)).intValue();
                    int hour = ((Number) dateArray.get(3)).intValue();
                    int minute = ((Number) dateArray.get(4)).intValue();
                    int second = ((Number) dateArray.get(5)).intValue();
                    int nano = dateArray.size() > 6 ? ((Number) dateArray.get(6)).intValue() : 0;

                    this.fechaVenta = LocalDateTime.of(year, month, day, hour, minute, second, nano);
                }
            } catch (Exception e) {
                // If parsing fails, just ignore the date
            }
        }
    }

    // Standard getters and setters
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

    @Override
    public String toString() {
        return "VentaDTO{" +
                "id=" + id +
                ", codigoProducto='" + codigoProducto + '\'' +
                ", cantidad=" + cantidad +
                ", precioUnitario=" + precioUnitario +
                ", total=" + total +
                ", clienteId='" + clienteId + '\'' +
                ", fechaVenta=" + fechaVenta +
                ", canalVenta='" + canalVenta + '\'' +
                ", ubicacion='" + ubicacion + '\'' +
                ", additionalFields=" + additionalFields +
                '}';
    }
}
