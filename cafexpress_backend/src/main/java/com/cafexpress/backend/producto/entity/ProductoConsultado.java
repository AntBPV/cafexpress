package com.cafexpress.backend.producto.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "productos_consultados")
public class ProductoConsultado {
    @Id private UUID id;
    @Column(name = "usuario_id", nullable = false) private UUID usuarioId;
    @Column(name = "producto_id", nullable = false) private UUID productoId;
    @Column(name = "consultado_en", nullable = false) private Instant consultadoEn;
    protected ProductoConsultado() {}
}
