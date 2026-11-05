package com.cafexpress.backend.alerta.service;

import com.cafexpress.backend.alerta.dto.AlertaClimaticaResponse;
import com.cafexpress.backend.alerta.dto.OpenMeteoResponse;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class OpenMeteoService {

    private final RestClient restClient;
    private final String dailyVariables;
    private final String currentVariables;
    private final String timezone;
    private final double temperaturaMinima;
    private final double temperaturaMaxima;
    private final double lluviaMinima;
    private final double lluviaMaxima;

    public OpenMeteoService(
            @Qualifier("openMeteoRestClient")             RestClient restClient,
            @Value("${app.open-meteo.daily-variables}") String dailyVariables,
            @Value("${app.open-meteo.current-variables}") String currentVariables,
            @Value("${app.open-meteo.timezone}") String timezone,
            @Value("${app.alerta.cafe.temperatura-minima}") double temperaturaMinima,
            @Value("${app.alerta.cafe.temperatura-maxima}") double temperaturaMaxima,
            @Value("${app.alerta.cafe.lluvia-minima}") double lluviaMinima,
            @Value("${app.alerta.cafe.lluvia-maxima}") double lluviaMaxima
    ) {
        this.restClient = restClient;
        this.dailyVariables = dailyVariables;
        this.currentVariables = currentVariables;
        this.timezone = timezone;
        this.temperaturaMinima = temperaturaMinima;
        this.temperaturaMaxima = temperaturaMaxima;
        this.lluviaMinima = lluviaMinima;
        this.lluviaMaxima = lluviaMaxima;
    }

    public OpenMeteoResponse consultar(double latitude, double longitude) {
        try {
            OpenMeteoResponse response = restClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/forecast")
                            .queryParam("latitude", latitude)
                            .queryParam("longitude", longitude)
                            .queryParam("daily", dailyVariables)
                            .queryParam("current", currentVariables)
                            .queryParam("timezone", timezone)
                            .build())
                    .retrieve()
                    .body(OpenMeteoResponse.class);

            if (response == null) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_GATEWAY,
                        "El servicio de clima devolvio una respuesta vacia."
                );
            }

            return response;
        } catch (RestClientException ex) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "No fue posible consultar el servicio de clima.",
                    ex
            );
        }
    }

    public AlertaClimaticaResponse consultarAlerta(
            double latitude,
            double longitude
    ) {
        OpenMeteoResponse clima = consultar(latitude, longitude);
        OpenMeteoResponse.CurrentWeather current = clima.current();
        OpenMeteoResponse.DailyWeather daily = clima.daily();

        if (current == null
                || current.temperature_2m() == null
                || daily == null
                || daily.temperature_2m_max() == null
                || daily.temperature_2m_min() == null
                || daily.rain_sum() == null
                || daily.temperature_2m_max().isEmpty()
                || daily.temperature_2m_max().size() != daily.temperature_2m_min().size()
                || daily.temperature_2m_max().size() != daily.rain_sum().size()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_GATEWAY,
                    "El servicio de clima devolvio datos incompletos."
            );
        }

        List<Double> temperaturasMaximas = daily.temperature_2m_max();
        List<Double> temperaturasMinimas = daily.temperature_2m_min();
        List<Double> lluvias = daily.rain_sum();

        double temperaturaPromedio = promedioTemperatura(
                temperaturasMaximas,
                temperaturasMinimas
        );
        double lluviaPromedio = lluvias.stream()
                .mapToDouble(Double::doubleValue)
                .average()
                .orElseThrow();

        boolean temperaturaActualOptima = enRango(
                current.temperature_2m(),
                temperaturaMinima,
                temperaturaMaxima
        );
        boolean pronosticoOptimo = true;

        for (int i = 0; i < temperaturasMaximas.size(); i++) {
            double temperaturaDiaria = (
                    temperaturasMaximas.get(i) + temperaturasMinimas.get(i)
            ) / 2;

            if (!enRango(temperaturaDiaria, temperaturaMinima, temperaturaMaxima)
                    || !enRango(lluvias.get(i), lluviaMinima, lluviaMaxima)) {
                pronosticoOptimo = false;
                break;
            }
        }

        boolean condicionesOptimas = temperaturaActualOptima && pronosticoOptimo;

        return new AlertaClimaticaResponse(
                condicionesOptimas
                        ? "Precio bajo por abundancia"
                        : "Precio en aumento por escazes",
                condicionesOptimas,
                current.temperature_2m(),
                temperaturaPromedio,
                lluviaPromedio,
                lluvias.size()
        );
    }

    private double promedioTemperatura(
            List<Double> maximas,
            List<Double> minimas
    ) {
        double suma = 0;

        for (int i = 0; i < maximas.size(); i++) {
            suma += (maximas.get(i) + minimas.get(i)) / 2;
        }

        return suma / maximas.size();
    }

    private boolean enRango(double valor, double minimo, double maximo) {
        return valor >= minimo && valor <= maximo;
    }
}
