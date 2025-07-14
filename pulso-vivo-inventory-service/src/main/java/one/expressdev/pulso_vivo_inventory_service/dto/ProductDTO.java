package one.expressdev.pulso_vivo_inventory_service.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProductDTO {

    private Long id;
    private String name = "";
    private String description = "";
    private int quantity = 0;
    private String category = "General";
    private boolean active = true;
    private BigDecimal price = BigDecimal.ZERO;
    private LocalDateTime lastPriceUpdate = LocalDateTime.now();
    private BigDecimal previousPrice = BigDecimal.ZERO;
    private Long version = 0L;

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
}
