package one.expressdev.pulso_vivo_inventory_service.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "PRODUCT")
@Data
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public class Product {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @Column(name = "NAME", nullable = false)
    private String name = "";

    @Column(name = "DESCRIPTION")
    private String description = "";

    @Column(name = "QUANTITY", nullable = false)
    private int quantity = 0;

    @Column(name = "CATEGORY", nullable = false)
    private String category = "General";

    @Column(name = "ACTIVE", nullable = false)
    private boolean active = true;

    @Column(name = "PRICE", precision = 10, scale = 2, nullable = false)
    private BigDecimal price = BigDecimal.ZERO;

    @Column(name = "LAST_PRICE_UPDATE")
    private LocalDateTime lastPriceUpdate;

    @Column(name = "PREVIOUS_PRICE", precision = 10, scale = 2)
    private BigDecimal previousPrice = BigDecimal.ZERO;

    @Version
    @Column(name = "VERSION")
    private Long version;

    @PreUpdate
    public void preUpdate() {
        if (this.lastPriceUpdate == null) {
            this.lastPriceUpdate = LocalDateTime.now();
        }
    }

    @PrePersist
    public void prePersist() {
        if (this.lastPriceUpdate == null) {
            this.lastPriceUpdate = LocalDateTime.now();
        }
    }

    public void updatePrice(BigDecimal newPrice) {
        if (newPrice != null && (this.price == null || this.price.compareTo(newPrice) != 0)) {
            this.previousPrice = this.price;
            this.price = newPrice;
            this.lastPriceUpdate = LocalDateTime.now();
        }
    }

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
