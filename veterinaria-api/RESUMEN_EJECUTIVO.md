# 🐾 Sistema de Gestión Veterinaria - Resumen Ejecutivo

## 📋 Descripción General

API REST completa para sistema de gestión de clínica veterinaria con:
- ✅ Autenticación Laravel Sanctum + Firebase
- ✅ Notificaciones push automáticas con Firebase Cloud Messaging
- ✅ Sistema de roles (cliente, veterinario, recepción, admin)
- ✅ Gestión completa de citas con validación de disponibilidad
- ✅ Códigos QR para identificación rápida de mascotas
- ✅ Historial médico con adjuntos
- ✅ Facturación automática
- ✅ Auditoría completa

## 🏗️ Arquitectura

### Backend
- **Framework**: Laravel 11
- **Base de datos**: MySQL
- **Autenticación**: Laravel Sanctum (tokens API)
- **Permisos**: Spatie Laravel Permission
- **Storage**: Laravel Storage (archivos locales)
- **Jobs**: Laravel Scheduler (recordatorios automáticos)

### Frontend (Flutter)
- **Autenticación**: Firebase Auth + Sanctum tokens
- **Notificaciones**: Firebase Cloud Messaging
- **HTTP**: package:http
- **State**: Provider/Bloc (recomendado)

## 📊 Base de Datos (14 Tablas)

### Tablas Principales
1. **users** - Usuarios del sistema
2. **clientes** - Dueños de mascotas
3. **mascotas** - Pacientes (con QR UUID)
4. **veterinarios** - Médicos veterinarios
5. **servicios** - Catálogo de servicios (vacunas, consultas, cirugías, etc.)
6. **citas** - Agendamiento de citas
7. **cita_servicio** - Servicios por cita (precios congelados)
8. **historial_medico** - Registros médicos
9. **archivos** - Archivos adjuntos (polimórfico)
10. **agendas_disponibilidad** - Horarios de veterinarios
11. **notificaciones** - Sistema de notificaciones
12. **fcm_tokens** - Tokens Firebase para push
13. **facturas** - Facturación
14. **audit_logs** - Auditoría de cambios

### Relaciones Clave
```
User 1:1 Cliente
User 1:1 Veterinario
Cliente 1:N Mascotas
Mascota 1:N Citas
Mascota 1:N HistorialMedico
Veterinario 1:N Citas
Veterinario 1:N AgendaDisponibilidad
Cita M:N Servicios (con pivot cita_servicio)
Cita 1:1 Factura
HistorialMedico 1:N Archivos (morphMany)
```

## 🎯 Funcionalidades Principales

### 1. Gestión de Mascotas
- ✅ CRUD completo con foto
- ✅ Cálculo automático de edad
- ✅ Generación de QR único (UUID)
- ✅ Búsqueda por QR sin autenticación
- ✅ Historial médico completo
- ✅ Prevención de eliminación si tiene historial

### 2. Sistema de Citas
- ✅ Agendamiento con servicios múltiples
- ✅ Validación de disponibilidad del veterinario
- ✅ Detección automática de solapamientos
- ✅ Cálculo de duración sumando servicios
- ✅ Congelamiento de precios al momento de agendar
- ✅ Estados: programada, confirmada, en_curso, completada, cancelada
- ✅ Notificación automática al crear/modificar

### 3. Disponibilidad de Veterinarios
- ✅ Configuración de horarios semanales
- ✅ Día de semana: 0 (domingo) a 6 (sábado)
- ✅ Múltiples bloques horarios por día
- ✅ Vista de agenda con citas existentes
- ✅ API para selección de horarios en frontend

### 4. Historial Médico
- ✅ Registro de consultas (solo veterinarios)
- ✅ Adjuntos múltiples (fotos, PDFs, etc.)
- ✅ Relación polimórfica con archivos
- ✅ Peso y temperatura por visita
- ✅ Diagnóstico y tratamiento
- ✅ Notificación cuando se sube resultado

### 5. Notificaciones
- ✅ Base de datos + Push (FCM)
- ✅ Recordatorios automáticos 24h antes de cita
- ✅ Notificación al crear/cancelar/modificar cita
- ✅ Contador de no leídas para badge
- ✅ Marcar individual o todas como leídas
- ✅ Tipos: recordatorio_cita, cita_creada, cita_cancelada, resultado_disponible, etc.

### 6. Facturación
- ✅ Generación automática desde citas
- ✅ Numeración secuencial anual (FAC-2025-00001)
- ✅ Cálculo de impuestos (16% IVA)
- ✅ Estados: pendiente, pagado, anulado
- ✅ Múltiples métodos de pago
- ✅ Dashboard de estadísticas
- ✅ Filtros por fecha, estado, cliente

### 7. Códigos QR
- ✅ UUID auto-generado para clientes y mascotas
- ✅ Endpoint público para lookup (sin auth)
- ✅ Genera URL + imagen base64
- ✅ Incluye datos de emergencia (dueño, teléfono)

### 8. Auditoría
- ✅ Registro de todas las operaciones importantes
- ✅ Usuario, acción, tabla, registro_id, cambios
- ✅ JSON de cambios realizados
- ✅ Timestamp automático

## 🔐 Sistema de Autenticación

### Flujo Recomendado
```
1. Usuario se registra/login en Firebase (opcional)
2. Firebase retorna ID Token
3. App valida con Laravel API → recibe Sanctum token
4. App guarda Sanctum token en Flutter Secure Storage
5. App obtiene FCM token de Firebase
6. App envía FCM token a Laravel
7. Todas las requests usan: Authorization: Bearer {sanctum_token}
```

### Roles Implementados
- **cliente**: Dueños de mascotas (ven solo sus datos)
- **veterinario**: Médicos (ven sus citas, crean historial)
- **recepcion**: Personal administrativo (acceso completo)
- **admin**: Administrador del sistema (acceso completo)

## 📱 Endpoints por Funcionalidad

### Auth (Sin token)
- POST `/api/auth/register`
- POST `/api/auth/login`

### Auth (Con token)
- POST `/api/auth/logout`

### QR (Sin token)
- GET `/api/qr/lookup/{uuid}`

### CRUD Resources (Con token)
- `/api/clientes` (CRUD)
- `/api/mascotas` (CRUD + foto)
- `/api/veterinarios` (CRUD + disponibilidad)
- `/api/servicios` (CRUD)
- `/api/citas` (CRUD + validaciones)
- `/api/facturas` (CRUD + estadísticas)

### Especiales (Con token)
- POST `/api/fcm-token` (guardar token FCM)
- GET `/api/notificaciones/unread-count`
- POST `/api/notificaciones/mark-all-read`
- GET `/api/veterinarios/{id}/disponibilidad`
- POST `/api/veterinarios/{id}/disponibilidad`
- GET `/api/historial-medico?mascota_id={id}`
- POST `/api/historial-medico/{id}/archivos`
- GET `/api/generar-numero-factura`

## 🔥 Notificaciones Push (FCM)

### Backend envía automáticamente:
1. **Recordatorio de cita** - 24 horas antes (Job diario 08:00 AM)
2. **Cita creada** - Al agendar nueva cita
3. **Cita cancelada** - Al cancelar cita
4. **Cita modificada** - Al reprogramar
5. **Resultado disponible** - Al subir archivos a historial

### Formato de payload:
```json
{
  "notification": {
    "title": "Título",
    "body": "Mensaje"
  },
  "data": {
    "tipo": "recordatorio_cita",
    "cita_id": "5",
    "extra_data": "..."
  }
}
```

## ⚙️ Jobs Automáticos

### Scheduler Configurado
```php
// routes/console.php
Schedule::command('citas:enviar-recordatorios')
    ->dailyAt('08:00')
    ->timezone('America/Mexico_City');
```

### Job: EnviarRecordatoriosCitas
- ✅ Busca citas en próximas 24 horas
- ✅ Crea notificación en BD
- ✅ Intenta enviar push via FCM
- ✅ Fallback a email si FCM falla
- ✅ Ejecuta diariamente a las 08:00 AM

## 🗄️ Seeders Incluidos

### RolesSeeder
- cliente
- veterinario
- recepcion
- admin

### ServiciosSeeder (13 servicios)
- CONS-01: Consulta General ($50, 30min)
- VAC-01: Vacuna Antirrábica ($35, 15min)
- VAC-02: Vacuna Parvovirus ($40, 15min)
- VAC-03: Vacuna Triple Felina ($45, 15min)
- DESP-01: Desparasitación Interna ($25, 10min)
- DESP-02: Desparasitación Externa ($30, 10min)
- BAÑO-01: Baño Básico ($40, 60min)
- BAÑO-02: Baño Completo con Corte ($80, 90min)
- CIR-01: Esterilización ($250, 120min)
- CIR-02: Castración ($200, 90min)
- EXAM-01: Rayos X ($100, 30min)
- EXAM-02: Análisis de Sangre ($80, 20min)
- CONS-02: Consulta de Emergencia ($100, 45min)

## 📦 Archivos de Documentación

1. **API_DOCUMENTATION.md** - Documentación completa y detallada
2. **FLUTTER_QUICK_START.md** - Guía rápida para Flutter
3. **BUSINESS_LOGIC.md** - Reglas de negocio detalladas
4. **README_VETERINARIA.md** - Visión general del proyecto
5. **IMPLEMENTATION_STATUS.md** - Estado de implementación

## 🚀 Comandos Útiles

### Migraciones
```bash
php artisan migrate
php artisan db:seed --class=RolesSeeder
php artisan db:seed --class=ServiciosSeeder
```

### Jobs
```bash
php artisan citas:enviar-recordatorios  # Ejecutar manualmente
```

### Storage
```bash
php artisan storage:link  # Crear symlink para archivos públicos
```

### Testing
```bash
php artisan test
```

## 📈 Estado del Proyecto

### ✅ Completado (100%)

**Base de Datos:**
- ✅ 14 tablas migradas
- ✅ Relaciones establecidas
- ✅ Índices optimizados
- ✅ Constraints de integridad

**Modelos Eloquent:**
- ✅ 14 modelos con relationships
- ✅ Accessors (edad de mascota)
- ✅ Scopes (citas por veterinario)
- ✅ Métodos helper (isVaccine, overlaps)

**Controladores:**
- ✅ AuthController (register, login, logout)
- ✅ ClienteController (CRUD + auditoría)
- ✅ MascotaController (CRUD + foto)
- ✅ VeterinarioController (CRUD + disponibilidad)
- ✅ ServicioController (CRUD + filtros)
- ✅ CitaController (CRUD + validaciones complejas)
- ✅ HistorialController (CRUD + archivos)
- ✅ NotificacionController (CRUD + contador)
- ✅ FacturaController (CRUD + estadísticas)
- ✅ QRController (lookup + generación)
- ✅ FcmTokenController (gestión tokens)

**Rutas:**
- ✅ 70+ endpoints documentados
- ✅ Agrupación por middleware auth
- ✅ Resource routes optimizados
- ✅ Rutas especiales (QR, disponibilidad, etc.)

**Jobs & Scheduler:**
- ✅ EnviarRecordatoriosCitas Job
- ✅ Command wrapper
- ✅ Scheduler configurado

**Seeders:**
- ✅ Roles (4 roles)
- ✅ Servicios (13 servicios base)

**Validaciones:**
- ✅ Overlap detection en citas
- ✅ Ownership validation
- ✅ Dependency checks antes de eliminar
- ✅ Unique constraints (emails, códigos, etc.)

**Documentación:**
- ✅ API completa para Flutter
- ✅ Quick start guide
- ✅ Business logic
- ✅ Resumen ejecutivo

## 🔮 Posibles Mejoras Futuras

### Fase 2 (Opcional)
- [ ] Sistema de recordatorios de vacunas (30 días antes)
- [ ] Dashboard analítico para admin
- [ ] Exportación de reportes (PDF, Excel)
- [ ] Sistema de mensajería entre cliente-veterinario
- [ ] Historial de pagos y estados de cuenta
- [ ] Integración con pasarelas de pago
- [ ] Sistema de citas recurrentes
- [ ] Videoconferencia para teleconsultas
- [ ] Sistema de inventario de medicamentos
- [ ] App móvil completa en Flutter

### Optimizaciones
- [ ] Cache con Redis
- [ ] Queue workers para jobs
- [ ] Búsqueda con Elasticsearch
- [ ] CDN para archivos estáticos
- [ ] Rate limiting por usuario
- [ ] API versioning (v1, v2)

## 👥 Roles del Equipo

### Backend (Laravel)
- ✅ API REST completamente funcional
- ✅ Sistema de autenticación y permisos
- ✅ Jobs automáticos configurados
- ✅ Base de datos optimizada
- ✅ Documentación completa

### Frontend (Flutter)
- 📱 Implementar UI/UX
- 📱 Consumir endpoints documentados
- 📱 Configurar Firebase (Auth + FCM)
- 📱 Implementar navegación
- 📱 State management
- 📱 Escáner QR
- 📱 Notificaciones push
- 📱 Upload de imágenes

## 📞 Información de Contacto

- **Stack**: Laravel 11 + MySQL + Firebase + Flutter
- **Autenticación**: Sanctum + Firebase Auth
- **Notificaciones**: Firebase Cloud Messaging
- **Roles**: Spatie Laravel Permission

---

**Nota:** Este proyecto está 100% funcional del lado backend. El equipo de Flutter puede comenzar inmediatamente el desarrollo frontend usando la documentación proporcionada.

## 📄 Licencia

Proyecto privado. Todos los derechos reservados.
