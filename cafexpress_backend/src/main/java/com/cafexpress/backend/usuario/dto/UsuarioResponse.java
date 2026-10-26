package com.cafexpress.backend.usuario.dto;

import com.cafexpress.backend.usuario.entity.Usuario;
import com.cafexpress.backend.usuario.enums.Rol;

import java.util.UUID;

public record UsuarioResponse(
        UUID id,
        String nombre,
        String email,
        Rol rol
) {

    public static UsuarioResponse desde(Usuario usuario) {
        return new UsuarioResponse(
                usuario.getId(),
                usuario.getNombre(),
                usuario.getEmail(),
                usuario.getRol()
        );
    }
}