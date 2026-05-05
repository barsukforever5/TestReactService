package org.example;

import com.arangodb.ArangoDB;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ArangoConfig {

    @Bean
    public ArangoDB arangoDB() {
        return new ArangoDB.Builder()
                .host("host.containers.internal", 8529)
                .user("root")
                .password("root")
                .build();
    }
}
