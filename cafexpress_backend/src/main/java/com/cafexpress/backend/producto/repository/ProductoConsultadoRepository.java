package com.cafexpress.backend.producto.repository;

import com.cafexpress.backend.producto.entity.ProductoConsultado;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.*;

public interface ProductoConsultadoRepository extends JpaRepository<ProductoConsultado, UUID> {
    @Modifying
    @Query(value = """
        INSERT INTO productos_consultados (id, usuario_id, producto_id, consultado_en)
        VALUES (:id, :usuario, :producto, CURRENT_TIMESTAMP)
        ON CONFLICT (usuario_id, producto_id)
        DO UPDATE SET consultado_en = CURRENT_TIMESTAMP
        """, nativeQuery = true)
    void registrar(@Param("id") UUID id, @Param("usuario") UUID usuario, @Param("producto") UUID producto);

    @Query(value = """
        SELECT producto_id FROM productos_consultados WHERE usuario_id = :usuario
        ORDER BY consultado_en DESC LIMIT 100
        """, nativeQuery = true)
    List<UUID> recientes(@Param("usuario") UUID usuario);
}
