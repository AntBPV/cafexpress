package com.cafexpress.backend.producto.repository;

import com.cafexpress.backend.producto.entity.Producto;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProductoRepository extends JpaRepository<Producto, UUID> {

    List<Producto> findAllByDisponibleTrueOrderByCreadoEnDesc();

    List<Producto> findAllByVendedorIdOrderByCreadoEnDesc(UUID vendedorId);

    Optional<Producto> findByIdAndVendedorId(UUID id, UUID vendedorId);
}
