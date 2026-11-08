ALTER TABLE ordenes
    ADD COLUMN precio_unitario NUMERIC(14, 2),
    ADD COLUMN precio_total NUMERIC(16, 2),
    ADD COLUMN activo BOOLEAN;

UPDATE ordenes o
SET precio_unitario = p.precio_unitario,
    precio_total = o.cantidad * p.precio_unitario,
    activo = (o.estado = 'SOLICITADA')
FROM productos p
WHERE o.producto_id = p.id;

ALTER TABLE ordenes
    ALTER COLUMN precio_unitario SET NOT NULL,
    ALTER COLUMN precio_total SET NOT NULL,
    ALTER COLUMN activo SET NOT NULL;

ALTER TABLE ordenes
    ADD CONSTRAINT ck_ordenes_precio_unitario
        CHECK (precio_unitario > 0),
    ADD CONSTRAINT ck_ordenes_precio_total
        CHECK (precio_total > 0);

CREATE INDEX ix_ordenes_comprador_activo
    ON ordenes (comprador_id, activo, creado_en DESC);

CREATE INDEX ix_ordenes_vendedor_activo
    ON ordenes (vendedor_id, activo, creado_en DESC);
