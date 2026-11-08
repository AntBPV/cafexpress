package com.cafexpress.backend.producto.controller;

import com.cafexpress.backend.producto.dto.*;
import com.cafexpress.backend.producto.service.DetalleProductoService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/productos")
public class DetalleProductoController {
    private final DetalleProductoService detalles;
    public DetalleProductoController(DetalleProductoService detalles) { this.detalles = detalles; }
    @GetMapping("/{id}")
    public ProductoResponse detalle(@PathVariable UUID id) { return detalles.detalle(id); }
    @PostMapping("/{id}/consulta")
    public MensajeResponse consulta(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        detalles.registrarConsulta(id, UUID.fromString(jwt.getSubject()));
        return new MensajeResponse("Consulta registrada.");
    }
}
