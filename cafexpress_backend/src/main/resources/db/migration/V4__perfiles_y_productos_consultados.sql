ALTER TABLE usuarios ADD COLUMN empresa_productor VARCHAR(120);
ALTER TABLE usuarios ADD COLUMN pais_origen VARCHAR(80);

CREATE TABLE productos_consultados (
    id UUID PRIMARY KEY,
    usuario_id UUID NOT NULL REFERENCES usuarios(id),
    producto_id UUID NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    consultado_en TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_consulta_usuario_producto UNIQUE (usuario_id, producto_id)
);
CREATE INDEX ix_consultas_usuario_fecha
    ON productos_consultados (usuario_id, consultado_en DESC);
