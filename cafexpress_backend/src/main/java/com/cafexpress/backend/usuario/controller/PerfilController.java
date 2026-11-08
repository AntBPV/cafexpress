package com.cafexpress.backend.usuario.controller;

import com.cafexpress.backend.usuario.dto.*;
import com.cafexpress.backend.usuario.service.PerfilService;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class PerfilController {
    private final PerfilService perfiles;
    public PerfilController(PerfilService perfiles) { this.perfiles = perfiles; }

    @GetMapping("/perfil")
    public UsuarioResponse actual(@AuthenticationPrincipal Jwt jwt) {
        return perfiles.actual(UUID.fromString(jwt.getSubject()));
    }

    @PutMapping("/vendedor/perfil")
    public UsuarioResponse actualizar(@AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody PerfilVendedorRequest request) {
        return perfiles.actualizarVendedor(UUID.fromString(jwt.getSubject()), request);
    }
}
