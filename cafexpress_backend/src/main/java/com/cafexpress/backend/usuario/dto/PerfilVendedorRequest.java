package com.cafexpress.backend.usuario.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PerfilVendedorRequest(
        @NotBlank @Size(max = 100) String nombre,
        @NotBlank @Size(max = 120) String empresaProductor,
        @NotBlank @Size(max = 80) String paisOrigen
) {}
