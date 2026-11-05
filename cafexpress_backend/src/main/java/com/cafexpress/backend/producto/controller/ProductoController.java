package com.cafexpress.backend.producto.controller;

import com.cafexpress.backend.producto.dto.ProductoResponse;
import com.cafexpress.backend.producto.dto.PaginaResponse;
import com.cafexpress.backend.producto.service.ProductoService;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/productos")
public class ProductoController {

    private final ProductoService productoService;

    public ProductoController(ProductoService productoService) {
        this.productoService = productoService;
    }

    @GetMapping
    public PaginaResponse<ProductoResponse> listarDisponibles(
            @PageableDefault(
                    size = 20,
                    sort = "creadoEn",
                    direction = Sort.Direction.DESC
            )
            Pageable pageable
    ) {
        return productoService.listarDisponibles(pageable);
    }
}
