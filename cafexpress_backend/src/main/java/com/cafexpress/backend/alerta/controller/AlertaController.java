package com.cafexpress.backend.alerta.controller;

import com.cafexpress.backend.alerta.dto.AlertaClimaticaResponse;
import com.cafexpress.backend.alerta.service.OpenMeteoService;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1/alerta")
public class AlertaController {

    private final OpenMeteoService openMeteoService;

    public AlertaController(OpenMeteoService openMeteoService) {
        this.openMeteoService = openMeteoService;
    }

    @GetMapping("/clima")
    public AlertaClimaticaResponse clima(
            @RequestParam
            @DecimalMin(value = "-90.0")
            @DecimalMax(value = "90.0")
            double latitude,
            @RequestParam
            @DecimalMin(value = "-180.0")
            @DecimalMax(value = "180.0")
            double longitude
    ) {
        return openMeteoService.consultarAlerta(latitude, longitude);
    }
}
