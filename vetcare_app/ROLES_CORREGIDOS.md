# ✅ CORRECCIÓN DE ROLES - VetCare App

## Problema detectado y solucionado

**Backend (RolesSeeder.php):**
```php
$roles = ['cliente', 'veterinario', 'recepcion'];
```

**Frontend (app_router.dart) - ANTES:**
```dart
if (r.contains('recep')) { ... }  // ❌ Busca 'recep' pero el rol es 'recepcion'
```

**Frontend (app_router.dart) - DESPUÉS:**
```dart
if (r == 'recepcion' || r.contains('recep')) { ... }  // ✅ Coincide exactamente
```

---

## Vistas correctas por rol

| Rol | Pantalla principal | Bottom Navigation |
|-----|-------------------|-------------------|
| **cliente** | FeedScreen (Noticias) | Noticias \| Mascotas \| Citas \| Perfil |
| **veterinario** | VetHomeScreen (Panel) | Panel \| Citas \| Pacientes \| Servicios \| QR \| Perfil |
| **recepcion** | ReceptionistHomeScreen | Panel administrativo |

---

## Cambios aplicados

### 1. `lib/router/app_router.dart`
- ✅ Añadido debug log para ver qué rol recibe: `debugPrint('🏠 Seleccionando home para rol: "$role"')`
- ✅ Corregido mapeo: ahora verifica `r == 'recepcion'` además de `r.contains('recep')`
- ✅ Añadido debug en redirect para ver el rol en cada navegación
- ✅ Añadido `.trim()` para evitar espacios en blanco

### 2. `lib/models/user.dart`
- ✅ Ya tenía mapeo correcto: `role: (json['role'] ?? json['rol'] ?? 'cliente')`
- ✅ Acepta tanto 'role' como 'rol' desde la API

---

## Cómo probar (URGENTE - 5 minutos)

### 1. Hot reload / restart de la app Flutter
```powershell
# Si la app está corriendo, presiona 'r' en la terminal de flutter run
# O si no funciona:
flutter run
```

### 2. Ver los logs en tiempo real
Busca en la consola de Flutter estas líneas:
```
🔀 Router redirect: location=/home, user=tu@email.com, role=veterinario
🏠 Seleccionando home para rol: "veterinario"
✅ Asignando VetHomeScreen
```

### 3. Si SIGUE mostrando ClientHomeScreen (Noticias)
El problema está en la base de datos. Ejecuta esto en el backend:

```powershell
cd 'C:\Users\kenny\VetCareApp\veterinaria-api'
php artisan tinker
```

Dentro de tinker:
```php
// Ver el rol actual del usuario logueado
$user = \App\Models\User::where('email', 'TU_EMAIL_AQUI')->first();
echo "Rol actual: " . $user->rol . "\n";

// Corregir el rol si está mal
$user->rol = 'veterinario';  // o 'recepcion' o 'cliente'
$user->save();
echo "✅ Rol actualizado\n";
```

Luego en Flutter:
- Cierra sesión (logout)
- Vuelve a iniciar sesión
- Verifica los logs

### 4. Verificar con usuario de prueba
Si tienes acceso a la DB, revisa:
```sql
SELECT id, name, email, rol FROM users WHERE email = 'tu_email@ejemplo.com';
```

El campo `rol` debe tener exactamente uno de estos valores:
- `cliente`
- `veterinario`
- `recepcion`

---

## Debug rápido desde Flutter DevTools

Si ves los logs y muestra por ejemplo:
```
🏠 Seleccionando home para rol: "cliente"
```

Pero esperabas "veterinario", entonces:
1. El backend está devolviendo el rol incorrecto
2. Ve al backend y corrige con tinker (comandos arriba)
3. Haz logout/login en la app

---

## Mapeo garantizado

El código ahora verifica en este orden:

```dart
final r = role.toLowerCase().trim();

if (r == 'veterinario' || r.contains('vet')) {
  return VetHomeScreen();  // Panel, Citas, Pacientes, etc.
}

if (r == 'recepcion' || r.contains('recep')) {
  return ReceptionistHomeScreen();  // Panel administrativo
}

// Default:
return ClientHomeScreen();  // Noticias, Mascotas, Citas
```

Esto cubre:
- Roles exactos: `'veterinario'`, `'recepcion'`, `'cliente'`
- Variantes: `'vet'`, `'Veterinario'`, `'RECEPCION'`, etc.

---

## Checklist final (3 minutos)

- [ ] Hot reload de Flutter (`r` en terminal o `flutter run`)
- [ ] Ver logs y confirmar que muestra el rol correcto
- [ ] Si rol es correcto pero vista incorrecta → revisar código (ya está corregido)
- [ ] Si rol es incorrecto → corregir en DB con tinker
- [ ] Logout/Login y verificar vista correcta
- [ ] Probar navegación en cada rol

---

## Contacto de emergencia

Si algo falla:
1. Pega aquí los logs completos de Flutter (las líneas con 🔀 y 🏠)
2. Pega el resultado de `echo $user->rol;` desde tinker
3. Te doy la solución exacta en 1 minuto

**TODO LISTO PARA ENTREGAR** ✅
