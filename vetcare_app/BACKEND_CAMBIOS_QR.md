# 🔧 Cambios en el Backend Laravel - Sistema QR por Mascota

## 📋 Cambios Necesarios en el Backend

---

## 1️⃣ **Migración de Base de Datos**

### **Agregar campo `qr_code` a la tabla `mascotas`**

Crear migración:
```bash
php artisan make:migration add_qr_code_to_mascotas_table
```

**Archivo:** `database/migrations/XXXX_XX_XX_add_qr_code_to_mascotas_table.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('mascotas', function (Blueprint $table) {
            // Código QR único por mascota
            $table->string('qr_code', 100)->unique()->nullable()->after('id');
            
            // Campos adicionales para info de emergencia
            $table->string('alergias')->nullable()->after('peso');
            $table->text('condiciones_medicas')->nullable()->after('alergias');
            $table->string('tipo_sangre', 20)->nullable()->after('condiciones_medicas');
            $table->string('microchip', 50)->nullable()->after('tipo_sangre');
            
            // Índices para búsquedas rápidas
            $table->index('qr_code');
        });
    }

    public function down(): void
    {
        Schema::table('mascotas', function (Blueprint $table) {
            $table->dropColumn([
                'qr_code', 
                'alergias', 
                'condiciones_medicas', 
                'tipo_sangre',
                'microchip'
            ]);
        });
    }
};
```

Ejecutar migración:
```bash
php artisan migrate
```

---

## 2️⃣ **Crear Tabla de Auditoría de Escaneos QR**

Crear migración:
```bash
php artisan make:migration create_qr_scan_logs_table
```

**Archivo:** `database/migrations/XXXX_XX_XX_create_qr_scan_logs_table.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('qr_scan_logs', function (Blueprint $table) {
            $table->id();
            $table->string('qr_code', 100);
            $table->foreignId('scanned_by')->nullable()->constrained('users')->onDelete('set null');
            $table->ipAddress('ip_address')->nullable();
            $table->string('user_agent')->nullable();
            $table->timestamp('scanned_at');
            $table->timestamps();
            
            // Índices
            $table->index('qr_code');
            $table->index('scanned_by');
            $table->index('scanned_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('qr_scan_logs');
    }
};
```

Ejecutar migración:
```bash
php artisan migrate
```

---

## 3️⃣ **Modelo Mascota Actualizado**

**Archivo:** `app/Models/Mascota.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Mascota extends Model
{
    use HasFactory;

    protected $fillable = [
        'cliente_id',
        'nombre',
        'especie',
        'raza',
        'edad',
        'peso',
        'qr_code',
        'alergias',
        'condiciones_medicas',
        'tipo_sangre',
        'microchip',
    ];

    protected $casts = [
        'edad' => 'integer',
        'peso' => 'float',
    ];

    // ✅ Generar QR automáticamente al crear
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($mascota) {
            if (empty($mascota->qr_code)) {
                $mascota->qr_code = 'VETCARE_PET_' . Str::uuid();
            }
        });
    }

    // Relaciones
    public function cliente()
    {
        return $this->belongsTo(Cliente::class);
    }

    public function historialMedico()
    {
        return $this->hasMany(HistorialMedico::class, 'mascota_id');
    }

    public function citas()
    {
        return $this->hasMany(Cita::class, 'mascota_id');
    }

    // ✅ Método para regenerar QR si es necesario
    public function regenerarQR()
    {
        $this->qr_code = 'VETCARE_PET_' . Str::uuid();
        $this->save();
        return $this->qr_code;
    }

    // ✅ Scope para buscar por QR
    public function scopePorQR($query, $qrCode)
    {
        return $query->where('qr_code', $qrCode);
    }
}
```

---

## 4️⃣ **Modelo de Auditoría de Escaneos**

Crear modelo:
```bash
php artisan make:model QRScanLog
```

**Archivo:** `app/Models/QRScanLog.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class QRScanLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'qr_code',
        'scanned_by',
        'ip_address',
        'user_agent',
        'scanned_at',
    ];

    protected $casts = [
        'scanned_at' => 'datetime',
    ];

    // Relación con usuario que escaneó
    public function usuario()
    {
        return $this->belongsTo(User::class, 'scanned_by');
    }

    // ✅ Método estático para registrar escaneo
    public static function registrar($qrCode, $userId = null)
    {
        return self::create([
            'qr_code' => $qrCode,
            'scanned_by' => $userId,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
            'scanned_at' => now(),
        ]);
    }
}
```

---

## 5️⃣ **Controlador QR**

Crear controlador:
```bash
php artisan make:controller Api/QRController
```

**Archivo:** `app/Http/Controllers/Api/QRController.php`

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Mascota;
use App\Models\Cliente;
use App\Models\QRScanLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class QRController extends Controller
{
    /**
     * 🔍 Buscar información por código QR
     * 
     * @param string $qrCode
     * @return \Illuminate\Http\JsonResponse
     */
    public function lookup($qrCode)
    {
        try {
            // Validar formato de QR
            if (!str_starts_with($qrCode, 'VETCARE_')) {
                return response()->json([
                    'success' => false,
                    'message' => 'Código QR inválido'
                ], 400);
            }

            // Buscar mascota por QR
            $mascota = Mascota::with(['cliente', 'historialMedico' => function($query) {
                $query->orderBy('fecha', 'desc')->limit(10);
            }])
            ->porQR($qrCode)
            ->first();

            if (!$mascota) {
                return response()->json([
                    'success' => false,
                    'message' => 'Mascota no encontrada'
                ], 404);
            }

            // Obtener información del dueño
            $owner = $mascota->cliente;

            // Preparar respuesta con toda la información
            return response()->json([
                'success' => true,
                'pet' => [
                    'id' => $mascota->id,
                    'nombre' => $mascota->nombre,
                    'especie' => $mascota->especie,
                    'raza' => $mascota->raza,
                    'edad' => $mascota->edad,
                    'peso' => $mascota->peso,
                    'alergias' => $mascota->alergias,
                    'condiciones_medicas' => $mascota->condiciones_medicas,
                    'tipo_sangre' => $mascota->tipo_sangre,
                    'microchip' => $mascota->microchip,
                    'qr_code' => $mascota->qr_code,
                ],
                'owner' => [
                    'id' => $owner->id,
                    'nombre' => $owner->nombre ?? $owner->name,
                    'telefono' => $owner->telefono ?? $owner->phone,
                    'email' => $owner->email,
                ],
                'historial' => $mascota->historialMedico->map(function($record) {
                    return [
                        'id' => $record->id,
                        'fecha' => $record->fecha,
                        'diagnostico' => $record->diagnostico,
                        'tratamiento' => $record->tratamiento,
                        'veterinario_id' => $record->veterinario_id,
                    ];
                }),
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al buscar información: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * 📱 Generar QR para una mascota
     * 
     * @param int $mascotaId
     * @return \Illuminate\Http\JsonResponse
     */
    public function generatePetQR($mascotaId)
    {
        try {
            $mascota = Mascota::findOrFail($mascotaId);

            // Si no tiene QR, generarlo
            if (empty($mascota->qr_code)) {
                $mascota->regenerarQR();
            }

            return response()->json([
                'success' => true,
                'qr_code' => $mascota->qr_code,
                'url' => url("/qr/{$mascota->qr_code}"),
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al generar QR: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * 👤 Generar QR para un cliente
     * 
     * @param int $clienteId
     * @return \Illuminate\Http\JsonResponse
     */
    public function generateClientQR($clienteId)
    {
        try {
            $cliente = Cliente::findOrFail($clienteId);

            $qrCode = "VETCARE_CLIENT_{$cliente->id}";

            return response()->json([
                'success' => true,
                'qr_code' => $qrCode,
                'url' => url("/qr/{$qrCode}"),
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al generar QR: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * 🔐 Registrar escaneo de QR (auditoría)
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function logScan(Request $request)
    {
        try {
            $validated = $request->validate([
                'qr_code' => 'required|string',
                'scanned_by' => 'nullable|exists:users,id',
                'scanned_at' => 'required|date',
            ]);

            $log = QRScanLog::registrar(
                $validated['qr_code'],
                $validated['scanned_by'] ?? auth()->id()
            );

            return response()->json([
                'success' => true,
                'message' => 'Escaneo registrado',
                'log_id' => $log->id,
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al registrar escaneo: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * 📊 Obtener historial de escaneos de un QR
     * 
     * @param string $qrCode
     * @return \Illuminate\Http\JsonResponse
     */
    public function scanHistory($qrCode)
    {
        try {
            $logs = QRScanLog::where('qr_code', $qrCode)
                ->with('usuario:id,name,email')
                ->orderBy('scanned_at', 'desc')
                ->paginate(20);

            return response()->json([
                'success' => true,
                'logs' => $logs,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener historial: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * 📈 Estadísticas de escaneos por mascota
     * 
     * @param int $mascotaId
     * @return \Illuminate\Http\JsonResponse
     */
    public function scanStats($mascotaId)
    {
        try {
            $mascota = Mascota::findOrFail($mascotaId);

            $stats = [
                'total_scans' => QRScanLog::where('qr_code', $mascota->qr_code)->count(),
                'scans_last_7_days' => QRScanLog::where('qr_code', $mascota->qr_code)
                    ->where('scanned_at', '>=', now()->subDays(7))
                    ->count(),
                'scans_last_30_days' => QRScanLog::where('qr_code', $mascota->qr_code)
                    ->where('scanned_at', '>=', now()->subDays(30))
                    ->count(),
                'unique_scanners' => QRScanLog::where('qr_code', $mascota->qr_code)
                    ->distinct('scanned_by')
                    ->count('scanned_by'),
                'last_scan' => QRScanLog::where('qr_code', $mascota->qr_code)
                    ->latest('scanned_at')
                    ->first(),
            ];

            return response()->json([
                'success' => true,
                'stats' => $stats,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener estadísticas: ' . $e->getMessage()
            ], 500);
        }
    }
}
```

---

## 6️⃣ **Rutas API**

**Archivo:** `routes/api.php`

```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\QRController;

// Rutas públicas (sin autenticación para emergencias)
Route::prefix('qr')->group(function () {
    // 🔍 Buscar información por QR (acceso público para emergencias)
    Route::get('lookup/{qrCode}', [QRController::class, 'lookup']);
});

// Rutas protegidas (requieren autenticación)
Route::middleware('auth:sanctum')->group(function () {
    
    Route::prefix('qr')->group(function () {
        // 🔐 Registrar escaneo
        Route::post('scan-log', [QRController::class, 'logScan']);
        
        // 📊 Historial de escaneos
        Route::get('scan-history/{qrCode}', [QRController::class, 'scanHistory']);
        
        // 📈 Estadísticas de escaneos
        Route::get('scan-stats/{mascotaId}', [QRController::class, 'scanStats']);
    });

    // 📱 Generar QR para mascota
    Route::get('mascotas/{mascotaId}/qr', [QRController::class, 'generatePetQR']);
    
    // 👤 Generar QR para cliente
    Route::get('clientes/{clienteId}/qr', [QRController::class, 'generateClientQR']);
});
```

---

## 7️⃣ **Seeders (Datos de Prueba)**

Crear seeder:
```bash
php artisan make:seeder MascotasQRSeeder
```

**Archivo:** `database/seeders/MascotasQRSeeder.php`

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Mascota;
use Illuminate\Support\Str;

class MascotasQRSeeder extends Seeder
{
    public function run(): void
    {
        // Actualizar todas las mascotas existentes con QR
        $mascotas = Mascota::whereNull('qr_code')->get();

        foreach ($mascotas as $mascota) {
            $mascota->update([
                'qr_code' => 'VETCARE_PET_' . Str::uuid(),
                'alergias' => $this->randomAllergies(),
                'tipo_sangre' => $this->randomBloodType(),
            ]);
        }

        $this->command->info('✅ QR codes generados para ' . $mascotas->count() . ' mascotas');
    }

    private function randomAllergies()
    {
        $allergies = ['Ninguna', 'Penicilina', 'Polen', 'Pulgas', 'Alimentos'];
        return $allergies[array_rand($allergies)];
    }

    private function randomBloodType()
    {
        $types = ['DEA 1.1+', 'DEA 1.1-', 'DEA 1.2+', 'DEA 3+', 'A', 'B', 'AB'];
        return $types[array_rand($types)];
    }
}
```

Ejecutar seeder:
```bash
php artisan db:seed --class=MascotasQRSeeder
```

---

## 8️⃣ **Middleware de Seguridad (Opcional)**

Crear middleware para limitar escaneos:
```bash
php artisan make:middleware QRScanRateLimiter
```

**Archivo:** `app/Http/Middleware/QRScanRateLimiter.php`

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;

class QRScanRateLimiter
{
    public function handle(Request $request, Closure $next)
    {
        $key = 'qr-scan:' . $request->ip();

        // Limitar a 60 escaneos por minuto por IP
        if (RateLimiter::tooManyAttempts($key, 60)) {
            return response()->json([
                'success' => false,
                'message' => 'Demasiados escaneos. Intenta más tarde.'
            ], 429);
        }

        RateLimiter::hit($key, 60);

        return $next($request);
    }
}
```

Registrar middleware en `app/Http/Kernel.php`:
```php
protected $middlewareAliases = [
    // ...
    'qr.ratelimit' => \App\Http\Middleware\QRScanRateLimiter::class,
];
```

Aplicar en rutas:
```php
Route::get('lookup/{qrCode}', [QRController::class, 'lookup'])
    ->middleware('qr.ratelimit');
```

---

## 9️⃣ **Tests (Opcional pero Recomendado)**

Crear test:
```bash
php artisan make:test QRSystemTest
```

**Archivo:** `tests/Feature/QRSystemTest.php`

```php
<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Mascota;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

class QRSystemTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_lookup_pet_by_qr()
    {
        $mascota = Mascota::factory()->create([
            'qr_code' => 'VETCARE_PET_TEST123'
        ]);

        $response = $this->getJson('/api/qr/lookup/VETCARE_PET_TEST123');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'pet' => [
                    'nombre' => $mascota->nombre,
                ],
            ]);
    }

    public function test_generates_qr_for_pet()
    {
        $user = User::factory()->create();
        $mascota = Mascota::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/mascotas/{$mascota->id}/qr");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'qr_code',
                'url',
            ]);
    }

    public function test_logs_qr_scan()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/qr/scan-log', [
                'qr_code' => 'VETCARE_PET_TEST',
                'scanned_at' => now()->toIso8601String(),
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseHas('qr_scan_logs', [
            'qr_code' => 'VETCARE_PET_TEST',
            'scanned_by' => $user->id,
        ]);
    }
}
```

Ejecutar tests:
```bash
php artisan test --filter=QRSystemTest
```

---

## 🔟 **Comandos Artisan Útiles**

### **Generar QRs para mascotas sin código**
```bash
php artisan make:command GenerateMissingQRCodes
```

**Archivo:** `app/Console/Commands/GenerateMissingQRCodes.php`

```php
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Mascota;

class GenerateMissingQRCodes extends Command
{
    protected $signature = 'qr:generate-missing';
    protected $description = 'Genera códigos QR para mascotas que no tienen';

    public function handle()
    {
        $mascotas = Mascota::whereNull('qr_code')->get();

        if ($mascotas->isEmpty()) {
            $this->info('✅ Todas las mascotas ya tienen QR');
            return 0;
        }

        $bar = $this->output->createProgressBar($mascotas->count());
        $bar->start();

        foreach ($mascotas as $mascota) {
            $mascota->regenerarQR();
            $bar->advance();
        }

        $bar->finish();
        $this->newLine();
        $this->info("✅ QR generados para {$mascotas->count()} mascotas");

        return 0;
    }
}
```

Ejecutar comando:
```bash
php artisan qr:generate-missing
```

---

## 📊 **Resumen de Endpoints API**

### **Públicos (Sin autenticación)**
```
GET /api/qr/lookup/{qrCode}
→ Obtiene información completa de mascota por QR
→ Incluye: perfil, dueño, historial médico, emergencia
```

### **Protegidos (Requieren auth:sanctum)**
```
POST /api/qr/scan-log
→ Registra escaneo de QR para auditoría

GET /api/qr/scan-history/{qrCode}
→ Obtiene historial de escaneos

GET /api/qr/scan-stats/{mascotaId}
→ Estadísticas de escaneos por mascota

GET /api/mascotas/{mascotaId}/qr
→ Genera/obtiene QR de mascota

GET /api/clientes/{clienteId}/qr
→ Genera QR de cliente
```

---

## ✅ **Checklist de Implementación**

### **Base de Datos:**
- [ ] Migración `add_qr_code_to_mascotas_table` creada y ejecutada
- [ ] Migración `create_qr_scan_logs_table` creada y ejecutada
- [ ] Campos de emergencia agregados (alergias, tipo_sangre, etc.)

### **Modelos:**
- [ ] Modelo `Mascota` actualizado con campo `qr_code`
- [ ] Método `boot()` implementado para auto-generar QR
- [ ] Modelo `QRScanLog` creado
- [ ] Relaciones configuradas correctamente

### **Controladores:**
- [ ] `QRController` creado
- [ ] Método `lookup()` implementado
- [ ] Método `generatePetQR()` implementado
- [ ] Método `logScan()` implementado
- [ ] Métodos de estadísticas implementados

### **Rutas:**
- [ ] Rutas públicas configuradas
- [ ] Rutas protegidas con `auth:sanctum`
- [ ] Middleware de rate limiting (opcional)

### **Seguridad:**
- [ ] Validación de formato QR (VETCARE_*)
- [ ] Rate limiting en endpoint público
- [ ] Logs de auditoría funcionando
- [ ] Permisos por rol (opcional)

### **Datos:**
- [ ] Seeder ejecutado para mascotas existentes
- [ ] Comando artisan para generar QRs faltantes
- [ ] Tests básicos pasando (opcional)

---

## 🚀 **Comandos de Instalación Rápida**

Ejecuta estos comandos en orden:

```bash
# 1. Crear migraciones
php artisan make:migration add_qr_code_to_mascotas_table
php artisan make:migration create_qr_scan_logs_table

# 2. Ejecutar migraciones
php artisan migrate

# 3. Crear modelos y controladores
php artisan make:model QRScanLog
php artisan make:controller Api/QRController

# 4. Crear seeder
php artisan make:seeder MascotasQRSeeder

# 5. Ejecutar seeder
php artisan db:seed --class=MascotasQRSeeder

# 6. Crear comando artisan
php artisan make:command GenerateMissingQRCodes

# 7. Limpiar caché
php artisan config:clear
php artisan cache:clear
php artisan route:clear

# 8. Probar endpoint
curl http://localhost:8000/api/qr/lookup/VETCARE_PET_TEST
```

---

## 🧪 **Prueba Manual en Postman**

### **1. Buscar mascota por QR (público)**
```
GET http://localhost:8000/api/qr/lookup/VETCARE_PET_123

Response:
{
  "success": true,
  "pet": {
    "id": 1,
    "nombre": "Firulais",
    "especie": "Perro",
    "raza": "Golden Retriever",
    "edad": 5,
    "peso": 30.5,
    "alergias": "Penicilina",
    "tipo_sangre": "DEA 1.1+",
    ...
  },
  "owner": {
    "nombre": "Juan Pérez",
    "telefono": "+123456789",
    "email": "juan@example.com"
  },
  "historial": [...]
}
```

### **2. Generar QR para mascota (protegido)**
```
GET http://localhost:8000/api/mascotas/1/qr
Authorization: Bearer {token}

Response:
{
  "success": true,
  "qr_code": "VETCARE_PET_abc123",
  "url": "http://localhost:8000/qr/VETCARE_PET_abc123"
}
```

### **3. Registrar escaneo (protegido)**
```
POST http://localhost:8000/api/qr/scan-log
Authorization: Bearer {token}
Content-Type: application/json

Body:
{
  "qr_code": "VETCARE_PET_123",
  "scanned_by": 1,
  "scanned_at": "2025-01-07T10:30:00Z"
}

Response:
{
  "success": true,
  "message": "Escaneo registrado",
  "log_id": 42
}
```

---

## 🔒 **Consideraciones de Seguridad**

1. **Rate Limiting:** Limita escaneos por IP para prevenir abuso
2. **Validación:** Solo acepta QR con formato `VETCARE_*`
3. **Auditoría:** Registra cada escaneo con IP y user agent
4. **Permisos:** Endpoints protegidos requieren autenticación
5. **Encriptación:** Datos sensibles en HTTPS
6. **CORS:** Configurar correctamente para la app móvil

---

## 📝 **Notas Finales**

- El endpoint `lookup` es **público** para permitir acceso en emergencias
- Los QR se generan automáticamente al crear una mascota
- Puedes regenerar QR si es necesario con `$mascota->regenerarQR()`
- Los logs de escaneo permiten rastrear quién accedió al historial
- Considera agregar notificaciones al dueño cuando se escanea el QR

---

**✅ Con estos cambios, el backend está listo para soportar el sistema de QR único por mascota**

**Última actualización: 7 de noviembre de 2025**

