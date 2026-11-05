## Tecnologías

Java 21, Spring Boot, Spring Security, PostgreSQL y Flyway.

## Conexiones

- Flutter se comunica con el backend mediante una API REST.
- El backend se conecta a PostgreSQL para guardar y consultar los datos.
- Dirección local del backend: `http://localhost:8080`.
- Base de datos local: `cafexpress`, en el puerto `5432`.
- Supabase Storage se integrará posteriormente para almacenar documentos.

La configuración está en `src/main/resources/application.properties`.

Variables de entorno:
- `DB_URL`: dirección JDBC de PostgreSQL; tiene un valor local predeterminado.
- `DB_USERNAME`: usuario de PostgreSQL; por defecto, `postgres`.
- `DB_PASSWORD`: contraseña de PostgreSQL.
- `JWT_SECRET`: clave del backend para firmar los tokens.
- `CORS_ALLOWED_ORIGINS`: orígenes permitidos para el frontend web.

## Autenticación

| Método | Ruta | Datos enviados |
|---|---|---|
| POST | `/api/v1/auth/register` | nombre, email, password y rol |
| POST | `/api/v1/auth/login` | email y password |
| GET | `/api/v1/auth/me` | Token en la cabecera Authorization |

Roles disponibles: `VENDEDOR` y `COMPRADOR`.

El registro y el login devuelven:
- `accessToken`: token de acceso.
- `tokenType`: Bearer.
- `expiresIn`: duración en segundos; inicialmente, 3600.
- `usuario`: id, nombre, email y rol.

Para las solicitudes autenticadas:
`Authorization: Bearer <accessToken>`

## Datos almacenados

La tabla `usuarios` guarda:

`id`, `nombre`, `email`, `password_hash`, `rol`, `activo` y `creado_en`.

El correo se guarda en minúsculas y debe ser único.
La contraseña recibida por la API se transforma mediante BCrypt:
la base de datos almacena únicamente su hash.

Flyway administra los cambios de la base de datos mediante los archivos
de `src/main/resources/db/migration`.

## Comprobación

`GET /actuator/health` permite consultar el estado del backend.