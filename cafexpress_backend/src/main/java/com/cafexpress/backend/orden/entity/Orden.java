package com.cafexpress.backend.orden.entity;

import com.cafexpress.backend.orden.enums.EstadoOrden;
import com.cafexpress.backend.producto.entity.Producto;
import com.cafexpress.backend.usuario.entity.Usuario;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ordenes")
public class Orden {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "producto_id", nullable = false)
    private Producto producto;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "comprador_id", nullable = false)
    private Usuario comprador;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "vendedor_id", nullable = false)
    private Usuario vendedor;

    @Column(nullable = false, precision = 12, scale = 3)
    private BigDecimal cantidad;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 12)
    private EstadoOrden estado;

    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    @Column(name = "resuelto_en")
    private Instant resueltoEn;

    protected Orden() {
    }

    public Orden(
            Producto producto,
            Usuario comprador,
            BigDecimal cantidad
    ) {
        this.producto = producto;
        this.comprador = comprador;
        this.vendedor = producto.getVendedor();
        this.cantidad = cantidad;
        this.estado = EstadoOrden.SOLICITADA;
    }

    public void aceptar() {
        estado = EstadoOrden.ACEPTADA;
        resueltoEn = Instant.now();
    }

    public void rechazar() {
        estado = EstadoOrden.RECHAZADA;
        resueltoEn = Instant.now();
    }

    @PrePersist
    void antesDeGuardar() {
        creadoEn = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public Producto getProducto() {
        return producto;
    }

    public Usuario getComprador() {
        return comprador;
    }

    public Usuario getVendedor() {
        return vendedor;
    }

    public BigDecimal getCantidad() {
        return cantidad;
    }

    public EstadoOrden getEstado() {
        return estado;
    }

    public Instant getCreadoEn() {
        return creadoEn;
    }

    public Instant getResueltoEn() {
        return resueltoEn;
    }
}
