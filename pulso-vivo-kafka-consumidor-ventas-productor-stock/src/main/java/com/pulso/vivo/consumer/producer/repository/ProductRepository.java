package com.pulso.vivo.consumer.producer.repository;

import com.pulso.vivo.consumer.producer.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    @Query("SELECT p.id FROM Product p WHERE p.name = :productCode OR CAST(p.id AS string) = :productCode")
    Optional<Long> findProductIdByCode(@Param("productCode") String productCode);

    @Query("SELECT p FROM Product p WHERE p.name = :productCode OR CAST(p.id AS string) = :productCode")
    Optional<Product> findByProductCode(@Param("productCode") String productCode);
}
