package cl.duoc.pulsovivo.dto;

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
public class PriceChangeEventDTO {
    private Long productId;
    private String productName;
    private String productCategory;
    private BigDecimal oldPrice;
    private BigDecimal newPrice;
    private BigDecimal changeAmount;
    private Double changePercentage;
    private LocalDateTime changeTimestamp;
    private PriceChangeType changeType;
    private String changeReason;

    public enum PriceChangeType {
        PRICE_INCREASE,
        PRICE_DECREASE,
        INITIAL_PRICE,
        PRICE_RESET
    }

    public static PriceChangeEventDTO fromProduct(Long productId, String productName, String productCategory, 
                                                 BigDecimal oldPrice, BigDecimal newPrice) {
        BigDecimal changeAmount = BigDecimal.ZERO;
        Double changePercentage = 0.0;
        PriceChangeType changeType = PriceChangeType.INITIAL_PRICE;

        if (oldPrice != null && newPrice != null) {
            changeAmount = newPrice.subtract(oldPrice);
            if (oldPrice.compareTo(BigDecimal.ZERO) > 0) {
                changePercentage = changeAmount
                        .divide(oldPrice, 4, java.math.RoundingMode.HALF_UP)
                        .multiply(BigDecimal.valueOf(100))
                        .doubleValue();
            }
            changeType = changeAmount.compareTo(BigDecimal.ZERO) > 0 ? 
                        PriceChangeType.PRICE_INCREASE : PriceChangeType.PRICE_DECREASE;
        } else if (oldPrice == null && newPrice != null) {
            changeType = PriceChangeType.INITIAL_PRICE;
        }

        return PriceChangeEventDTO.builder()
                .productId(productId)
                .productName(productName)
                .productCategory(productCategory)
                .oldPrice(oldPrice)
                .newPrice(newPrice)
                .changeAmount(changeAmount)
                .changePercentage(changePercentage)
                .changeType(changeType)
                .build();
    }
}
