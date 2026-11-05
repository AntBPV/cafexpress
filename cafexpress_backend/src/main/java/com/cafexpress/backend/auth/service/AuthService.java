package com.cafexpress.backend.auth.service;

import com.cafexpress.backend.auth.dto.*;
import com.cafexpress.backend.usuario.dto.UsuarioResponse;
import com.cafexpress.backend.usuario.entity.Usuario;
import com.cafexpress.backend.usuario.repository.UsuarioRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.util.UUID;

@Service
public class AuthService {

    private final UsuarioRepository usuarios;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final String hashSimulado;

    public AuthService(
            UsuarioRepository usuarios,
            PasswordEncoder passwordEncoder,
            JwtService jwtService
    ) {
        this.usuarios = usuarios;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;

        // Permite comprobar una contrasena incluso si el correo no existe.
        this.hashSimulado = passwordEncoder.encode(
                UUID.randomUUID().toString()
        );
    }

    @Transactional
    public AuthResponse registrar(RegistroRequest request) {
        if (request.password().getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "La contrasena supera los 72 bytes permitidos; algunos caracteres ocupan mas de uno."
            );
        }

        if (usuarios.existsByEmail(request.email())) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "El correo ya esta registrado."
            );
        }

        Usuario usuario = new Usuario(
                request.nombre(),
                request.email(),
                passwordEncoder.encode(request.password()),
                request.rol()
        );

        try {
            usuarios.saveAndFlush(usuario);
        } catch (DataIntegrityViolationException ex) {
            // Tambien protege si dos solicitudes registran el mismo correo a la vez.
            if (ex.getMostSpecificCause() instanceof SQLException sql
                    && "23505".equals(sql.getSQLState())) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "El correo ya esta registrado."
                );
            }

            throw ex;
        }

        return jwtService.crearRespuesta(usuario);
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        if (request.password().getBytes(StandardCharsets.UTF_8).length > 72) {
            throw credencialesInvalidas();
        }

        Usuario usuario = usuarios
                .findByEmail(request.email())
                .orElse(null);

        String hash = usuario == null
                ? hashSimulado
                : usuario.getPasswordHash();

        boolean coincide = passwordEncoder.matches(
                request.password(),
                hash
        );

        if (usuario == null || !coincide || !usuario.isActivo()) {
            throw credencialesInvalidas();
        }

        return jwtService.crearRespuesta(usuario);
    }

    @Transactional(readOnly = true)
    public UsuarioResponse actual(String id) {
        return usuarios.findById(UUID.fromString(id))
                .filter(Usuario::isActivo)
                .map(UsuarioResponse::desde)
                .orElseThrow(this::credencialesInvalidas);
    }

    private ResponseStatusException credencialesInvalidas() {
        return new ResponseStatusException(
                HttpStatus.UNAUTHORIZED,
                "Correo o contrasena incorrectos."
        );
    }
}