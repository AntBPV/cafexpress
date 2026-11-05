package com.cafexpress.backend.alerta.dto;

public record AlertaClimaticaResponse(
        String mensaje,
        boolean condicionesOptimas,
        double temperaturaActual,
        double temperaturaPromedioPronosticada,
        double lluviaPromedioPronosticada,
        int diasEvaluados
) {
}
