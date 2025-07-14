package com.pulsovivo.promotions.repository;

import com.pulsovivo.promotions.model.Promotion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PromotionRepository extends JpaRepository<Promotion, String> {

    List<Promotion> findByActiveTrue();

    List<Promotion> findByProductIdAndActiveTrue(String productId);

    List<Promotion> findByPromotionTypeAndActiveTrue(String promotionType);
}
