package com.cafexpress.backend.producto.dto;

import com.cafexpress.backend.producto.entity.Producto;
import com.cafexpress.backend.producto.enums.UnidadCantidad;
import com.cafexpress.backend.producto.enums.TipoProducto;
import com.cafexpress.backend.usuario.dto.UsuarioResponse;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record ProductoResponse(
        UUID id,
        String nombre,
        TipoProducto tipo,
        String variedad,
        BigDecimal cantidadUnitaria,
        UnidadCantidad unidadCantidad,
        BigDecimal cantidadDisponible,
        String lugarOrigen,
        BigDecimal precioUnitario,
        boolean disponible,
        UsuarioResponse vendedor,
        Instant creadoEn
) {

    public static ProductoResponse desde(Producto producto) {
        return new ProductoResponse(
                producto.getId(),
                producto.getNombre(),
                producto.getTipo(),
                producto.getVariedad(),
                producto.getCantidadUnitaria(),
                producto.getUnidadCantidad(),
                producto.getCantidadDisponible(),
                producto.getLugarOrigen(),
                producto.getPrecioUnitario(),
                producto.isDisponible(),
                UsuarioResponse.desde(producto.getVendedor()),
                producto.getCreadoEn()
        );
    }
}
