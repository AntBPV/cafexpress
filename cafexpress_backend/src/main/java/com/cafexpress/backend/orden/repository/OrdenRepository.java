package com.cafexpress.backend.orden.repository;

import com.cafexpress.backend.orden.entity.Orden;
import com.cafexpress.backend.orden.enums.EstadoOrden;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface OrdenRepository extends JpaRepository<Orden, UUID> {

    Page<Orden> findAllByCompradorId(UUID compradorId, Pageable pageable);

    Page<Orden> findAllByVendedorId(UUID vendedorId, Pageable pageable);

    Page<Orden> findAllByCompradorIdAndActivoTrue(UUID compradorId, Pageable pageable);

    Page<Orden> findAllByVendedorIdAndActivoTrue(UUID vendedorId, Pageable pageable);

    Page<Orden> findAllByCompradorIdAndActivoFalse(UUID compradorId, Pageable pageable);

    Page<Orden> findAllByVendedorIdAndActivoFalse(UUID vendedorId, Pageable pageable);

    Optional<Orden> findByIdAndVendedorId(UUID id, UUID vendedorId);

    boolean existsByProductoIdAndCompradorIdAndEstado(
            UUID productoId,
            UUID compradorId,
            EstadoOrden estado
    );
}
