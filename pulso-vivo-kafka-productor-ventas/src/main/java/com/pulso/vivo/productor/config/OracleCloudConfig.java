package com.pulso.vivo.productor.config;

import oracle.jdbc.pool.OracleDataSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

import javax.sql.DataSource;
import java.sql.SQLException;

@Configuration
public class OracleCloudConfig {

    private final Environment env;

    public OracleCloudConfig(Environment env) {
        this.env = env;
    }

    @Bean
    public DataSource dataSource() throws SQLException {
        // Set system properties for Oracle Wallet
        System.setProperty("oracle.net.wallet_location",
            env.getProperty("oracle.net.wallet_location", "file:./wallet"));
        System.setProperty("oracle.net.ssl_server_dn_match",
            env.getProperty("oracle.net.ssl_server_dn_match", "false"));

        OracleDataSource dataSource = new OracleDataSource();
        dataSource.setURL(env.getProperty("spring.datasource.url"));
        dataSource.setUser(env.getProperty("spring.datasource.username"));
        dataSource.setPassword(env.getProperty("spring.datasource.password"));

        return dataSource;
    }
}
