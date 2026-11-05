package com.cafexpress.backend.auth.service;

import com.cafexpress.backend.auth.dto.AuthResponse;
import com.cafexpress.backend.usuario.dto.UsuarioResponse;
import com.cafexpress.backend.usuario.entity.Usuario;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

@Service
public class JwtService {

    private final JwtEncoder encoder;
    private final String issuer;
    private final String audience;
    private final long duracion;

    public JwtService(
            JwtEncoder encoder,
            @Value("${app.jwt.issuer}") String issuer,
            @Value("${app.jwt.audience}") String audience,
            @Value("${app.jwt.duration-seconds}") long duracion
    ) {
        if (duracion <= 0 || duracion > 86400) {
            throw new IllegalArgumentException(
                    "La duracion JWT debe estar entre 1 y 86400 segundos."
            );
        }

        this.encoder = encoder;
        this.issuer = issuer;
        this.audience = audience;
        this.duracion = duracion;
    }

    public AuthResponse crearRespuesta(Usuario usuario) {
        Instant ahora = Instant.now();

        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(issuer)
                .subject(usuario.getId().toString())
                .audience(List.of(audience))
                .issuedAt(ahora)
                .expiresAt(ahora.plusSeconds(duracion))
                .claim("rol", usuario.getRol().name())
                .build();

        JwsHeader header = JwsHeader
                .with(MacAlgorithm.HS256)
                .build();

        String token = encoder
                .encode(JwtEncoderParameters.from(header, claims))
                .getTokenValue();

        return new AuthResponse(
                token,
                "Bearer",
                duracion,
                UsuarioResponse.desde(usuario)
        );
    }
}