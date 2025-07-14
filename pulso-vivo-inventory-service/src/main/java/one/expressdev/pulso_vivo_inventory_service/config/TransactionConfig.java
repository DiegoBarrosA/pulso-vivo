package one.expressdev.pulso_vivo_inventory_service.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import jakarta.persistence.EntityManagerFactory;

@Configuration
@EnableTransactionManagement
public class TransactionConfig {

    @Autowired
    private EntityManagerFactory entityManagerFactory;

    @Bean(name = "transactionManager")
    public PlatformTransactionManager transactionManager() {
        JpaTransactionManager transactionManager = new JpaTransactionManager();
        transactionManager.setEntityManagerFactory(entityManagerFactory);
        
        // Set transaction timeout (30 seconds)
        transactionManager.setDefaultTimeout(30);
        
        // Enable nested transactions support
        transactionManager.setNestedTransactionAllowed(true);
        
        // Fail early on commit failure
        transactionManager.setFailEarlyOnGlobalRollbackOnly(true);
        
        // Validate existing transactions
        transactionManager.setValidateExistingTransaction(true);
        
        return transactionManager;
    }
}