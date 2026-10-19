# Conexión del inicio de sesión

**Contrato propuesto, pendiente de acuerdo con backend.** El repositorio todavía
no implementa este endpoint. Cambiar el contrato no exige rehacer la pantalla.

## Configuración

La aplicación recibe `API_BASE_URL` y `AUTH_LOGIN_PATH` mediante `--dart-define`
o `--dart-define-from-file`. La URL se deja vacía por defecto: sin configuración,
la interfaz explica la indisponibilidad y no envía credenciales a ningún servidor.

Desde `cafexpress_frontend`, copiar `config/api.local.example.json` a
`config/api.local.json` y ajustar la URL y la ruta. Este último archivo está
ignorado por Git. Los valores de ejemplo **no representan servicios existentes**.

```powershell
flutter run -d windows --dart-define-from-file=config/api.local.json
```

Para un emulador Android estándar usar `http://10.0.2.2:8080` en lugar de
`localhost`; en un teléfono físico, la dirección accesible del equipo que ejecuta
el backend. Para desarrollo Android por HTTP, el manifiesto `debug` permite
tráfico sin cifrar. Las compilaciones release no incluyen esa excepción. Para
producción usar HTTPS. No cambiar las políticas de transporte de producción.

En web, el backend debe permitir mediante CORS el origen de desarrollo y los
encabezados `Content-Type` y `Authorization` cuando se utilice este último.
Los valores `dart-define` son configuración pública, nunca secretos.

## Solicitud provisional

`POST /api/auth/login` con `Content-Type: application/json`.

```json
{
  "identifier": "cristhian.orbes",
  "password": "contraseña escrita por el usuario"
}
```

`identifier` puede contener un nombre de usuario o correo. Se eliminan espacios
externos del identificador, sin cambiar mayúsculas; la contraseña se envía tal
como se escribió. No se decide desde la pantalla cómo buscar la cuenta.

## Respuesta provisional

HTTP 200 y un objeto JSON:

```json
{
  "accessToken": "token-entregado-por-el-backend",
  "tokenType": "Bearer",
  "user": {
    "name": "Cristhian",
    "email": "cristhian@example.com"
  }
}
```

`accessToken` es obligatorio y no puede estar vacío. `tokenType` es opcional y
solo admite `Bearer`; `user`, `name` y `email` son opcionales. Una respuesta 2xx
sin token válido **no** autentica al usuario. Esta implementación presupone un
token Bearer; si el equipo elige cookies u otro formato, se adapta la capa de
datos antes de integrarlo.

## Dónde adaptar el contrato

- `lib/core/config/api_config.dart`: URL, ruta y espera máxima (15 segundos).
- `lib/core/network/api_client.dart`: POST JSON, encabezados y errores HTTP/red.
- `lib/features/auth/data/auth_repository.dart`: nombres y estructura del JSON
  de solicitud. `AuthRepository` permite sustituir la implementación.
- `lib/features/auth/domain/auth_session.dart`: lectura de la respuesta y
  encabezado `authorizationHeader` para futuras solicitudes autenticadas.
- `lib/features/auth/presentation/login_screen.dart`: interfaz; desconoce HTTP.

El cliente permite un encabezado `authorization` opcional para otros POST JSON.
Agregar otros métodos HTTP cuando se conozcan los siguientes endpoints.

## Comportamiento y límites del paso actual

- Campos obligatorios, correo con formato básico si se escribe `@`, contraseña
  visible/oculta, autocompletado y envío con la tecla de acción.
- No se imponen reglas nuevas de longitud de contraseña al login: se deben
  aceptar las contraseñas existentes que valide el backend.
- Durante el envío no se permiten solicitudes duplicadas. El identificador y
  la contraseña se conservan si falla, para permitir corregirlos o reintentar.
- HTTP 400/422, 401, 403, 404, 429, fallos de servidor, tiempo de espera y red
  tienen mensajes en español. No se muestran cuerpos ni trazas del servidor.
- Solo una respuesta válida muestra la confirmación de sesión. No hay modo
  demo ni acceso simulado en ejecución normal.
- El token vive solo en memoria. No se escribe en archivos, preferencias ni
  registros. Cerrar sesión descarta esta sesión local; no invoca un endpoint
  de logout o revocación porque todavía no se ha definido.
- No hay persistencia, renovación de tokens, dashboard, registro ni roles en
  este paso. La redirección posterior se conectará al módulo que corresponda.
- Autenticar por usuario **o** correo, buscar la cuenta, verificar la contraseña
  y emitir el token son responsabilidades del backend.

## Verificación

```powershell
flutter analyze
flutter test
```

Las pruebas cubren formulario → repositorio → cliente HTTP → JSON con transporte
inyectado; no requieren cuentas ni llamadas a producción. Hasta acordar e
implementar el endpoint no se puede comprobar el acceso contra el backend real.

Referencia técnica: [envío de JSON desde Flutter](https://docs.flutter.dev/cookbook/networking/send-data).
