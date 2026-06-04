package org.example;

import com.arangodb.ArangoDB;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ArangoConfig {

    @Value("${arangodb.host}")
    private String host;

    @Value("${arangodb.port}")
    private int port;

    @Value("${arangodb.user}")
    private String user;

    @Value("${arangodb.password}")
    private String password;

    @Bean
    public ArangoDB arangoDB() {
        return new ArangoDB.Builder()
                .host(host, port)
                .user(user)
                .password(password)
                .build();
    }
}
