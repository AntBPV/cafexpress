package com.cafexpress.backend.orden.controller;
import com.cafexpress.backend.orden.dto.OrdenResponse;
import com.cafexpress.backend.orden.service.OrdenService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
@RestController
@RequestMapping("/api/v1/ordenes")
public class DetalleOrdenController {
    private final OrdenService ordenes;
    public DetalleOrdenController(OrdenService ordenes) { this.ordenes = ordenes; }
    @GetMapping("/{id}")
    public OrdenResponse detalle(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        return ordenes.detalle(id, UUID.fromString(jwt.getSubject()));
    }
}
