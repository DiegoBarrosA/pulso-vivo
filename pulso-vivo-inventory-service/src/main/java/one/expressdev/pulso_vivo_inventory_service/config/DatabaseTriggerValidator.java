package one.expressdev.pulso_vivo_inventory_service.config;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
@Slf4j
public class DatabaseTriggerValidator {
    
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    @PostConstruct
    public void validateAndFixTriggers() {
        try {
            validateProductTrigger();
        } catch (Exception e) {
            log.error("Failed to validate database triggers", e);
            // Decide whether to fail startup or continue
            throw new RuntimeException("Database trigger validation failed", e);
        }
    }
    
    private void validateProductTrigger() {
        // Check trigger status
        String checkTriggerSql = """
            SELECT status FROM user_triggers 
            WHERE trigger_name = 'TRG_PRODUCT_ID'
            """;
        
        try {
            String status = jdbcTemplate.queryForObject(checkTriggerSql, String.class);
            
            if (!"ENABLED".equals(status)) {
                log.warn("Trigger TRG_PRODUCT_ID is {}, attempting to fix...", status);
                fixProductTrigger();
            } else {
                log.info("Trigger TRG_PRODUCT_ID is valid");
            }
        } catch (EmptyResultDataAccessException e) {
            log.warn("Trigger TRG_PRODUCT_ID not found, creating...");
            createProductTrigger();
        }
    }
    
    private void fixProductTrigger() {
        try {
            // Try to recompile first
            jdbcTemplate.execute("ALTER TRIGGER TRG_PRODUCT_ID COMPILE");
            log.info("Successfully recompiled trigger TRG_PRODUCT_ID");
        } catch (DataAccessException e) {
            log.warn("Failed to recompile trigger, recreating...", e);
            recreateProductTrigger();
        }
    }
    
    private void recreateProductTrigger() {
        try {
            // Drop existing trigger
            jdbcTemplate.execute("DROP TRIGGER TRG_PRODUCT_ID");
        } catch (DataAccessException e) {
            log.debug("Trigger didn't exist or couldn't be dropped", e);
        }
        
        createProductTrigger();
    }
    
    private void createProductTrigger() {
        // Ensure sequence exists
        createSequenceIfNotExists();
        
        // Create trigger
        String createTriggerSql = """
            CREATE OR REPLACE TRIGGER TRG_PRODUCT_ID
            BEFORE INSERT ON product
            FOR EACH ROW
            WHEN (new.id IS NULL)
            BEGIN
              SELECT SEQ_PRODUCT_ID.NEXTVAL INTO :new.id FROM dual;
            END;
            """;
        
        jdbcTemplate.execute(createTriggerSql);
        log.info("Successfully created trigger TRG_PRODUCT_ID");
    }
    
    private void createSequenceIfNotExists() {
        try {
            // Check if sequence exists
            jdbcTemplate.queryForObject(
                "SELECT sequence_name FROM user_sequences WHERE sequence_name = 'SEQ_PRODUCT_ID'", 
                String.class
            );
        } catch (EmptyResultDataAccessException e) {
            // Sequence doesn't exist, create it
            String createSeqSql = """
                CREATE SEQUENCE SEQ_PRODUCT_ID 
                START WITH 1 
                INCREMENT BY 1 
                NOCACHE
                """;
            jdbcTemplate.execute(createSeqSql);
            log.info("Created sequence SEQ_PRODUCT_ID");
        }
    }
}
