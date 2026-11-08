package com.cafexpress.backend.orden.repository;

import com.cafexpress.backend.orden.entity.Orden;
import com.cafexpress.backend.orden.enums.EstadoOrden;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

import java.util.Optional;
import java.util.UUID;

public interface OrdenRepository extends JpaRepository<Orden, UUID> {

    @Query("select o.estado, count(o) from Orden o where o.vendedor.id = :id group by o.estado")
    List<Object[]> resumenVendedor(@Param("id") UUID id);

    @Query("select o.estado, count(o) from Orden o where o.comprador.id = :id group by o.estado")
    List<Object[]> resumenComprador(@Param("id") UUID id);

    @Query("select distinct o.producto.id from Orden o where o.comprador.id = :id")
    List<UUID> productosDelComprador(@Param("id") UUID id);

    Page<Orden> findAllByCompradorId(UUID compradorId, Pageable pageable);

    Page<Orden> findAllByVendedorId(UUID vendedorId, Pageable pageable);

    Optional<Orden> findByIdAndVendedorId(UUID id, UUID vendedorId);

    boolean existsByProductoIdAndCompradorIdAndEstado(
            UUID productoId,
            UUID compradorId,
            EstadoOrden estado
    );
}
