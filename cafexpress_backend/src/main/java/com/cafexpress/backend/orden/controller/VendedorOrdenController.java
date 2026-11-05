package com.cafexpress.backend.orden.controller;

import com.cafexpress.backend.orden.dto.OrdenResponse;
import com.cafexpress.backend.orden.service.OrdenService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/vendedor/ordenes")
@PreAuthorize("hasRole('VENDEDOR')")
public class VendedorOrdenController {

    private final OrdenService ordenService;

    public VendedorOrdenController(OrdenService ordenService) {
        this.ordenService = ordenService;
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
        return ordenService.listarDelVendedor(idDesde(jwt), pageable);
    }

    @PatchMapping("/{ordenId}/aceptar")
    public OrdenResponse aceptar(
            @PathVariable UUID ordenId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ordenService.aceptar(ordenId, idDesde(jwt));
    }

    @PatchMapping("/{ordenId}/rechazar")
    public OrdenResponse rechazar(
            @PathVariable UUID ordenId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return ordenService.rechazar(ordenId, idDesde(jwt));
    }

    private UUID idDesde(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
