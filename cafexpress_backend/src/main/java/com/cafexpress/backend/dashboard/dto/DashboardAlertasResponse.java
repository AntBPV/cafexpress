package com.cafexpress.backend.dashboard.dto;

import java.time.Instant;
import java.util.*;

public record DashboardAlertasResponse(
        List<Alerta> alertas, List<String> avisos, Instant actualizadoEn
) {
    public record Alerta(UUID productoId, String productoNombre, String origen,
            String mensaje, boolean condicionesOptimas, double temperaturaActual,
            Instant consultadoEn) {}
}
