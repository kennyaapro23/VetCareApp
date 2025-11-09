# Permisos y Vistas Implementados — VetCare App

## Resumen de Cambios Aplicados

Se ajustaron las pantallas existentes para reflejar los permisos correctos según el rol del usuario (Cliente, Veterinario, Recepción).

---

## 1. Ajustes en `pet_detail_screen.dart` (Ficha de Mascota)

### Permisos Implementados

- **Veterinario:**
  - ✅ Ver toda la información de la mascota (solo lectura)
  - ✅ Ver historial médico completo
  - ✅ Botón flotante "Nuevo Historial" (solo visible en tab Historial)
  - ✅ Ver código QR
  - ❌ NO puede editar datos de la mascota

- **Recepción:**
  - ✅ Ver toda la información
  - ✅ Editar mascota (botón en menú)
  - ✅ Ver/generar código QR
  - ✅ Ver historial médico (solo lectura para recepción según spec)

- **Cliente:**
  - ✅ Ver información solo si es dueño
  - ✅ Editar solo sus propias mascotas
  - ✅ Ver historial (solo lectura)
  - ❌ NO puede ver mascotas de otros clientes

### Código Añadido

```dart
// En build() method
final auth = context.read<AuthProvider>();
final userRole = auth.user?.role.toLowerCase().trim() ?? 'cliente';
final isVet = userRole == 'veterinario' || userRole.contains('vet');
final isReception = userRole == 'recepcion' || userRole.contains('recep');
final isOwner = auth.user?.id == widget.pet.clientId.toString();

// PopupMenu dinámico según rol
// - Recepción: editar + QR
// - Cliente dueño: editar (solo su mascota)
// - Veterinario: solo QR
```

### FloatingActionButton para Veterinario

```dart
floatingActionButton: isVet && _tabController.index == 1
    ? FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navegar a crear historial médico
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Historial'),
        backgroundColor: AppTheme.primaryColor,
      )
    : null,
```

---

## 2. Ajustes en `qr_screen.dart` (Scanner QR)

### Funcionalidad Mejorada

- ✅ Después de escanear un QR de mascota, navega **directamente** a `pet_detail_screen.dart`
- ✅ Registro de auditoría del escaneo (quién escaneó, cuándo)
- ✅ Validación de QR (solo acepta códigos VetCare)
- ✅ Manejo de errores: muestra mensaje si mascota no existe

### Flujo Actualizado

1. Usuario (vet o recepción) abre scanner desde bottom nav
2. Escanea QR de mascota
3. Sistema valida código y busca mascota en API
4. Si existe → Navega a `PetDetailScreen(pet: pet)`
5. Usuario ve historial, puede crear episodio clínico (si es vet) o editar (si es recepción)

### Import Añadido

```dart
import 'pet_detail_screen.dart';
```

---

## 3. Verificación de `vet_home_screen.dart`

### Bottom Navigation Confirmado

```dart
final _screens = const [
  _VetDashboard(),      // Panel de citas hoy
  CitasScreen(),        // Todas las citas del vet
  AllPatientsScreen(),  // Lista de pacientes (lectura)
  ServiciosScreen(),    // Servicios disponibles (lectura)
  QRScreen(),          // Scanner de mascotas ✅
  PerfilScreen(),      // Perfil del veterinario
];
```

✅ El veterinario tiene acceso al scanner en el índice 4 del bottom nav.

---

## 4. Modelo de Usuario (`user.dart`)

### Mapeo de Rol Mejorado

Se ajustó `UserModel.fromJson` para leer el rol desde múltiples posibles claves que el backend puede enviar:

```dart
role: (json['role'] ?? json['rol'] ?? json['tipo_usuario'] ?? json['perfil'] ?? 'cliente').toString(),
```

Esto garantiza que si el backend devuelve `tipo_usuario: 'veterinario'`, la app lo reconozca correctamente.

---

## 5. Router (`app_router.dart`)

### Selección de Home por Rol

```dart
Widget _getHomeScreenForRole() {
  final user = authProvider.user;
  
  // Priorizar helper del modelo
  if (user != null && user.esVeterinario) {
    return const VetHomeScreen();
  }
  
  // Fallback: comparación de string
  final roleStr = user.role.toLowerCase().trim();
  if (roleStr == 'veterinario' || roleStr.contains('vet')) {
    return const VetHomeScreen();
  }
  if (roleStr == 'recepcion' || roleStr.contains('recep')) {
    return const ReceptionistHomeScreen();
  }
  
  // Default: cliente
  return const ClientHomeScreen();
}
```

✅ Ahora detecta correctamente `tipo_usuario: 'veterinario'` del backend y asigna `VetHomeScreen`.

---

## Pantallas Existentes y Sus Roles

| Pantalla | Cliente | Veterinario | Recepción |
|----------|---------|-------------|-----------|
| `client_home_screen.dart` | ✅ | ❌ | ❌ |
| `vet_home_screen.dart` | ❌ | ✅ | ❌ |
| `receptionist_home_screen.dart` | ❌ | ❌ | ✅ |
| `pet_detail_screen.dart` | ✅ (solo suyas) | ✅ (todas, lectura) | ✅ (todas, edición) |
| `all_patients_screen.dart` | ❌ | ✅ | ✅ |
| `qr_screen.dart` | ❌ | ✅ | ✅ |
| `citas_screen.dart` | ✅ (solo suyas) | ✅ (solo suyas) | ✅ (todas) |
| `add_pet_screen.dart` | ✅ (crear/editar suyas) | ❌ | ✅ (crear/editar todas) |
| `create_medical_record_screen.dart` | ❌ | ✅ | ❌ |
| `vet_schedule_screen.dart` | ❌ | ✅ | ❌ |
| `perfil_screen.dart` | ✅ | ✅ | ✅ |

---

## Pendientes / Próximos Pasos

### Alta prioridad ✅ COMPLETADAS
1. ✅ **Implementar pantalla para crear historial médico** (`create_medical_record_screen.dart`)
   - Formulario: diagnóstico, tratamiento, servicios, observaciones
   - Endpoint: `POST /api/historial-medico`
   - Solo accesible por veterinario
   - Integrado en `pet_detail_screen.dart` (botón FAB)

2. ✅ **Ajustar `ReceptionistHomeScreen`**
   - Agregado tab "Mascotas" (índice 3) con `AllPatientsScreen`
   - Agregado tab "QR" (índice 4) con `QRScreen`
   - Bottom nav actualizado: 5 → 7 tabs
   - Verificar que tiene acceso a crear mascotas, clientes, servicios ✅
   - Revisar `quick_register_screen.dart` para walk-in ✅

3. ✅ **Gestión de horarios para veterinarios**
   - Pantalla `vet_schedule_screen.dart` implementada
   - CRUD completo de disponibilidad
   - Integrado en `vet_home_screen.dart` (tab "Mi Agenda")

### Pendiente (Backend)
4. ⚠️ **Validar permisos en backend**
   - Verificar que endpoints respeten roles (middleware Laravel)
   - Veterinario NO puede crear/editar mascotas
   - Cliente NO puede ver mascotas ajenas

### Media prioridad
4. 📁 **Reorganizar carpetas (opcional)**
   - Mover a `lib/screens/vet/`, `lib/screens/reception/`, `lib/screens/client/`, `lib/screens/shared/`
   - Actualizar imports
   - Facilita mantenimiento

5. 🧪 **Pruebas de roles**
   - Crear usuarios de prueba (cliente, vet, recepción)
   - Verificar flujos completos
   - Probar scanner en dispositivo físico

---

## Comandos para Probar

```bash
# Hot restart para aplicar cambios de rol
flutter run

# Limpiar si hay problemas de caché
flutter clean
flutter pub get
flutter run
```

---

## Notas Finales

- ✅ Los permisos están implementados en el **lado del cliente** (UI)
- ⚠️ El backend **debe validar** los mismos permisos en endpoints
- 🔒 Nunca confiar solo en UI para seguridad — siempre validar en servidor
- 📱 El scanner requiere permisos de cámara en AndroidManifest.xml / Info.plist

---

**Archivo generado:** `PERMISOS_Y_VISTAS_IMPLEMENTADOS.md`  
**Fecha:** 2025-11-08  
**Última actualización de código:** pet_detail_screen.dart, qr_screen.dart, user.dart, app_router.dart
