# 🐾 Veterinaria API

Sistema completo de gestión veterinaria con Laravel, Sanctum y Spatie Permissions.

## 📊 Esquema Completo de Base de Datos

### Tablas Principales

#### **users** (14 campos)
- `id`, `name`, `email`, `password`, `telefono`, `tipo_usuario`, `perfil` (json)
- Tipos: cliente, veterinario, recepcion, admin
- Relaciones: 1:1 con Cliente/Veterinario

#### **clientes** (10 campos)
- `id`, `public_id` (UUID para QR), `user_id`, `nombre`, `email`, `telefono`
- `documento_tipo`, `documento_num`, `direccion`, `notas`

#### **veterinarios** (9 campos)
- `id`, `user_id`, `nombre`, `matricula`, `especialidad`, `telefono`, `email`
- `disponibilidad` (json con horarios flexibles)

#### **mascotas** (11 campos)
- `id`, `public_id` (UUID para QR), `cliente_id`, `nombre`, `especie`, `raza`
- `sexo` (macho/hembra/desconocido), `fecha_nacimiento`, `color`, `chip_id`, `foto_url`

#### **servicios** (8 campos)
- `id`, `codigo` (ej: VAC-01), `nombre`, `descripcion`, `tipo`
- Tipos: vacuna, tratamiento, baño, consulta, cirugía, otro
- `duracion_minutos`, `precio`, `requiere_vacuna_info` (bool)

#### **citas** (13 campos)
- `id`, `cliente_id`, `mascota_id`, `veterinario_id`, `fecha`, `duracion_minutos`
- `estado` (pendiente, confirmado, atendida, cancelada, reprogramada)
- `motivo`, `notas`, `created_by`, `lugar` (clinica/a_domicilio/teleconsulta), `direccion`

#### **cita_servicio** (pivot - 6 campos)
- `id`, `cita_id`, `servicio_id`, `cantidad`, `precio_unitario`, `notas`
- ⚠️ `precio_unitario` congela el precio histórico para trazabilidad

#### **historial_medicos** (11 campos)
- `id`, `mascota_id`, `cita_id`, `fecha`, `tipo` (consulta/vacuna/procedimiento/control/otro)
- `diagnostico`, `tratamiento`, `observaciones`, `realizado_por` (veterinario_id)
- `archivos_meta` (json con metadata de archivos)

#### **archivos** (polymorphic - 8 campos)
- `id`, `relacionado_tipo`, `relacionado_id`, `nombre`, `url`, `tipo_mime`, `size`, `uploaded_by`
- Puede vincularse a: Mascota, Cita, HistorialMedico

#### **notificaciones** (9 campos)
- `id`, `user_id`, `tipo`, `titulo`, `cuerpo`, `leida`, `meta` (json), `sent_via` (push/email/sms)

#### **fcm_tokens** (6 campos)
- `id`, `user_id`, `token`, `plataforma` (android/ios/web), `ultimo_registro`

#### **agendas_disponibilidad** (8 campos)
- `id`, `veterinario_id`, `dia_semana` (0-6), `hora_inicio`, `hora_fin`
- `intervalo_minutos`, `activo`

#### **facturas** (7 campos)
- `id`, `cliente_id`, `cita_id`, `total`, `estado` (pendiente/pagado/anulado)
- `metodo_pago`, `detalles` (json)

#### **audit_logs** (6 campos)
- `id`, `user_id`, `accion`, `tabla`, `registro_id`, `cambios` (json)

---

## 🔗 Relaciones Eloquent Implementadas

```php
User hasOne Cliente, Veterinario
Cliente hasMany Mascotas, Citas, Facturas
Mascota belongsTo Cliente | hasMany HistorialMedicos, Citas
Veterinario hasMany Citas, HistorialMedicos, AgendasDisponibilidad
Cita belongsTo Cliente, Mascota, Veterinario
Cita belongsToMany Servicios (pivot: cita_servicio)
Servicio belongsToMany Citas
HistorialMedico belongsTo Mascota, Cita, Veterinario (realizado_por)
Archivo morphTo (Mascota, Cita, HistorialMedico)
```

---

## 🚀 Instalación y Configuración

### 1. Clonar y configurar entorno

```bash
# Copiar .env y configurar DB
cp .env.example .env

# En .env configurar:
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=veterinaria
DB_USERNAME=root
DB_PASSWORD=
```

### 2. Instalar dependencias

```bash
composer install
npm install
```

### 3. Generar clave y migrar

```bash
php artisan key:generate
php artisan migrate
```

### 4. Instalar Spatie Permissions

```bash
composer require spatie/laravel-permission
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
php artisan migrate
```

### 5. Seed de roles

```bash
php artisan db:seed --class=RolesSeeder
```

Roles creados: `cliente`, `veterinario`, `recepcion`

### 6. Dependencias adicionales (opcional)

```bash
# QR Code
composer require simplesoftwareio/simple-qrcode

# Firebase Cloud Messaging
composer require kreait/laravel-firebase
```

---

## 🔐 Autenticación (Sanctum)

### Endpoints

**POST /api/auth/register**
```json
{
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "cliente"
}
```

**POST /api/auth/login**
```json
{
  "email": "juan@example.com",
  "password": "password123"
}
```

Respuesta:
```json
{
  "user": {...},
  "token": "1|abc123..."
}
```

**POST /api/auth/logout** (requiere Bearer token)

---

## 📋 Reglas de Negocio Clave

### ✅ Creación de Cita
1. Validar que mascota pertenezca al cliente
2. Verificar disponibilidad del veterinario (evitar solapamiento)
3. Si es a domicilio, validar dirección
4. Calcular duración total sumando servicios
5. Congelar precios actuales en pivot `cita_servicio.precio_unitario`
6. Crear notificación y enviar push (FCM)
7. Registrar auditoría

### 🔄 Reprogramar/Cancelar Cita
- Cambiar estado y validar disponibilidad (si reprograma)
- Notificar al cliente
- Registrar quién hizo el cambio en `audit_logs`

### 📲 Sistema QR
- Mascotas y clientes tienen campo `public_id` (UUID)
- QR contiene: `/api/qr/lookup/{uuid}?type=mascota`
- Endpoint devuelve datos completos (historial, cliente, etc.)

### 📝 Historial Médico
- Vincular a `cita_id` si proviene de una cita
- Permitir adjuntar archivos (polymorphic `archivos`)
- Filtros: fecha, veterinario, tipo

### 🔔 Notificaciones Programadas
- Scheduler ejecuta cada hora
- Envía recordatorios 24h antes de cita
- Prioridad: Push (FCM) → Email fallback

---

## 📁 Estructura de Archivos Creados

```
app/
├── Models/
│   ├── User.php (actualizado con HasApiTokens, HasRoles)
│   ├── Cliente.php
│   ├── Mascota.php
│   ├── Veterinario.php
│   ├── Cita.php
│   ├── Servicio.php
│   ├── HistorialMedico.php
│   ├── Archivo.php
│   ├── Notificacion.php
│   ├── FcmToken.php
│   ├── AgendaDisponibilidad.php
│   ├── Factura.php
│   └── AuditLog.php
├── Http/Controllers/
│   └── AuthController.php (registro, login, logout)
database/
├── migrations/
│   ├── 0001_01_01_000000_create_users_table.php (actualizado)
│   ├── 2025_11_05_000001_create_clientes_table.php
│   ├── 2025_11_05_000002_create_mascotas_table.php
│   ├── 2025_11_05_000003_create_veterinarios_table.php
│   ├── 2025_11_05_000004_create_citas_table.php
│   ├── 2025_11_05_000005_create_historial_medicos_table.php
│   ├── 2025_11_05_000006_create_servicios_table.php
│   ├── 2025_11_05_000007_create_cita_servicio_table.php
│   ├── 2025_11_05_000008_create_archivos_table.php
│   ├── 2025_11_05_000009_create_notificaciones_table.php
│   ├── 2025_11_05_000010_create_fcm_tokens_table.php
│   ├── 2025_11_05_000011_create_agendas_disponibilidad_table.php
│   ├── 2025_11_05_000012_create_facturas_table.php
│   ├── 2025_11_05_000013_create_audit_logs_table.php
│   └── 2025_11_05_000014_add_public_id_to_clientes_and_mascotas.php
└── seeders/
    └── RolesSeeder.php
BUSINESS_LOGIC.md (documentación completa)
```

---

## 📖 Documentación Adicional

Ver **`BUSINESS_LOGIC.md`** para:
- Implementación detallada de cada regla de negocio
- Código de ejemplo para validaciones
- Jobs de notificaciones
- Configuración de Scheduler
- Endpoints API sugeridos
- Checklist de implementación

---

## ✅ Estado Actual

✅ Base de datos diseñada (14 tablas)  
✅ Modelos Eloquent con relaciones completas  
✅ AuthController con Sanctum  
✅ RolesSeeder (Spatie)  
✅ UUID para QR en mascotas y clientes  
✅ Documentación de reglas de negocio  

### Próximos pasos:
- [ ] Correr migraciones: `php artisan migrate`
- [ ] Seed roles: `php artisan db:seed --class=RolesSeeder`
- [ ] Crear controladores (Citas, Mascotas, Historial, etc.)
- [ ] Implementar validación de disponibilidad
- [ ] Configurar FCM y jobs de notificaciones
- [ ] Crear rutas API en `routes/api.php`

---

## 🧪 Testing

```bash
# Crear base de datos de testing
php artisan migrate --env=testing

# Ejecutar tests
php artisan test
```

---

## 📞 Contacto

Sistema desarrollado para gestión veterinaria con Laravel 11 y Sanctum.

**Tecnologías:**
- Laravel 11
- MySQL
- Laravel Sanctum (API auth)
- Spatie Laravel Permission (roles)
- Eloquent ORM (relaciones completas)

---

**Licencia:** MIT
