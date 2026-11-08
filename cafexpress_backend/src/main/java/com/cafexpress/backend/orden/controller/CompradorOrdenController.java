package com.cafexpress.backend.orden.controller;

import com.cafexpress.backend.orden.dto.CrearOrdenRequest;
import com.cafexpress.backend.orden.dto.OrdenResponse;
import com.cafexpress.backend.orden.service.OrdenService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/comprador/ordenes")
@PreAuthorize("hasRole('COMPRADOR')")
public class CompradorOrdenController {

    private final OrdenService ordenService;

    public CompradorOrdenController(OrdenService ordenService) {
        this.ordenService = ordenService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public OrdenResponse solicitar(
            @Valid @RequestBody CrearOrdenRequest request,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ordenService.solicitar(request, idDesde(jwt));
    }

    @GetMapping
    public Page<OrdenResponse> listar(
            @AuthenticationPrincipal Jwt jwt,
            @PageableDefault(
                    size = 20,
                    sort = "creadoEn",
                    direction = Sort.Direction.DESC
            )
            Pageable pageable
    ) {
        return ordenService.listarDelComprador(idDesde(jwt), pageable);
    }

    @GetMapping("/historial")
    public Page<OrdenResponse> historial(
            @AuthenticationPrincipal Jwt jwt,
            @PageableDefault(
                    size = 20,
                    sort = "creadoEn",
                    direction = Sort.Direction.DESC
            )
            Pageable pageable
    ) {
        return ordenService.historialDelComprador(idDesde(jwt), pageable);
    }

    private UUID idDesde(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
