package com.pulso.vivo.productor.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@Service
public class InventarioService {
    private final RestTemplate restTemplate;
    private final String inventarioBaseUrl;

    public InventarioService(@Value("${inventario.service.base-url}") String inventarioBaseUrl) {
        this.restTemplate = new RestTemplate();
        this.inventarioBaseUrl = inventarioBaseUrl;
    }

    public Integer obtenerStockActual(String codigoProducto) {
        try {
            Long id = Long.parseLong(codigoProducto);
            String url = inventarioBaseUrl + "/products/" + id;
            ProductDTO product = restTemplate.getForObject(url, ProductDTO.class);
            return product != null ? product.getQuantity() : 0;
        } catch (NumberFormatException e) {
            System.out.println("codigoProducto no es un ID numérico: " + codigoProducto);
            return 0;
        } catch (Exception e) {
            System.out.println("Error consultando stock a inventario: " + e.getMessage());
            return 0;
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ProductDTO {
        private int quantity;
        public int getQuantity() { return quantity; }
        public void setQuantity(int quantity) { this.quantity = quantity; }
    }
}
