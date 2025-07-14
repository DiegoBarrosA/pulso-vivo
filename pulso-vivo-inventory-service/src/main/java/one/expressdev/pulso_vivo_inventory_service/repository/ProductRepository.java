package one.expressdev.pulso_vivo_inventory_service.repository;

import java.util.List;
import one.expressdev.pulso_vivo_inventory_service.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProductRepository extends JpaRepository<Product, Long> {
    List<Product> findByQuantityLessThan(int quantity);
}
