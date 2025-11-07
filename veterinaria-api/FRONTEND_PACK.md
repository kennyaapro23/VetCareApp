# 📦 PACK COMPLETO PARA EQUIPO FLUTTER
## Sistema de Gestión Veterinaria - Backend API

---

## 🎯 RESUMEN EJECUTIVO

**¿La API está lista?** ✅ **SÍ, 100% funcional**

- ✅ Servidor: `http://172.20.76.28:8000` (tu red WiFi)
- ✅ 11 controladores CRUD completos
- ✅ Autenticación Laravel Sanctum
- ✅ Firebase Cloud Messaging
- ✅ Filtros y búsquedas avanzadas
- ✅ Paginación en todos los endpoints
- ✅ Documentación completa

---

## 📱 CONFIGURACIÓN URLS

### Android Emulator:
```dart
const String baseUrl = 'http://10.0.2.2:8000/api';
```

### Dispositivo Real (mismo WiFi que el servidor):
```dart
const String baseUrl = 'http://172.20.76.28:8000/api';
```

### iOS Simulator:
```dart
const String baseUrl = 'http://localhost:8000/api';
```

---

## 🔐 USUARIOS DE PRUEBA

```
Cliente:
  email: cliente1@veterinaria.com
  password: password

Veterinario:
  email: vet1@veterinaria.com
  password: password

Admin:
  email: admin@veterinaria.com
  password: password
```

---

## 📚 ARCHIVOS DE DOCUMENTACIÓN (en el repositorio)

| Archivo | Descripción | Para quién |
|---------|-------------|------------|
| **README.md** | Inicio y visión general | Todos |
| **CONEXION_FLUTTER.md** | ⭐ Setup completo Flutter | Flutter devs (START HERE) |
| **FILTROS_GUIDE.md** | Filtros y búsquedas | Flutter devs |
| **FLUTTER_QUICK_START.md** | Guía rápida | Flutter devs |
| **FLUTTER_CODE_EXAMPLES.md** | Código listo para usar | Flutter devs |
| **API_DOCUMENTATION.md** | Referencia completa API (600+ líneas) | Todos los devs |
| **RESUMEN_EJECUTIVO.md** | Arquitectura y base de datos | Backend/PM |
| **INDEX.md** | Índice de toda la documentación | Navegación |

---

## 🚀 API SERVICE (COPIAR A FLUTTER)

```dart
// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ⚠️ CAMBIAR según tu dispositivo
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Emulator
  // static const String baseUrl = 'http://172.20.76.28:8000/api'; // Real device
  
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // GET Request
  Future<http.Response> get(String endpoint) async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    return await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
  }
  
  // POST Request
  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    return await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
  }
  
  // PUT Request
  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    return await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
  }
  
  // DELETE Request
  Future<http.Response> delete(String endpoint) async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    return await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
  }
  
  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await post('auth/login', {
      'email': email,
      'password': password,
    });
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await _saveToken(data['token']);
      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }
  
  // Register
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await post('auth/register', userData);
    
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      await _saveToken(data['token']);
      return data;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await post('auth/logout', {});
    } finally {
      await _removeToken();
    }
  }
  
  // Registrar FCM Token
  Future<void> registerFcmToken(String fcmToken, String deviceType) async {
    await post('fcm-token', {
      'token': fcmToken,
      'device_type': deviceType,
    });
  }
}
```

---

## 🎯 ENDPOINTS PRINCIPALES

### Autenticación (sin token)
```
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/logout (requiere token)
```

### Clientes
```
GET    /api/clientes              # Listar
POST   /api/clientes              # Crear
GET    /api/clientes/{id}         # Ver uno
PUT    /api/clientes/{id}         # Actualizar
DELETE /api/clientes/{id}         # Eliminar
GET    /api/clientes/{id}/qr      # Generar QR del cliente
```

### Mascotas
```
GET    /api/mascotas              # Listar (filtros: cliente_id, especie, search)
POST   /api/mascotas              # Crear (con foto)
GET    /api/mascotas/{id}         # Ver una
PUT    /api/mascotas/{id}         # Actualizar
DELETE /api/mascotas/{id}         # Eliminar
GET    /api/mascotas/{id}/qr      # Generar QR de la mascota
```

### Citas (con filtros avanzados)
```
GET    /api/citas                 # Listar
       ?veterinario_id=2
       &mascota_id=5
       &fecha=2025-01-20
       &fecha_desde=2025-01-01&fecha_hasta=2025-01-31
       &estado=programada
       &nombre_mascota=Max
       &nombre_cliente=Juan
       &nombre_veterinario=García
       &search=vacuna

POST   /api/citas                 # Crear
GET    /api/citas/{id}            # Ver una
PUT    /api/citas/{id}            # Actualizar
DELETE /api/citas/{id}            # Eliminar
```

### Historial Médico (con filtros avanzados)
```
GET    /api/historial-medico      # Listar
       ?mascota_id=5
       &veterinario_id=2
       &tipo=vacuna
       &fecha_desde=2025-01-01&fecha_hasta=2025-12-31
       &nombre_mascota=Max
       &nombre_cliente=Juan
       &search=alergia

POST   /api/historial-medico      # Crear
GET    /api/historial-medico/{id} # Ver uno
PUT    /api/historial-medico/{id} # Actualizar
DELETE /api/historial-medico/{id} # Eliminar
POST   /api/historial-medico/{id}/archivos  # Adjuntar archivos
```

### Notificaciones
```
GET    /api/notificaciones        # Listar (filtros: leida, tipo)
GET    /api/notificaciones/{id}   # Ver una
PUT    /api/notificaciones/{id}   # Marcar como leída
DELETE /api/notificaciones/{id}   # Eliminar
```

### Facturas
```
GET    /api/facturas              # Listar (filtros: estado, fecha_desde, fecha_hasta)
POST   /api/facturas              # Crear
GET    /api/facturas/{id}         # Ver una
PUT    /api/facturas/{id}         # Actualizar
DELETE /api/facturas/{id}         # Eliminar
GET    /api/facturas-estadisticas # Estadísticas
```

### Veterinarios
```
GET    /api/veterinarios          # Listar
POST   /api/veterinarios          # Crear
GET    /api/veterinarios/{id}     # Ver uno
PUT    /api/veterinarios/{id}     # Actualizar
DELETE /api/veterinarios/{id}     # Eliminar
GET    /api/veterinarios/{id}/disponibilidad    # Ver disponibilidad
POST   /api/veterinarios/{id}/disponibilidad    # Configurar horarios
```

### Servicios
```
GET    /api/servicios             # Listar (filtros: tipo, precio_min, precio_max, search)
POST   /api/servicios             # Crear
GET    /api/servicios/{id}        # Ver uno
PUT    /api/servicios/{id}        # Actualizar
DELETE /api/servicios/{id}        # Eliminar
```

### QR (público, sin autenticación)
```
GET    /api/qr/lookup/{uuid}      # Escanear QR y obtener info de mascota
```

### FCM Tokens
```
POST   /api/fcm-token             # Registrar token
DELETE /api/fcm-token             # Eliminar token del dispositivo actual
GET    /api/fcm-tokens            # Listar todos los tokens del usuario
DELETE /api/fcm-tokens/all        # Eliminar todos los tokens del usuario
```

---

## 📋 MODELOS DE DATOS (DART)

### User
```dart
class User {
  final int id;
  final String nombre;
  final String email;
  final String? telefono;
  final String rol; // 'admin', 'veterinario', 'cliente'
  
  User({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    required this.rol,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      telefono: json['telefono'],
      rol: json['rol'],
    );
  }
}
```

### Mascota
```dart
class Mascota {
  final int id;
  final String nombre;
  final String especie; // 'perro', 'gato', 'ave', 'reptil', 'otro'
  final String raza;
  final DateTime fechaNacimiento;
  final String? color;
  final double? peso;
  final String? foto;
  final String? qrUuid;
  final int clienteId;
  final Cliente? cliente; // Si viene con eager loading
  
  Mascota({
    required this.id,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.fechaNacimiento,
    this.color,
    this.peso,
    this.foto,
    this.qrUuid,
    required this.clienteId,
    this.cliente,
  });
  
  factory Mascota.fromJson(Map<String, dynamic> json) {
    return Mascota(
      id: json['id'],
      nombre: json['nombre'],
      especie: json['especie'],
      raza: json['raza'],
      fechaNacimiento: DateTime.parse(json['fecha_nacimiento']),
      color: json['color'],
      peso: json['peso'] != null ? double.parse(json['peso'].toString()) : null,
      foto: json['foto'],
      qrUuid: json['qr_uuid'],
      clienteId: json['cliente_id'],
      cliente: json['cliente'] != null ? Cliente.fromJson(json['cliente']) : null,
    );
  }
}
```

### Cita
```dart
class Cita {
  final int id;
  final DateTime fecha;
  final String hora;
  final String motivo;
  final String estado; // 'programada', 'confirmada', 'en_curso', 'completada', 'cancelada'
  final String? notas;
  final int veterinarioId;
  final int clienteId;
  final int mascotaId;
  final Veterinario? veterinario;
  final Cliente? cliente;
  final Mascota? mascota;
  
  Cita({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.motivo,
    required this.estado,
    this.notas,
    required this.veterinarioId,
    required this.clienteId,
    required this.mascotaId,
    this.veterinario,
    this.cliente,
    this.mascota,
  });
  
  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      hora: json['hora'],
      motivo: json['motivo'],
      estado: json['estado'],
      notas: json['notas'],
      veterinarioId: json['veterinario_id'],
      clienteId: json['cliente_id'],
      mascotaId: json['mascota_id'],
      veterinario: json['veterinario'] != null 
          ? Veterinario.fromJson(json['veterinario']) 
          : null,
      cliente: json['cliente'] != null 
          ? Cliente.fromJson(json['cliente']) 
          : null,
      mascota: json['mascota'] != null 
          ? Mascota.fromJson(json['mascota']) 
          : null,
    );
  }
}
```

### HistorialMedico
```dart
class HistorialMedico {
  final int id;
  final DateTime fecha;
  final String tipo; // 'consulta', 'vacuna', 'procedimiento', 'control', 'otro'
  final String? diagnostico;
  final String? tratamiento;
  final String? observaciones;
  final double? peso;
  final double? temperatura;
  final int mascotaId;
  final int veterinarioId;
  final Mascota? mascota;
  final Veterinario? veterinario;
  
  HistorialMedico({
    required this.id,
    required this.fecha,
    required this.tipo,
    this.diagnostico,
    this.tratamiento,
    this.observaciones,
    this.peso,
    this.temperatura,
    required this.mascotaId,
    required this.veterinarioId,
    this.mascota,
    this.veterinario,
  });
  
  factory HistorialMedico.fromJson(Map<String, dynamic> json) {
    return HistorialMedico(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      tipo: json['tipo'],
      diagnostico: json['diagnostico'],
      tratamiento: json['tratamiento'],
      observaciones: json['observaciones'],
      peso: json['peso'] != null ? double.parse(json['peso'].toString()) : null,
      temperatura: json['temperatura'] != null 
          ? double.parse(json['temperatura'].toString()) 
          : null,
      mascotaId: json['mascota_id'],
      veterinarioId: json['veterinario_id'],
      mascota: json['mascota'] != null 
          ? Mascota.fromJson(json['mascota']) 
          : null,
      veterinario: json['veterinario'] != null 
          ? Veterinario.fromJson(json['veterinario']) 
          : null,
    );
  }
}
```

---

## 🔥 FIREBASE CLOUD MESSAGING

### Setup en Flutter

1. **Crear proyecto Firebase**: https://console.firebase.google.com/
2. **Agregar app Android/iOS**
3. **Descargar archivos**:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`

### Dependencias
```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
```

### Código de inicialización
```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Mensaje en background: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _api = ApiService();
  
  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }
  
  Future<void> _setupFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;
    
    // Pedir permisos
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Obtener token FCM
    final fcmToken = await messaging.getToken();
    print('FCM Token: $fcmToken');
    
    if (fcmToken != null) {
      try {
        await _api.registerFcmToken(fcmToken, 'android'); // o 'ios'
        print('✅ Token registrado en backend');
      } catch (e) {
        print('❌ Error: $e');
      }
    }
    
    // Escuchar mensajes en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje: ${message.notification?.title}');
      
      if (message.notification != null) {
        // Mostrar notificación local o actualizar UI
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veterinaria App',
      home: LoginScreen(),
    );
  }
}
```

### Tipos de Notificaciones Push
- `recordatorio_cita` - Recordatorio 1 día antes
- `cita_creada` - Nueva cita agendada
- `cita_cancelada` - Cita cancelada
- `cita_modificada` - Cita modificada
- `vacuna_proxima` - Vacuna próxima a vencer
- `resultado_disponible` - Resultado médico disponible
- `mensaje_veterinario` - Mensaje del veterinario
- `otro` - Otras notificaciones

---

## 🧪 TEST DE CONEXIÓN

### 1. Login Test
```dart
void testLogin() async {
  final api = ApiService();
  
  try {
    final data = await api.login('cliente1@veterinaria.com', 'password');
    print('✅ Login exitoso');
    print('Token: ${data['token']}');
    print('Usuario: ${data['user']['nombre']}');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

### 2. Get Mascotas Test
```dart
void testGetMascotas() async {
  final api = ApiService();
  
  // Primero login
  await api.login('cliente1@veterinaria.com', 'password');
  
  try {
    final response = await api.get('mascotas');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Mascotas obtenidas: ${data['data'].length}');
      
      for (var mascota in data['data']) {
        print('- ${mascota['nombre']} (${mascota['especie']})');
      }
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

### 3. Crear Cita Test
```dart
void testCrearCita() async {
  final api = ApiService();
  
  await api.login('cliente1@veterinaria.com', 'password');
  
  try {
    final response = await api.post('citas', {
      'veterinario_id': 1,
      'cliente_id': 1,
      'mascota_id': 1,
      'fecha': '2025-01-20',
      'hora': '10:00',
      'motivo': 'Vacunación anual',
      'estado': 'programada',
    });
    
    if (response.statusCode == 201) {
      print('✅ Cita creada exitosamente');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

---

## 🐛 DEBUGGING

### Error: "Connection refused"
**Causa**: URL incorrecta para el dispositivo

**Solución**:
```dart
// ✅ Android Emulator
const String baseUrl = 'http://10.0.2.2:8000/api';

// ❌ NO uses en emulador:
// const String baseUrl = 'http://localhost:8000/api';
// const String baseUrl = 'http://127.0.0.1:8000/api';
```

### Error: "Unauthenticated" (401)
**Causa**: Token no incluido o expirado

**Verificar**:
1. Token guardado en SharedPreferences
2. Header `Authorization: Bearer {token}` presente
3. Login exitoso antes de hacer peticiones

### Error: No se reciben notificaciones push
**Verificar**:
1. Firebase project creado
2. `google-services.json` en lugar correcto
3. FCM token registrado en backend
4. Permisos de notificaciones otorgados
5. `FIREBASE_SERVER_KEY` en Laravel `.env`

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

### Backend (Listo ✅)
- [x] Servidor corriendo
- [x] Base de datos configurada
- [x] Migraciones ejecutadas
- [x] Seeders con datos de prueba
- [x] Autenticación Sanctum
- [x] 11 controladores CRUD
- [x] Filtros implementados
- [x] FCM configurado
- [x] Documentación completa

### Frontend (Por hacer)
- [ ] Proyecto Flutter creado
- [ ] Dependencias instaladas (`http`, `shared_preferences`, `firebase_core`, `firebase_messaging`)
- [ ] ApiService implementado
- [ ] baseUrl configurada según dispositivo
- [ ] Login screen
- [ ] Test de conexión exitoso
- [ ] Firebase configurado
- [ ] FCM token registrado
- [ ] Pantallas principales (Mascotas, Citas, Historial)
- [ ] Filtros implementados
- [ ] Notificaciones push funcionando

---

## 📞 CONTACTO Y SOPORTE

### Archivos de referencia en el repositorio:
1. `README.md` - Inicio
2. `CONEXION_FLUTTER.md` - Guía completa de setup
3. `FILTROS_GUIDE.md` - Filtros y búsquedas
4. `FLUTTER_CODE_EXAMPLES.md` - Más ejemplos de código
5. `API_DOCUMENTATION.md` - Referencia completa (600+ líneas)

### Servidor de desarrollo:
```
URL: http://172.20.76.28:8000
Status: ✅ Corriendo
```

---

## 🎉 ¡TODO LISTO PARA DESARROLLAR!

Este archivo contiene TODO lo necesario para empezar con Flutter:
- ✅ URLs configuradas
- ✅ ApiService completo
- ✅ Modelos Dart
- ✅ Ejemplos de uso
- ✅ Setup Firebase
- ✅ Debugging tips
- ✅ Checklist

**¡Empieza a construir la app!** 🚀
