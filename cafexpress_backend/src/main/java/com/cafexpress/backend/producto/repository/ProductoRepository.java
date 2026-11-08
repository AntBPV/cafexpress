package com.cafexpress.backend.producto.repository;

import com.cafexpress.backend.producto.entity.Producto;
import org.springframework.data.domain.Page;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface ProductoRepository extends JpaRepository<Producto, UUID> {

    Page<Producto> findAllByDisponibleTrue(Pageable pageable);

    Page<Producto> findAllByVendedorId(UUID vendedorId, Pageable pageable);

    long countByVendedorIdAndDisponibleTrue(UUID vendedorId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from Producto p where p.id = :id")
    Optional<Producto> findByIdForUpdate(@Param("id") UUID id);

    Optional<Producto> findByIdAndVendedorId(UUID id, UUID vendedorId);
}
