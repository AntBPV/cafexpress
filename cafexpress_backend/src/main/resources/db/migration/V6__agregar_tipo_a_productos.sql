ALTER TABLE productos
    ADD COLUMN tipo VARCHAR(10) NOT NULL DEFAULT 'CAFE';

ALTER TABLE productos
    ADD CONSTRAINT ck_productos_tipo
        CHECK (tipo IN ('CAFE', 'CACAO', 'VARIEDAD'));

CREATE INDEX ix_productos_filtros
    ON productos (tipo, lugar_origen, precio_unitario);
