package one.expressdev.pulso_vivo_inventory_service.controller;

import one.expressdev.pulso_vivo_inventory_service.repository.ProductRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
public class HealthController {

    private static final Logger logger = LoggerFactory.getLogger(HealthController.class);

    @Autowired
    private DataSource dataSource;

    @Autowired
    private ProductRepository productRepository;

    @GetMapping
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> health = new HashMap<>();
        health.put("timestamp", LocalDateTime.now().toString());
        health.put("service", "pulso-vivo-inventory-service");
        health.put("status", "UP");

        try {
            // Check database connectivity
            Map<String, Object> dbHealth = checkDatabaseHealth();
            health.put("database", dbHealth);

            // Check repository functionality
            Map<String, Object> repoHealth = checkRepositoryHealth();
            health.put("repository", repoHealth);

            // Overall status
            boolean dbUp = "UP".equals(dbHealth.get("status"));
            boolean repoUp = "UP".equals(repoHealth.get("status"));
            
            if (dbUp && repoUp) {
                health.put("status", "UP");
                return ResponseEntity.ok(health);
            } else {
                health.put("status", "DOWN");
                return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(health);
            }

        } catch (Exception e) {
            logger.error("Health check failed", e);
            health.put("status", "DOWN");
            health.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(health);
        }
    }

    @GetMapping("/db")
    public ResponseEntity<Map<String, Object>> databaseHealth() {
        Map<String, Object> response = checkDatabaseHealth();
        
        if ("UP".equals(response.get("status"))) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(response);
        }
    }

    @GetMapping("/detailed")
    public ResponseEntity<Map<String, Object>> detailedHealth() {
        Map<String, Object> health = new HashMap<>();
        health.put("timestamp", LocalDateTime.now().toString());
        health.put("service", "pulso-vivo-inventory-service");

        try {
            // Database health
            Map<String, Object> dbHealth = checkDatabaseHealth();
            health.put("database", dbHealth);

            // Repository health
            Map<String, Object> repoHealth = checkRepositoryHealth();
            health.put("repository", repoHealth);

            // JVM information
            Map<String, Object> jvmHealth = getJvmInfo();
            health.put("jvm", jvmHealth);

            // System information
            Map<String, Object> systemHealth = getSystemInfo();
            health.put("system", systemHealth);

            // Overall status
            boolean dbUp = "UP".equals(dbHealth.get("status"));
            boolean repoUp = "UP".equals(repoHealth.get("status"));
            
            health.put("status", (dbUp && repoUp) ? "UP" : "DOWN");

            return ResponseEntity.ok(health);

        } catch (Exception e) {
            logger.error("Detailed health check failed", e);
            health.put("status", "DOWN");
            health.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(health);
        }
    }

    private Map<String, Object> checkDatabaseHealth() {
        Map<String, Object> dbHealth = new HashMap<>();
        
        try (Connection connection = dataSource.getConnection()) {
            if (connection.isValid(5)) {
                dbHealth.put("status", "UP");
                dbHealth.put("database", connection.getMetaData().getDatabaseProductName());
                dbHealth.put("version", connection.getMetaData().getDatabaseProductVersion());
                dbHealth.put("url", connection.getMetaData().getURL());
                dbHealth.put("autoCommit", connection.getAutoCommit());
                dbHealth.put("transactionIsolation", connection.getTransactionIsolation());
            } else {
                dbHealth.put("status", "DOWN");
                dbHealth.put("error", "Connection validation failed");
            }
        } catch (SQLException e) {
            logger.error("Database health check failed", e);
            dbHealth.put("status", "DOWN");
            dbHealth.put("error", e.getMessage());
            dbHealth.put("sqlState", e.getSQLState());
            dbHealth.put("errorCode", e.getErrorCode());
        }
        
        return dbHealth;
    }

    private Map<String, Object> checkRepositoryHealth() {
        Map<String, Object> repoHealth = new HashMap<>();
        
        try {
            long productCount = productRepository.count();
            repoHealth.put("status", "UP");
            repoHealth.put("productCount", productCount);
            repoHealth.put("message", "Repository is functioning correctly");
        } catch (Exception e) {
            logger.error("Repository health check failed", e);
            repoHealth.put("status", "DOWN");
            repoHealth.put("error", e.getMessage());
            repoHealth.put("type", e.getClass().getSimpleName());
        }
        
        return repoHealth;
    }

    private Map<String, Object> getJvmInfo() {
        Map<String, Object> jvmInfo = new HashMap<>();
        Runtime runtime = Runtime.getRuntime();
        
        jvmInfo.put("javaVersion", System.getProperty("java.version"));
        jvmInfo.put("javaVendor", System.getProperty("java.vendor"));
        jvmInfo.put("maxMemory", runtime.maxMemory() / (1024 * 1024) + " MB");
        jvmInfo.put("totalMemory", runtime.totalMemory() / (1024 * 1024) + " MB");
        jvmInfo.put("freeMemory", runtime.freeMemory() / (1024 * 1024) + " MB");
        jvmInfo.put("usedMemory", (runtime.totalMemory() - runtime.freeMemory()) / (1024 * 1024) + " MB");
        jvmInfo.put("availableProcessors", runtime.availableProcessors());
        
        return jvmInfo;
    }

    private Map<String, Object> getSystemInfo() {
        Map<String, Object> systemInfo = new HashMap<>();
        
        systemInfo.put("osName", System.getProperty("os.name"));
        systemInfo.put("osVersion", System.getProperty("os.version"));
        systemInfo.put("osArch", System.getProperty("os.arch"));
        systemInfo.put("userTimezone", System.getProperty("user.timezone"));
        systemInfo.put("fileEncoding", System.getProperty("file.encoding"));
        
        return systemInfo;
    }
}