package com.cafexpress.backend.producto.enums;

import com.fasterxml.jackson.annotation.JsonCreator;

public enum UnidadCantidad {

    GRAMOS,
    KILOGRAMOS;

    @JsonCreator
    public static UnidadCantidad desde(String valor) {
        return valor == null ? null : UnidadCantidad.valueOf(valor);
    }
}
