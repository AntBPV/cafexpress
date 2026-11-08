package com.cafexpress.backend.producto.repository;

import com.cafexpress.backend.producto.entity.Producto;
import com.cafexpress.backend.producto.enums.TipoProducto;
import org.springframework.data.domain.Page;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;
import java.math.BigDecimal;

public interface ProductoRepository extends JpaRepository<Producto, UUID> {

    @Query("""
            select p from Producto p
            where p.disponible = true
              and (:tipo is null or p.tipo = :tipo)
              and (:lugarOrigen is null or lower(p.lugarOrigen) = lower(:lugarOrigen))
              and (:precioMin is null or p.precioUnitario >= :precioMin)
              and (:precioMax is null or p.precioUnitario <= :precioMax)
            """)
    Page<Producto> buscarDisponibles(
            @Param("tipo") TipoProducto tipo,
            @Param("lugarOrigen") String lugarOrigen,
            @Param("precioMin") BigDecimal precioMin,
            @Param("precioMax") BigDecimal precioMax,
            Pageable pageable
    );

    @Query("""
            select p from Producto p
            where p.vendedor.id = :vendedorId
              and (:tipo is null or p.tipo = :tipo)
              and (:lugarOrigen is null or lower(p.lugarOrigen) = lower(:lugarOrigen))
              and (:precioMin is null or p.precioUnitario >= :precioMin)
              and (:precioMax is null or p.precioUnitario <= :precioMax)
            """)
    Page<Producto> buscarDelVendedor(
            @Param("vendedorId") UUID vendedorId,
            @Param("tipo") TipoProducto tipo,
            @Param("lugarOrigen") String lugarOrigen,
            @Param("precioMin") BigDecimal precioMin,
            @Param("precioMax") BigDecimal precioMax,
            Pageable pageable
    );

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from Producto p where p.id = :id")
    Optional<Producto> findByIdForUpdate(@Param("id") UUID id);

    Optional<Producto> findByIdAndVendedorId(UUID id, UUID vendedorId);
}
