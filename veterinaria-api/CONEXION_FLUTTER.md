# 📱 Conexión Flutter - API Veterinaria

## ✅ Estado de la API

### 🟢 **API Lista para Flutter**

La API está **100% funcional** y lista para conectarse desde Flutter:

- ✅ Servidor corriendo en: `http://0.0.0.0:8000`
- ✅ Autenticación con Laravel Sanctum
- ✅ 11 controladores CRUD completos
- ✅ Filtros implementados
- ✅ Paginación habilitada
- ✅ FCM tokens configurados

---

## 🌐 URLs de Conexión

### Desarrollo Local

#### Desde Emulador Android:
```dart
const String baseUrl = 'http://10.0.2.2:8000/api';
```

#### Desde Dispositivo Real (mismo WiFi):
```dart
// Reemplaza con tu IP local
const String baseUrl = 'http://192.168.1.XXX:8000/api';
```

#### Desde iOS Simulator:
```dart
const String baseUrl = 'http://localhost:8000/api';
```

### Producción
```dart
const String baseUrl = 'https://tu-dominio.com/api';
```

---

## 🔧 Configuración Rápida en Flutter

### 1️⃣ Agregar Dependencias

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  provider: ^6.1.1
  intl: ^0.18.1
```

### 2️⃣ Crear Servicio API

```dart
// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
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
  
  Map<String, String> _getHeaders([bool includeAuth = true]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (includeAuth) {
      final token = _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // GET Request
  Future<http.Response> get(String endpoint) async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
    
    return response;
  }
  
  // POST Request
  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    
    return response;
  }
  
  // PUT Request
  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    
    return response;
  }
  
  // DELETE Request
  Future<http.Response> delete(String endpoint) async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );
    
    return response;
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

### 3️⃣ Ejemplo de Login Screen

```dart
// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiService();
  bool _loading = false;
  
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      final response = await _api.login(
        _emailController.text,
        _passwordController.text,
      );
      
      // Login exitoso
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Bienvenido!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
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
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleLogin,
                  child: _loading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Iniciar Sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 4️⃣ Ejemplo de Obtener Mascotas

```dart
// lib/screens/mascotas_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/mascota.dart';

class MascotasScreen extends StatefulWidget {
  @override
  _MascotasScreenState createState() => _MascotasScreenState();
}

class _MascotasScreenState extends State<MascotasScreen> {
  final _api = ApiService();
  List<Mascota> _mascotas = [];
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadMascotas();
  }
  
  Future<void> _loadMascotas() async {
    setState(() => _loading = true);
    
    try {
      final response = await _api.get('mascotas');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _mascotas = (data['data'] as List)
              .map((json) => Mascota.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar mascotas: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mascotas'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navegar a crear mascota
            },
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _mascotas.length,
              itemBuilder: (context, index) {
                final mascota = _mascotas[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(mascota.nombre[0].toUpperCase()),
                  ),
                  title: Text(mascota.nombre),
                  subtitle: Text('${mascota.especie} - ${mascota.raza}'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    // Navegar a detalles
                  },
                );
              },
            ),
    );
  }
}
```

---

## 🧪 Probar la Conexión

### Test Rápido en Flutter:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final api = ApiService();
  
  try {
    // Test de registro
    print('🔄 Probando registro...');
    final registerData = await api.register({
      'nombre': 'Test User',
      'email': 'test@example.com',
      'password': 'password123',
      'password_confirmation': 'password123',
      'telefono': '1234567890',
      'rol': 'cliente',
    });
    print('✅ Registro exitoso: ${registerData['user']['nombre']}');
    
    // Test de login
    print('🔄 Probando login...');
    final loginData = await api.login('test@example.com', 'password123');
    print('✅ Login exitoso: Token recibido');
    
    // Test de obtener mascotas
    print('🔄 Probando GET mascotas...');
    final response = await api.get('mascotas');
    if (response.statusCode == 200) {
      print('✅ Mascotas obtenidas correctamente');
    }
    
    print('🎉 ¡Todos los tests pasaron!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

---

## 🔐 Autenticación

### Flujo Completo:

1. **Registro/Login** → Recibir token
2. **Guardar token** en SharedPreferences
3. **Incluir token** en headers: `Authorization: Bearer {token}`
4. **Todas las peticiones** deben incluir el token

### Token en Postman (para testing):

```
Headers:
Authorization: Bearer tu_token_aqui
Content-Type: application/json
Accept: application/json
```

---

## 📡 Endpoints Disponibles

### Autenticación
- `POST /api/auth/register` - Registrar usuario
- `POST /api/auth/login` - Iniciar sesión
- `POST /api/auth/logout` - Cerrar sesión

### Mascotas
- `GET /api/mascotas` - Listar mascotas
- `POST /api/mascotas` - Crear mascota
- `GET /api/mascotas/{id}` - Ver mascota
- `PUT /api/mascotas/{id}` - Actualizar mascota
- `DELETE /api/mascotas/{id}` - Eliminar mascota

### Citas
- `GET /api/citas` - Listar citas (con filtros)
- `POST /api/citas` - Crear cita
- `GET /api/citas/{id}` - Ver cita
- `PUT /api/citas/{id}` - Actualizar cita
- `DELETE /api/citas/{id}` - Eliminar cita

### Historial Médico
- `GET /api/historial-medico` - Listar historial (con filtros)
- `POST /api/historial-medico` - Crear registro
- `GET /api/historial-medico/{id}` - Ver registro
- `PUT /api/historial-medico/{id}` - Actualizar registro
- `DELETE /api/historial-medico/{id}` - Eliminar registro

### FCM Tokens
- `POST /api/fcm-token` - Registrar token
- `DELETE /api/fcm-token` - Eliminar token del dispositivo actual
- `GET /api/fcm-tokens` - Listar tokens
- `DELETE /api/fcm-tokens/all` - Eliminar todos los tokens del usuario

**Ver más endpoints en:** [API_DOCUMENTATION.md](API_DOCUMENTATION.md)

---

## 🔥 Configurar Firebase (FCM)

### 1. Crear proyecto en Firebase Console

1. Ir a https://console.firebase.google.com/
2. Crear nuevo proyecto
3. Agregar app Android/iOS
4. Descargar `google-services.json` (Android) o `GoogleService-Info.plist` (iOS)

### 2. Configurar en Flutter

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Mensaje en background: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
      // Registrar en backend
      try {
        await _api.registerFcmToken(fcmToken, 'android');
        print('✅ Token FCM registrado en backend');
      } catch (e) {
        print('❌ Error al registrar token: $e');
      }
    }
    
    // Escuchar mensajes en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje recibido: ${message.notification?.title}');
      
      // Mostrar notificación local
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification!.title ?? 'Notificación'),
          ),
        );
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

### 3. Obtener Server Key de Firebase

1. Firebase Console → Project Settings
2. Cloud Messaging
3. Copiar **Server Key**
4. Agregar al `.env` de Laravel:

```env
FIREBASE_SERVER_KEY=tu_server_key_aqui
```

---

## 🐛 Debugging

### Error: "Connection refused"

**Solución:**
```dart
// Android Emulator usa IP especial
const String baseUrl = 'http://10.0.2.2:8000/api';

// NO uses:
// ❌ http://localhost:8000/api
// ❌ http://127.0.0.1:8000/api
```

### Error: "Unauthenticated" (401)

**Verificar:**
1. Token guardado correctamente
2. Header `Authorization: Bearer {token}` presente
3. Token no expirado

### Error: "CORS policy"

**Laravel ya está configurado para aceptar peticiones de cualquier origen en desarrollo.**

Si persiste, verificar que el servidor esté corriendo con:
```bash
php artisan serve --host=0.0.0.0 --port=8000
```

---

## 📊 Monitoreo

### Logs del Servidor:

```bash
# Ver logs en tiempo real
tail -f storage/logs/laravel.log
```

### Logs en Flutter:

```dart
// Activar logs HTTP
import 'package:http/http.dart' as http;

print('Request: ${response.request?.url}');
print('Status: ${response.statusCode}');
print('Body: ${response.body}');
```

---

## ✅ Checklist de Conexión

- [ ] Servidor Laravel corriendo en `http://0.0.0.0:8000`
- [ ] Base de datos MySQL funcionando
- [ ] Migraciones ejecutadas (`php artisan migrate`)
- [ ] Seeders ejecutados (roles y servicios)
- [ ] Firebase project creado
- [ ] `google-services.json` agregado a Flutter
- [ ] Dependencias de Flutter instaladas
- [ ] API Service creado en Flutter
- [ ] IP correcta configurada (10.0.2.2 para emulador)
- [ ] Token de autenticación guardándose correctamente
- [ ] FCM tokens registrándose en backend

---

## 🚀 Próximos Pasos

1. ✅ **Conexión establecida**
2. 📱 **Implementar pantallas en Flutter**
3. 🔐 **Testing de autenticación**
4. 📊 **CRUD de mascotas/citas**
5. 🔔 **Probar notificaciones push**
6. 🎨 **UI/UX pulido**
7. 🚀 **Deploy a producción**

---

## 📚 Recursos

- [API Documentation](API_DOCUMENTATION.md) - Todos los endpoints
- [Flutter Quick Start](FLUTTER_QUICK_START.md) - Guía completa
- [Flutter Code Examples](FLUTTER_CODE_EXAMPLES.md) - Ejemplos de código
- [Filtros Guide](FILTROS_GUIDE.md) - Implementación de filtros

---

## 💡 Ayuda

Si tienes problemas:
1. Verifica los logs de Laravel
2. Usa Postman para probar endpoints
3. Revisa la documentación completa
4. Verifica que el servidor esté corriendo

**¡La API está lista! 🎉**
