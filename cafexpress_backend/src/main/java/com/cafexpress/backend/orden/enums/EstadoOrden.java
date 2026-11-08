package com.cafexpress.backend.orden.enums;

public enum EstadoOrden {

    SOLICITADA(true, false),
    ACEPTADA(false, true),
    EN_PREPARACION(true, true),
    ENVIADA(true, true),
    ENTREGADA(false, false),
    RECHAZADA(false, false);

    private final boolean puedeAvanzar;
    private final boolean activa;

    EstadoOrden(boolean puedeAvanzar, boolean activa) {
        this.puedeAvanzar = puedeAvanzar;
        this.activa = activa;
    }

    public boolean puedeAvanzarA(EstadoOrden siguiente) {
        return switch (this) {
            case SOLICITADA -> siguiente == ACEPTADA || siguiente == RECHAZADA;
            case ACEPTADA -> siguiente == EN_PREPARACION;
            case EN_PREPARACION -> siguiente == ENVIADA;
            case ENVIADA -> siguiente == ENTREGADA;
            case ENTREGADA, RECHAZADA -> false;
        };
    }

    public boolean isActiva() {
        return activa;
    }

    public boolean puedeAvanzar() {
        return puedeAvanzar;
    }
}
