package com.cafexpress.backend.auth.dto;

import com.cafexpress.backend.usuario.dto.UsuarioResponse;

public record AuthResponse(
        String accessToken,
        String tokenType,
        long expiresIn,
        UsuarioResponse usuario
) {
}