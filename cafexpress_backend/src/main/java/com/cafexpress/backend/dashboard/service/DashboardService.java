package com.cafexpress.backend.dashboard.service;

import com.cafexpress.backend.dashboard.dto.DashboardResponse;
import com.cafexpress.backend.orden.dto.OrdenResponse;
import com.cafexpress.backend.orden.enums.EstadoOrden;
import com.cafexpress.backend.orden.repository.OrdenRepository;
import com.cafexpress.backend.producto.dto.ProductoResponse;
import com.cafexpress.backend.producto.repository.*;
import com.cafexpress.backend.usuario.dto.UsuarioResponse;
import com.cafexpress.backend.usuario.enums.Rol;
import com.cafexpress.backend.usuario.service.PerfilService;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.util.*;

@Service
public class DashboardService {
    private final OrdenRepository ordenes;
    private final ProductoRepository productos;
    private final ProductoConsultadoRepository consultas;
    private final PerfilService perfiles;
    public DashboardService(OrdenRepository ordenes, ProductoRepository productos,
            ProductoConsultadoRepository consultas, PerfilService perfiles) {
        this.ordenes = ordenes; this.productos = productos; this.consultas = consultas; this.perfiles = perfiles;
    }

    @Transactional(readOnly = true)
    public DashboardResponse resumen(UUID id) {
        var usuario = perfiles.obtener(id);
        boolean vendedor = usuario.getRol() == Rol.VENDEDOR;
        Map<String, Long> estados = new LinkedHashMap<>();
        for (var estado : EstadoOrden.values()) estados.put(estado.name(), 0L);
        for (Object[] row : vendedor ? ordenes.resumenVendedor(id) : ordenes.resumenComprador(id)) {
            estados.put(row[0].toString(), ((Number) row[1]).longValue());
        }
        long activas = estados.get("SOLICITADA") + estados.get("ACEPTADA");
        var pagina = PageRequest.of(0, 5, Sort.by(Sort.Direction.DESC, "creadoEn"));
        var recientes = vendedor ? ordenes.findAllByVendedorId(id, pagina)
                : ordenes.findAllByCompradorId(id, pagina);
        return new DashboardResponse(UsuarioResponse.desde(usuario),
                vendedor ? productos.countByVendedorIdAndDisponibleTrue(id) : 0,
                activas, estados, recientes.map(OrdenResponse::desde).getContent(), Instant.now());
    }

    @Transactional(readOnly = true)
    public List<ProductoResponse> relevantes(UUID id) {
        if (perfiles.obtener(id).getRol() == Rol.VENDEDOR) {
            return productos.findAllByVendedorId(id, PageRequest.of(0, 100, Sort.by(Sort.Direction.DESC, "creadoEn")))
                    .stream().filter(p -> p.isDisponible()).map(ProductoResponse::desde).toList();
        }
        Set<UUID> ids = new LinkedHashSet<>(consultas.recientes(id));
        ids.addAll(ordenes.productosDelComprador(id));
        Map<UUID, ProductoResponse> porId = new HashMap<>();
        productos.findAllById(ids).stream().filter(p -> p.getVendedor().isActivo())
                .forEach(p -> porId.put(p.getId(), ProductoResponse.desde(p)));
        return ids.stream().map(porId::get).filter(Objects::nonNull).toList();
    }
}
