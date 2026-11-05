CREATE TABLE productos (
    id UUID PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    cantidad_unitaria NUMERIC(10, 3) NOT NULL,
    unidad_cantidad VARCHAR(12) NOT NULL,
    cantidad_disponible NUMERIC(12, 3) NOT NULL,
    lugar_origen VARCHAR(100) NOT NULL,
    precio_unitario NUMERIC(14, 2) NOT NULL,
    disponible BOOLEAN NOT NULL DEFAULT TRUE,
    vendedor_id UUID NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_productos_vendedor
        FOREIGN KEY (vendedor_id) REFERENCES usuarios (id),

    CONSTRAINT ck_productos_unidad_cantidad
        CHECK (unidad_cantidad IN ('GRAMOS', 'KILOGRAMOS')),

    CONSTRAINT ck_productos_cantidad_unitaria
        CHECK (cantidad_unitaria > 0),

    CONSTRAINT ck_productos_cantidad_disponible
        CHECK (cantidad_disponible >= 0),

    CONSTRAINT ck_productos_precio_unitario
        CHECK (precio_unitario > 0)
);

CREATE INDEX ix_productos_disponibles
    ON productos (disponible, creado_en DESC);

CREATE INDEX ix_productos_vendedor
    ON productos (vendedor_id, creado_en DESC);
