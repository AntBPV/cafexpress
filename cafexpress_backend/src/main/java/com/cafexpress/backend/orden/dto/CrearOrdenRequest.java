package com.cafexpress.backend.orden.dto;

import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.util.UUID;

public record CrearOrdenRequest(
        @NotNull
        UUID productoId,

        @NotNull
        @Positive
        @Digits(integer = 9, fraction = 3)
        BigDecimal cantidad
) {
}
