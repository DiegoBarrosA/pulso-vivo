package com.pulso.vivo.consumer.producer.repository;

import com.pulso.vivo.consumer.producer.model.StockMovement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface StockMovementRepository extends JpaRepository<StockMovement, Long> {

    List<StockMovement> findByProductCodeOrderByFechaMovimientoDesc(String productCode);

    List<StockMovement> findByProductIdOrderByFechaMovimientoDesc(Long productId);

    List<StockMovement> findByVentaId(Long ventaId);

    @Query("SELECT sm FROM StockMovement sm WHERE sm.fechaMovimiento >= :desde ORDER BY sm.fechaMovimiento DESC")
    List<StockMovement> findRecentMovements(@Param("desde") LocalDateTime desde);

    @Query("SELECT SUM(sm.cantidad) FROM StockMovement sm WHERE sm.productCode = :productCode AND sm.tipoMovimiento = 'VENTA'")
    Integer getTotalVentasByProductCode(@Param("productCode") String productCode);

    @Query("SELECT SUM(sm.cantidad) FROM StockMovement sm WHERE sm.productId = :productId AND sm.tipoMovimiento = 'VENTA'")
    Integer getTotalVentasByProductId(@Param("productId") Long productId);
}
