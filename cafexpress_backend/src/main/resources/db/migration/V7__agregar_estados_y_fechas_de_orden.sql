ALTER TABLE ordenes
    ALTER COLUMN estado TYPE VARCHAR(15),
    ADD COLUMN aceptada_en TIMESTAMP WITH TIME ZONE,
    ADD COLUMN en_preparacion_en TIMESTAMP WITH TIME ZONE,
    ADD COLUMN enviada_en TIMESTAMP WITH TIME ZONE,
    ADD COLUMN entregada_en TIMESTAMP WITH TIME ZONE,
    ADD COLUMN rechazada_en TIMESTAMP WITH TIME ZONE;

UPDATE ordenes
SET aceptada_en = resuelto_en
WHERE estado = 'ACEPTADA';

UPDATE ordenes
SET rechazada_en = resuelto_en
WHERE estado = 'RECHAZADA';

UPDATE ordenes
SET activo = CASE
    WHEN estado = 'ACEPTADA' THEN TRUE
    ELSE FALSE
END;

ALTER TABLE ordenes
    DROP CONSTRAINT ck_ordenes_estado,
    ADD CONSTRAINT ck_ordenes_estado
        CHECK (estado IN (
            'SOLICITADA',
            'ACEPTADA',
            'EN_PREPARACION',
            'ENVIADA',
            'ENTREGADA',
            'RECHAZADA'
        ));
