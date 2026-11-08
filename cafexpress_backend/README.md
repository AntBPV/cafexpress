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
- `OPEN_METEO_BASE_URL`: URL base de Open-Meteo; por defecto, `https://api.open-meteo.com/v1`.
- `OPEN_METEO_DAILY_VARIABLES`: variables diarias solicitadas a Open-Meteo.
- `OPEN_METEO_CURRENT_VARIABLES`: variables actuales solicitadas a Open-Meteo.
- `OPEN_METEO_TIMEZONE`: zona horaria enviada a Open-Meteo; por defecto, `auto`.
 - `CAFE_TEMPERATURA_MINIMA` y `CAFE_TEMPERATURA_MAXIMA`: rango de temperatura
  de referencia para la alerta; por defecto, entre 18 y 24 °C.
- `CAFE_LLUVIA_MINIMA` y `CAFE_LLUVIA_MAXIMA`: rango diario de lluvia de
  referencia; por defecto, entre 2 y 10 mm.

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

## Clima y alertas

El backend consulta Open-Meteo mediante:

`GET /api/v1/alerta/clima?latitude=4&longitude=-73.25`

La ruta requiere un token Bearer y devuelve los datos `current` y
`daily`, junto con sus unidades y la información de ubicación. Las variables
solicitadas por defecto se pueden cambiar mediante las variables de entorno
anteriores sin modificar el código.

La respuesta indica `Precio bajo por abundancia` cuando la temperatura actual,
el promedio diario y la lluvia de los próximos días están dentro de los rangos
configurados. Si alguna condición queda fuera del rango, indica
`Precio en aumento por escazes`.

## Productos

El catálogo de productos requiere autenticación. Los vendedores pueden
publicar y administrar sus productos mediante:

| Método | Ruta | Rol |
|---|---|---|
| POST | `/api/v1/vendedor/productos` | VENDEDOR |
| GET | `/api/v1/vendedor/productos` | VENDEDOR |
| PUT | `/api/v1/vendedor/productos/{id}` | VENDEDOR |
| DELETE | `/api/v1/vendedor/productos/{id}` | VENDEDOR |
| GET | `/api/v1/productos` | VENDEDOR o COMPRADOR |

Los endpoints GET de productos tienen paginación backend. Usan páginas
base cero y aceptan `page`, `size` y `sort`. El tamaño predeterminado es 20
y el máximo es 100. Por ejemplo:

`GET /api/v1/productos?page=0&size=20&sort=creadoEn,desc`

La respuesta contiene los productos en `content` y los metadatos
`page`, `size`, `totalElements`, `totalPages`, `first` y `last`.

El cuerpo de creación y actualización contiene `nombre`,
`cantidadUnitaria`, `unidadCantidad` (`GRAMOS` o `KILOGRAMOS`),
`cantidadDisponible`, `lugarOrigen`, `precioUnitario` y `disponible`.
Cada producto queda vinculado al vendedor autenticado. La implementación
solo administra el catálogo; no realiza pagos ni transacciones reales.
La actualización permite enviar únicamente los campos que se desean
modificar. La eliminación devuelve un mensaje de confirmación.

## Ordenes

Los compradores pueden solicitar productos disponibles y los vendedores
pueden consultar y resolver las solicitudes de sus propios productos:

| Método | Ruta | Rol |
|---|---|---|
| POST | `/api/v1/comprador/ordenes` | COMPRADOR |
| GET | `/api/v1/comprador/ordenes` | COMPRADOR |
| GET | `/api/v1/comprador/ordenes/historial` | COMPRADOR |
| GET | `/api/v1/vendedor/ordenes` | VENDEDOR |
| GET | `/api/v1/vendedor/ordenes/historial` | VENDEDOR |
| PATCH | `/api/v1/vendedor/ordenes/{id}/aceptar` | VENDEDOR |
| PATCH | `/api/v1/vendedor/ordenes/{id}/rechazar` | VENDEDOR |
| PATCH | `/api/v1/vendedor/ordenes/{id}/preparar` | VENDEDOR |
| PATCH | `/api/v1/vendedor/ordenes/{id}/enviar` | VENDEDOR |
| PATCH | `/api/v1/vendedor/ordenes/{id}/entregar` | VENDEDOR |

Para solicitar una orden se envían `productoId` y `cantidad`. La orden se
crea con estado `SOLICITADA`. Al aceptarla, el backend bloquea el producto,
comprueba nuevamente la disponibilidad y descuenta la cantidad solicitada.
La orden guarda el precio unitario y el precio total acordados al momento de
crear la solicitud, por lo que las modificaciones posteriores del precio del
producto no cambian una orden existente. El recorrido debe ejecutarse en este
orden, siempre por el vendedor propietario: `SOLICITADA` →
`ACEPTADA` → `EN_PREPARACION` → `ENVIADA` → `ENTREGADA`. Una solicitud también
puede pasar de `SOLICITADA` a `RECHAZADA`; ningún estado permite retrocesos ni
saltos. Cada transición conserva su fecha de ejecución en la respuesta.

`GET /api/v1/comprador/ordenes` y `GET /api/v1/vendedor/ordenes` muestran las
órdenes activas. Las órdenes `SOLICITADA` y `RECHAZADA` no están activas;
`ACEPTADA`, `EN_PREPARACION` y `ENVIADA` permanecen activas, y `ENTREGADA`
pasa a ser inactiva.
El historial se consulta mediante las rutas `/historial` correspondientes y
solo incluye las órdenes del participante autenticado.

## Datos almacenados

La tabla `usuarios` guarda:

`id`, `nombre`, `email`, `password_hash`, `rol`, `activo` y `creado_en`.

La tabla `productos` guarda la información del catálogo y `vendedor_id`,
que referencia al usuario vendedor responsable del producto.

El correo se guarda en minúsculas y debe ser único.
La contraseña recibida por la API se transforma mediante BCrypt:
la base de datos almacena únicamente su hash.

Flyway administra los cambios de la base de datos mediante los archivos
de `src/main/resources/db/migration`.

## Comprobación

`GET /actuator/health` permite consultar el estado del backend.