package com.cafexpress.backend.producto.dto;

import com.cafexpress.backend.producto.enums.UnidadCantidad;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;

public record ProductoUpdateRequest(
        @Size(max = 150)
        String nombre,

        @Positive
        @Digits(integer = 7, fraction = 3)
        BigDecimal cantidadUnitaria,

        UnidadCantidad unidadCantidad,

        @PositiveOrZero
        @Digits(integer = 9, fraction = 3)
        BigDecimal cantidadDisponible,

        @Size(max = 100)
        String lugarOrigen,

        @Positive
        @Digits(integer = 12, fraction = 2)
        BigDecimal precioUnitario,

        Boolean disponible
) {

    public boolean estaVacio() {
        return nombre == null
                && cantidadUnitaria == null
                && unidadCantidad == null
                && cantidadDisponible == null
                && lugarOrigen == null
                && precioUnitario == null
                && disponible == null;
    }
}
