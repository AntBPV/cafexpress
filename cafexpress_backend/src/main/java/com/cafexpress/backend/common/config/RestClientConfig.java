package com.cafexpress.backend.common.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;

@Configuration
public class RestClientConfig {

    @Bean("openMeteoRestClient")
    RestClient openMeteoRestClient(
            RestClient.Builder builder,
            @Value("${app.open-meteo.base-url}") String baseUrl
    ) {
        return builder
                .baseUrl(baseUrl)
                .build();
    }
}
