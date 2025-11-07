# 🎯 Ejemplos de Código Flutter - Copy & Paste

## 📦 Configuración Inicial

### pubspec.yaml
```yaml
name: veterinaria_app
description: App móvil para gestión veterinaria

dependencies:
  flutter:
    sdk: flutter
    
  # HTTP & API
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
  
  # UI Utils
  intl: ^0.18.1
  cached_network_image: ^3.3.1
  
  # File picker
  image_picker: ^1.0.7
  file_picker: ^6.1.1
```

## 🔧 Servicios Base

### api_service.dart
```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://tu-dominio.com/api';
  final storage = const FlutterSecureStorage();

  // Obtener token guardado
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  // Guardar token
  Future<void> saveToken(String token) async {
    await storage.write(key: 'token', value: token);
  }

  // Eliminar token
  Future<void> deleteToken() async {
    await storage.delete(key: 'token');
  }

  // Headers con autenticación
  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await saveToken(data['token']);
      return data;
    } else {
      throw Exception('Error en login: ${response.body}');
    }
  }

  // REGISTER
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String telefono,
    String role = 'cliente',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'telefono': telefono,
        'role': role,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      await saveToken(data['token']);
      return data;
    } else {
      throw Exception('Error en registro: ${response.body}');
    }
  }

  // LOGOUT
  Future<void> logout() async {
    final headers = await getHeaders();
    await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: headers,
    );
    await deleteToken();
  }

  // GET genérico
  Future<http.Response> get(String endpoint) async {
    final headers = await getHeaders();
    return await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
  }

  // POST genérico
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    return await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(body),
    );
  }

  // PUT genérico
  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    return await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(body),
    );
  }

  // DELETE genérico
  Future<http.Response> delete(String endpoint) async {
    final headers = await getHeaders();
    return await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
  }

  // MULTIPART para archivos
  Future<http.StreamedResponse> uploadFile({
    required String endpoint,
    required Map<String, String> fields,
    required List<String> filePaths,
    String fileFieldName = 'foto',
  }) async {
    final token = await getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/$endpoint'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);

    for (var filePath in filePaths) {
      request.files.add(
        await http.MultipartFile.fromPath(fileFieldName, filePath),
      );
    }

    return await request.send();
  }
}
```

### fcm_service.dart
```dart
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

// Handler para notificaciones en background
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiService _api = ApiService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Inicializar notificaciones locales
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Manejar tap en notificación local
        print('Local notification tapped: ${details.payload}');
      },
    );

    // Solicitar permisos
    NotificationSettings permissions = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (permissions.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permisos de notificaciones concedidos');

      // Obtener token FCM
      String? token = await _fcm.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _sendTokenToBackend(token);
      }

      // Escuchar actualizaciones del token
      _fcm.onTokenRefresh.listen(_sendTokenToBackend);

      // Configurar listeners
      _setupMessageHandlers();
    } else {
      print('❌ Permisos de notificaciones denegados');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await _api.post('fcm-token', {
        'token': token,
        'device_type': Platform.isIOS ? 'ios' : 'android',
        'device_name': Platform.operatingSystem,
      });
      print('✅ FCM token enviado al backend');
    } catch (e) {
      print('❌ Error al enviar FCM token: $e');
    }
  }

  void _setupMessageHandlers() {
    // App en FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Notificación en foreground');
      _showLocalNotification(message);
    });

    // App en BACKGROUND - usuario toca notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 Usuario tocó notificación (app en background)');
      _handleNotificationTap(message);
    });

    // App CERRADA - usuario toca notificación
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('👆 Usuario tocó notificación (app cerrada)');
        _handleNotificationTap(message);
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'veterinaria_channel',
      'Notificaciones Veterinaria',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Nueva notificación',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final tipo = message.data['tipo'];
    final citaId = message.data['cita_id'];

    print('Tipo: $tipo, Cita ID: $citaId');

    // Aquí puedes navegar según el tipo
    // navigatorKey.currentState?.pushNamed('/cita/$citaId');
  }

  Future<void> deleteToken() async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _api.post('fcm-token/delete', {'token': token});
    }
    await _fcm.deleteToken();
  }
}
```

## 📊 Modelos Dart

### mascota.dart
```dart
class Mascota {
  final int id;
  final int clienteId;
  final String nombre;
  final String especie;
  final String? raza;
  final DateTime? fechaNacimiento;
  final String? edad;
  final String sexo;
  final double? peso;
  final String? color;
  final String? chipId;
  final String? foto;
  final String publicId;

  Mascota({
    required this.id,
    required this.clienteId,
    required this.nombre,
    required this.especie,
    this.raza,
    this.fechaNacimiento,
    this.edad,
    required this.sexo,
    this.peso,
    this.color,
    this.chipId,
    this.foto,
    required this.publicId,
  });

  factory Mascota.fromJson(Map<String, dynamic> json) {
    return Mascota(
      id: json['id'],
      clienteId: json['cliente_id'],
      nombre: json['nombre'],
      especie: json['especie'],
      raza: json['raza'],
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.parse(json['fecha_nacimiento'])
          : null,
      edad: json['edad'],
      sexo: json['sexo'],
      peso: json['peso']?.toDouble(),
      color: json['color'],
      chipId: json['chip_id'],
      foto: json['foto'],
      publicId: json['public_id'],
    );
  }

  String get fotoUrl => foto ?? '';
  bool get tieneFoto => foto != null && foto!.isNotEmpty;
}
```

### cita.dart
```dart
class Cita {
  final int id;
  final int mascotaId;
  final int veterinarioId;
  final DateTime fechaHora;
  final int duracionMinutos;
  final String estado;
  final String? motivoConsulta;
  final String? observaciones;
  final List<Servicio>? servicios;
  final Mascota? mascota;

  Cita({
    required this.id,
    required this.mascotaId,
    required this.veterinarioId,
    required this.fechaHora,
    required this.duracionMinutos,
    required this.estado,
    this.motivoConsulta,
    this.observaciones,
    this.servicios,
    this.mascota,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['id'],
      mascotaId: json['mascota_id'],
      veterinarioId: json['veterinario_id'],
      fechaHora: DateTime.parse(json['fecha_hora']),
      duracionMinutos: json['duracion_minutos'],
      estado: json['estado'],
      motivoConsulta: json['motivo_consulta'],
      observaciones: json['observaciones'],
      servicios: json['servicios'] != null
          ? (json['servicios'] as List)
              .map((s) => Servicio.fromJson(s))
              .toList()
          : null,
      mascota: json['mascota'] != null
          ? Mascota.fromJson(json['mascota'])
          : null,
    );
  }

  String get estadoTexto {
    switch (estado) {
      case 'programada':
        return 'Programada';
      case 'confirmada':
        return 'Confirmada';
      case 'en_curso':
        return 'En curso';
      case 'completada':
        return 'Completada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return estado;
    }
  }
}

class Servicio {
  final int id;
  final String codigo;
  final String nombre;
  final String tipo;
  final double precio;

  Servicio({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.tipo,
    required this.precio,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      id: json['id'],
      codigo: json['codigo'],
      nombre: json['nombre'],
      tipo: json['tipo'],
      precio: json['precio'].toDouble(),
    );
  }
}
```

### notificacion.dart
```dart
class Notificacion {
  final int id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final Map<String, dynamic>? data;
  final bool leida;
  final DateTime createdAt;

  Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.data,
    required this.leida,
    required this.createdAt,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'],
      tipo: json['tipo'],
      titulo: json['titulo'],
      mensaje: json['mensaje'],
      data: json['data'],
      leida: json['leida'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
```

## 🔐 Pantalla de Login

### login_screen.dart
```dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'fcm_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiService();
  final _fcm = FCMService();
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1. Login con Laravel
      final response = await _api.login(
        _emailController.text,
        _passwordController.text,
      );

      // 2. Inicializar FCM y enviar token
      await _fcm.initialize();

      // 3. Navegar a home
      Navigator.pushReplacementNamed(context, '/home');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Bienvenido ${response['user']['name']}!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Iniciar Sesión')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              _loading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: Text('Ingresar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 📋 Lista de Citas

### citas_screen.dart
```dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'api_service.dart';
import 'cita.dart';
import 'package:intl/intl.dart';

class CitasScreen extends StatefulWidget {
  @override
  _CitasScreenState createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  final _api = ApiService();
  List<Cita> _citas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCitas();
  }

  Future<void> _loadCitas() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get('citas');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _citas = (data['data'] as List)
              .map((json) => Cita.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mis Citas')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCitas,
              child: ListView.builder(
                itemCount: _citas.length,
                itemBuilder: (context, index) {
                  final cita = _citas[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: cita.mascota?.tieneFoto == true
                            ? NetworkImage(cita.mascota!.fotoUrl)
                            : null,
                        child: cita.mascota?.tieneFoto != true
                            ? Text(cita.mascota?.nombre[0] ?? '?')
                            : null,
                      ),
                      title: Text(cita.mascota?.nombre ?? 'Sin nombre'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('dd/MM/yyyy HH:mm')
                              .format(cita.fechaHora)),
                          Text(cita.motivoConsulta ?? ''),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(cita.estadoTexto),
                        backgroundColor: _getEstadoColor(cita.estado),
                      ),
                      onTap: () {
                        // Navegar a detalle
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a crear cita
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'programada':
        return Colors.blue.shade100;
      case 'confirmada':
        return Colors.green.shade100;
      case 'completada':
        return Colors.grey.shade300;
      case 'cancelada':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }
}
```

## 📸 Subir Foto de Mascota

### crear_mascota_screen.dart
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class CrearMascotaScreen extends StatefulWidget {
  @override
  _CrearMascotaScreenState createState() => _CrearMascotaScreenState();
}

class _CrearMascotaScreenState extends State<CrearMascotaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  final _nombreController = TextEditingController();
  String _especie = 'perro';
  String _sexo = 'macho';
  File? _imagen;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagen = File(pickedFile.path);
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final fields = {
        'cliente_id': '1', // Obtener del usuario actual
        'nombre': _nombreController.text,
        'especie': _especie,
        'sexo': _sexo,
      };

      final response = await _api.uploadFile(
        endpoint: 'mascotas',
        fields: fields,
        filePaths: _imagen != null ? [_imagen!.path] : [],
        fileFieldName: 'foto',
      );

      if (response.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mascota creada exitosamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nueva Mascota')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imagen != null
                    ? Image.file(_imagen!, fit: BoxFit.cover)
                    : Icon(Icons.camera_alt, size: 50),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: 'Nombre'),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _especie,
              decoration: InputDecoration(labelText: 'Especie'),
              items: [
                DropdownMenuItem(value: 'perro', child: Text('Perro')),
                DropdownMenuItem(value: 'gato', child: Text('Gato')),
                DropdownMenuItem(value: 'ave', child: Text('Ave')),
                DropdownMenuItem(value: 'reptil', child: Text('Reptil')),
                DropdownMenuItem(value: 'otro', child: Text('Otro')),
              ],
              onChanged: (value) => setState(() => _especie = value!),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _sexo,
              decoration: InputDecoration(labelText: 'Sexo'),
              items: [
                DropdownMenuItem(value: 'macho', child: Text('Macho')),
                DropdownMenuItem(value: 'hembra', child: Text('Hembra')),
              ],
              onChanged: (value) => setState(() => _sexo = value!),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _guardar,
              child: Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🔔 Badge de Notificaciones

### notification_badge.dart
```dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'api_service.dart';

class NotificationBadge extends StatefulWidget {
  @override
  _NotificationBadgeState createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final _api = ApiService();
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      final response = await _api.get('notificaciones/unread-count');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _count = data['total'];
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () {
            Navigator.pushNamed(context, '/notificaciones');
          },
        ),
        if (_count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                _count > 99 ? '99+' : '$_count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

## 📱 main.dart Completo

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'fcm_service.dart';
import 'login_screen.dart';
import 'citas_screen.dart';

// Handler para background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurar handler de background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veterinaria App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => CitasScreen(),
      },
    );
  }
}
```

---

## ✅ Checklist de Implementación

- [ ] Copiar `api_service.dart`
- [ ] Copiar `fcm_service.dart`
- [ ] Configurar Firebase (google-services.json / GoogleService-Info.plist)
- [ ] Crear modelos (Mascota, Cita, Notificacion, etc.)
- [ ] Implementar login_screen.dart
- [ ] Implementar pantallas principales
- [ ] Configurar main.dart con Firebase
- [ ] Probar notificaciones push
- [ ] Implementar QR scanner
- [ ] Testing completo

---

**Nota:** Reemplaza `http://tu-dominio.com/api` con la URL real de tu backend.
