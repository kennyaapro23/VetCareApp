# VetCareApp - Sistema Veterinario Completo

Aplicación móvil completa tipo Instagram para gestión veterinaria construida con Flutter y backend Laravel.

## 🚀 Características Implementadas

### ✅ Autenticación y Roles
- Login y registro con Laravel Sanctum/JWT
- Persistencia de sesión con SharedPreferences
- Navegación automática según rol (Cliente/Veterinario/Recepcionista)
- AutoLogin al iniciar la app

### ✅ Arquitectura Limpia
```
lib/
├── models/          # Modelos de datos (User, Client, Pet, Appointment, Service, Notification)
├── services/        # Servicios API (ApiService, AuthService, AppointmentService, etc.)
├── providers/       # Proveedores de estado (AuthProvider)
├── screens/         # Pantallas de la app
└── widgets/         # Componentes reutilizables
```

### ✅ Gestión de Citas (CitasScreen)
- Listado de citas con filtros por estado (pendiente, confirmada, atendida, cancelada)
- Crear nuevas citas con validaciones de fecha/hora
- Cancelar citas con confirmación modal
- Diseño moderno con chips de estado con colores
- Consume: `GET /api/citas`, `POST /api/citas`, `PUT /api/citas/{id}`

### ✅ Módulo de Servicios Veterinarios (ServiciosScreen)
- Listado de servicios (vacunas, baños, cortes, controles)
- Crear servicios asociados a mascotas
- Iconos y colores distintivos por tipo de servicio
- Consume: `GET /api/servicios`, `POST /api/servicios`, `GET /api/mascotas/{id}/servicios`

### ✅ Escaneo y Generación de QR (QRScreen)
- Generación de código QR del usuario con `qr_flutter`
- Escaneo de códigos QR con `mobile_scanner`
- Búsqueda automática en el backend: `GET /api/buscarQR/{codigo}`
- Visualización de datos con tarjetas animadas (historial médico, servicios recientes)
- Diseño minimalista estilo cámara de Instagram

### ✅ Notificaciones Push con Firebase (NotificacionesScreen)
- Configuración de Firebase Cloud Messaging (FCM)
- Recepción de notificaciones en foreground y background
- Almacenamiento local de notificaciones
- Lista agrupada por fecha
- Función de limpiar notificaciones

### ✅ Perfil de Usuario (PerfilScreen)
- Diseño tipo Instagram con foto circular
- Estadísticas (citas, mascotas, servicios)
- Edición de información personal
- Cambio de foto de perfil con `image_picker`
- Animaciones con Hero y AnimatedContainer
- Cerrar sesión con confirmación

### ✅ Pantalla Feed Tipo Instagram (FeedScreen)
- Tarjetas modernas con información de servicios/citas
- Scroll fluido con ListView.builder
- Sombras suaves y esquinas redondeadas
- Optimizado para Android

### ✅ ApiService Robusto
- Métodos GET, POST, PUT, DELETE
- Token Bearer automático
- Reintentos exponenciales para errores de red
- Manejo de errores con `ApiException`
- Base URL adaptativa (localhost para desktop, 10.0.2.2 para emulador Android)

## 📦 Dependencias

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5              # Estado
  http: ^0.13.6                 # Peticiones HTTP
  shared_preferences: ^2.1.0    # Persistencia local
  intl: ^0.18.1                 # Formateo de fechas
  qr_flutter: ^4.1.0            # Generación de QR
  mobile_scanner: ^3.5.5        # Escaneo de QR
  firebase_core: ^2.24.2        # Firebase base
  firebase_messaging: ^14.7.9   # Notificaciones push
  image_picker: ^1.0.7          # Selección de imágenes
```

## 🔧 Instalación

### 1. Instalar Dependencias

**Opción A - Usando el script batch:**
```cmd
install_dependencies.bat
```

**Opción B - Manualmente:**
```cmd
cd C:\Users\kenny\vetcare_app
flutter pub get
```

### 2. Configurar Firebase

#### Para Android:
1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Crea un proyecto nuevo
3. Agrega una app Android con package name: `com.example.vetcare_app`
4. Descarga `google-services.json`
5. Colócalo en: `android/app/google-services.json`
6. Agrega en `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```
7. Agrega en `android/build.gradle.kts`:
```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.4.0")
}
```

#### Para Web:
1. En Firebase Console, agrega una app Web
2. Copia la configuración en `lib/firebase_options.dart`

### 3. Configurar Backend Laravel

Asegúrate de que tu backend Laravel tenga estos endpoints:

```php
// Autenticación
POST /api/auth/login
POST /api/auth/register

// Citas
GET /api/citas?estado={status}
POST /api/citas
PUT /api/citas/{id}

// Servicios
GET /api/servicios
POST /api/servicios
GET /api/mascotas/{id}/servicios

// QR
GET /api/buscarQR/{codigo}
```

### 4. Ejecutar la App

**Android (emulador o dispositivo):**
```cmd
flutter run
```

**Web (Chrome):**
```cmd
flutter run -d chrome
```

**Windows Desktop:**
```cmd
flutter run -d windows
```

## 🎨 Estructura de Navegación

### Cliente
- **Home (Feed)**: Ver actualizaciones de citas y servicios
- **Citas**: Gestionar mis citas
- **QR**: Ver mi código QR y escanear
- **Notificaciones**: Ver notificaciones push
- **Perfil**: Editar perfil y cerrar sesión

### Veterinario
- **Panel**: Ver citas del día
- **Citas**: Gestionar todas las citas
- **Servicios**: Registrar servicios realizados
- **QR**: Escanear códigos de mascotas/clientes
- **Perfil**: Configuración personal

### Recepcionista
- **Panel**: Acciones rápidas (registrar clientes, citas, servicios)
- **Citas**: Crear y gestionar citas
- **Servicios**: Registrar servicios
- **QR**: Escanear y generar códigos
- **Perfil**: Configuración

## 🔐 Flujo de Autenticación

1. **Login/Registro** → Token guardado en SharedPreferences
2. **AuthProvider** carga automáticamente la sesión al iniciar
3. **AuthGate** redirige según el rol del usuario
4. **ApiService** incluye token Bearer en todas las peticiones

## 📱 Capturas de Funcionalidades

- ✅ Material Design 3 con modo oscuro
- ✅ Animaciones fluidas (Hero, AnimatedContainer)
- ✅ Diseño responsivo (adapta a tablets y móviles)
- ✅ Validaciones en formularios
- ✅ Feedback visual con Snackbars y Modals
- ✅ Chips de filtros interactivos
- ✅ Cards con elevación y bordes redondeados

## 🐛 Solución de Problemas

### Error: "Couldn't resolve the package..."
```cmd
flutter pub get
flutter clean
flutter pub get
```

### Error de Firebase en Android
Verifica que `google-services.json` esté en `android/app/` y que hayas agregado el plugin en los gradle.

### Error de conexión al backend
- Emulador Android: Usa `http://10.0.2.2:8000/api/`
- Dispositivo físico: Usa la IP de tu PC en la red local
- Web/Desktop: Usa `http://localhost:8000/api/`

Puedes cambiar la URL base en `lib/services/api_service.dart`

### Permisos de cámara (para QR scanner)
En `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

## 🚧 Próximos Pasos (Opcional)

- [ ] Implementar refresh token
- [ ] Añadir tests unitarios e integración
- [ ] Caché de datos offline
- [ ] Internacionalización (i18n)
- [ ] Animaciones más elaboradas
- [ ] Gráficas de estadísticas
- [ ] Chat en tiempo real

## 📄 Licencia

Este proyecto es de código privado para uso educativo.

---

**Desarrollado con ❤️ usando Flutter + Laravel**

