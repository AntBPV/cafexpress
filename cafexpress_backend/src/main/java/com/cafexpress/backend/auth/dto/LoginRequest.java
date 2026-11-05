package com.cafexpress.backend.auth.dto;

import jakarta.validation.constraints.*;

import java.util.Locale;

public record LoginRequest(

        @NotBlank(message = "El correo es obligatorio.")
        @Email(message = "Ingresa un correo valido.")
        @Size(max = 254)
        String email,

        @NotBlank(message = "La contrasena es obligatoria.")
        @Size(max = 72)
        String password

) {

    public LoginRequest {
        email = email == null
                ? null
                : email.strip().toLowerCase(Locale.ROOT);
    }
}