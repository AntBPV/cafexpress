package com.cafexpress.backend.dashboard.controller;

import com.cafexpress.backend.dashboard.dto.*;
import com.cafexpress.backend.dashboard.service.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/dashboard")
public class DashboardController {
    private final DashboardService dashboard;
    private final DashboardAlertasService alertas;
    public DashboardController(DashboardService dashboard, DashboardAlertasService alertas) {
        this.dashboard = dashboard; this.alertas = alertas;
    }
    @GetMapping
    public DashboardResponse resumen(@AuthenticationPrincipal Jwt jwt) {
        return dashboard.resumen(UUID.fromString(jwt.getSubject()));
    }
    @GetMapping("/alertas")
    public DashboardAlertasResponse alertas(@AuthenticationPrincipal Jwt jwt) {
        return alertas.recientes(UUID.fromString(jwt.getSubject()));
    }
    @GetMapping("/productos-relevantes")
    public java.util.Map<String, ?> productosRelevantes(@AuthenticationPrincipal Jwt jwt) {
        return java.util.Map.of("productos", dashboard.relevantes(UUID.fromString(jwt.getSubject())));
    }
}
