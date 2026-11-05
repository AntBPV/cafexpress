package com.cafexpress.backend.producto.entity;

import com.cafexpress.backend.producto.enums.UnidadCantidad;
import com.cafexpress.backend.usuario.entity.Usuario;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "productos")
public class Producto {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 150)
    private String nombre;

    @Column(name = "cantidad_unitaria", nullable = false, precision = 10, scale = 3)
    private BigDecimal cantidadUnitaria;

    @Enumerated(EnumType.STRING)
    @Column(name = "unidad_cantidad", nullable = false, length = 12)
    private UnidadCantidad unidadCantidad;

    @Column(name = "cantidad_disponible", nullable = false, precision = 12, scale = 3)
    private BigDecimal cantidadDisponible;

    @Column(name = "lugar_origen", nullable = false, length = 100)
    private String lugarOrigen;

    @Column(name = "precio_unitario", nullable = false, precision = 14, scale = 2)
    private BigDecimal precioUnitario;

    @Column(nullable = false)
    private boolean disponible;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "vendedor_id", nullable = false)
    private Usuario vendedor;

    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    protected Producto() {
    }

    public Producto(
            String nombre,
            BigDecimal cantidadUnitaria,
            UnidadCantidad unidadCantidad,
            BigDecimal cantidadDisponible,
            String lugarOrigen,
            BigDecimal precioUnitario,
            boolean disponible,
            Usuario vendedor
    ) {
        this.nombre = nombre;
        this.cantidadUnitaria = cantidadUnitaria;
        this.unidadCantidad = unidadCantidad;
        this.cantidadDisponible = cantidadDisponible;
        this.lugarOrigen = lugarOrigen;
        this.precioUnitario = precioUnitario;
        this.disponible = disponible;
        this.vendedor = vendedor;
    }

    public void actualizar(
            String nombre,
            BigDecimal cantidadUnitaria,
            UnidadCantidad unidadCantidad,
            BigDecimal cantidadDisponible,
            String lugarOrigen,
            BigDecimal precioUnitario,
            boolean disponible
    ) {
        this.nombre = nombre;
        this.cantidadUnitaria = cantidadUnitaria;
        this.unidadCantidad = unidadCantidad;
        this.cantidadDisponible = cantidadDisponible;
        this.lugarOrigen = lugarOrigen;
        this.precioUnitario = precioUnitario;
        this.disponible = disponible;
    }

    public void actualizarParcial(
            String nombre,
            BigDecimal cantidadUnitaria,
            UnidadCantidad unidadCantidad,
            BigDecimal cantidadDisponible,
            String lugarOrigen,
            BigDecimal precioUnitario,
            Boolean disponible
    ) {
        if (nombre != null) {
            this.nombre = nombre;
        }
        if (cantidadUnitaria != null) {
            this.cantidadUnitaria = cantidadUnitaria;
        }
        if (unidadCantidad != null) {
            this.unidadCantidad = unidadCantidad;
        }
        if (cantidadDisponible != null) {
            this.cantidadDisponible = cantidadDisponible;
        }
        if (lugarOrigen != null) {
            this.lugarOrigen = lugarOrigen;
        }
        if (precioUnitario != null) {
            this.precioUnitario = precioUnitario;
        }
        if (disponible != null) {
            this.disponible = disponible;
        }
    }

    public void descontarCantidad(BigDecimal cantidad) {
        cantidadDisponible = cantidadDisponible.subtract(cantidad);
        if (cantidadDisponible.signum() == 0) {
            disponible = false;
        }
    }

    @PrePersist
    void antesDeGuardar() {
        creadoEn = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public String getNombre() {
        return nombre;
    }

    public BigDecimal getCantidadUnitaria() {
        return cantidadUnitaria;
    }

    public UnidadCantidad getUnidadCantidad() {
        return unidadCantidad;
    }

    public BigDecimal getCantidadDisponible() {
        return cantidadDisponible;
    }

    public String getLugarOrigen() {
        return lugarOrigen;
    }

    public BigDecimal getPrecioUnitario() {
        return precioUnitario;
    }

    public boolean isDisponible() {
        return disponible;
    }

    public Usuario getVendedor() {
        return vendedor;
    }

    public Instant getCreadoEn() {
        return creadoEn;
    }
}
