# Endpoints del Backend Laravel - VetCareApp

## Base URL
```
http://localhost:8000/api/
```

Para emulador Android: `http://10.0.2.2:8000/api/`

## 🔓 Rutas Públicas

### Autenticación
```
POST /auth/register
POST /auth/login
```

### QR Lookup (público)
```
GET /qr/lookup/{token}
```

## 🔐 Rutas Protegidas (Requieren auth:sanctum)

### Usuario Actual
```
GET /user
```

### Logout
```
POST /auth/logout
```

### FCM Tokens (Firebase Cloud Messaging)
```
POST   /fcm-token              # Guardar token
DELETE /fcm-token              # Eliminar token actual
GET    /fcm-tokens             # Listar tokens
DELETE /fcm-tokens/all         # Eliminar todos los tokens
```

### Clientes
```
GET    /clientes               # Listar todos
POST   /clientes               # Crear
GET    /clientes/{id}          # Ver uno
PUT    /clientes/{id}          # Actualizar
DELETE /clientes/{id}          # Eliminar
```

### Mascotas
```
GET    /mascotas               # Listar todas
POST   /mascotas               # Crear
GET    /mascotas/{id}          # Ver una
PUT    /mascotas/{id}          # Actualizar
DELETE /mascotas/{id}          # Eliminar
GET    /mascotas/{id}/qr       # Generar QR
```

### Veterinarios
```
GET    /veterinarios                        # Listar todos
POST   /veterinarios                        # Crear
GET    /veterinarios/{id}                   # Ver uno
PUT    /veterinarios/{id}                   # Actualizar
DELETE /veterinarios/{id}                   # Eliminar
GET    /veterinarios/{id}/disponibilidad    # Ver disponibilidad
POST   /veterinarios/{id}/disponibilidad    # Establecer disponibilidad
```

### Citas
```
GET    /citas                  # Listar todas
POST   /citas                  # Crear
GET    /citas/{id}             # Ver una
PUT    /citas/{id}             # Actualizar
DELETE /citas/{id}             # Eliminar
```

### Servicios
```
GET    /servicios              # Listar todos
POST   /servicios              # Crear
GET    /servicios/{id}         # Ver uno
PUT    /servicios/{id}         # Actualizar
DELETE /servicios/{id}         # Eliminar
GET    /servicios-tipos        # Obtener tipos de servicios
```

### Historial Médico
```
GET    /historial-medico                    # Listar
POST   /historial-medico                    # Crear
GET    /historial-medico/{id}               # Ver uno
POST   /historial-medico/{id}/archivos      # Adjuntar archivos
```

### Notificaciones
```
GET    /notificaciones                      # Listar todas
GET    /notificaciones/{id}                 # Ver una
DELETE /notificaciones/{id}                 # Eliminar una
GET    /notificaciones/tipos                # Tipos de notificaciones
GET    /notificaciones/unread-count         # Cantidad no leídas
POST   /notificaciones/mark-all-read        # Marcar todas como leídas
POST   /notificaciones/{id}/mark-read       # Marcar una como leída
DELETE /notificaciones/delete-read          # Eliminar leídas
```

### Facturas
```
GET    /facturas                            # Listar todas
POST   /facturas                            # Crear
GET    /facturas/{id}                       # Ver una
PUT    /facturas/{id}                       # Actualizar
DELETE /facturas/{id}                       # Eliminar
GET    /facturas-estadisticas               # Estadísticas
GET    /generar-numero-factura              # Generar número
```

### QR Codes (Protegidos)
```
GET    /clientes/{id}/qr                    # Generar QR de cliente
```

## 📝 Notas de Implementación

### Headers Requeridos
Todas las rutas protegidas requieren:
```
Authorization: Bearer {token}
Accept: application/json
Content-Type: application/json
```

### Respuestas Comunes
```json
// Éxito
{
  "data": {...},
  "message": "Success"
}

// Error
{
  "message": "Error message",
  "errors": {...}
}
```

### Filtros y Paginación
La mayoría de endpoints GET soportan:
- `?page=1` - Paginación
- `?per_page=15` - Elementos por página
- `?search=query` - Búsqueda
- `?sort_by=field` - Ordenamiento
- `?estado=valor` - Filtros específicos

## 🔧 Configuración en Flutter

Los servicios Flutter ya están configurados para usar estos endpoints:
- `ApiService` - Cliente HTTP base
- `AuthService` - Login/Register/Logout
- `AppointmentService` - Citas
- `VetServiceService` - Servicios veterinarios
- `ClientService` - Clientes
- `PetService` - Mascotas
- `VeterinarianService` - Veterinarios
- `QRService` - Búsqueda y generación QR
- `NotificationService` - Notificaciones y FCM

## 🚀 Ejemplo de Uso

```dart
final auth = context.read<AuthProvider>();

// Login
final user = await auth.login('email@test.com', 'password');

// Obtener citas
final appointmentService = AppointmentService(auth.api);
final citas = await appointmentService.getAppointments();

// Crear servicio
final vetService = VetServiceService(auth.api);
await vetService.createService({
  'mascota_id': '1',
  'tipo_servicio': 'Vacunación',
  'descripcion': 'Vacuna antirrábica',
  'costo': 50.0,
});
```

