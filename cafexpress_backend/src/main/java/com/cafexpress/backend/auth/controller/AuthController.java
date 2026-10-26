package com.cafexpress.backend.auth.controller;

import com.cafexpress.backend.auth.dto.*;
import com.cafexpress.backend.auth.service.AuthService;
import com.cafexpress.backend.usuario.dto.UsuarioResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthResponse registrar(
            @Valid @RequestBody RegistroRequest request
    ) {
        return authService.registrar(request);
    }

    @PostMapping("/login")
    public AuthResponse login(
            @Valid @RequestBody LoginRequest request
    ) {
        return authService.login(request);
    }

    @GetMapping("/me")
    public UsuarioResponse actual(
            @AuthenticationPrincipal Jwt jwt
    ) {
        return authService.actual(jwt.getSubject());
    }
}