# 🔧 ERROR 404: "Mi Agenda" - No query results for model Veterinario

## 🐛 **EL PROBLEMA**

Cuando un veterinario intenta ver "Mi Agenda", la app muestra error:

```
❌ ApiException(404)
No query results for model [App\Models\Veterinario] 2

Endpoint: GET /api/veterinarios/2/disponibilidad
```

## 🔍 **CAUSA RAÍZ**

El frontend envía el **user_id** (tabla `users`), pero el backend busca en **veterinario_id** (tabla `veterinarios`).

**Ejemplo:**
- Usuario: `users.id = 2` (existe ✅)
- Veterinario: `veterinarios.user_id = 2` (no existe ❌)

El backend busca `veterinarios.id = 2` y no lo encuentra → **404 Error**

---

## ✅ **FRONTEND YA ARREGLADO**

El código Flutter ya está actualizado:

1. **`UserModel`** ahora puede recibir `veterinario_id` del backend
2. **`vet_schedule_screen.dart`** usa `veterinarioId` en todos los métodos CRUD

```dart
// Código ya aplicado:
final vetId = auth.user?.veterinarioId ?? auth.user?.id;
```

**Tu app está lista para recibir el `veterinario_id` del backend.** Solo falta configurar el backend.

---

## �️ **NECESITAS ARREGLAR EL BACKEND**

Elige **UNA** de estas 3 opciones:

---

## 🚀 **OPCIÓN 1: SOLUCIÓN RÁPIDA (SQL)** ⭐ Recomendada para probar

### Paso 1: Verificar el problema

Abre tu gestor de base de datos y ejecuta:

```sql
-- Ver si el usuario veterinario tiene registro en tabla veterinarios
SELECT 
    u.id AS user_id,
    u.name,
    u.email,
    u.tipo_usuario,
    v.id AS veterinario_id,
    v.especialidad
FROM users u
LEFT JOIN veterinarios v ON v.user_id = u.id
WHERE u.tipo_usuario = 'veterinario';
```

**Resultado esperado:**
```
user_id | name          | tipo_usuario | veterinario_id | especialidad
--------|---------------|--------------|----------------|-------------
2       | Dr. Juan      | veterinario  | NULL           | NULL    ← ⚠️ PROBLEMA
```

Si `veterinario_id` es **NULL**, ese es el problema.

### Paso 2: Crear el registro faltante

```sql
-- Crear registro en tabla veterinarios para cada usuario veterinario sin registro
INSERT INTO veterinarios (user_id, especialidad, created_at, updated_at)
SELECT 
    u.id,
    'General',  -- Especialidad por defecto
    NOW(),
    NOW()
FROM users u
LEFT JOIN veterinarios v ON v.user_id = u.id
WHERE u.tipo_usuario = 'veterinario' 
  AND v.id IS NULL;
```

### Paso 3: Verificar que se creó

```sql
-- Debe mostrar los veterinarios con su ID
SELECT * FROM veterinarios;
```

### Paso 4: Reiniciar la app

```bash
# En el terminal de Flutter, presiona:
R   # Hot restart
```

**✅ Listo, debería funcionar.**

---

## 🔧 **OPCIÓN 2: SOLUCIÓN PERMANENTE (Laravel - Opción A)**

Modifica el endpoint que devuelve el usuario autenticado para incluir `veterinario_id`.

### Ubicación del archivo

Busca uno de estos archivos:
- `app/Http/Controllers/Auth/AuthController.php`
- `app/Http/Controllers/API/AuthController.php`
- `app/Http/Controllers/API/UserController.php`

### Código a agregar

Busca el método que devuelve el usuario autenticado (probablemente `user()`, `me()`, o `show()`):

```php
/**
 * Obtener usuario autenticado
 */
public function user(Request $request)
{
    $user = $request->user();
    
    // Preparar datos base
    $userData = [
        'id' => $user->id,
        'name' => $user->name,
        'email' => $user->email,
        'telefono' => $user->telefono,
        'tipo_usuario' => $user->tipo_usuario,
        'role' => $user->tipo_usuario,
        'created_at' => $user->created_at,
        'updated_at' => $user->updated_at,
    ];
    
    // ⭐ AGREGAR: Si es veterinario, incluir veterinario_id
    if ($user->tipo_usuario === 'veterinario') {
        $veterinario = \App\Models\Veterinario::where('user_id', $user->id)->first();
        
        // Si no existe, crear automáticamente
        if (!$veterinario) {
            $veterinario = \App\Models\Veterinario::create([
                'user_id' => $user->id,
                'especialidad' => 'General',
            ]);
        }
        
        $userData['veterinario_id'] = $veterinario->id;
    }
    
    return response()->json($userData);
}
```

### Reiniciar backend

```bash
php artisan cache:clear
php artisan config:clear
```

---

## 🎯 **OPCIÓN 3: SOLUCIÓN PERMANENTE (Laravel - Opción B)**

Agrega una relación en el modelo `User` para que siempre devuelva el `veterinario_id` automáticamente.

Edita `app/Models/User.php` y agrega:

```php
<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;
    
    // ... código existente ...
    
    /**
     * ⭐ AGREGAR: Relación con tabla veterinarios
     */
    public function veterinario()
    {
        return $this->hasOne(Veterinario::class, 'user_id');
    }
    
    /**
     * ⭐ AGREGAR: Atributos que se agregan automáticamente al JSON
     */
    protected $appends = ['veterinario_id'];
    
    /**
     * ⭐ AGREGAR: Accessor para veterinario_id
     * Se ejecuta automáticamente cuando el modelo se convierte a JSON
     */
    public function getVeterinarioIdAttribute()
    {
        // Si es veterinario, devolver su ID en tabla veterinarios
        if ($this->tipo_usuario === 'veterinario') {
            return $this->veterinario?->id;
        }
        return null;
    }
}
```

### Reiniciar backend

```bash
php artisan cache:clear
php artisan config:clear
```

**Ventaja:** No necesitas modificar controladores, el `veterinario_id` se agrega automáticamente.

---

## 🆘 **OPCIÓN 4: Si las anteriores no funcionan**

Verifica que exista el modelo `Veterinario`:

**Archivo:** `app/Models/Veterinario.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Veterinario extends Model
{
    protected $table = 'veterinarios';
    
    protected $fillable = [
        'user_id',
        'especialidad',
        'licencia',
        'telefono',
        'biografia',
    ];
    
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
    
---

## 📋 **RESUMEN: ¿QUÉ HACER?**

### ✅ **Camino Rápido (5 minutos)**

1. Ejecuta el SQL de **OPCIÓN 1** para crear registros faltantes
2. Presiona `R` en el terminal de Flutter (hot restart)
3. Prueba "Mi Agenda" → debería funcionar ✅

### ✅ **Camino Permanente (15 minutos)**

1. Aplica **OPCIÓN 2** o **OPCIÓN 3** en tu código Laravel
2. Ejecuta el SQL de **OPCIÓN 1** para casos existentes
3. Reinicia backend: `php artisan cache:clear`
4. Presiona `R` en Flutter
5. Prueba "Mi Agenda" → debería funcionar ✅

---

## � **DIAGRAMA DEL PROBLEMA**

```
┌─────────────────────────────────────────────────────────┐
│  ANTES (❌ Error)                                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Flutter App                     Laravel API            │
│  ───────────                     ───────────            │
│                                                          │
│  user.id = "2" ───────────────►  /api/veterinarios/2/   │
│  (users table)                   disponibilidad         │
│                                                          │
│                                  ❌ "No query results   │
│                                     for Veterinario 2"  │
│                                                          │
│  veterinarios table:                                    │
│  ┌────┬─────────┬──────────────┐                        │
│  │ id │ user_id │ especialidad │                        │
│  ├────┼─────────┼──────────────┤                        │
│  │ 1  │ 5       │ Cirujano     │                        │
│  └────┴─────────┴──────────────┘                        │
│       ▲                                                  │
│       └─ NO existe user_id = 2                          │
│                                                          │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  DESPUÉS (✅ Funciona)                                   │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Flutter App                     Laravel API            │
│  ───────────                     ───────────            │
│                                                          │
│  Backend envía:                  /api/user              │
│  {                               returns:               │
│    "id": 2,              ◄───────                       │
│    "veterinario_id": 1   ◄───────  ⭐ NUEVO            │
│  }                                                       │
│                                                          │
│  user.veterinarioId = "1" ──────► /api/veterinarios/1/  │
│                                   disponibilidad        │
│                                                          │
│                                   ✅ Returns schedule   │
│                                                          │
│  veterinarios table:                                    │
│  ┌────┬─────────┬──────────────┐                        │
│  │ id │ user_id │ especialidad │                        │
│  ├────┼─────────┼──────────────┤                        │
│  │ 1  │ 2       │ General      │ ◄─ CREADO             │
│  │ 2  │ 5       │ Cirujano     │                        │
│  └────┴─────────┴──────────────┘                        │
│                                                          │
└─────────────────────────────────────────────────────────┘
```
### 3. Modificar el endpoint de autenticación

Edita el controlador que devuelve el usuario autenticado para incluir `veterinario_id`.

### 4. Reiniciar la app

```bash
# Backend
php artisan cache:clear

# Frontend
flutter run
```

---

## ✅ **CÓMO VERIFICAR QUE FUNCIONA**

### 1. Verificar que el backend devuelve veterinario_id

Usa Postman o curl para probar el endpoint:

```bash
# Reemplaza {TOKEN} con tu token de autenticación
curl -X GET http://127.0.0.1:8000/api/user \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Accept: application/json"
```

**Respuesta esperada:**
```json
{
  "id": 2,
  "name": "Dr. Juan Pérez",
  "email": "veterinario@example.com",
  "tipo_usuario": "veterinario",
  "veterinario_id": 1,  ← ⭐ DEBE APARECER ESTE CAMPO
  "created_at": "2024-01-01T00:00:00.000000Z",
  "updated_at": "2024-01-01T00:00:00.000000Z"
}
```

### 2. Probar en la app

1. **Hot restart** en Flutter: presiona `R` en el terminal
2. Login como veterinario
3. Navegar a "Mi Agenda" (tab 3)
4. **Debería cargar** sin error 404

### 3. Revisar logs de Flutter

Si funciona, verás:
```
🌐 GET http://127.0.0.1:8000/api/veterinarios/1/disponibilidad
✅ Response status: 200
```

Si sigue fallando:
```
❌ Error: ApiException(404)
```
→ Revisa que el backend esté devolviendo `veterinario_id`

---

## 🆘 **TROUBLESHOOTING**

### Error persiste después de aplicar cambios

**Causa:** Cache del backend o hot reload incompleto

**Solución:**
```bash
# Backend
php artisan cache:clear
php artisan config:clear
php artisan route:clear

# Frontend (en terminal de Flutter, detener y volver a correr)
q   # Quit
flutter run
```

### Backend devuelve veterinario_id: null

**Causa:** No existe registro en tabla `veterinarios`

**Solución:** Ejecuta el SQL de la OPCIÓN 1

### Error 500 en lugar de 404

**Causa:** Problema en el código Laravel

**Solución:** Revisa los logs:
```bash
tail -f storage/logs/laravel.log
```

---

## 📚 **ARCHIVOS MODIFICADOS**

### ✅ Frontend (Ya hecho)
- `lib/models/user.dart` - Agregado campo `veterinarioId`
- `lib/screens/vet_schedule_screen.dart` - Usa `veterinarioId` en todos los métodos

### ⚠️ Backend (Pendiente)
Dependiendo de la opción elegida:
- **OPCIÓN 1:** Solo SQL, no modifica código
- **OPCIÓN 2:** `app/Http/Controllers/Auth/AuthController.php`
- **OPCIÓN 3:** `app/Models/User.php`

---

## 🎯 **RECOMENDACIÓN FINAL**

**Para probar rápido:** Usa **OPCIÓN 1** (SQL)  
**Para solución permanente:** Usa **OPCIÓN 3** (Model con accessor) + **OPCIÓN 1** (SQL para usuarios existentes)

**Tiempo estimado:**
- Opción 1: 2 minutos
- Opción 2: 10 minutos
- Opción 3: 5 minutos

---

## 📞 **¿NECESITAS MÁS AYUDA?**

Si después de aplicar estas soluciones sigue sin funcionar, comparte:

1. La respuesta de `GET /api/user` (JSON)
2. El resultado del SQL: `SELECT * FROM veterinarios;`
3. Los logs de Flutter cuando intentas ver "Mi Agenda"

¡Con eso podré ayudarte a resolverlo! 🚀
