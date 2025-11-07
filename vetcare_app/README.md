VetCareApp - API integration

Descripción
-----------
Esta rama contiene la estructura base de VetCareApp (Flutter) con arquitectura limpia y un servicio `ApiService` preparado para comunicarse con una API REST (Laravel) alojada en `http://localhost:8000/api/`.

Qué añadí
---------
- `lib/services/api_service.dart` — cliente HTTP robusto con métodos GET/POST/PUT/DELETE, token Bearer, manejo de errores, reintentos exponenciales y parseo JSON mediante una función `fromJson` pasada por parámetro.
- `lib/services/auth_service.dart` — ejemplo de uso de `ApiService` para `auth/login` que extrae token y usuario y guarda el token en `ApiService`.
- Estructura de carpetas: `models`, `services`, `providers`, `screens`, `widgets`.
- `pubspec.yaml` actualizado con `provider` y `http`.

Cómo instalar dependencias (en Windows, cmd.exe)
-----------------------------------------------
Abre una terminal (cmd.exe) en la raíz del proyecto y ejecuta:

```cmd
cd /d C:\Users\kenny\vetcare_app
flutter pub get
flutter analyze
```

Si todo está correcto, ejecuta la app:

```cmd
flutter run
# o para correr en Windows si está habilitado
flutter run -d windows
```

Notas sobre networking y localhost
---------------------------------
- Si usas un emulador Android, `http://localhost:8000` desde el emulador no apunta al host; usa `http://10.0.2.2:8000/api/` para el emulador de Android (o configura tu `ApiService(baseUrl: ...)`).
- Si usas iOS Simulator, `localhost` sí suele apuntar al host, pero verifica según tu configuración.

Ejemplo de uso de `ApiService` / `AuthService`
---------------------------------------------
(usa este patrón en tus providers o servicios):

```dart
final authService = AuthService();

Future<void> exampleLogin() async {
  try {
    final user = await authService.login(email: 'dev@example.com', password: 'secret123');
    if (user != null) {
      print('Usuario: ${user.name}');
      // authService.api ya tiene el token seteado
    } else {
      print('Login falló: usuario nulo');
    }
  } catch (e) {
    print('Error de login: $e');
  }
}
```

Consejos y siguientes pasos (opcional)
-------------------------------------
- Persistir el token con `flutter_secure_storage` para mantener sesión entre reinicios.
- Implementar refresh token si tu backend lo soporta (capturando 401 y renovando token automático).
- Añadir tests unitarios con inyección de cliente HTTP (por ejemplo usando `http` con un `MockClient`).

Si quieres, puedo:
- Añadir persistencia del token con `flutter_secure_storage` y un ejemplo de refresh token.
- Crear tests unitarios mínimos para `ApiService` usando un `MockClient`.
- Intentar ejecutar `flutter pub get` desde aquí si me confirmas que la terminal integrada de la herramienta puede abrirse (en mi intento anterior la herramienta falló en crear la terminal clásica). 

Pega aquí la salida de `flutter pub get` o `flutter analyze` si quieres que revise resultados y haga correcciones.

