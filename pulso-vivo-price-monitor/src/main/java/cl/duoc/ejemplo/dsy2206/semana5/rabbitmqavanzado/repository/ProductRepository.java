package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.repository;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.entity.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    /**
     * Find products that have been updated after a specific timestamp
     * This is useful for polling-based price change detection
     */
    @Query("SELECT p FROM Product p WHERE p.lastPriceUpdate > :timestamp")
    List<Product> findProductsUpdatedAfter(@Param("timestamp") LocalDateTime timestamp);

    /**
     * Find products by category with active status
     */
    @Query("SELECT p FROM Product p WHERE p.category = :category AND p.active = true")
    List<Product> findActiveProductsByCategory(@Param("category") String category);

    /**
     * Find products with price changes in a specific time range
     */
    @Query("SELECT p FROM Product p WHERE p.lastPriceUpdate BETWEEN :startTime AND :endTime")
    List<Product> findProductsWithPriceChangesInRange(
            @Param("startTime") LocalDateTime startTime, 
            @Param("endTime") LocalDateTime endTime);

    /**
     * Find products where previous price is different from current price
     * Useful for detecting products with pending price change notifications
     */
    @Query("SELECT p FROM Product p WHERE p.previousPrice IS NOT NULL AND p.previousPrice != p.price")
    List<Product> findProductsWithPriceChanges();

    /**
     * Find active products only
     */
    @Query("SELECT p FROM Product p WHERE p.active = true")
    List<Product> findActiveProducts();

    /**
     * Find product by name (case insensitive)
     */
    @Query("SELECT p FROM Product p WHERE UPPER(p.name) = UPPER(:name)")
    Optional<Product> findByNameIgnoreCase(@Param("name") String name);

    /**
     * Count products updated after a specific timestamp
     */
    @Query("SELECT COUNT(p) FROM Product p WHERE p.lastPriceUpdate > :timestamp")
    long countProductsUpdatedAfter(@Param("timestamp") LocalDateTime timestamp);

    /**
     * Find products that haven't been updated for a while (potentially stale data)
     */
    @Query("SELECT p FROM Product p WHERE p.lastPriceUpdate < :threshold OR p.lastPriceUpdate IS NULL")
    List<Product> findStaleProducts(@Param("threshold") LocalDateTime threshold);
}