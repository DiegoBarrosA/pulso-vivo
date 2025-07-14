package one.expressdev.pulso_vivo_inventory_service;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import one.expressdev.pulso_vivo_inventory_service.model.Product;
import one.expressdev.pulso_vivo_inventory_service.repository.ProductRepository;

@SpringBootTest
class PulsoVivoInventoryServiceApplicationTests {

    @Autowired
    private ProductRepository productRepository;

    @Test
    void contextLoads() {
    }

    @Test
    void testDataInitialized() {
        var products = productRepository.findAll();
        assertTrue(products.size() > 0);
        
        products.forEach(product -> {
            assertNotNull(product.getName());
            assertNotNull(product.getDescription());
            assertNotNull(product.getPrice());
            assertNotNull(product.getLastPriceUpdate());
            assertNotNull(product.getPreviousPrice(), "Previous price should not be null for product: " + product.getName());
        });
    }
}
