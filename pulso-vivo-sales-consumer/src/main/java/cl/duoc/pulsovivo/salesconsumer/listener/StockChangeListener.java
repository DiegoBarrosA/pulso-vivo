package cl.duoc.pulsovivo.salesconsumer.listener;

import cl.duoc.pulsovivo.salesconsumer.entity.SaleStockChange;
import cl.duoc.pulsovivo.salesconsumer.repository.SaleStockChangeRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

@Component
public class StockChangeListener {
    @Autowired
    private SaleStockChangeRepository repository;

    @Autowired
    private ObjectMapper objectMapper;

    @RabbitListener(queues = "stock-changes")
    public void handleStockChange(String message) throws Exception {
        var node = objectMapper.readTree(message);
        SaleStockChange entity = new SaleStockChange();
        entity.setProductId(node.get("productId").asLong());
        entity.setProductName(node.get("productName").asText());
        entity.setProductCategory(node.get("productCategory").asText());
        entity.setQuantityChanged(node.get("quantityChanged").asInt());
        entity.setNewQuantity(node.get("newQuantity").asInt());
        entity.setSaleTotal(node.get("saleTotal").asDouble());
        List<Integer> ts = objectMapper.convertValue(node.get("changeTimestamp"), List.class);
        entity.setChangeTimestamp(LocalDateTime.of(ts.get(0), ts.get(1), ts.get(2), ts.get(3), ts.get(4), ts.get(5), ts.get(6)));
        repository.save(entity);
    }
}