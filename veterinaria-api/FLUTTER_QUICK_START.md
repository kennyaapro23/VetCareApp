# 📱 Resumen Rápido - API Veterinaria para Flutter

## 🔗 Base URL
```
http://tu-dominio.com/api
```

## 🔑 Autenticación

### 1. Login
```dart
POST /api/auth/login
{
  "email": "usuario@example.com",
  "password": "password123"
}

// Response:
{
  "token": "1|abcd1234...",
  "user": {
    "id": 1,
    "name": "Juan Pérez",
    "email": "usuario@example.com",
    "roles": [{"name": "cliente"}]
  }
}
```

### 2. Todas las peticiones posteriores:
```dart
headers: {
  'Authorization': 'Bearer {token}',
  'Content-Type': 'application/json'
}
```

### 3. Enviar FCM Token (después del login)
```dart
POST /api/fcm-token
{
  "token": "fcm_token_de_firebase",
  "device_type": "android", // o "ios"
  "device_name": "Samsung Galaxy S21"
}
```

## 📊 Modelos Principales

### Mascota
```dart
{
  "id": 1,
  "cliente_id": 1,
  "nombre": "Max",
  "especie": "perro", // perro, gato, ave, reptil, otro
  "raza": "Golden Retriever",
  "fecha_nacimiento": "2020-06-15",
  "edad": "4 años, 5 meses", // calculado automáticamente
  "sexo": "macho",
  "peso": 30.5,
  "color": "dorado",
  "chip_id": "123456789",
  "foto": "http://api.com/storage/mascotas/foto.jpg",
  "public_id": "uuid-para-qr"
}
```

### Cita
```dart
{
  "id": 1,
  "mascota_id": 1,
  "veterinario_id": 1,
  "fecha_hora": "2025-01-20T10:00:00Z",
  "duracion_minutos": 45,
  "estado": "programada", // programada, confirmada, en_curso, completada, cancelada
  "motivo_consulta": "Vacunación anual",
  "observaciones": "Primera visita del año",
  "servicios": [
    {
      "id": 2,
      "nombre": "Vacuna Antirrábica",
      "precio": 35.00,
      "pivot": {
        "precio_momento": 35.00 // precio congelado al momento de la cita
      }
    }
  ],
  "mascota": {...},
  "veterinario": {...}
}
```

### Notificación
```dart
{
  "id": 1,
  "tipo": "recordatorio_cita",
  "titulo": "Recordatorio de cita",
  "mensaje": "Tienes una cita mañana a las 10:00 AM",
  "data": {
    "cita_id": 5
  },
  "leida": false,
  "created_at": "2025-01-19T08:00:00Z"
}
```

## 🚀 Endpoints Más Usados

### Mascotas
```dart
GET    /api/mascotas                    // Listar todas
GET    /api/mascotas?cliente_id=1       // Filtrar por cliente
GET    /api/mascotas/{id}               // Ver detalle
POST   /api/mascotas                    // Crear (multipart/form-data para foto)
PUT    /api/mascotas/{id}               // Actualizar
DELETE /api/mascotas/{id}               // Eliminar
GET    /api/mascotas/{id}/qr            // Generar QR
```

### Citas
```dart
GET    /api/citas                       // Listar según rol
GET    /api/citas?mascota_id=1          // Filtrar por mascota
GET    /api/citas?fecha=2025-01-20      // Filtrar por fecha
GET    /api/citas/{id}                  // Ver detalle
POST   /api/citas                       // Crear
PUT    /api/citas/{id}                  // Actualizar
DELETE /api/citas/{id}                  // Cancelar
```

### Crear Cita (Request)
```dart
POST /api/citas
{
  "mascota_id": 1,
  "veterinario_id": 1,
  "fecha_hora": "2025-01-20T10:00:00Z",
  "motivo_consulta": "Vacunación anual",
  "servicio_ids": [2, 5]
}
```

### Servicios
```dart
GET    /api/servicios                   // Listar todos
GET    /api/servicios?tipo=vacuna       // Filtrar por tipo
GET    /api/servicios-tipos             // Tipos disponibles
```

### Notificaciones
```dart
GET    /api/notificaciones              // Listar mis notificaciones
GET    /api/notificaciones?leida=false  // Solo no leídas
GET    /api/notificaciones/unread-count // Contador para badge
POST   /api/notificaciones/{id}/mark-read  // Marcar como leída
POST   /api/notificaciones/mark-all-read   // Marcar todas
DELETE /api/notificaciones/delete-read     // Eliminar leídas
```

### Historial Médico
```dart
GET    /api/historial-medico?mascota_id=1  // Historial de una mascota
POST   /api/historial-medico               // Crear registro (veterinarios)
POST   /api/historial-medico/{id}/archivos // Adjuntar archivos
```

### QR (Sin autenticación)
```dart
GET    /api/qr/lookup/{uuid}            // Buscar por QR
```

### Facturas
```dart
GET    /api/facturas                    // Mis facturas
GET    /api/facturas?estado=pendiente   // Filtrar por estado
POST   /api/facturas                    // Crear desde cita
PUT    /api/facturas/{id}               // Actualizar estado
GET    /api/generar-numero-factura      // Número automático
```

### Veterinarios
```dart
GET    /api/veterinarios                // Listar todos
GET    /api/veterinarios/{id}/disponibilidad?fecha=2025-01-20  // Ver horarios y citas
```

## 🔥 Firebase Cloud Messaging

### Setup en Flutter
```dart
// 1. Inicializar
await Firebase.initializeApp();

// 2. Solicitar permisos
await FirebaseMessaging.instance.requestPermission();

// 3. Obtener token
String? fcmToken = await FirebaseMessaging.instance.getToken();

// 4. Enviar a backend
await http.post(
  Uri.parse('$baseUrl/api/fcm-token'),
  headers: {
    'Authorization': 'Bearer $sanctumToken',
    'Content-Type': 'application/json',
  },
  body: json.encode({
    'token': fcmToken,
    'device_type': Platform.isIOS ? 'ios' : 'android',
  }),
);

// 5. Escuchar notificaciones
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // App en foreground
  print('Notificación: ${message.notification?.title}');
});

FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Usuario tocó la notificación
  final tipo = message.data['tipo'];
  final citaId = message.data['cita_id'];
  // Navegar a la pantalla correspondiente
});
```

### Tipos de Notificaciones Push

| Tipo | Cuándo | Data |
|------|--------|------|
| `recordatorio_cita` | 24h antes | `cita_id`, `fecha_hora` |
| `cita_creada` | Al crear | `cita_id` |
| `cita_cancelada` | Al cancelar | `cita_id` |
| `resultado_disponible` | Al subir archivos | `historial_id`, `mascota_id` |

### Formato de Notificación
```dart
{
  "notification": {
    "title": "Recordatorio de cita",
    "body": "Tienes una cita mañana a las 10:00 AM"
  },
  "data": {
    "tipo": "recordatorio_cita",
    "cita_id": "5",
    "fecha_hora": "2025-01-20T10:00:00Z"
  }
}
```

## 📤 Subir Archivos

### Subir foto de mascota
```dart
var request = http.MultipartRequest(
  'POST',
  Uri.parse('$baseUrl/api/mascotas'),
);
request.headers['Authorization'] = 'Bearer $token';
request.fields['cliente_id'] = '1';
request.fields['nombre'] = 'Max';
request.fields['especie'] = 'perro';
request.files.add(
  await http.MultipartFile.fromPath('foto', photoPath)
);

var response = await request.send();
```

### Adjuntar archivos a historial
```dart
var request = http.MultipartRequest(
  'POST',
  Uri.parse('$baseUrl/api/historial-medico/$id/archivos'),
);
request.headers['Authorization'] = 'Bearer $token';

for (var file in files) {
  request.files.add(
    await http.MultipartFile.fromPath('archivos[]', file.path)
  );
}

await request.send();
```

## 🔒 Roles y Permisos

### Cliente
- ✅ Ver sus mascotas
- ✅ Agendar citas para sus mascotas
- ✅ Ver historial de sus mascotas
- ✅ Ver sus facturas
- ❌ No puede crear historial médico

### Veterinario
- ✅ Ver citas asignadas
- ✅ Crear historial médico
- ✅ Adjuntar archivos a historial
- ✅ Ver historial de cualquier mascota
- ✅ Configurar su disponibilidad

### Recepción
- ✅ Gestionar clientes
- ✅ Gestionar mascotas
- ✅ Agendar citas para cualquier cliente
- ✅ Generar facturas
- ✅ Ver todo

## ⚠️ Validaciones Importantes

### Al crear cita, el backend valida:
- ✅ La mascota pertenece al cliente (si es cliente quien crea)
- ✅ No hay solapamiento con otras citas del veterinario
- ✅ El veterinario tiene disponibilidad configurada para ese horario
- ✅ Calcula duración automáticamente sumando servicios
- ✅ Congela precios en tabla pivot

### Al eliminar:
- ❌ No se puede eliminar cliente si tiene mascotas
- ❌ No se puede eliminar mascota si tiene historial o citas
- ❌ No se puede eliminar veterinario si tiene citas
- ❌ No se puede eliminar servicio si está en citas

## 🎯 Flujo Típico

### 1. Usuario Cliente
```
1. Login → Guardar token
2. Enviar FCM token
3. Listar mis mascotas
4. Seleccionar mascota
5. Ver servicios disponibles
6. Ver disponibilidad del veterinario
7. Crear cita
8. Recibir notificación push 24h antes
```

### 2. Usuario Veterinario
```
1. Login → Guardar token
2. Ver mis citas del día
3. Atender cita (cambiar estado a "en_curso")
4. Crear registro de historial médico
5. Adjuntar fotos/documentos
6. Completar cita (cambiar estado a "completada")
7. Generar factura
```

## 🛠️ Dependencias Flutter Recomendadas

```yaml
dependencies:
  # HTTP
  http: ^1.1.0
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  firebase_messaging: ^14.7.9
  
  # Storage seguro
  flutter_secure_storage: ^9.0.0
  
  # State management
  provider: ^6.1.1
  
  # Notificaciones locales
  flutter_local_notifications: ^16.3.0
  
  # QR
  qr_flutter: ^4.1.0
  mobile_scanner: ^3.5.5
  
  # UI
  intl: ^0.18.1
  cached_network_image: ^3.3.1
  
  # File picker
  image_picker: ^1.0.7
  file_picker: ^6.1.1
```

## 📞 Soporte

Para más detalles, consultar `API_DOCUMENTATION.md` (documentación completa).

---

**Notas importantes:**
- Todos los endpoints (excepto `/auth/login`, `/auth/register`, `/qr/lookup`) requieren `Authorization: Bearer {token}`
- Las fechas están en formato ISO 8601 UTC
- La paginación por defecto es de 20 items
- Los archivos de storage están en: `http://api.com/storage/{ruta}`
