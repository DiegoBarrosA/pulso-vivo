package com.pulso.vivo.consumer.producer.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "PRODUCT")
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "NAME", nullable = false)
    private String name;

    @Column(name = "DESCRIPTION")
    private String description;

    @Column(name = "QUANTITY", nullable = false)
    private int quantity;

    @Column(name = "CATEGORY", nullable = false)
    private String category;

    @Column(name = "ACTIVE", nullable = false)
    private boolean active;

    @Column(name = "PRICE", precision = 10, scale = 2, nullable = false)
    private BigDecimal price;

    @Column(name = "LAST_PRICE_UPDATE")
    private LocalDateTime lastPriceUpdate;

    @Column(name = "PREVIOUS_PRICE", precision = 10, scale = 2)
    private BigDecimal previousPrice;

    @Version
    @Column(name = "VERSION")
    private Long version;

    // Constructors
    public Product() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public LocalDateTime getLastPriceUpdate() { return lastPriceUpdate; }
    public void setLastPriceUpdate(LocalDateTime lastPriceUpdate) { this.lastPriceUpdate = lastPriceUpdate; }

    public BigDecimal getPreviousPrice() { return previousPrice; }
    public void setPreviousPrice(BigDecimal previousPrice) { this.previousPrice = previousPrice; }

    public Long getVersion() { return version; }
    public void setVersion(Long version) { this.version = version; }
}
