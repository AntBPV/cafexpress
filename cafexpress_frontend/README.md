# Frontend de Caféxpress

Aplicación Flutter. El paso actual implementa únicamente el inicio de sesión
con nombre de usuario o correo electrónico y contraseña. Registro y selección
de roles se incorporarán después.

## Ejecutar en local

Requiere un SDK de Flutter con Dart 3.13.5 compatible con `pubspec.yaml`.

```powershell
flutter pub get
flutter run
```

Sin configuración de API se puede revisar toda la interfaz, pero no se inicia
una sesión ficticia. Para conectar el backend, copiar
`config/api.local.example.json` a `config/api.local.json`, ajustar sus valores y
usar:

```powershell
flutter run --dart-define-from-file=config/api.local.json
```

El endpoint y los JSON del login aún no están definidos por el equipo. La
implementación contiene un contrato provisional, documentado en
[Conexión del inicio de sesión](docs/conexion-backend.md), con los puntos donde
adaptarlo. No se han modificado archivos del backend.

## Comprobar

```powershell
flutter analyze
flutter test
```

Las pruebas verifican acceso por ambos identificadores, errores, conexión JSON,
solicitudes duplicadas, tamaño de controles y adaptación a diferentes tamaños,
modo oscuro, teclado y texto ampliado. Las pruebas usan respuestas de prueba
inyectadas; no necesitan cuentas reales.
