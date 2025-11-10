# Fix: Error 404 en /api/facturas/estadisticas

## 🐛 Problema

El endpoint `GET /api/facturas/estadisticas` devuelve un error 404:
```
No query results for model [App\Models\Factura] estadisticas
```

## 🔍 Causa

Laravel está interpretando "estadisticas" como un ID de factura (parámetro `{id}`) en lugar de reconocerlo como una ruta específica.

Esto ocurre porque la ruta dinámica `GET /api/facturas/{id}` está **antes** de la ruta específica `GET /api/facturas/estadisticas` en el archivo de rutas.

## ✅ Solución

En el archivo de rutas del backend (generalmente `routes/api.php`), **reordenar las rutas** para que las rutas específicas estén **ANTES** de las rutas dinámicas:

### ❌ Incorrecto (orden actual):
```php
Route::middleware('auth:sanctum')->group(function () {
    // Ruta dinámica PRIMERO (mal)
    Route::get('facturas/{id}', [FacturaController::class, 'show']);
    
    // Ruta específica DESPUÉS (se ignora)
    Route::get('facturas/estadisticas', [FacturaController::class, 'estadisticas']);
});
```

### ✅ Correcto (orden corregido):
```php
Route::middleware('auth:sanctum')->group(function () {
    // Rutas específicas PRIMERO
    Route::get('facturas/estadisticas', [FacturaController::class, 'estadisticas']);
    Route::get('facturas/generateNumeroFactura', [FacturaController::class, 'generateNumeroFactura']);
    
    // Ruta dinámica AL FINAL
    Route::get('facturas/{id}', [FacturaController::class, 'show']);
    
    // Otras rutas...
    Route::get('facturas', [FacturaController::class, 'index']);
    Route::post('facturas', [FacturaController::class, 'store']);
    Route::post('facturas/desde-historiales', [FacturaController::class, 'createFromHistoriales']);
    Route::put('facturas/{id}', [FacturaController::class, 'update']);
    Route::delete('facturas/{id}', [FacturaController::class, 'destroy']);
});
```

## 📝 Regla General

**Siempre colocar rutas específicas (con nombres literales) ANTES de rutas dinámicas (con parámetros `{id}`).**

### Orden recomendado para RESTful:
1. Rutas con nombres específicos (estadisticas, generateNumeroFactura, etc.)
2. Ruta index (GET /resource)
3. Ruta create (GET /resource/create) - si aplica
4. Ruta store (POST /resource)
5. Ruta show (GET /resource/{id})
6. Ruta edit (GET /resource/{id}/edit) - si aplica
7. Ruta update (PUT/PATCH /resource/{id})
8. Ruta destroy (DELETE /resource/{id})

## 🔄 Cambio Temporal en Frontend

Mientras se corrige el backend, he **comentado** temporalmente todas las llamadas a `_loadEstadisticas()` en `manage_invoices_screen.dart` para evitar errores 404.

### Para reactivar después de arreglar el backend:

Buscar y descomentar todas las líneas:
```dart
// _loadEstadisticas();
```

Cambiar a:
```dart
_loadEstadisticas();
```

## ✅ Verificación

Después de corregir las rutas, probar:

```bash
# Desde terminal o Postman
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8000/api/facturas/estadisticas
```

Debe devolver:
```json
{
  "total": 1234.56,
  "pagadas": 10,
  "pendientes": 5,
  "anuladas": 2
}
```

## 📚 Referencias

- [Laravel Routing: Route Order](https://laravel.com/docs/11.x/routing#route-parameters)
- Regla: Las rutas más específicas deben definirse antes que las más genéricas
