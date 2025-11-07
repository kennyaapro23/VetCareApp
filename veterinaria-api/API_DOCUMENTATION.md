# 🐾 API Veterinaria - Documentación para Flutter

> Sistema completo de gestión veterinaria con autenticación Laravel Sanctum + Firebase y notificaciones push FCM.

## 📋 Tabla de Contenidos

- [Información General](#información-general)
- [Configuración Firebase](#configuración-firebase)
- [Autenticación](#autenticación)
- [Modelos de Datos](#modelos-de-datos)
- [Endpoints](#endpoints)
- [Flujos de Negocio](#flujos-de-negocio)
- [Códigos QR](#códigos-qr)
- [Notificaciones Push](#notificaciones-push)
- [Ejemplos Flutter](#ejemplos-flutter)

---

## 🔧 Información General

### Base URL
```
http://tu-dominio.com/api
```

### Autenticación
- **Método**: Laravel Sanctum (Bearer Token)
- **Header requerido**: `Authorization: Bearer {token}`
- **Firebase**: Para autenticación social y notificaciones push

### Roles de Usuario
- `cliente`: Dueños de mascotas
- `veterinario`: Médicos veterinarios
- `recepcion`: Personal administrativo
- `admin`: Administrador del sistema

---

## 🔥 Configuración Firebase

### 1. Proyecto Firebase
1. Crear proyecto en [Firebase Console](https://console.firebase.google.com)
2. Habilitar **Authentication** (Email/Password, Google, etc.)
3. Habilitar **Cloud Messaging** (FCM)
4. Descargar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)

### 2. Flutter Setup
```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  firebase_messaging: ^14.7.9
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0
```

### 3. Inicializar Firebase
```dart
// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

### 4. Enviar FCM Token al Backend
Después de login exitoso, enviar el token de Firebase:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> sendFCMToken() async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  
  // Enviar a tu API
  await http.post(
    Uri.parse('$baseUrl/api/fcm-token'),
    headers: {
      'Authorization': 'Bearer $yourSanctumToken',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'token': fcmToken,
      'device_type': Platform.isIOS ? 'ios' : 'android',
      'device_name': 'Flutter App',
    }),
  );
}
```

---

## 🔐 Autenticación

### Flujo de Autenticación Recomendado

#### Opción 1: Firebase + Laravel (Recomendado)
```dart
// 1. Login con Firebase
UserCredential credential = await FirebaseAuth.instance
    .signInWithEmailAndPassword(email: email, password: password);

// 2. Obtener ID Token de Firebase
String? firebaseToken = await credential.user?.getIdToken();

// 3. Validar con tu Laravel API y obtener Sanctum token
final response = await http.post(
  Uri.parse('$baseUrl/api/auth/firebase-login'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'firebase_token': firebaseToken,
    'email': email,
  }),
);

// 4. Guardar Sanctum token
final data = json.decode(response.body);
String sanctumToken = data['token'];
```

#### Opción 2: Solo Laravel Sanctum
```dart
// Login tradicional
final response = await http.post(
  Uri.parse('$baseUrl/api/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'email': 'cliente@example.com',
    'password': 'password123',
  }),
);

final data = json.decode(response.body);
String token = data['token'];
String role = data['user']['roles'][0]['name'];
```

### Endpoints de Autenticación

#### POST `/api/auth/register`
Registro de nuevo usuario.

**Request:**
```json
{
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "telefono": "+52 123 456 7890",
  "role": "cliente"
}
```

**Response:**
```json
{
  "message": "Usuario registrado exitosamente",
  "user": {
    "id": 1,
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "telefono": "+52 123 456 7890",
    "tipo_usuario": "cliente",
    "roles": [{"name": "cliente"}]
  },
  "token": "1|abcd1234tokenlaravel..."
}
```

#### POST `/api/auth/login`
Login con email/password.

**Request:**
```json
{
  "email": "juan@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "token": "2|xyz5678token...",
  "user": {
    "id": 1,
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "roles": [{"name": "cliente"}]
  }
}
```

#### POST `/api/auth/logout`
Cerrar sesión (requiere token).

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "message": "Sesión cerrada exitosamente"
}
```

#### POST `/api/fcm-token`
Guardar token FCM para notificaciones push.

**Request:**
```json
{
  "token": "firebase_fcm_token_aqui...",
  "device_type": "android",
  "device_name": "Samsung Galaxy S21"
}
```

---

## 📊 Modelos de Datos

### User (Usuario)
```dart
class User {
  final int id;
  final String name;
  final String email;
  final String? telefono;
  final String tipoUsuario; // 'cliente', 'veterinario', 'recepcion', 'admin'
  final Map<String, dynamic>? perfil;
  final List<Role> roles;

  User.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      name = json['name'],
      email = json['email'],
      telefono = json['telefono'],
      tipoUsuario = json['tipo_usuario'],
      perfil = json['perfil'],
      roles = (json['roles'] as List).map((r) => Role.fromJson(r)).toList();
}
```

### Cliente
```dart
class Cliente {
  final int id;
  final int? userId;
  final String nombre;
  final String email;
  final String telefono;
  final String? direccion;
  final String publicId; // UUID para QR
  final DateTime createdAt;

  Cliente.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      userId = json['user_id'],
      nombre = json['nombre'],
      email = json['email'],
      telefono = json['telefono'],
      direccion = json['direccion'],
      publicId = json['public_id'],
      createdAt = DateTime.parse(json['created_at']);
}
```

### Mascota
```dart
class Mascota {
  final int id;
  final int clienteId;
  final String nombre;
  final String especie; // 'perro', 'gato', 'ave', 'reptil', 'otro'
  final String? raza;
  final DateTime? fechaNacimiento;
  final String? edad; // Calculado automáticamente (ej: "2 años, 3 meses")
  final String sexo; // 'macho', 'hembra'
  final double? peso;
  final String? color;
  final String? chipId;
  final String? foto; // URL de la foto
  final String publicId; // UUID para QR
  final DateTime createdAt;

  Mascota.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      clienteId = json['cliente_id'],
      nombre = json['nombre'],
      especie = json['especie'],
      raza = json['raza'],
      fechaNacimiento = json['fecha_nacimiento'] != null 
          ? DateTime.parse(json['fecha_nacimiento']) 
          : null,
      edad = json['edad'],
      sexo = json['sexo'],
      peso = json['peso']?.toDouble(),
      color = json['color'],
      chipId = json['chip_id'],
      foto = json['foto'],
      publicId = json['public_id'],
      createdAt = DateTime.parse(json['created_at']);
}
```

### Veterinario
```dart
class Veterinario {
  final int id;
  final int? userId;
  final String nombre;
  final String email;
  final String telefono;
  final String? cedulaProfesional;
  final String? especialidad;
  final DateTime createdAt;

  Veterinario.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      userId = json['user_id'],
      nombre = json['nombre'],
      email = json['email'],
      telefono = json['telefono'],
      cedulaProfesional = json['cedula_profesional'],
      especialidad = json['especialidad'],
      createdAt = DateTime.parse(json['created_at']);
}
```

### Servicio
```dart
class Servicio {
  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final String tipo; // 'vacuna', 'tratamiento', 'baño', 'consulta', 'cirugía', 'otro'
  final int duracionMinutos;
  final double precio;
  final bool requiereVacunaInfo;

  bool get esVacuna => tipo == 'vacuna';

  Servicio.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      codigo = json['codigo'],
      nombre = json['nombre'],
      descripcion = json['descripcion'],
      tipo = json['tipo'],
      duracionMinutos = json['duracion_minutos'],
      precio = json['precio'].toDouble(),
      requiereVacunaInfo = json['requiere_vacuna_info'] ?? false;
}
```

### Cita
```dart
class Cita {
  final int id;
  final int mascotaId;
  final int veterinarioId;
  final DateTime fechaHora;
  final int duracionMinutos;
  final String estado; // 'programada', 'confirmada', 'en_curso', 'completada', 'cancelada'
  final String? motivoConsulta;
  final String? observaciones;
  final List<Servicio> servicios;
  final Mascota? mascota;
  final Veterinario? veterinario;

  Cita.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      mascotaId = json['mascota_id'],
      veterinarioId = json['veterinario_id'],
      fechaHora = DateTime.parse(json['fecha_hora']),
      duracionMinutos = json['duracion_minutos'],
      estado = json['estado'],
      motivoConsulta = json['motivo_consulta'],
      observaciones = json['observaciones'],
      servicios = json['servicios'] != null
          ? (json['servicios'] as List).map((s) => Servicio.fromJson(s)).toList()
          : [],
      mascota = json['mascota'] != null ? Mascota.fromJson(json['mascota']) : null,
      veterinario = json['veterinario'] != null ? Veterinario.fromJson(json['veterinario']) : null;
}
```

### HistorialMedico
```dart
class HistorialMedico {
  final int id;
  final int mascotaId;
  final int veterinarioId;
  final DateTime fecha;
  final String motivoConsulta;
  final String? diagnostico;
  final String? tratamiento;
  final String? observaciones;
  final double? peso;
  final double? temperatura;
  final List<Archivo> archivos;

  HistorialMedico.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      mascotaId = json['mascota_id'],
      veterinarioId = json['veterinario_id'],
      fecha = DateTime.parse(json['fecha']),
      motivoConsulta = json['motivo_consulta'],
      diagnostico = json['diagnostico'],
      tratamiento = json['tratamiento'],
      observaciones = json['observaciones'],
      peso = json['peso']?.toDouble(),
      temperatura = json['temperatura']?.toDouble(),
      archivos = json['archivos'] != null
          ? (json['archivos'] as List).map((a) => Archivo.fromJson(a)).toList()
          : [];
}
```

### Notificacion
```dart
class Notificacion {
  final int id;
  final int userId;
  final String tipo; // 'recordatorio_cita', 'cita_creada', 'cita_cancelada', etc.
  final String titulo;
  final String mensaje;
  final Map<String, dynamic>? data;
  final bool leida;
  final DateTime? fechaLectura;
  final DateTime createdAt;

  Notificacion.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      userId = json['user_id'],
      tipo = json['tipo'],
      titulo = json['titulo'],
      mensaje = json['mensaje'],
      data = json['data'],
      leida = json['leida'],
      fechaLectura = json['fecha_lectura'] != null 
          ? DateTime.parse(json['fecha_lectura']) 
          : null,
      createdAt = DateTime.parse(json['created_at']);
}
```

### Factura
```dart
class Factura {
  final int id;
  final int citaId;
  final String numeroFactura;
  final DateTime fechaEmision;
  final double subtotal;
  final double impuestos;
  final double total;
  final String estado; // 'pendiente', 'pagado', 'anulado'
  final String? metodoPago; // 'efectivo', 'tarjeta', 'transferencia', 'otro'
  final DateTime? fechaPago;
  final Cita? cita;

  Factura.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      citaId = json['cita_id'],
      numeroFactura = json['numero_factura'],
      fechaEmision = DateTime.parse(json['fecha_emision']),
      subtotal = json['subtotal'].toDouble(),
      impuestos = json['impuestos'].toDouble(),
      total = json['total'].toDouble(),
      estado = json['estado'],
      metodoPago = json['metodo_pago'],
      fechaPago = json['fecha_pago'] != null 
          ? DateTime.parse(json['fecha_pago']) 
          : null,
      cita = json['cita'] != null ? Cita.fromJson(json['cita']) : null;
}
```

---

## 🌐 Endpoints

Todos los endpoints (excepto auth y QR lookup) requieren:
```
Authorization: Bearer {token}
```

### 👤 Clientes

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/clientes` | Listar clientes (con paginación y búsqueda) |
| GET | `/api/clientes/{id}` | Ver detalle con mascotas, citas y facturas |
| POST | `/api/clientes` | Crear cliente |
| PUT | `/api/clientes/{id}` | Actualizar cliente |
| DELETE | `/api/clientes/{id}` | Eliminar cliente |

### 🐕 Mascotas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/mascotas` | Listar mascotas (filtros: cliente_id, especie, search) |
| GET | `/api/mascotas/{id}` | Ver detalle con historial y citas |
| POST | `/api/mascotas` | Crear mascota (multipart/form-data para foto) |
| PUT | `/api/mascotas/{id}` | Actualizar mascota |
| DELETE | `/api/mascotas/{id}` | Eliminar mascota |
| GET | `/api/mascotas/{id}/qr` | Generar código QR |

### 👨‍⚕️ Veterinarios

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/veterinarios` | Listar veterinarios |
| GET | `/api/veterinarios/{id}` | Ver detalle |
| POST | `/api/veterinarios` | Crear veterinario |
| PUT | `/api/veterinarios/{id}` | Actualizar veterinario |
| DELETE | `/api/veterinarios/{id}` | Eliminar veterinario |
| GET | `/api/veterinarios/{id}/disponibilidad?fecha=YYYY-MM-DD` | Ver horarios y citas |
| POST | `/api/veterinarios/{id}/disponibilidad` | Configurar horarios semanales |

### 🩺 Servicios

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/servicios` | Listar servicios (filtros: tipo, search, precio) |
| GET | `/api/servicios/{id}` | Ver detalle |
| POST | `/api/servicios` | Crear servicio |
| PUT | `/api/servicios/{id}` | Actualizar servicio |
| DELETE | `/api/servicios/{id}` | Eliminar servicio |
| GET | `/api/servicios-tipos` | Tipos de servicios disponibles |

### 📅 Citas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/citas` | Listar citas según rol (filtros: mascota_id, veterinario_id, estado, fecha) |
| GET | `/api/citas/{id}` | Ver detalle |
| POST | `/api/citas` | Crear cita (valida disponibilidad, calcula duración) |
| PUT | `/api/citas/{id}` | Actualizar cita |
| DELETE | `/api/citas/{id}` | Cancelar cita |

### 📋 Historial Médico

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/historial-medico?mascota_id={id}` | Listar historial de mascota |
| POST | `/api/historial-medico` | Crear registro (solo veterinarios) |
| GET | `/api/historial-medico/{id}` | Ver detalle |
| POST | `/api/historial-medico/{id}/archivos` | Adjuntar archivos (multipart) |

### 🔔 Notificaciones

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/notificaciones` | Listar notificaciones (filtros: leida, tipo) |
| GET | `/api/notificaciones/{id}` | Ver detalle (marca como leída automáticamente) |
| POST | `/api/notificaciones/{id}/mark-read` | Marcar como leída |
| POST | `/api/notificaciones/mark-all-read` | Marcar todas como leídas |
| GET | `/api/notificaciones/unread-count?by_type=true` | Contador para badge |
| DELETE | `/api/notificaciones/{id}` | Eliminar notificación |
| DELETE | `/api/notificaciones/delete-read` | Eliminar todas las leídas |
| GET | `/api/notificaciones/tipos` | Tipos disponibles |

### 💰 Facturas

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/facturas` | Listar facturas (filtros: estado, fechas, numero_factura) |
| GET | `/api/facturas/{id}` | Ver detalle |
| POST | `/api/facturas` | Crear desde cita (calcula impuestos automáticamente) |
| PUT | `/api/facturas/{id}` | Actualizar estado |
| DELETE | `/api/facturas/{id}` | Eliminar (solo pendientes) |
| GET | `/api/generar-numero-factura` | Generar número secuencial |
| GET | `/api/facturas-estadisticas?fecha_desde=&fecha_hasta=` | Dashboard de facturación |

### 📱 QR (Sin autenticación)

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/qr/lookup/{uuid}` | Buscar mascota/cliente por UUID |

---

## 🔄 Flujos de Negocio

### 1. Registro y Login (Cliente)

```dart
// 1. Registro
final response = await http.post(
  Uri.parse('$baseUrl/api/auth/register'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'name': 'Juan Pérez',
    'email': 'juan@example.com',
    'password': 'password123',
    'password_confirmation': 'password123',
    'telefono': '+52 123 456 7890',
    'role': 'cliente',
  }),
);

// 2. Guardar token
String token = json.decode(response.body)['token'];
await FlutterSecureStorage().write(key: 'token', value: token);

// 3. Enviar FCM token
final fcmToken = await FirebaseMessaging.instance.getToken();
await http.post(
  Uri.parse('$baseUrl/api/fcm-token'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: json.encode({
    'token': fcmToken,
    'device_type': Platform.isIOS ? 'ios' : 'android',
  }),
);
```

### 2. Agendar Cita

```dart
// 1. Seleccionar servicios
final servicios = await getServicios();

// 2. Ver disponibilidad del veterinario
final dispResponse = await http.get(
  Uri.parse('$baseUrl/api/veterinarios/1/disponibilidad?fecha=2025-01-20'),
  headers: {'Authorization': 'Bearer $token'},
);

// 3. Crear la cita
final citaResponse = await http.post(
  Uri.parse('$baseUrl/api/citas'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: json.encode({
    'mascota_id': 1,
    'veterinario_id': 1,
    'fecha_hora': '2025-01-20T10:00:00Z',
    'motivo_consulta': 'Vacunación anual',
    'servicio_ids': [2, 5],
  }),
);

// El backend automáticamente:
// ✅ Valida disponibilidad (sin solapamientos)
// ✅ Calcula duración sumando servicios
// ✅ Congela precios en tabla pivot
// ✅ Crea notificación para el cliente
// ✅ Registra en audit log
```

### 3. Registrar Consulta (Veterinario)

```dart
// 1. Crear registro de historial
final historialResponse = await http.post(
  Uri.parse('$baseUrl/api/historial-medico'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: json.encode({
    'mascota_id': 1,
    'fecha': DateTime.now().toIso8601String(),
    'motivo_consulta': 'Vacunación',
    'diagnostico': 'Animal sano',
    'tratamiento': 'Vacuna antirrábica',
    'peso': 30.5,
    'temperatura': 38.5,
  }),
);

int historialId = json.decode(historialResponse.body)['historial']['id'];

// 2. Adjuntar archivos (opcional)
var request = http.MultipartRequest(
  'POST',
  Uri.parse('$baseUrl/api/historial-medico/$historialId/archivos'),
);
request.headers['Authorization'] = 'Bearer $token';
for (var file in files) {
  request.files.add(await http.MultipartFile.fromPath('archivos[]', file.path));
}
await request.send();

// 3. Actualizar cita a "completada"
await http.put(
  Uri.parse('$baseUrl/api/citas/$citaId'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: json.encode({'estado': 'completada'}),
);

// 4. Generar factura
await http.post(
  Uri.parse('$baseUrl/api/facturas'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: json.encode({
    'cita_id': citaId,
    'numero_factura': 'FAC-2025-00001',
    'metodo_pago': 'efectivo',
  }),
);
```

### 4. Escanear QR de Mascota

```dart
// 1. Escanear QR y obtener UUID
String uuid = await BarcodeScanner.scan();

// 2. Buscar en la API (sin autenticación requerida)
final response = await http.get(
  Uri.parse('$baseUrl/api/qr/lookup/$uuid'),
);

// 3. Mostrar información
if (response.statusCode == 200) {
  final data = json.decode(response.body);
  if (data['tipo'] == 'mascota') {
    final mascota = data['data'];
    print('Nombre: ${mascota['nombre']}');
    print('Dueño: ${mascota['cliente']['nombre']}');
    print('Teléfono: ${mascota['cliente']['telefono']}');
  }
}
```

---

## 🔥 Notificaciones Push (Firebase Cloud Messaging)

### Configuración FCM en Flutter

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Solicitar permisos
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Obtener token FCM
      String? token = await _fcm.getToken();
      
      // 3. Enviar a backend
      await sendTokenToBackend(token!);
      
      // 4. Escuchar actualizaciones del token
      _fcm.onTokenRefresh.listen(sendTokenToBackend);
      
      // 5. Configurar listeners
      setupInteractions();
    }
  }

  void setupInteractions() {
    // App en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notificación en foreground: ${message.notification?.title}');
      showLocalNotification(message);
    });

    // App en background - usuario toca notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationTap(message);
    });

    // App cerrada - usuario toca notificación
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        handleNotificationTap(message);
      }
    });
  }

  Future<void> sendTokenToBackend(String token) async {
    await http.post(
      Uri.parse('$baseUrl/api/fcm-token'),
      headers: {
        'Authorization': 'Bearer $sanctumToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'token': token,
        'device_type': Platform.isIOS ? 'ios' : 'android',
        'device_name': 'Mi Dispositivo',
      }),
    );
  }

  void handleNotificationTap(RemoteMessage message) {
    final tipo = message.data['tipo'];
    
    switch (tipo) {
      case 'recordatorio_cita':
        final citaId = message.data['cita_id'];
        navigatorKey.currentState?.pushNamed('/cita/$citaId');
        break;
      
      case 'resultado_disponible':
        final historialId = message.data['historial_id'];
        navigatorKey.currentState?.pushNamed('/historial/$historialId');
        break;
      
      default:
        navigatorKey.currentState?.pushNamed('/notificaciones');
    }
  }
}
```

### Tipos de Notificaciones Push

| Tipo | Cuándo se envía | Data incluida |
|------|----------------|---------------|
| `recordatorio_cita` | 24 horas antes de la cita | `cita_id`, `fecha_hora` |
| `cita_creada` | Al crear una cita | `cita_id` |
| `cita_cancelada` | Al cancelar una cita | `cita_id` |
| `cita_modificada` | Al reprogramar una cita | `cita_id`, `nueva_fecha` |
| `resultado_disponible` | Al agregar archivos a historial | `historial_id`, `mascota_id` |
| `vacuna_proxima` | 30 días antes de vencimiento | `mascota_id`, `vacuna` |

### Formato de Notificación

```json
{
  "notification": {
    "title": "Recordatorio de cita",
    "body": "Tienes una cita mañana a las 10:00 AM con el Dr. García"
  },
  "data": {
    "tipo": "recordatorio_cita",
    "cita_id": "5",
    "mascota_id": "1",
    "fecha_hora": "2025-01-20T10:00:00Z"
  }
}
```

---

## 📱 Ejemplos Flutter Completos

### ApiService (api_service.dart)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://tu-dominio.com/api';
  final storage = FlutterSecureStorage();

  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await storage.write(key: 'token', value: data['token']);
      return data;
    } else {
      throw Exception('Error en login');
    }
  }

  Future<List<Mascota>> getMascotas() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/mascotas'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .map((json) => Mascota.fromJson(json))
          .toList();
    } else {
      throw Exception('Error al obtener mascotas');
    }
  }

  Future<int> getUnreadCount() async {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/notificaciones/unread-count'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['total'];
    }
    return 0;
  }
}
```

### NotificationProvider

```dart
import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService api = ApiService();
  int unreadCount = 0;

  Future<void> loadUnreadCount() async {
    unreadCount = await api.getUnreadCount();
    notifyListeners();
  }

  Future<void> markAsRead(int notificationId) async {
    final headers = await api.getHeaders();
    await http.post(
      Uri.parse('${ApiService.baseUrl}/notificaciones/$notificationId/mark-read'),
      headers: headers,
    );
    
    unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    final headers = await api.getHeaders();
    await http.post(
      Uri.parse('${ApiService.baseUrl}/notificaciones/mark-all-read'),
      headers: headers,
    );
    
    unreadCount = 0;
    notifyListeners();
  }
}
```

---

## 🛡️ Validaciones Automáticas del Backend

### Al crear/actualizar cita:
- ✅ Verifica que la mascota pertenece al cliente autenticado
- ✅ Detecta solapamientos con otras citas del veterinario
- ✅ Calcula duración total sumando todos los servicios
- ✅ Congela precios actuales en tabla pivot `cita_servicio`
- ✅ Crea notificación automática para el cliente
- ✅ Registra operación en `audit_logs`

### Al crear factura:
- ✅ Verifica que la cita no tenga factura previa
- ✅ Calcula subtotal desde precios congelados
- ✅ Calcula impuestos (16% IVA)
- ✅ Calcula total automáticamente

### Al eliminar:
- ✅ Cliente: No permite si tiene mascotas
- ✅ Mascota: No permite si tiene historial o citas
- ✅ Veterinario: No permite si tiene citas
- ✅ Servicio: No permite si está en citas

---

## 🚀 Job Automático

### Recordatorios de Citas

El sistema ejecuta **diariamente a las 08:00 AM** un job que:

1. Busca citas programadas en las próximas 24 horas
2. Crea notificación en base de datos
3. Envía push notification vía FCM
4. Envía email de respaldo si FCM falla

**Comando manual:**
```bash
php artisan citas:enviar-recordatorios
```

---

## 📞 Contacto y Soporte

- **Backend**: Laravel 11 + MySQL
- **Autenticación**: Laravel Sanctum + Firebase Auth
- **Notificaciones**: Firebase Cloud Messaging (FCM)
- **Storage**: Laravel Storage (fotos mascotas, archivos historial)
- **Roles**: Spatie Laravel Permission

---

## 📄 Licencia

Este proyecto es privado. Todos los derechos reservados.
