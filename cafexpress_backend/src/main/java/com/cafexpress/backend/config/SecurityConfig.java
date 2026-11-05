package com.cafexpress.backend.config;

import com.cafexpress.backend.common.exception.ApiError;
import com.cafexpress.backend.usuario.entity.Usuario;
import com.cafexpress.backend.usuario.repository.UsuarioRepository;
import jakarta.servlet.DispatcherType;
import jakarta.servlet.http.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.*;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.security.web.*;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.web.cors.*;
import tools.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.time.Instant;
import java.util.*;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }

    @Bean
    SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            JwtDecoder decoder,
            UsuarioRepository usuarios,
            ObjectMapper mapper
    ) throws Exception {

        AuthenticationEntryPoint noAutenticado = (req, res, ex) -> {
            res.setHeader("WWW-Authenticate", "Bearer");

            responder(
                    req,
                    res,
                    mapper,
                    401,
                    "Inicia sesion con un token valido."
            );
        };

        AccessDeniedHandler sinPermiso = (req, res, ex) ->
                responder(
                        req,
                        res,
                        mapper,
                        403,
                        "Tu rol no tiene permiso para esta operacion."
                );

        http
                .csrf(csrf -> csrf.disable())
                .cors(cors -> {})
                .formLogin(form -> form.disable())
                .httpBasic(basic -> basic.disable())
                .logout(logout -> logout.disable())

                .sessionManagement(session ->
                        session.sessionCreationPolicy(
                                SessionCreationPolicy.STATELESS
                        )
                )

                .exceptionHandling(errors -> errors
                        .authenticationEntryPoint(noAutenticado)
                        .accessDeniedHandler(sinPermiso)
                )

                .authorizeHttpRequests(auth -> auth
                        .dispatcherTypeMatchers(DispatcherType.ERROR)
                        .permitAll()

                        .requestMatchers(
                                HttpMethod.GET,
                                "/actuator/health",
                                "/actuator/health/**"
                        )
                        .permitAll()

                        .requestMatchers(
                                HttpMethod.POST,
                                "/api/v1/auth/register",
                                "/api/v1/auth/login"
                        )
                        .permitAll()

                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/v1/auth/me"
                        )
                        .authenticated()

                        .requestMatchers("/api/v1/alerta/**")
                        .authenticated()

                        .requestMatchers("/api/v1/productos")
                        .authenticated()

                        .requestMatchers("/api/v1/vendedor/**")
                        .hasRole("VENDEDOR")

                        .requestMatchers("/api/v1/comprador/**")
                        .hasRole("COMPRADOR")

                        .anyRequest()
                        .denyAll()
                )

                .oauth2ResourceServer(oauth -> oauth
                        .authenticationEntryPoint(noAutenticado)
                        .accessDeniedHandler(sinPermiso)

                        .jwt(jwt -> jwt
                                .decoder(decoder)
                                .jwtAuthenticationConverter(token -> {
                                    UUID id;

                                    try {
                                        id = UUID.fromString(token.getSubject());
                                    } catch (IllegalArgumentException | NullPointerException ex) {
                                        throw new OAuth2AuthenticationException(
                                                "invalid_token"
                                        );
                                    }

                                    Usuario usuario = usuarios.findById(id)
                                            .filter(Usuario::isActivo)
                                            .orElseThrow(() ->
                                                    new OAuth2AuthenticationException(
                                                            "invalid_token"
                                                    )
                                            );

                                    return new JwtAuthenticationToken(
                                            token,
                                            List.of(
                                                    new SimpleGrantedAuthority(
                                                            "ROLE_" + usuario.getRol().name()
                                                    )
                                            )
                                    );
                                })
                        )
                );

        return http.build();
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource(
            @Value("${app.cors.allowed-origins}") List<String> origins
    ) {
        CorsConfiguration config = new CorsConfiguration();

        config.setAllowedOrigins(origins);

        config.setAllowedMethods(
                List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
        );

        config.setAllowedHeaders(
                List.of("Authorization", "Content-Type")
        );

        config.setAllowCredentials(false);

        UrlBasedCorsConfigurationSource source =
                new UrlBasedCorsConfigurationSource();

        source.registerCorsConfiguration("/api/**", config);

        return source;
    }

    private static void responder(
            HttpServletRequest request,
            HttpServletResponse response,
            ObjectMapper mapper,
            int status,
            String mensaje
    ) throws IOException {

        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        mapper.writeValue(
                response.getOutputStream(),
                new ApiError(
                        Instant.now(),
                        status,
                        mensaje,
                        request.getRequestURI(),
                        Map.of()
                )
        );
    }
}