package com.cafexpress.backend.producto.service;

import com.cafexpress.backend.producto.dto.ProductoResponse;
import com.cafexpress.backend.producto.entity.Producto;
import com.cafexpress.backend.producto.repository.*;
import com.cafexpress.backend.usuario.enums.Rol;
import com.cafexpress.backend.usuario.service.PerfilService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.UUID;

@Service
public class DetalleProductoService {
    private final ProductoRepository productos;
    private final ProductoConsultadoRepository consultas;
    private final PerfilService perfiles;
    public DetalleProductoService(ProductoRepository productos,
            ProductoConsultadoRepository consultas, PerfilService perfiles) {
        this.productos = productos; this.consultas = consultas; this.perfiles = perfiles;
    }
    private Producto obtener(UUID id) {
        return productos.findById(id).filter(p -> p.getVendedor().isActivo())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "No encontramos este producto."));
    }
    @Transactional(readOnly = true)
    public ProductoResponse detalle(UUID id) { return ProductoResponse.desde(obtener(id)); }

    @Transactional
    public void registrarConsulta(UUID id, UUID usuarioId) {
        if (perfiles.obtener(usuarioId).getRol() != Rol.COMPRADOR) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Solo el comprador registra consultas.");
        }
        obtener(id);
        consultas.registrar(UUID.randomUUID(), usuarioId, id);
    }
}
