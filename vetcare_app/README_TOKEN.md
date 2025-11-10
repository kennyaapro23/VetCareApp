# Cómo asegurar que el token de autenticación funcione en toda la app

## Problema
Después de hacer login, el token (`sanctum_token`, `token` o `access_token`) debe usarse en todas las peticiones a la API. Si el token no se actualiza correctamente en el `ApiService` global, el backend responde 401 "Unauthenticated".

## Solución

### 1. Actualiza el token en el ApiService después del login
En tu función de login (Firebase o tradicional), después de recibir el token:
```dart
if (token != null) {
  _api.setToken(token); // <-- Esto es clave
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_tokenKey, token);
}
```

### 2. Usa el mismo ApiService en toda la app
- Si usas Provider, asegúrate que el ApiService en Provider se actualiza con el nuevo token después del login.
- Si usas singleton, asegúrate que todas las pantallas usan la misma instancia.

### 3. Recupera el token al iniciar la app
Al iniciar la app (auto-login), recupera el token guardado y llama a:
```dart
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString(_tokenKey);
if (token != null) {
  _api.setToken(token);
}
```

### 4. Verifica que todas las peticiones usan el token actualizado
El ApiService debe incluir el header:
```http
Authorization: Bearer <token>
```

### 5. Ejemplo de headers en ApiService
```dart
Map<String, String> _headers({bool jsonContent = true}) {
  final headers = <String, String>{'Accept': 'application/json'};
  if (jsonContent) headers['Content-Type'] = 'application/json';
  if (_token != null) {
    headers['Authorization'] = 'Bearer $_token';
  }
  return headers;
}
```

## Recomendaciones
- Haz logout/login para forzar la actualización del token si tienes problemas.
- Usa solo una instancia de ApiService en toda la app.
- Si usas Provider, actualiza el token en el Provider después del login.

---

¿Dudas? Revisa este README y verifica que el token se actualiza y se usa en todas las peticiones a la API.
