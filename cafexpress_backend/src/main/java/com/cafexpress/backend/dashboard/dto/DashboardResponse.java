package com.cafexpress.backend.dashboard.dto;

import com.cafexpress.backend.orden.dto.OrdenResponse;
import com.cafexpress.backend.usuario.dto.UsuarioResponse;
import java.time.Instant;
import java.util.*;

public record DashboardResponse(
        UsuarioResponse usuario,
        long productosActivos,
        long ordenesActivas,
        Map<String, Long> ordenesPorEstado,
        List<OrdenResponse> ordenesRecientes,
        Instant actualizadoEn
) {}
