package com.cafexpress.backend.usuario.enums;

import com.fasterxml.jackson.annotation.JsonCreator;

public enum Rol {

    VENDEDOR,
    COMPRADOR;

    @JsonCreator
    public static Rol desde(String valor) {
        return valor == null ? null : Rol.valueOf(valor);
    }
}