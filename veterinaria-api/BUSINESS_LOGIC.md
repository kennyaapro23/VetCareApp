# Veterinaria API - Reglas de Negocio

## 📋 Resumen de Relaciones Eloquent

### User (Usuario del sistema)
- `hasOne(Cliente::class)` - Un usuario puede ser un cliente
- `hasOne(Veterinario::class)` - Un usuario puede ser un veterinario
- `hasMany(Notificacion::class)` - Notificaciones del usuario
- `hasMany(FcmToken::class)` - Tokens FCM para push notifications
- `hasMany(AuditLog::class)` - Registro de auditoría
- Usa traits: `HasApiTokens` (Sanctum), `HasRoles` (Spatie)

### Cliente
- `belongsTo(User::class)` - Relación con usuario (opcional, 1:1)
- `hasMany(Mascota::class)` - Un cliente tiene muchas mascotas
- `hasMany(Cita::class)` - Un cliente tiene muchas citas
- `hasMany(Factura::class)` - Facturas del cliente

### Mascota
- `belongsTo(Cliente::class)` - Pertenece a un cliente
- `hasMany(HistorialMedico::class)` - Historial médico de la mascota
- `hasMany(Cita::class)` - Citas programadas
- `morphMany(Archivo::class, 'relacionado')` - Archivos adjuntos (fotos, documentos)

### Veterinario
- `belongsTo(User::class)` - Relación con usuario (opcional, 1:1)
- `hasMany(Cita::class)` - Citas asignadas al veterinario
- `hasMany(HistorialMedico::class, 'realizado_por')` - Historial médico registrado
- `hasMany(AgendaDisponibilidad::class)` - Horarios de disponibilidad

### Cita (Appointment)
- `belongsTo(Cliente::class)` - Cliente que solicita la cita
- `belongsTo(Mascota::class)` - Mascota a atender
- `belongsTo(Veterinario::class)` - Veterinario asignado
- `belongsTo(User::class, 'created_by')` - Usuario que creó la cita (recepción)
- `belongsToMany(Servicio::class, 'cita_servicio')` - Servicios de la cita (pivot)
  - Pivot: `cantidad`, `precio_unitario`, `notas`
- `hasMany(HistorialMedico::class)` - Historial generado desde la cita
- `hasMany(Factura::class)` - Facturas asociadas
- `morphMany(Archivo::class, 'relacionado')` - Archivos adjuntos

### Servicio
- `belongsToMany(Cita::class, 'cita_servicio')` - Citas que usan este servicio
  - Pivot: `cantidad`, `precio_unitario`, `notas`

### HistorialMedico
- `belongsTo(Mascota::class)` - Mascota del historial
- `belongsTo(Cita::class)` - Cita que generó este registro (opcional)
- `belongsTo(Veterinario::class, 'realizado_por')` - Veterinario que registró
- `morphMany(Archivo::class, 'relacionado')` - Archivos adjuntos (radiografías, análisis)

### Archivo (Attachment - Polymorphic)
- `morphTo('relacionado')` - Puede pertenecer a: Mascota, Cita, HistorialMedico
- `belongsTo(User::class, 'uploaded_by')` - Usuario que subió el archivo

### Notificacion
- `belongsTo(User::class)` - Usuario destinatario

### FcmToken
- `belongsTo(User::class)` - Usuario propietario del token

### AgendaDisponibilidad
- `belongsTo(Veterinario::class)` - Veterinario con disponibilidad

### Factura
- `belongsTo(Cliente::class)` - Cliente facturado
- `belongsTo(Cita::class)` - Cita asociada (opcional)

### AuditLog
- `belongsTo(User::class)` - Usuario que realizó la acción

---

## 🔐 Reglas de Negocio - Implementación

### 1. **Creación de Cita** (`CitaController@store`)

#### Validaciones:
```php
// 1. Validar que la mascota pertenezca al cliente
$mascota = Mascota::findOrFail($request->mascota_id);
if ($mascota->cliente_id !== $request->cliente_id) {
    return response()->json(['error' => 'La mascota no pertenece al cliente'], 422);
}

// 2. Verificar disponibilidad del veterinario (evitar solapamiento)
$fecha = Carbon::parse($request->fecha);
$duracion = $request->duracion_minutos ?? 30;

$conflicto = Cita::where('veterinario_id', $request->veterinario_id)
    ->where('estado', '!=', 'cancelada')
    ->where(function ($query) use ($fecha, $duracion) {
        $query->whereBetween('fecha', [
            $fecha,
            $fecha->copy()->addMinutes($duracion)
        ])
        ->orWhere(function ($q) use ($fecha, $duracion) {
            $q->where('fecha', '<=', $fecha)
              ->whereRaw('DATE_ADD(fecha, INTERVAL duracion_minutos MINUTE) > ?', [$fecha]);
        });
    })
    ->exists();

if ($conflicto) {
    return response()->json(['error' => 'El veterinario no está disponible en ese horario'], 409);
}

// 3. Si es a domicilio, validar dirección
if ($request->lugar === 'a_domicilio' && empty($request->direccion)) {
    return response()->json(['error' => 'Debe proporcionar una dirección para citas a domicilio'], 422);
}

// 4. Calcular duración total basada en servicios seleccionados
$servicios = Servicio::whereIn('id', $request->servicios)->get();
$duracion_total = $servicios->sum('duracion_minutos');
```

#### Creación:
```php
// Crear la cita
$cita = Cita::create([
    'cliente_id' => $request->cliente_id,
    'mascota_id' => $request->mascota_id,
    'veterinario_id' => $request->veterinario_id,
    'fecha' => $request->fecha,
    'duracion_minutos' => $duracion_total,
    'estado' => 'pendiente',
    'motivo' => $request->motivo,
    'notas' => $request->notas,
    'created_by' => auth()->id(),
    'lugar' => $request->lugar ?? 'clinica',
    'direccion' => $request->direccion,
]);

// Adjuntar servicios con precios actuales (para trazabilidad histórica)
foreach ($servicios as $servicio) {
    $cita->servicios()->attach($servicio->id, [
        'cantidad' => 1, // O desde el request
        'precio_unitario' => $servicio->precio, // Precio actual congelado
        'notas' => null,
    ]);
}

// Crear notificación
Notificacion::create([
    'user_id' => $cita->cliente->user_id,
    'tipo' => 'cita_confirmada',
    'titulo' => 'Cita Confirmada',
    'cuerpo' => "Tu cita para {$mascota->nombre} ha sido confirmada para el {$fecha->format('d/m/Y H:i')}",
    'meta' => ['cita_id' => $cita->id],
    'sent_via' => 'push',
]);

// Enviar push notification via FCM
dispatch(new SendPushNotificationJob($cita->cliente->user_id, [
    'title' => 'Cita Confirmada',
    'body' => "Tu cita para {$mascota->nombre} ha sido confirmada",
    'data' => ['cita_id' => $cita->id, 'type' => 'cita_confirmada'],
]));

// Registrar auditoría
AuditLog::create([
    'user_id' => auth()->id(),
    'accion' => 'crear_cita',
    'tabla' => 'citas',
    'registro_id' => $cita->id,
    'cambios' => $cita->toArray(),
]);
```

---

### 2. **Reprogramar / Cancelar Cita** (`CitaController@update`)

```php
// Reprogramar
if ($request->has('fecha')) {
    // Validar disponibilidad del veterinario (igual que creación)
    // ...
    
    $cita->update([
        'fecha' => $request->fecha,
        'estado' => 'reprogramada',
    ]);
    
    // Notificar al cliente
    Notificacion::create([
        'user_id' => $cita->cliente->user_id,
        'tipo' => 'cita_reprogramada',
        'titulo' => 'Cita Reprogramada',
        'cuerpo' => "Tu cita ha sido reprogramada para el {$request->fecha}",
        'meta' => ['cita_id' => $cita->id],
    ]);
}

// Cancelar
if ($request->estado === 'cancelada') {
    $cita->update(['estado' => 'cancelada']);
    
    // Notificar cancelación
    Notificacion::create([
        'user_id' => $cita->cliente->user_id,
        'tipo' => 'cita_cancelada',
        'titulo' => 'Cita Cancelada',
        'cuerpo' => 'Tu cita ha sido cancelada',
        'meta' => ['cita_id' => $cita->id],
    ]);
}

// Registrar quién hizo el cambio
AuditLog::create([
    'user_id' => auth()->id(),
    'accion' => $request->estado === 'cancelada' ? 'cancelar_cita' : 'reprogramar_cita',
    'tabla' => 'citas',
    'registro_id' => $cita->id,
    'cambios' => $cita->getChanges(),
]);
```

---

### 3. **Generación de QR** (`QrController`)

#### Migración adicional (agregar campo UUID):
```php
// En migrations de mascotas y clientes:
$table->uuid('public_id')->unique()->index();
```

#### Generación:
```php
use Illuminate\Support\Str;

// Al crear mascota/cliente
$mascota->public_id = (string) Str::uuid();
$mascota->save();

// Generar QR
$qr_data = route('api.qr.lookup', ['token' => $mascota->public_id, 'type' => 'mascota']);
// Usar librería: SimpleSoftwareIO/simple-qrcode
$qr_image = QrCode::format('png')->size(300)->generate($qr_data);
```

#### Endpoint de lookup:
```php
// routes/api.php
Route::get('/qr/lookup/{token}', [QrController::class, 'lookup']);

// QrController@lookup
public function lookup($token, Request $request)
{
    $type = $request->query('type', 'mascota');
    
    if ($type === 'mascota') {
        $mascota = Mascota::where('public_id', $token)->firstOrFail();
        return response()->json([
            'type' => 'mascota',
            'data' => $mascota->load('cliente', 'historialMedicos.realizadoPor'),
        ]);
    }
    
    if ($type === 'cliente') {
        $cliente = Cliente::where('public_id', $token)->firstOrFail();
        return response()->json([
            'type' => 'cliente',
            'data' => $cliente->load('mascotas'),
        ]);
    }
    
    return response()->json(['error' => 'Tipo no válido'], 400);
}
```

---

### 4. **Historial Médico** (`HistorialMedicoController`)

#### Crear registro:
```php
$historial = HistorialMedico::create([
    'mascota_id' => $request->mascota_id,
    'cita_id' => $request->cita_id, // Opcional, si viene de una cita
    'fecha' => now(),
    'tipo' => $request->tipo, // consulta, vacuna, procedimiento, control, otro
    'diagnostico' => $request->diagnostico,
    'tratamiento' => $request->tratamiento,
    'observaciones' => $request->observaciones,
    'realizado_por' => auth()->user()->veterinario->id,
]);

// Adjuntar archivos (si existen)
if ($request->hasFile('archivos')) {
    foreach ($request->file('archivos') as $file) {
        $path = $file->store('historial_medico', 'public');
        
        Archivo::create([
            'relacionado_tipo' => 'App\Models\HistorialMedico',
            'relacionado_id' => $historial->id,
            'nombre' => $file->getClientOriginalName(),
            'url' => Storage::url($path),
            'tipo_mime' => $file->getMimeType(),
            'size' => $file->getSize(),
            'uploaded_by' => auth()->id(),
        ]);
    }
}

// También se puede guardar metadata en JSON
$historial->update([
    'archivos_meta' => $archivos_info, // Array de metadata
]);
```

#### Filtros:
```php
// GET /api/historial-medico?mascota_id=1&tipo=vacuna&fecha_desde=2025-01-01&veterinario_id=2
$query = HistorialMedico::query();

if ($request->has('mascota_id')) {
    $query->where('mascota_id', $request->mascota_id);
}

if ($request->has('tipo')) {
    $query->where('tipo', $request->tipo);
}

if ($request->has('fecha_desde')) {
    $query->where('fecha', '>=', $request->fecha_desde);
}

if ($request->has('fecha_hasta')) {
    $query->where('fecha', '<=', $request->fecha_hasta);
}

if ($request->has('veterinario_id')) {
    $query->where('realizado_por', $request->veterinario_id);
}

$historial = $query->with('realizadoPor', 'mascota', 'archivos')->get();
```

---

### 5. **Servicios - Trazabilidad de Precios**

**⚠️ IMPORTANTE**: Los precios se guardan en el pivot `cita_servicio.precio_unitario` al momento de crear la cita.

```php
// Al crear cita, copiar precio actual
$servicio = Servicio::find($servicio_id);
$cita->servicios()->attach($servicio->id, [
    'cantidad' => $cantidad,
    'precio_unitario' => $servicio->precio, // ← Precio histórico congelado
    'notas' => $notas,
]);

// Más adelante, si el precio del servicio cambia:
$servicio->update(['precio' => 150.00]); // Nuevo precio

// Las citas antiguas mantienen el precio original en el pivot:
$cita->servicios->first()->pivot->precio_unitario; // Precio antiguo
$servicio->precio; // Precio actual (nuevo)
```

---

### 6. **Notificaciones Programadas** (Recordatorios)

#### En `app/Console/Kernel.php`:
```php
protected function schedule(Schedule $schedule)
{
    // Enviar recordatorios 24 horas antes de la cita
    $schedule->call(function () {
        $citas = Cita::where('estado', 'confirmado')
            ->whereBetween('fecha', [
                now()->addHours(23),
                now()->addHours(25)
            ])
            ->get();
        
        foreach ($citas as $cita) {
            // Crear notificación
            Notificacion::create([
                'user_id' => $cita->cliente->user_id,
                'tipo' => 'recordatorio_cita',
                'titulo' => 'Recordatorio de Cita',
                'cuerpo' => "Recordatorio: Tienes una cita mañana a las {$cita->fecha->format('H:i')} para {$cita->mascota->nombre}",
                'meta' => ['cita_id' => $cita->id],
                'sent_via' => 'push',
            ]);
            
            // Enviar push notification
            $tokens = FcmToken::where('user_id', $cita->cliente->user_id)->pluck('token');
            
            if ($tokens->isNotEmpty()) {
                dispatch(new SendFcmNotificationJob($tokens, [
                    'title' => 'Recordatorio de Cita',
                    'body' => "Cita mañana para {$cita->mascota->nombre}",
                    'data' => ['cita_id' => $cita->id],
                ]));
            } else {
                // Fallback a email
                Mail::to($cita->cliente->email)->send(new CitaReminderMail($cita));
            }
        }
    })->hourly(); // Ejecutar cada hora
}
```

#### Job para enviar FCM:
```php
// app/Jobs/SendFcmNotificationJob.php
public function handle()
{
    $fcm = app('firebase.messaging');
    
    $message = CloudMessage::new()
        ->withNotification(Notification::create($this->title, $this->body))
        ->withData($this->data);
    
    foreach ($this->tokens as $token) {
        try {
            $fcm->send($message->withChangedTarget('token', $token));
        } catch (\Exception $e) {
            Log::error("Error enviando FCM: {$e->getMessage()}");
        }
    }
}
```

---

## 📦 Dependencias Recomendadas

```bash
# Sanctum (ya instalado)
composer require laravel/sanctum

# Spatie Roles & Permissions
composer require spatie/laravel-permission

# QR Code
composer require simplesoftwareio/simple-qrcode

# Firebase Cloud Messaging
composer require kreait/laravel-firebase
```

---

## 🚀 Endpoints API Sugeridos

```
POST   /api/auth/register          - Registro con asignación de rol
POST   /api/auth/login             - Login con token
POST   /api/auth/logout            - Logout

GET    /api/clientes               - Listar clientes
POST   /api/clientes               - Crear cliente
GET    /api/clientes/{id}          - Ver cliente
PUT    /api/clientes/{id}          - Actualizar cliente
DELETE /api/clientes/{id}          - Eliminar cliente

GET    /api/mascotas               - Listar mascotas
POST   /api/mascotas               - Crear mascota
GET    /api/mascotas/{id}          - Ver mascota con historial
GET    /api/mascotas/{id}/qr       - Generar QR de mascota

GET    /api/veterinarios           - Listar veterinarios
GET    /api/veterinarios/{id}/disponibilidad - Ver horarios

GET    /api/citas                  - Listar citas (filtros: fecha, estado, veterinario)
POST   /api/citas                  - Crear cita (validar disponibilidad)
PUT    /api/citas/{id}             - Reprogramar/cancelar cita
GET    /api/citas/{id}             - Ver detalle

GET    /api/servicios              - Listar servicios
POST   /api/servicios              - Crear servicio

GET    /api/historial-medico       - Listar historial (filtros)
POST   /api/historial-medico       - Crear registro
POST   /api/historial-medico/{id}/archivos - Adjuntar archivos

GET    /api/qr/lookup/{token}      - Lookup de QR (mascota/cliente)

GET    /api/notificaciones         - Listar notificaciones del usuario
PUT    /api/notificaciones/{id}/leer - Marcar como leída

POST   /api/fcm-tokens             - Registrar token FCM
```

---

## ✅ Checklist de Implementación

- [ ] Instalar dependencias (Spatie, QR, Firebase)
- [ ] Configurar Spatie permissions y correr migraciones
- [ ] Implementar validación de disponibilidad en `CitaController`
- [ ] Crear Job para envío de FCM notifications
- [ ] Configurar Scheduler para recordatorios automáticos
- [ ] Implementar QR generation y lookup
- [ ] Agregar campos `public_id` (UUID) a mascotas y clientes
- [ ] Crear middleware para validar roles (cliente, veterinario, recepcion, admin)
- [ ] Implementar audit logs en eventos de Eloquent (observers)
- [ ] Configurar storage para archivos adjuntos
- [ ] Crear FormRequests para validación robusta
- [ ] Implementar tests unitarios y de integración

