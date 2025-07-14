package cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.controller;

import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.entity.Product;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.repository.ProductRepository;
import cl.duoc.ejemplo.dsy2206.semana5.rabbitmqavanzado.service.StockChangeNotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/monitoring")
public class ProductController {

    private final ProductRepository productRepository;
    private final StockChangeNotificationService stockChangeNotificationService;

    public ProductController(ProductRepository productRepository,
                           StockChangeNotificationService stockChangeNotificationService) {
        this.productRepository = productRepository;
        this.stockChangeNotificationService = stockChangeNotificationService;
    }

    // Stock monitoring endpoints only
    @GetMapping("/products/active")
    public ResponseEntity<List<Product>> getActiveProductsForMonitoring() {
        List<Product> products = productRepository.findActiveProducts();
        return ResponseEntity.ok(products);
    }

    @GetMapping("/products/{id}")
    public ResponseEntity<Product> getProductForMonitoring(@PathVariable Long id) {
        Optional<Product> product = productRepository.findById(id);
        return product.map(ResponseEntity::ok)
                     .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/products/category/{category}")
    public ResponseEntity<List<Product>> getProductsByCategoryForMonitoring(@PathVariable String category) {
        List<Product> products = productRepository.findActiveProductsByCategory(category);
        return ResponseEntity.ok(products);
    }
}