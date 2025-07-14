package cl.duoc.pulsovivo.salesconsumer.repository;

import cl.duoc.pulsovivo.salesconsumer.entity.SaleStockChange;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SaleStockChangeRepository extends JpaRepository<SaleStockChange, Long> {
    List<SaleStockChange> findByProductId(Long productId);
    List<SaleStockChange> findByProductCategory(String productCategory);
    List<SaleStockChange> findByProductNameContainingIgnoreCase(String productName);
    List<SaleStockChange> findByChangeTimestampBetween(java.time.LocalDateTime start, java.time.LocalDateTime end);
}