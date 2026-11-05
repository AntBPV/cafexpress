package com.cafexpress.backend.producto.controller;

import com.cafexpress.backend.producto.dto.ProductoRequest;
import com.cafexpress.backend.producto.dto.ProductoResponse;
import com.cafexpress.backend.producto.dto.ProductoUpdateRequest;
import com.cafexpress.backend.producto.dto.MensajeResponse;
import com.cafexpress.backend.producto.dto.PaginaResponse;
import com.cafexpress.backend.producto.service.ProductoService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/vendedor/productos")
@PreAuthorize("hasRole('VENDEDOR')")
public class VendedorProductoController {

    private final ProductoService productoService;

    public VendedorProductoController(ProductoService productoService) {
        this.productoService = productoService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ProductoResponse crear(
            @Valid @RequestBody ProductoRequest request,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return productoService.crear(request, idDesde(jwt));
    }

    @GetMapping
    public PaginaResponse<ProductoResponse> listarPropios(
            @AuthenticationPrincipal Jwt jwt,
            @PageableDefault(
                    size = 20,
                    sort = "creadoEn",
                    direction = Sort.Direction.DESC
            )
            Pageable pageable
    ) {
        return productoService.listarDelVendedor(idDesde(jwt), pageable);
    }

    @PutMapping("/{productoId}")
    public ProductoResponse actualizar(
            @PathVariable UUID productoId,
            @Valid @RequestBody ProductoUpdateRequest request,
            @AuthenticationPrincipal Jwt jwt
    ) {
        return productoService.actualizar(
                productoId,
                request,
                idDesde(jwt)
        );
    }

    @DeleteMapping("/{productoId}")
    public MensajeResponse eliminar(
            @PathVariable UUID productoId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        productoService.eliminar(productoId, idDesde(jwt));
        return new MensajeResponse("Producto eliminado correctamente.");
    }

    private UUID idDesde(Jwt jwt) {
        return UUID.fromString(jwt.getSubject());
    }
}
