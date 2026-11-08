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
        BigDecimal precioUnitario,
        BigDecimal precioTotal,
        EstadoOrden estado,
        boolean activo,
        UsuarioResponse comprador,
        UsuarioResponse vendedor,
        Instant creadoEn,
        Instant resueltoEn,
        Instant aceptadaEn,
        Instant enPreparacionEn,
        Instant enviadaEn,
        Instant entregadaEn,
        Instant rechazadaEn
) {

    public static OrdenResponse desde(Orden orden) {
        return new OrdenResponse(
                orden.getId(),
                orden.getProducto().getId(),
                orden.getProducto().getNombre(),
                orden.getCantidad(),
                orden.getPrecioUnitario(),
                orden.getPrecioTotal(),
                orden.getEstado(),
                orden.isActivo(),
                UsuarioResponse.desde(orden.getComprador()),
                UsuarioResponse.desde(orden.getVendedor()),
                orden.getCreadoEn(),
                orden.getResueltoEn(),
                orden.getAceptadaEn(),
                orden.getEnPreparacionEn(),
                orden.getEnviadaEn(),
                orden.getEntregadaEn(),
                orden.getRechazadaEn()
        );
    }
}
