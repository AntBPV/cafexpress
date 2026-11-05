package com.cafexpress.backend.orden.dto;

import com.cafexpress.backend.orden.entity.Orden;
import com.cafexpress.backend.orden.enums.EstadoOrden;
import com.cafexpress.backend.usuario.dto.UsuarioResponse;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record OrdenResponse(
        UUID id,
        UUID productoId,
        String productoNombre,
        BigDecimal cantidad,
        EstadoOrden estado,
        UsuarioResponse comprador,
        UsuarioResponse vendedor,
        Instant creadoEn,
        Instant resueltoEn
) {

    public static OrdenResponse desde(Orden orden) {
        return new OrdenResponse(
                orden.getId(),
                orden.getProducto().getId(),
                orden.getProducto().getNombre(),
                orden.getCantidad(),
                orden.getEstado(),
                UsuarioResponse.desde(orden.getComprador()),
                UsuarioResponse.desde(orden.getVendedor()),
                orden.getCreadoEn(),
                orden.getResueltoEn()
        );
    }
}
