package com.cafexpress.backend.auth.dto;

import com.cafexpress.backend.usuario.enums.Rol;
import jakarta.validation.constraints.*;

import java.util.Locale;

public record RegistroRequest(

        @NotBlank(message = "El nombre es obligatorio.")
        @Size(max = 100, message = "El nombre admite hasta 100 caracteres.")
        String nombre,

        @NotBlank(message = "El correo es obligatorio.")
        @Email(message = "Ingresa un correo valido.")
        @Size(max = 254, message = "El correo es demasiado largo.")
        String email,

        @NotBlank(message = "La contrasena es obligatoria.")
        @Size(min = 8, max = 72, message = "Usa entre 8 y 72 caracteres.")
        @Pattern(
                regexp = "(?s)(?=.*\\p{L})(?=.*\\p{N}).+",
                message = "La contrasena debe incluir letras y numeros."
        )
        String password,

        @NotNull(message = "Selecciona VENDEDOR o COMPRADOR.")
        Rol rol

) {

    public RegistroRequest {
        nombre = nombre == null ? null : nombre.strip();

        email = email == null
                ? null
                : email.strip().toLowerCase(Locale.ROOT);
    }
}