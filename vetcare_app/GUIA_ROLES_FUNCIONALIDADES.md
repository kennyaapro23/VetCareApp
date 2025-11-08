# 📱 VetCare App - Guía de Roles y Funcionalidades

## 🎯 Resumen de Roles

La aplicación VetCare tiene **3 roles principales**:
1. **Cliente** - Dueños de mascotas
2. **Veterinario** - Profesionales médicos
3. **Recepcionista** - Personal administrativo

---

## 👤 ROL: CLIENTE

### 📊 Pantalla Principal (4 pestañas)

#### 1️⃣ **Noticias** (Feed)
- 📰 Ver noticias de salud animal
- 📱 Feed de contenido educativo
- 🔔 Notificaciones en tiempo real

#### 2️⃣ **Mis Mascotas**
- 🐾 Ver lista de todas mis mascotas en tarjetas visuales
- ➕ Agregar nueva mascota (nombre, especie, raza, sexo, edad, peso)
- ✏️ Editar información de mascotas existentes
- 🗑️ Eliminar mascotas
- 🔍 Buscar mascotas por nombre, especie o raza
- 👁️ Ver detalles completos de cada mascota:
  - **Pestaña Info**: Datos básicos + Código QR único
  - **Pestaña Historial**: Historial médico completo
  - **Pestaña Citas**: Citas programadas para esa mascota
- 📱 QR Code por mascota para identificación

#### 3️⃣ **Mis Citas**
- 📅 Ver todas mis citas programadas
- ➕ Agendar nueva cita
- 👁️ Ver detalles de citas
- ❌ Cancelar citas
- 🟢 Estados: Pendiente, Confirmada, Cancelada
- 📋 Filtros por estado

#### 4️⃣ **Perfil**
- 👤 Ver información personal
- ✏️ Editar datos de perfil
- 🌙 Cambiar entre modo claro/oscuro
- 🚪 Cerrar sesión

### 🔔 Notificaciones
- 📬 Centro de notificaciones accesible desde todas las pantallas
- 🔴 Indicador de notificaciones sin leer

---

## 👨‍⚕️ ROL: VETERINARIO

### 📊 Pantalla Principal (5 pestañas)

#### 1️⃣ **Panel** (Dashboard)
- 📊 Resumen de citas del día
- 📈 Estadísticas rápidas
- 🕐 Citas de hoy en tiempo real
- ⚡ Acceso rápido a funciones principales

#### 2️⃣ **Citas**
- 📅 Ver todas las citas asignadas
- 👁️ Ver detalles completos de cada cita
- ✅ Confirmar citas
- ❌ Cancelar citas
- 📝 Agregar notas a las citas
- 🔍 Buscar citas por paciente
- 📋 Filtrar por estado (pendiente, confirmada, completada)
- 📅 Calendario de citas

#### 3️⃣ **Servicios**
- 💉 Ver lista de servicios disponibles
- ➕ Crear nuevos servicios
- ✏️ Editar servicios existentes
- 💰 Gestionar precios
- 📝 Descripciones de servicios
- 🏷️ Categorías de servicios

#### 4️⃣ **Escanear QR**
- 📷 Escanear código QR de mascotas
- 🔍 Identificación rápida de pacientes
- 📋 Acceso inmediato al historial
- ⚡ Registro rápido de atención

#### 5️⃣ **Perfil**
- 👤 Ver información profesional
- ✏️ Editar datos
- 🌙 Tema claro/oscuro
- 🚪 Cerrar sesión

### 🏥 Funcionalidades Médicas
- 📋 Acceso a historial médico completo de pacientes
- 💊 Registrar diagnósticos y tratamientos
- 💉 Administrar vacunas
- 🩺 Seguimiento de pacientes

---

## 👩‍💼 ROL: RECEPCIONISTA

### 📊 Pantalla Principal (5 pestañas)

#### 1️⃣ **Dashboard**
- 📊 Panel de control administrativo
- 📈 Estadísticas del día
- 👥 Resumen de clientes activos
- 📅 Citas del día
- 💰 Resumen financiero diario

#### 2️⃣ **Gestión de Clientes**
- 👥 Ver lista completa de clientes
- ➕ Registrar nuevos clientes
- ✏️ Editar información de clientes
- 🔍 Buscar clientes
- 📱 Ver contactos y datos
- 🐾 Ver mascotas asociadas a cada cliente
- 📋 Historial de servicios por cliente

#### 3️⃣ **Gestión de Citas**
- 📅 Ver TODAS las citas del sistema
- ➕ Agendar citas para cualquier cliente
- ✏️ Modificar citas existentes
- ❌ Cancelar citas
- ✅ Confirmar citas
- 🔄 Reasignar citas a diferentes veterinarios
- 📋 Filtros avanzados (fecha, estado, veterinario, cliente)
- 📊 Vista de calendario

#### 4️⃣ **Gestión de Facturas**
- 💰 Ver todas las facturas
- ➕ Crear nuevas facturas
- ✏️ Editar facturas pendientes
- 💳 Registrar pagos
- 🧾 Generar reportes
- 📊 Estadísticas de facturación
- 🔍 Buscar facturas por cliente
- 📅 Filtrar por fecha
- 💵 Estados: Pendiente, Pagada, Vencida

#### 5️⃣ **Perfil**
- 👤 Información personal
- ✏️ Editar datos
- 🌙 Tema claro/oscuro
- 🚪 Cerrar sesión

### 🔔 Notificaciones
- 📬 Centro de notificaciones administrativas
- 🔴 Alertas de citas, pagos pendientes, etc.

---

## 🔐 Sistema de Autenticación

### Para TODOS los roles:
- 🔑 **Login**: Email y contraseña
- 📝 **Registro**: Solo clientes pueden auto-registrarse
- 🔒 **Seguridad**: Autenticación con tokens
- 💾 **Sesión persistente**: Recordar inicio de sesión
- 🚪 **Logout**: Cerrar sesión desde perfil

### Credenciales de prueba:
```
Cliente:
- Email: cliente@veterinaria.com
- Password: password123

Veterinario:
- Email: veterinario@veterinaria.com
- Password: password123

Recepcionista:
- Email: recepcionista@veterinaria.com
- Password: password123
```

---

## 🎨 Características Comunes

### Para TODOS los usuarios:
- ✅ **Modo oscuro/claro**: Disponible en perfil
- 🔔 **Notificaciones**: Sistema de alertas en tiempo real
- 🔄 **Pull to refresh**: Actualizar datos deslizando hacia abajo
- 🔍 **Búsquedas**: En todas las listas
- 📱 **Interfaz responsive**: Diseño adaptable
- ⚡ **Navegación fluida**: Transiciones suaves
- 🎨 **Tema consistente**: Colores corporativos
- 🌐 **Sincronización**: Datos en tiempo real con backend

---

## 📊 Comparativa de Permisos

| Funcionalidad | Cliente | Veterinario | Recepcionista |
|--------------|---------|-------------|---------------|
| Ver mis mascotas | ✅ | ❌ | ❌ |
| Ver todas las mascotas | ❌ | ✅ | ✅ |
| Agendar mis citas | ✅ | ❌ | ❌ |
| Gestionar todas las citas | ❌ | ✅ | ✅ |
| Ver historial médico | ✅ (solo mío) | ✅ (todos) | ✅ (todos) |
| Registrar diagnósticos | ❌ | ✅ | ❌ |
| Gestionar servicios | ❌ | ✅ | ❌ |
| Escanear QR | ❌ | ✅ | ✅ |
| Gestionar clientes | ❌ | ❌ | ✅ |
| Gestionar facturas | ❌ | ❌ | ✅ |
| Ver noticias | ✅ | ❌ | ❌ |

---

## 🚀 Flujos de Trabajo Típicos

### 👤 Cliente:
1. Inicia sesión
2. Agrega sus mascotas
3. Agenda una cita para una mascota
4. Recibe notificación de confirmación
5. Consulta historial médico de su mascota

### 👨‍⚕️ Veterinario:
1. Inicia sesión
2. Revisa citas del día en el dashboard
3. Escanea QR de mascota que llega
4. Realiza atención médica
5. Registra diagnóstico y tratamiento
6. Marca cita como completada

### 👩‍💼 Recepcionista:
1. Inicia sesión
2. Recibe cliente en recepción
3. Busca o registra cliente nuevo
4. Agenda cita con veterinario disponible
5. Genera factura del servicio
6. Registra el pago
7. Envía notificación al cliente

---

## 📱 Navegación en la App

### Estructura de Navegación:

```
Login/Register
    ↓
Auth Gate (detecta rol)
    ↓
┌─────────────────┬──────────────────┬────────────────────┐
│   CLIENTE       │   VETERINARIO    │   RECEPCIONISTA    │
├─────────────────┼──────────────────┼────────────────────┤
│ • Noticias      │ • Dashboard      │ • Dashboard        │
│ • Mis Mascotas  │ • Citas          │ • Clientes         │
│ • Mis Citas     │ • Servicios      │ • Citas            │
│ • Perfil        │ • Escanear QR    │ • Facturas         │
│                 │ • Perfil         │ • Perfil           │
└─────────────────┴──────────────────┴────────────────────┘
```

---

## 🔧 Configuración Técnica

### Backend API:
- Base URL: `http://127.0.0.1:8000/api/`
- Requiere: `adb reverse tcp:8000 tcp:8000` (para emulador)
- Laravel backend con autenticación Sanctum

### Credenciales de prueba incluidas en:
- `lib/config/app_config.dart`

---

## 📝 Notas Importantes

1. **QR Codes**: Cada mascota tiene un QR único para identificación rápida
2. **Notificaciones**: Sistema en tiempo real (requiere configuración de Firebase)
3. **Historial Médico**: Solo veterinarios pueden agregar registros
4. **Facturación**: Solo recepcionistas tienen acceso
5. **Servicios**: Solo veterinarios pueden crear/modificar

---

Creado: 8 de noviembre de 2025
Versión: 1.0.0

