package org.example;

import com.arangodb.ArangoDB;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ArangoConfig {

    @Bean
    public ArangoDB arangoDB() {
        return new ArangoDB.Builder()
                .host("arangodb.arango.svc.cluster.local", 8529)
                .user("root")
                .password("root")
                .build();
    }
}
