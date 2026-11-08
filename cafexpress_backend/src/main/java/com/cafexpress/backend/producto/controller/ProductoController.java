package com.cafexpress.backend.producto.controller;

import com.cafexpress.backend.producto.dto.ProductoResponse;
import com.cafexpress.backend.producto.dto.PaginaResponse;
import com.cafexpress.backend.producto.service.ProductoService;
import com.cafexpress.backend.producto.enums.TipoProducto;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;

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
            Pageable pageable,
            @RequestParam(name = "tipo", required = false) TipoProducto tipo,
            @RequestParam(name = "lugarOrigen", required = false) String lugarOrigen,
            @RequestParam(name = "paisOrigen", required = false) String paisOrigen,
            @RequestParam(name = "precioMin", required = false) BigDecimal precioMin,
            @RequestParam(name = "precioMax", required = false) BigDecimal precioMax
    ) {
        return productoService.listarDisponibles(
                tipo, lugarOrigen, paisOrigen, precioMin, precioMax, pageable
        );
    }
}
