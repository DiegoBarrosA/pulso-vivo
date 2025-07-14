package cl.duoc.pulsovivo.salesconsumer.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "SALE_STOCK_CHANGE")
public class SaleStockChange {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long productId;
    private String productName;
    private String productCategory;
    private Integer quantityChanged;
    private Integer newQuantity;
    private Double saleTotal;
    private LocalDateTime changeTimestamp;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getProductId() { return productId; }
    public void setProductId(Long productId) { this.productId = productId; }
    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }
    public String getProductCategory() { return productCategory; }
    public void setProductCategory(String productCategory) { this.productCategory = productCategory; }
    public Integer getQuantityChanged() { return quantityChanged; }
    public void setQuantityChanged(Integer quantityChanged) { this.quantityChanged = quantityChanged; }
    public Integer getNewQuantity() { return newQuantity; }
    public void setNewQuantity(Integer newQuantity) { this.newQuantity = newQuantity; }
    public Double getSaleTotal() { return saleTotal; }
    public void setSaleTotal(Double saleTotal) { this.saleTotal = saleTotal; }
    public LocalDateTime getChangeTimestamp() { return changeTimestamp; }
    public void setChangeTimestamp(LocalDateTime changeTimestamp) { this.changeTimestamp = changeTimestamp; }
}