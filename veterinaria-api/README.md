# 🐾 Sistema de Gestión Veterinaria - API

> **API REST completa para clínicas veterinarias** construida con Laravel 11, MySQL y Firebase Cloud Messaging.

[![Laravel](https://img.shields.io/badge/Laravel-11-FF2D20?logo=laravel)](https://laravel.com)
[![PHP](https://img.shields.io/badge/PHP-8.2+-777BB4?logo=php)](https://php.net)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql)](https://mysql.com)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?logo=firebase)](https://firebase.google.com)

---

## 🚀 ¿La API está lista para Flutter?

### ✅ **SÍ, completamente funcional**

- ✅ Servidor corriendo en `http://0.0.0.0:8000`
- ✅ 11 controladores CRUD completos
- ✅ Autenticación con Laravel Sanctum
- ✅ Firebase Cloud Messaging configurado
- ✅ Filtros y búsquedas implementados
- ✅ Paginación en todos los endpoints
- ✅ Documentación completa

**👉 [Ver guía de conexión Flutter](CONEXION_FLUTTER.md)**

---

## 📚 Documentación

### 🎯 Inicio Rápido

| Documento | Descripción |
|-----------|-------------|
| **[CONEXION_FLUTTER.md](CONEXION_FLUTTER.md)** | 🔌 Conectar Flutter con la API (empieza aquí) |
| **[FILTROS_GUIDE.md](FILTROS_GUIDE.md)** | 🔍 Implementar filtros y búsquedas en Flutter |
| **[FLUTTER_QUICK_START.md](FLUTTER_QUICK_START.md)** | 🚀 Guía rápida para desarrolladores Flutter |
| **[FLUTTER_CODE_EXAMPLES.md](FLUTTER_CODE_EXAMPLES.md)** | 💻 Código Flutter listo para usar |

### 📖 Documentación Completa

| Documento | Descripción |
|-----------|-------------|
| **[RESUMEN_EJECUTIVO.md](RESUMEN_EJECUTIVO.md)** | ⭐ Visión general del proyecto |
| **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)** | 📘 Referencia completa de la API (600+ líneas) |
| **[INDEX.md](INDEX.md)** | 📑 Índice de toda la documentación |

---

## ⚡ Instalación Rápida

### 1️⃣ Clonar e Instalar

```bash
git clone <repo-url>
cd veterinaria-api
composer install
```

### 2️⃣ Configurar Base de Datos

```bash
# Copiar .env
cp .env.example .env

# Editar .env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=veterinaria
DB_USERNAME=root
DB_PASSWORD=

# Generar key
php artisan key:generate
```

### 3️⃣ Migrar y Sembrar

```bash
php artisan migrate --seed
```

### 4️⃣ Iniciar Servidor

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

**✅ API corriendo en:** `http://localhost:8000`

---

## 🏗️ Arquitectura

### Stack Tecnológico

- **Backend**: Laravel 11
- **Base de Datos**: MySQL 8.0
- **Autenticación**: 
  - Laravel Sanctum (API tokens tradicional)
  - **🔥 Firebase Authentication** (OAuth, email/password)
- **Notificaciones**: Firebase Cloud Messaging (FCM) ✅
- **Push Notifications**: Sistema completo implementado
- **Storage**: Local filesystem (fotos mascotas, documentos)
- **QR**: Códigos únicos para mascotas

### 14 Tablas en la Base de Datos

```
users (con roles: admin, veterinario, cliente)
clientes
mascotas (con fotos y QR único)
veterinarios (con especialidades y horarios)
servicios (catálogo de servicios)
citas (con validación de disponibilidad)
historial_medico (consultas, vacunas, procedimientos)
notificaciones (leídas/no leídas)
facturas (con detalles de servicios)
disponibilidad_veterinarios
fcm_tokens (dispositivos para push notifications)
+ tablas de sistema (cache, jobs, sessions)
```

---

## 🔑 Endpoints Principales

### Autenticación
```
POST   /api/auth/register              # Registro tradicional
POST   /api/auth/login                 # Login tradicional
POST   /api/auth/logout                # Logout tradicional
```

### 🔥 Firebase Authentication (NUEVO)
```
POST   /api/firebase/verify            # Verificar token Firebase y sincronizar
GET    /api/firebase/profile           # Obtener perfil (requiere auth)
PUT    /api/firebase/profile           # Actualizar perfil (requiere auth)
POST   /api/firebase/fcm-token         # Registrar token FCM (requiere auth)
POST   /api/firebase/logout            # Cerrar sesión (requiere auth)
```

### CRUD Completo (con filtros y paginación)
```
/api/clientes
/api/mascotas
/api/veterinarios
/api/servicios
/api/citas
/api/historial-medico
/api/notificaciones
/api/facturas
```

### Especiales
```
GET    /api/qr/lookup/{uuid}           # Escanear QR de mascota (público)
POST   /api/fcm-token                  # Registrar token FCM
GET    /api/veterinarios/{id}/disponibilidad
POST   /api/historial-medico/{id}/archivos
GET    /api/facturas-estadisticas
```

**📘 [Ver documentación completa de endpoints](API_DOCUMENTATION.md)**

---

## 🔍 Filtros Disponibles

### Historial Médico
```
GET /api/historial-medico?mascota_id=5&fecha_desde=2025-01-01&nombre_cliente=Juan&search=alergia
```

### Citas
```
GET /api/citas?fecha=2025-01-20&estado=programada&nombre_mascota=Max&search=vacuna
```

### Mascotas
```
GET /api/mascotas?cliente_id=3&especie=perro&search=Max
```

**🔍 [Ver guía completa de filtros](FILTROS_GUIDE.md)**

---

## 🔔 Notificaciones Push

### Tipos de Notificaciones
- Recordatorio de cita (1 día antes)
- Cita creada/modificada/cancelada
- Vacuna próxima a vencer
- Resultado médico disponible
- Mensaje de veterinario

### Configuración Firebase

```env
FIREBASE_SERVER_KEY=tu_server_key_aqui
```

**🔥 [Ver setup Firebase en Flutter](CONEXION_FLUTTER.md#-configurar-firebase-fcm)**

---

## 📱 Conectar con Flutter

### URL según Dispositivo

```dart
// Android Emulator
const String baseUrl = 'http://10.0.2.2:8000/api';

// Dispositivo Real (mismo WiFi)
const String baseUrl = 'http://192.168.1.XXX:8000/api';

// iOS Simulator
const String baseUrl = 'http://localhost:8000/api';
```

### Test de Conexión

```dart
final api = ApiService();

// Login
final data = await api.login('test@example.com', 'password123');
print('Token: ${data['token']}');

// Obtener mascotas
final response = await api.get('mascotas');
print('Mascotas: ${response.body}');
```

**🔌 [Ver guía completa de conexión Flutter](CONEXION_FLUTTER.md)**

---

## 🧪 Testing

### Usuarios de Prueba (creados por seeders)

```php
// Admin
email: admin@veterinaria.com
password: password

// Veterinario
email: vet1@veterinaria.com
password: password

// Cliente
email: cliente1@veterinaria.com
password: password
```

### Probar con Postman

```
# Login
POST http://localhost:8000/api/auth/login
{
  "email": "cliente1@veterinaria.com",
  "password": "password"
}

# Usar token en headers
Authorization: Bearer {token}
```

---

## 📊 Features Implementadas

- ✅ Autenticación con roles (admin, veterinario, cliente)
- ✅ 🔥 **Firebase Authentication integrada** (email/password, OAuth)
- ✅ CRUD completo de 8 entidades principales
- ✅ Validación de disponibilidad de veterinarios
- ✅ Facturación automática
- ✅ Historial médico con adjuntos
- ✅ Códigos QR únicos por mascota
- ✅ 🔔 **Sistema completo de notificaciones push** con FCM
- ✅ Filtros avanzados y búsquedas
- ✅ Paginación en todos los listados
- ✅ Subida de fotos de mascotas
- ✅ Estadísticas de facturación

---

## 🔥 Firebase Integration

### Autenticación Firebase

El sistema soporta **doble autenticación**:

1. **Laravel Sanctum** (tradicional con email/password)
2. **Firebase Authentication** (email/password, Google, Facebook, etc.)

### Flujo Firebase:

```
1. Usuario se autentica en Firebase (Flutter)
2. Flutter obtiene ID Token de Firebase
3. Flutter envía token a /api/firebase/verify
4. Laravel verifica token con Firebase Admin SDK
5. Laravel crea/actualiza usuario en MySQL
6. Laravel genera Sanctum token
7. Flutter usa Sanctum token para todos los endpoints
```

### Configuración Firebase:

Ver guía completa en: **[FIREBASE_AUTH_GUIDE.md](FIREBASE_AUTH_GUIDE.md)**

**Configuración rápida:**

1. Descargar `firebase-credentials.json` de Firebase Console
2. Guardar en `storage/app/firebase-credentials.json`
3. Configurar `.env`:

```env
FIREBASE_CREDENTIALS=../storage/app/firebase-credentials.json
FIREBASE_PROJECT_ID=tu-proyecto-id
FCM_SERVER_KEY=tu_server_key_aqui
```

### Notificaciones Push:

```php
// Enviar notificación desde cualquier controlador
sendPushNotification(
    $fcmToken,
    'Nueva Cita Confirmada',
    'Tu cita está programada para ' . $cita->fecha
);
```

**📚 Documentación completa:** [FIREBASE_IMPLEMENTATION_SUMMARY.md](FIREBASE_IMPLEMENTATION_SUMMARY.md)

---

## 🤝 Contribuir

Este proyecto está documentado extensamente:

1. **Backend developers**: Ver [RESUMEN_EJECUTIVO.md](RESUMEN_EJECUTIVO.md)
2. **Flutter developers**: Ver [CONEXION_FLUTTER.md](CONEXION_FLUTTER.md)
3. **Todos**: Ver [INDEX.md](INDEX.md) para navegación completa

---

## 📄 Licencia

Este proyecto es parte de un sistema de gestión veterinaria.

---

## 📞 Soporte

Para más información, consulta:
- [Documentación completa](INDEX.md)
- [Guía de conexión Flutter](CONEXION_FLUTTER.md)
- [API Reference](API_DOCUMENTATION.md)

---

**🎉 ¡La API está lista para producción!**

In order to ensure that the Laravel community is welcoming to all, please review and abide by the [Code of Conduct](https://laravel.com/docs/contributions#code-of-conduct).

## Security Vulnerabilities

If you discover a security vulnerability within Laravel, please send an e-mail to Taylor Otwell via [taylor@laravel.com](mailto:taylor@laravel.com). All security vulnerabilities will be promptly addressed.

## License

The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
