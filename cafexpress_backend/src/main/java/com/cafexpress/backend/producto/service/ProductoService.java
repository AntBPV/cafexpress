package com.cafexpress.backend.producto.service;

import com.cafexpress.backend.producto.dto.ProductoRequest;
import com.cafexpress.backend.producto.dto.PaginaResponse;
import com.cafexpress.backend.producto.dto.ProductoResponse;
import com.cafexpress.backend.producto.dto.ProductoUpdateRequest;
import com.cafexpress.backend.producto.entity.Producto;
import com.cafexpress.backend.producto.enums.TipoProducto;
import com.cafexpress.backend.producto.repository.ProductoRepository;
import com.cafexpress.backend.usuario.entity.Usuario;
import com.cafexpress.backend.usuario.enums.Rol;
import com.cafexpress.backend.usuario.repository.UsuarioRepository;
import org.springframework.http.HttpStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;
import java.math.BigDecimal;

@Service
public class ProductoService {

    private final ProductoRepository productos;
    private final UsuarioRepository usuarios;
    private final com.cafexpress.backend.orden.repository.OrdenRepository ordenes;

    public ProductoService(
            ProductoRepository productos,
            UsuarioRepository usuarios,
            com.cafexpress.backend.orden.repository.OrdenRepository ordenes
    ) {
        this.productos = productos;
        this.usuarios = usuarios;
        this.ordenes = ordenes;
    }

    @Transactional
    public ProductoResponse crear(ProductoRequest request, UUID vendedorId) {
        Usuario vendedor = obtenerVendedor(vendedorId);

        if (vendedor.getEmpresaProductor() == null || vendedor.getEmpresaProductor().isBlank()
                || vendedor.getPaisOrigen() == null || vendedor.getPaisOrigen().isBlank()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Completa tu empresa o productor y el país de origen antes de publicar.");
        }

        Producto producto = productos.save(new Producto(
                request.nombre().trim(),
                request.tipo(),
                request.variedad() == null ? null : request.variedad().strip(),
                request.cantidadUnitaria(),
                request.unidadCantidad(),
                request.cantidadDisponible(),
                request.lugarOrigen().trim(),
                request.precioUnitario(),
                request.disponible(),
                vendedor
        ));

        return ProductoResponse.desde(producto);
    }

    @Transactional(readOnly = true)
    public PaginaResponse<ProductoResponse> listarDisponibles(
            TipoProducto tipo,
            String lugarOrigen,
            String paisOrigen,
            BigDecimal precioMin,
            BigDecimal precioMax,
            Pageable pageable
    ) {
        validarRangoPrecio(precioMin, precioMax);
        Page<ProductoResponse> pagina = productos
                .buscarDisponibles(tipo, normalizarLugarOrigen(lugarOrigen), normalizarLugarOrigen(paisOrigen), precioMin, precioMax, pageable)
                .map(ProductoResponse::desde);

        return PaginaResponse.desde(pagina);
    }

    @Transactional(readOnly = true)
    public PaginaResponse<ProductoResponse> listarDelVendedor(
            UUID vendedorId,
            TipoProducto tipo,
            String lugarOrigen,
            String paisOrigen,
            BigDecimal precioMin,
            BigDecimal precioMax,
            Pageable pageable
    ) {
        obtenerVendedor(vendedorId);
        validarRangoPrecio(precioMin, precioMax);

        Page<ProductoResponse> pagina = productos
                .buscarDelVendedor(
                        vendedorId,
                        tipo,
                        normalizarLugarOrigen(lugarOrigen),
                        normalizarLugarOrigen(paisOrigen),
                        precioMin,
                        precioMax,
                        pageable
                )
                .map(ProductoResponse::desde);

        return PaginaResponse.desde(pagina);
    }

    @Transactional
    public ProductoResponse actualizar(
            UUID productoId,
            ProductoUpdateRequest request,
            UUID vendedorId
    ) {
        if (request.estaVacio()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Debes enviar al menos un campo para actualizar."
            );
        }
        if (request.nombre() != null && request.nombre().isBlank()
                || request.lugarOrigen() != null && request.lugarOrigen().isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El nombre y el lugar de origen no pueden estar vacios."
            );
        }

        Producto producto = obtenerProductoDelVendedor(productoId, vendedorId);
        producto.actualizarParcial(
                request.nombre() == null ? null : request.nombre().trim(),
                request.tipo(),
                request.variedad() == null ? null : request.variedad().strip(),
                request.cantidadUnitaria(),
                request.unidadCantidad(),
                request.cantidadDisponible(),
                request.lugarOrigen() == null ? null : request.lugarOrigen().trim(),
                request.precioUnitario(),
                request.disponible()
        );

        return ProductoResponse.desde(producto);
    }

    private void validarRangoPrecio(BigDecimal precioMin, BigDecimal precioMax) {
        if (precioMin != null && precioMin.signum() < 0
                || precioMax != null && precioMax.signum() < 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Los precios del filtro no pueden ser negativos."
            );
        }
        if (precioMin != null && precioMax != null && precioMin.compareTo(precioMax) > 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "El precio minimo no puede ser mayor que el precio maximo."
            );
        }
    }

    private String normalizarLugarOrigen(String lugarOrigen) {
        return lugarOrigen == null || lugarOrigen.isBlank() ? null : lugarOrigen.trim().toLowerCase(java.util.Locale.ROOT);
    }

    @Transactional
    public void eliminar(UUID productoId, UUID vendedorId) {
        Producto producto = obtenerProductoDelVendedor(productoId, vendedorId);
        if (ordenes.existsByProductoId(productoId)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "El producto tiene órdenes. Puedes desactivarlo para conservar el historial.");
        }
        productos.delete(producto);
    }

    private Usuario obtenerVendedor(UUID vendedorId) {
        Usuario usuario = usuarios.findById(vendedorId)
                .filter(Usuario::isActivo)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "El vendedor no existe."
                ));

        if (usuario.getRol() != Rol.VENDEDOR) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Solo los vendedores pueden gestionar productos."
            );
        }

        return usuario;
    }

    private Producto obtenerProductoDelVendedor(UUID productoId, UUID vendedorId) {
        return productos.findByIdAndVendedorId(productoId, vendedorId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "El producto no existe o no pertenece al vendedor."
                ));
    }
}
