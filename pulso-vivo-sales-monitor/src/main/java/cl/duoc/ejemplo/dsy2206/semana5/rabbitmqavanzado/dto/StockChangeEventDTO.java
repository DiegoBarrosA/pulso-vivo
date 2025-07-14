package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;
import lombok.Builder;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
@ToString
@Builder
public class StockChangeEventDTO {
    private Long productId;
    private String productName;
    private String productCategory;
    private int quantityChanged;
    private int newQuantity;
    private BigDecimal saleTotal;
    private LocalDateTime changeTimestamp;

    // Métodos getter explícitos para compatibilidad con código que usa getX()
    public Long getProductId() { return productId; }
    public String getProductName() { return productName; }
    public String getProductCategory() { return productCategory; }
    public int getQuantityChanged() { return quantityChanged; }
    public int getNewQuantity() { return newQuantity; }
    public BigDecimal getSaleTotal() { return saleTotal; }
    public LocalDateTime getChangeTimestamp() { return changeTimestamp; }
}
