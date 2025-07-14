package one.expressdev.pulso_vivo_inventory_service.service;

import java.util.List;
import java.util.stream.Collectors;
import one.expressdev.pulso_vivo_inventory_service.dto.InventoryUpdateRequest;
import one.expressdev.pulso_vivo_inventory_service.dto.ProductDTO;
import one.expressdev.pulso_vivo_inventory_service.model.Product;
import one.expressdev.pulso_vivo_inventory_service.repository.ProductRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import jakarta.persistence.OptimisticLockException;

@Service
public class ProductService {

    @Autowired
    private ProductRepository productRepository;

    public List<ProductDTO> getAllProducts() {
        return productRepository
            .findAll()
            .stream()
            .map(this::toDTO)
            .collect(Collectors.toList());
    }

    public ProductDTO getProductById(Long id) {
        return productRepository.findById(id).map(this::toDTO).orElse(null);
    }

    @Transactional
    public ProductDTO createProduct(ProductDTO dto) {
        try {
            Product product = toEntity(dto);
            Product savedProduct = productRepository.save(product);
            return toDTO(savedProduct);
        } catch (Exception e) {
            throw new RuntimeException("Failed to create product: " + e.getMessage(), e);
        }
    }

    // You can add this method after your createProduct method

    @Transactional
    public ProductDTO updateProduct(Long id, ProductDTO dto) {
        try {
            // Find the existing product or throw an error if it's not found
            Product productToUpdate = productRepository
                .findById(id)
                .orElseThrow(() ->
                    new RuntimeException("Product not found with id: " + id)
                );

            // Fix version field if it's null (for existing records that might have null version)
            if (productToUpdate.getVersion() == null) {
                productToUpdate.setVersion(0L);
            }

            // Update the product's fields from the DTO
            productToUpdate.setName(dto.getName());
            productToUpdate.setDescription(dto.getDescription());
            productToUpdate.setCategory(dto.getCategory());
            productToUpdate.setActive(dto.isActive());
            
            // Handle price update if provided
            if (dto.getPrice() != null) {
                productToUpdate.updatePrice(dto.getPrice());
            }
            
            // Update quantity if provided
            if (dto.getQuantity() >= 0) {
                productToUpdate.setQuantity(dto.getQuantity());
            }

            // Save the updated product to the database
            Product savedProduct = productRepository.save(productToUpdate);

            // Return the updated product as a DTO
            return toDTO(savedProduct);
        } catch (OptimisticLockException e) {
            throw new RuntimeException("Product was modified by another user. Please refresh and try again.", e);
        } catch (Exception e) {
            throw new RuntimeException("Failed to update product: " + e.getMessage(), e);
        }
    }

    @Transactional
    public void updateStock(Long id, InventoryUpdateRequest request) {
        try {
            Product product = productRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Product not found with id: " + id));
        
            // Fix version field if it's null (for existing records that might have null version)
            if (product.getVersion() == null) {
                product.setVersion(0L);
            }
        
            int newQuantity = product.getQuantity() + request.getQuantityChanged();
            if (newQuantity < 0) {
                throw new RuntimeException("Insufficient stock. Current: " + product.getQuantity() + 
                    ", Requested change: " + request.getQuantityChanged());
            }
            
            product.setQuantity(newQuantity);
            productRepository.save(product);
        } catch (OptimisticLockException e) {
            throw new RuntimeException("Product was modified by another user. Please refresh and try again.", e);
        } catch (Exception e) {
            throw new RuntimeException("Failed to update stock: " + e.getMessage(), e);
        }
    }

    public List<ProductDTO> getLowStockProducts() {
        return productRepository
            .findByQuantityLessThan(10)
            .stream()
            .map(this::toDTO)
            .collect(Collectors.toList());
    }

    private ProductDTO toDTO(Product p) {
        ProductDTO dto = new ProductDTO();
        dto.setId(p.getId());
        dto.setName(p.getName());
        dto.setDescription(p.getDescription());
        dto.setQuantity(p.getQuantity());
        dto.setCategory(p.getCategory());
        dto.setActive(p.isActive());
        dto.setPrice(p.getPrice());
        dto.setLastPriceUpdate(p.getLastPriceUpdate());
        dto.setPreviousPrice(p.getPreviousPrice());
        dto.setVersion(p.getVersion());
        return dto;
    }

    private Product toEntity(ProductDTO dto) {
        Product p = new Product();
        if (dto.getId() != null) {
            p.setId(dto.getId());
        }
        p.setName(dto.getName());
        p.setDescription(dto.getDescription());
        p.setQuantity(dto.getQuantity());
        p.setCategory(dto.getCategory());
        p.setActive(dto.isActive());
        p.setPrice(dto.getPrice());
        p.setLastPriceUpdate(dto.getLastPriceUpdate());
        p.setPreviousPrice(dto.getPreviousPrice());
        if (dto.getVersion() != null) {
            p.setVersion(dto.getVersion());
        }
        return p;
    }
}
