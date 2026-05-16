package org.example;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import com.hazelcast.config.Config;
import com.hazelcast.core.HazelcastInstance;
import com.hazelcast.config.NetworkConfig;
import com.hazelcast.config.JoinConfig;
import com.hazelcast.core.Hazelcast;

@Configuration
public class HazelcastConfig {

    @Bean
    public Config hazelcastConfiguration() {
        Config config = new Config();

        config.setClusterName("demo-cluster");

        NetworkConfig network = config.getNetworkConfig();
        network.setPort(5701).setPortAutoIncrement(true);

        JoinConfig join = network.getJoin();

        // важно для контейнеров
        join.getTcpIpConfig()
                .setEnabled(true)
                .addMember("react-backend-app")
                .addMember("angular-backend-app");

        join.getMulticastConfig().setEnabled(false);

        return config;
    }

    @Bean
    public HazelcastInstance hazelcastInstance(Config config) {
        return Hazelcast.newHazelcastInstance(config);
    }
}
