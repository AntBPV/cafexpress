package com.cafexpress.backend.orden.service;

import com.cafexpress.backend.orden.dto.CrearOrdenRequest;
import com.cafexpress.backend.orden.dto.OrdenResponse;
import com.cafexpress.backend.orden.entity.Orden;
import com.cafexpress.backend.orden.enums.EstadoOrden;
import com.cafexpress.backend.orden.repository.OrdenRepository;
import com.cafexpress.backend.producto.entity.Producto;
import com.cafexpress.backend.producto.repository.ProductoRepository;
import com.cafexpress.backend.usuario.entity.Usuario;
import com.cafexpress.backend.usuario.enums.Rol;
import com.cafexpress.backend.usuario.repository.UsuarioRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;

@Service
public class OrdenService {

    private final OrdenRepository ordenes;
    private final ProductoRepository productos;
    private final UsuarioRepository usuarios;

    public OrdenService(
            OrdenRepository ordenes,
            ProductoRepository productos,
            UsuarioRepository usuarios
    ) {
        this.ordenes = ordenes;
        this.productos = productos;
        this.usuarios = usuarios;
    }

    @Transactional
    public OrdenResponse solicitar(CrearOrdenRequest request, UUID compradorId) {
        Usuario comprador = obtenerUsuario(compradorId, Rol.COMPRADOR);
        Producto producto = productos.findById(request.productoId())
                .orElseThrow(() -> productoNoEncontrado());

        if (!producto.isDisponible()
                || producto.getCantidadDisponible().compareTo(request.cantidad()) < 0) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "El producto no tiene suficiente cantidad disponible."
            );
        }

        Orden orden = ordenes.save(new Orden(
                producto,
                comprador,
                request.cantidad()
        ));

        return OrdenResponse.desde(orden);
    }

    @Transactional(readOnly = true)
    public Page<OrdenResponse> listarDelComprador(
            UUID compradorId,
            Pageable pageable
    ) {
        obtenerUsuario(compradorId, Rol.COMPRADOR);
        return ordenes.findAllByCompradorIdAndActivoTrue(compradorId, pageable)
                .map(OrdenResponse::desde);
    }

    @Transactional(readOnly = true)
    public Page<OrdenResponse> historialDelComprador(
            UUID compradorId,
            Pageable pageable
    ) {
        obtenerUsuario(compradorId, Rol.COMPRADOR);
        return ordenes.findAllByCompradorIdAndActivoFalse(compradorId, pageable)
                .map(OrdenResponse::desde);
    }

    @Transactional(readOnly = true)
    public Page<OrdenResponse> listarDelVendedor(
            UUID vendedorId,
            Pageable pageable
    ) {
        obtenerUsuario(vendedorId, Rol.VENDEDOR);
        return ordenes.findAllByVendedorIdAndActivoTrue(vendedorId, pageable)
                .map(OrdenResponse::desde);
    }

    @Transactional(readOnly = true)
    public Page<OrdenResponse> historialDelVendedor(
            UUID vendedorId,
            Pageable pageable
    ) {
        obtenerUsuario(vendedorId, Rol.VENDEDOR);
        return ordenes.findAllByVendedorIdAndActivoFalse(vendedorId, pageable)
                .map(OrdenResponse::desde);
    }

    @Transactional
    public OrdenResponse aceptar(UUID ordenId, UUID vendedorId) {
        Orden orden = obtenerOrdenParaAvanzar(ordenId, vendedorId, EstadoOrden.SOLICITADA);

        Producto producto = productos.findByIdForUpdate(orden.getProducto().getId())
                .orElseThrow(() -> productoNoEncontrado());

        if (!producto.isDisponible()
                || producto.getCantidadDisponible().compareTo(orden.getCantidad()) < 0) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "El producto ya no tiene suficiente cantidad disponible."
            );
        }

        producto.descontarCantidad(orden.getCantidad());
        orden.aceptar();
        return OrdenResponse.desde(orden);
    }

    @Transactional
    public OrdenResponse ponerEnPreparacion(UUID ordenId, UUID vendedorId) {
        return avanzar(ordenId, vendedorId, EstadoOrden.ACEPTADA, Orden::ponerEnPreparacion);
    }

    @Transactional
    public OrdenResponse enviar(UUID ordenId, UUID vendedorId) {
        return avanzar(ordenId, vendedorId, EstadoOrden.EN_PREPARACION, Orden::enviar);
    }

    @Transactional
    public OrdenResponse entregar(UUID ordenId, UUID vendedorId) {
        return avanzar(ordenId, vendedorId, EstadoOrden.ENVIADA, Orden::entregar);
    }

    @Transactional
    public OrdenResponse rechazar(UUID ordenId, UUID vendedorId) {
        Orden orden = obtenerOrdenParaAvanzar(ordenId, vendedorId, EstadoOrden.SOLICITADA);
        orden.rechazar();
        return OrdenResponse.desde(orden);
    }

    private OrdenResponse avanzar(
            UUID ordenId,
            UUID vendedorId,
            EstadoOrden estadoEsperado,
            java.util.function.Consumer<Orden> transicion
    ) {
        Orden orden = obtenerOrdenParaAvanzar(ordenId, vendedorId, estadoEsperado);
        transicion.accept(orden);
        return OrdenResponse.desde(orden);
    }

    private Usuario obtenerUsuario(UUID id, Rol rol) {
        Usuario usuario = usuarios.findById(id)
                .filter(Usuario::isActivo)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "El usuario no existe."
                ));

        if (usuario.getRol() != rol) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "El usuario no tiene el rol requerido."
            );
        }
        return usuario;
    }

    private Orden obtenerOrdenDelVendedor(UUID ordenId, UUID vendedorId) {
        return ordenes.findByIdAndVendedorId(ordenId, vendedorId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "La orden no existe o no pertenece al vendedor."
                ));
    }

    private Orden obtenerOrdenParaAvanzar(
            UUID ordenId,
            UUID vendedorId,
            EstadoOrden estadoEsperado
    ) {
        obtenerUsuario(vendedorId, Rol.VENDEDOR);
        Orden orden = obtenerOrdenDelVendedor(ordenId, vendedorId);
        if (orden.getEstado() != estadoEsperado) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "La orden debe estar en estado " + estadoEsperado + "."
            );
        }
        return orden;
    }

    private ResponseStatusException productoNoEncontrado() {
        return new ResponseStatusException(
                HttpStatus.NOT_FOUND,
                "El producto no existe."
        );
    }
}
