package com.cafexpress.backend.common.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import java.util.concurrent.*;

@Configuration
public class RestClientConfig {

    @Bean("openMeteoRestClient")
    RestClient openMeteoRestClient(
            RestClient.Builder builder,
            @Value("${app.open-meteo.base-url}") String baseUrl
    ) {
        return builder
                .requestFactory(timeouts())
                .baseUrl(baseUrl)
                .build();
    }

    private SimpleClientHttpRequestFactory timeouts() {
        var factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(2000);
        factory.setReadTimeout(3000);
        return factory;
    }

    @Bean("geocodingRestClient")
    RestClient geocodingRestClient(RestClient.Builder builder,
            @Value("${app.geocoding.base-url:https://geocoding-api.open-meteo.com/v1}") String baseUrl) {
        return builder.baseUrl(baseUrl).requestFactory(timeouts()).build();
    }

    @Bean(name = "dashboardWeatherExecutor", destroyMethod = "shutdown")
    ExecutorService dashboardWeatherExecutor() {
        return Executors.newFixedThreadPool(5);
    }
}
