CREATE TABLE usuarios (
    id UUID PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(254) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol VARCHAR(20) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uk_usuarios_email
        UNIQUE (email),

    CONSTRAINT ck_usuarios_rol
        CHECK (rol IN ('VENDEDOR', 'COMPRADOR')),

    CONSTRAINT ck_usuarios_email
        CHECK (email = LOWER(TRIM(email)))
);