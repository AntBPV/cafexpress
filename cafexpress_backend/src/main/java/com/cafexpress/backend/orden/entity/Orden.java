package com.cafexpress.backend.orden.entity;

import com.cafexpress.backend.orden.enums.EstadoOrden;
import com.cafexpress.backend.producto.entity.Producto;
import com.cafexpress.backend.usuario.entity.Usuario;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
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

    @Column(name = "precio_unitario", nullable = false, precision = 14, scale = 2)
    private BigDecimal precioUnitario;

    @Column(name = "precio_total", nullable = false, precision = 16, scale = 2)
    private BigDecimal precioTotal;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 15)
    private EstadoOrden estado;

    @Column(nullable = false)
    private boolean activo;

    @Column(name = "creado_en", nullable = false, updatable = false)
    private Instant creadoEn;

    @Column(name = "resuelto_en")
    private Instant resueltoEn;

    @Column(name = "aceptada_en")
    private Instant aceptadaEn;

    @Column(name = "en_preparacion_en")
    private Instant enPreparacionEn;

    @Column(name = "enviada_en")
    private Instant enviadaEn;

    @Column(name = "entregada_en")
    private Instant entregadaEn;

    @Column(name = "rechazada_en")
    private Instant rechazadaEn;

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
        this.precioUnitario = producto.getPrecioUnitario();
        this.precioTotal = precioUnitario.multiply(cantidad)
                .setScale(2, RoundingMode.HALF_UP);
        this.estado = EstadoOrden.SOLICITADA;
        this.activo = EstadoOrden.SOLICITADA.isActiva();
    }

    public void aceptar() {
        avanzarA(EstadoOrden.ACEPTADA);
    }

    public void ponerEnPreparacion() {
        avanzarA(EstadoOrden.EN_PREPARACION);
    }

    public void enviar() {
        avanzarA(EstadoOrden.ENVIADA);
    }

    public void entregar() {
        avanzarA(EstadoOrden.ENTREGADA);
    }

    public void rechazar() {
        avanzarA(EstadoOrden.RECHAZADA);
    }

    private void avanzarA(EstadoOrden siguiente) {
        if (!estado.puedeAvanzarA(siguiente)) {
            throw new IllegalStateException(
                    "No se puede pasar de " + estado + " a " + siguiente + "."
            );
        }

        Instant ahora = Instant.now();
        estado = siguiente;
        activo = siguiente.isActiva();

        switch (siguiente) {
            case ACEPTADA -> aceptadaEn = ahora;
            case EN_PREPARACION -> enPreparacionEn = ahora;
            case ENVIADA -> enviadaEn = ahora;
            case ENTREGADA -> {
                entregadaEn = ahora;
                resueltoEn = ahora;
            }
            case RECHAZADA -> {
                rechazadaEn = ahora;
                resueltoEn = ahora;
            }
            case SOLICITADA -> throw new IllegalStateException(
                    "Una orden no puede regresar a SOLICITADA."
            );
        }
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

    public BigDecimal getPrecioUnitario() {
        return precioUnitario;
    }

    public BigDecimal getPrecioTotal() {
        return precioTotal;
    }

    public EstadoOrden getEstado() {
        return estado;
    }

    public boolean isActivo() {
        return activo;
    }

    public Instant getCreadoEn() {
        return creadoEn;
    }

    public Instant getResueltoEn() {
        return resueltoEn;
    }

    public Instant getAceptadaEn() {
        return aceptadaEn;
    }

    public Instant getEnPreparacionEn() {
        return enPreparacionEn;
    }

    public Instant getEnviadaEn() {
        return enviadaEn;
    }

    public Instant getEntregadaEn() {
        return entregadaEn;
    }

    public Instant getRechazadaEn() {
        return rechazadaEn;
    }
}
