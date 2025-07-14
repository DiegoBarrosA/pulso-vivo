package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
@ToString
public class ProductoDTO {

    private Long id;
    private String name;
    private String description;
    private int quantity;
    private String category;
    private boolean active;
    private BigDecimal price;
    private LocalDateTime lastPriceUpdate;
    private BigDecimal previousPrice;
    private Long version;

    // Business methods for price change calculations
    public boolean hasPriceChanged() {
        if (previousPrice == null && price == null) {
            return false;
        }
        if (previousPrice == null || price == null) {
            return true;
        }
        return previousPrice.compareTo(price) != 0;
    }

    public BigDecimal getPriceChangeAmount() {
        if (previousPrice == null || price == null) {
            return BigDecimal.ZERO;
        }
        return price.subtract(previousPrice);
    }

    public double getPriceChangePercentage() {
        if (previousPrice == null || price == null || previousPrice.compareTo(BigDecimal.ZERO) == 0) {
            return 0.0;
        }
        return getPriceChangeAmount()
                .divide(previousPrice, 4, java.math.RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
                .doubleValue();
    }

    // Constructor for creating from Product entity
    public ProductoDTO(Long id, String name, String category) {
        this.id = id;
        this.name = name;
        this.category = category;
    }

    // Constructor for price monitoring focus
    public ProductoDTO(Long id, String name, String category, BigDecimal price, BigDecimal previousPrice, LocalDateTime lastPriceUpdate) {
        this.id = id;
        this.name = name;
        this.category = category;
        this.price = price;
        this.previousPrice = previousPrice;
        this.lastPriceUpdate = lastPriceUpdate;
    }
}