package com.cafexpress.backend.producto.dto;

import com.cafexpress.backend.producto.enums.UnidadCantidad;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;

public record ProductoRequest(
        @NotBlank
        @Size(max = 150)
        String nombre,

        @NotNull
        @Positive
        @Digits(integer = 7, fraction = 3)
        BigDecimal cantidadUnitaria,

        @NotNull
        UnidadCantidad unidadCantidad,

        @NotNull
        @PositiveOrZero
        @Digits(integer = 9, fraction = 3)
        BigDecimal cantidadDisponible,

        @NotBlank
        @Size(max = 100)
        String lugarOrigen,

        @NotNull
        @Positive
        @Digits(integer = 12, fraction = 2)
        BigDecimal precioUnitario,

        @NotNull
        Boolean disponible
) {
}
