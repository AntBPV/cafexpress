package com.cafexpress.backend.common.exception;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.*;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> validacion(
            MethodArgumentNotValidException ex,
            HttpServletRequest request
    ) {
        Map<String, String> errores = new LinkedHashMap<>();

        ex.getBindingResult().getFieldErrors().forEach(error ->
                errores.putIfAbsent(
                        error.getField(),
                        error.getDefaultMessage()
                )
        );

        return ResponseEntity.badRequest().body(
                new ApiError(
                        Instant.now(),
                        400,
                        "Revisa los campos del formulario.",
                        request.getRequestURI(),
                        errores
                )
        );
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiError> jsonInvalido(
            HttpServletRequest request
    ) {
        return ResponseEntity.badRequest().body(
                new ApiError(
                        Instant.now(),
                        400,
                        "JSON invalido. El rol debe ser VENDEDOR o COMPRADOR.",
                        request.getRequestURI(),
                        Map.of()
                )
        );
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ApiError> negocio(
            ResponseStatusException ex,
            HttpServletRequest request
    ) {
        return ResponseEntity.status(ex.getStatusCode()).body(
                new ApiError(
                        Instant.now(),
                        ex.getStatusCode().value(),
                        ex.getReason(),
                        request.getRequestURI(),
                        Map.of()
                )
        );
    }
}