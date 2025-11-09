## README — Desarrollo local: adb reverse, pruebas de API y diagnóstico

Este README explica cómo configurar y usar las ayudas que añadimos para el desarrollo local: automatizar `adb reverse`, verificar que la app muestre la pantalla correcta según el rol, y cómo diagnosticar el error de sincronización desde cuentas creadas por Firebase (columnas faltantes en la tabla `users`).

## Resumen rápido

- Archivos añadidos/algunos ya presentes:
  - `adb-reverse-watcher.ps1` — PowerShell que vigila dispositivos adb y aplica `adb reverse tcp:8000 tcp:8000` cuando aparece un dispositivo.
  - `flutter-run-with-reverse.bat` — Wrapper Windows que aplica un reverse (uno-shot) y luego ejecuta `flutter run`.
  - `start_dev.bat` — Inicia el watcher en background (actualizado).
  - `lib/router/app_router.dart` — Contiene debug prints añadidos para verificar qué rol recibe la app.

## Requisitos previos

- Tener instalado Flutter y Android SDK (platform-tools con `adb`).
- Asegurarse de que Laravel esté corriendo localmente en `http://127.0.0.1:8000` (o ajustar puertos según tu configuración).
- PowerShell (Windows) para ejecutar los scripts (si la política de ejecución lo bloquea, ver sección "Política de ejecución").

## Opciones para aplicar `adb reverse`

1) Usar el watcher (recomendado mientras desarrollas):

   - Abre PowerShell en la carpeta del proyecto (`c:\Users\kenny\VetCareApp\vetcare_app`) y ejecuta:

   ```powershell
   # Ejecutar el watcher en esta sesión (mantenerlo abierto)
   powershell -ExecutionPolicy Bypass -File .\adb-reverse-watcher.ps1
   ```

   - El script esperará a que un dispositivo/emulador aparezca y aplicará `adb reverse tcp:8000 tcp:8000` automáticamente.

   - Alternativamente puedes iniciarlo en una ventana separada o con `Start-Process` para dejarlo en segundo plano:

   ```powershell
   Start-Process -NoNewWindow -FilePath powershell -ArgumentList '-ExecutionPolicy Bypass -File .\adb-reverse-watcher.ps1'
   ```

2) One-shot (aplicar una vez antes de `flutter run`):

   ```powershell
   # Presuponiendo ANDROID_SDK_ROOT apuntando al SDK (o ajusta la ruta al adb.exe)
   $adb = "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe"
   & $adb reverse tcp:8000 tcp:8000
   # Después corre:
   flutter run
   ```

3) Usar el wrapper incluido (Windows):

   - Ejecuta en PowerShell:

   ```powershell
   .\flutter-run-with-reverse.bat
   ```

   Este wrapper intentará aplicar un reverse (si `adb` está en PATH o si `ANDROID_SDK_ROOT` existe) y luego iniciará `flutter run`.

## Comprobación rápida: ¿está funcionando el reverse?

- Abre un emulador o conecta un dispositivo.
- En la consola donde corre `adb-reverse-watcher.ps1` deberías ver un mensaje indicando que `adb reverse` se aplicó.
- En la ejecución de `flutter run`, en la app realiza una petición a `http://127.0.0.1:8000` y verifica que no obtengas "Connection refused". Si aún lo recibes, verifica que Laravel esté corriendo y que el puerto coincide.

## Probar el endpoint de login (PowerShell y curl)

- PowerShell (Invoke-RestMethod):

```powershell
$body = @{ email = 'tu-email@example.com'; password = 'tuPassword' } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri 'http://127.0.0.1:8000/api/auth/login' -Body $body -ContentType 'application/json' -Headers @{ Accept = 'application/json' } | ConvertTo-Json -Depth 6
```

- curl (ejemplo):

```powershell
curl -X POST "http://127.0.0.1:8000/api/auth/login" -H "Accept: application/json" -H "Content-Type: application/json" -d '{"email":"tu-email@example.com","password":"tuPassword"}'
```

Observa la respuesta JSON; busca la propiedad `role` o `rol` en el objeto `user` retornado. Si la petición falla (401, 422, 500), revisa el cuerpo de respuesta y los logs de Laravel (`storage/logs/laravel.log`).

## Diagnóstico Laravel: comprobar columnas en `users`

Ejecuta `tinker` y ejecuta las comprobaciones:

```bash
php artisan tinker
>>> \Schema::hasColumn('users', 'nombre')
>>> \Schema::hasColumn('users', 'rol')
>>> \Schema::hasColumn('users', 'firebase_uid')
```

- Si `nombre` devuelve `false`, entonces el backend está intentando insertar un campo llamado `nombre` que no existe y eso causa el error SQL que viste (Unknown column 'nombre').

### Qué hacer según el resultado

- Si todas las columnas necesarias existen: investigar el payload que llega al controlador y revisar que `User::create(...)` reciba claves que coincidan con las columnas.
- Si faltan columnas y no quieres correr una migración ahora: aplica el mapeo en el controlador (solución rápida abajo).
- Si prefieres arreglar la base de datos: crea y ejecuta una migración (plantilla también abajo).

## Solución rápida sin migración (mapear campos en el controlador)

En el controlador que maneja la verificación/creación del usuario (parte del flujo que recibe datos desde Firebase), añade justo antes de crear el usuario algo como:

```php
// $request es el Request entrante
$data = $request->all();

// Mapear español -> columnas existentes
if (isset($data['nombre'])) {
    $data['name'] = $data['nombre'];
}
if (isset($data['rol'])) {
    $data['role'] = $data['rol'];
}
// Mantén firebase_uid si viene
if (isset($data['firebase_uid'])) {
    $data['firebase_uid'] = $data['firebase_uid'];
}

// Ahora usa $data para crear/actualizar
// Ejemplo: User::create($data);
```

Esto evita el error SQL porque garantizamos que `name` y `role` (columnas existentes) estén presentes si el payload trae `nombre`/`rol`.

## Plantilla de migración (si decides arreglar la DB)

1) Crear migración:

```bash
php artisan make:migration add_nombre_rol_firebaseuid_to_users_table --table=users
```

2) En el `up()` de la migración:

```php
Schema::table('users', function (Blueprint $table) {
    $table->string('nombre')->nullable();
    $table->string('rol')->nullable();
    $table->string('firebase_uid')->nullable()->unique();
});
```

3) Ejecutar:

```bash
php artisan migrate
```

Nota: esta opción cambia el esquema; si trabajas en equipo coordina antes de aplicar migraciones en el repositorio compartido.

## Verificar roles en la app Flutter

- Se añadieron `debugPrint` en `lib/router/app_router.dart` para mostrar cuál `role` recibe la app y qué pantalla asigna.
- Ejecuta la app con `flutter run`, ingresa con la cuenta de prueba y observa la salida de la consola (la línea con debugPrint mostrará el rol recibido). Si ves `veterinario` y aún aparece la pantalla de cliente, pega aquí la salida completa del debugPrint y lo revisamos.

## Política de ejecución en PowerShell (si obtienes error al ejecutar el .ps1)

- Temporalmente permite ejecutar el script en esta sesión:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# luego ejecutar el script
powershell -ExecutionPolicy Bypass -File .\adb-reverse-watcher.ps1
```

## Pasos recomendados ahora (priorizados)

1. Ejecuta `php artisan tinker` y pega aquí los resultados de `\Schema::hasColumn('users', 'nombre')` y `\Schema::hasColumn('users', 'rol')`.
2. Inicia el watcher (`adb-reverse-watcher.ps1`) o ejecuta `.\n+flutter-run-with-reverse.bat` y abre la app en el emulador.
3. Prueba login con la cuenta que falla y pega la respuesta JSON del backend (o el error en `storage/logs/laravel.log`).
4. Si confirmas que falta `nombre`, aplica el snippet de mapeo rápido en el controlador y reintenta (no modifica la DB).

## Contacto / notas finales

Si quieres, puedo:
- Generar el parche exacto para el controlador (archivo y líneas) para que lo pegues.
- Crear la migración completa y aplicarla (si lo prefieres).

Pegame aquí los resultados del `tinker` y la respuesta JSON del login y te doy el parche exacto para aplicar el mapeo (o la migración completa si te decides).

---
Archivo generado: `README_DEV.md` — instrucciones para desarrollo local y diagnóstico.
