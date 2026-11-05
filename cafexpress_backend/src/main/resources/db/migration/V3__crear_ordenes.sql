CREATE TABLE ordenes (
    id UUID PRIMARY KEY,
    producto_id UUID NOT NULL,
    comprador_id UUID NOT NULL,
    vendedor_id UUID NOT NULL,
    cantidad NUMERIC(12, 3) NOT NULL,
    estado VARCHAR(12) NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resuelto_en TIMESTAMP WITH TIME ZONE,

    CONSTRAINT fk_ordenes_producto
        FOREIGN KEY (producto_id) REFERENCES productos (id),

    CONSTRAINT fk_ordenes_comprador
        FOREIGN KEY (comprador_id) REFERENCES usuarios (id),

    CONSTRAINT fk_ordenes_vendedor
        FOREIGN KEY (vendedor_id) REFERENCES usuarios (id),

    CONSTRAINT ck_ordenes_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT ck_ordenes_estado
        CHECK (estado IN ('SOLICITADA', 'ACEPTADA', 'RECHAZADA'))
);

CREATE INDEX ix_ordenes_comprador
    ON ordenes (comprador_id, creado_en DESC);

CREATE INDEX ix_ordenes_vendedor
    ON ordenes (vendedor_id, creado_en DESC);
