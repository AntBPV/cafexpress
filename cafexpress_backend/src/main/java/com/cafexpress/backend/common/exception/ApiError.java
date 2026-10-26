package com.cafexpress.backend.common.exception;

import java.time.Instant;
import java.util.Map;

public record ApiError(
        Instant timestamp,
        int status,
        String mensaje,
        String path,
        Map<String, String> errores
) {
}