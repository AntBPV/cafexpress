package com.cafexpress.backend.producto.controller;

import com.cafexpress.backend.producto.dto.ProductoResponse;
import com.cafexpress.backend.producto.service.ProductoService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/productos")
public class ProductoController {

    private final ProductoService productoService;

    public ProductoController(ProductoService productoService) {
        this.productoService = productoService;
    }

    @GetMapping
    public List<ProductoResponse> listarDisponibles() {
        return productoService.listarDisponibles();
    }
}
