# ✅ Verificación: Backend debe incluir servicios al listar historial médico

## 📋 Estado Actual

**Flutter:** ✅ TODO IMPLEMENTADO
- Modelo `HistorialMedico` con propiedad `servicios`
- UI que muestra badge con número de servicios y total
- Diálogo que lista servicios con detalles (cantidad, precio, notas)
- Cálculo de total automático

**Backend:** ⚠️ VERIFICAR

---

## 🔍 Qué verificar en Laravel

### 1. Controlador: HistorialMedicoController

**Archivo:** `app/Http/Controllers/HistorialMedicoController.php` (o `app/Http/Controllers/Api/HistorialMedicoController.php`)

**Método `index()` debe incluir:**
```php
public function index(Request $request)
{
    $query = HistorialMedico::query();
    
    // Filtros opcionales
    if ($request->has('mascota_id')) {
        $query->where('mascota_id', $request->mascota_id);
    }
    
    // ⭐ IMPORTANTE: Incluir relación servicios con pivot
    $query->with(['servicios' => function ($q) {
        $q->select('servicios.id', 'servicios.nombre', 'servicios.descripcion', 'servicios.tipo');
    }]);
    
    $historiales = $query->orderBy('fecha', 'desc')->get();
    
    // ⭐ Calcular total_servicios para cada historial
    $historiales->each(function ($historial) {
        $historial->total_servicios = $historial->servicios->sum(function ($servicio) {
            return $servicio->pivot->cantidad * $servicio->pivot->precio_unitario;
        });
    });
    
    return response()->json($historiales);
}
```

**Método `show()` debe incluir:**
```php
public function show($id)
{
    $historial = HistorialMedico::with(['mascota', 'cita', 'servicios'])
        ->findOrFail($id);
    
    // Calcular total_servicios
    $historial->total_servicios = $historial->servicios->sum(function ($servicio) {
        return $servicio->pivot->cantidad * $servicio->pivot->precio_unitario;
    });
    
    return response()->json($historial);
}
```

---

### 2. Modelo: HistorialMedico

**Archivo:** `app/Models/HistorialMedico.php`

**Debe tener relación `servicios()`:**
```php
public function servicios()
{
    return $this->belongsToMany(Servicio::class, 'historial_servicio')
                ->withPivot('cantidad', 'precio_unitario', 'notas')
                ->withTimestamps();
}
```

**Debe tener accessor `getTotalServiciosAttribute()`:**
```php
public function getTotalServiciosAttribute()
{
    return $this->servicios->sum(function ($servicio) {
        return $servicio->pivot->cantidad * $servicio->pivot->precio_unitario;
    });
}
```

**Debe incluir en `$appends` (opcional pero recomendado):**
```php
protected $appends = ['total_servicios'];
```

---

### 3. Tabla pivote: historial_servicio

**Debe tener columnas:**
- `id` (primary key, auto_increment)
- `historial_medico_id` (foreign key → historial_medicos.id)
- `servicio_id` (foreign key → servicios.id)
- `cantidad` (integer, default 1)
- `precio_unitario` (decimal(10,2))
- `notas` (text, nullable)
- `created_at` (timestamp)
- `updated_at` (timestamp)

**Si falta, crear migración:**
```bash
cd C:\Users\kenny\VetCareApp\veterinaria-api
php artisan make:migration create_historial_servicio_table
```

Contenido:
```php
public function up()
{
    Schema::create('historial_servicio', function (Blueprint $table) {
        $table->id();
        $table->foreignId('historial_medico_id')->constrained('historial_medicos')->onDelete('cascade');
        $table->foreignId('servicio_id')->constrained('servicios')->onDelete('cascade');
        $table->integer('cantidad')->default(1);
        $table->decimal('precio_unitario', 10, 2)->default(0);
        $table->text('notas')->nullable();
        $table->timestamps();
        
        // Índices
        $table->index(['historial_medico_id', 'servicio_id']);
    });
}
```

---

## 🧪 Cómo probar

### 1. Verificar endpoint manualmente

**GET** `http://127.0.0.1:8000/api/historial-medico?mascota_id=5`

**Respuesta esperada:**
```json
[
  {
    "id": 1,
    "mascota_id": 5,
    "cita_id": 3,
    "fecha": "2025-11-09T12:00:00.000000Z",
    "tipo": "consulta",
    "diagnostico": "Revisión rutinaria",
    "tratamiento": "Ninguno",
    "servicios": [
      {
        "id": 1,
        "nombre": "Baño Medicado",
        "pivot": {
          "cantidad": 1,
          "precio_unitario": 50.00,
          "notas": ""
        }
      },
      {
        "id": 4,
        "nombre": "Vacunación",
        "pivot": {
          "cantidad": 2,
          "precio_unitario": 15.00,
          "notas": "Antirrábica + moquillo"
        }
      }
    ],
    "total_servicios": 80.00
  }
]
```

### 2. Verificar con curl (PowerShell)

```powershell
$token = "28|0OFJr3q9ob4hkQVzi..."
curl -H "Authorization: Bearer $token" http://127.0.0.1:8000/api/historial-medico?mascota_id=5
```

### 3. Verificar en la app Flutter

1. Ejecutar app: `flutter run`
2. Login como veterinario
3. Ir a citas → Tocar cita → Ver perfil mascota
4. Tab "Historial"
5. Si hay historiales con servicios, debe aparecer badge con:
   - 🏥 Servicios: 2
   - $ 80.00
6. Tocar badge → Se abre diálogo con lista de servicios

---

## ❌ Problemas comunes

### Error: "servicios" viene vacío `[]`

**Causa:** Backend no carga relación o no hay datos en tabla pivote  
**Solución:**
1. Verificar que el controlador tenga `->with('servicios')`
2. Verificar que existan registros en `historial_servicio`
3. Query manual: `SELECT * FROM historial_servicio WHERE historial_medico_id = 1;`

### Error: "pivot" no tiene datos

**Causa:** Relación no tiene `withPivot()`  
**Solución:**
```php
->withPivot('cantidad', 'precio_unitario', 'notas')
```

### Error: "total_servicios" es null o 0

**Causa:** Accessor no está calculando o servicios están vacíos  
**Solución:**
1. Verificar accessor `getTotalServiciosAttribute()`
2. O calcular manualmente en controlador (ver código arriba)

### Error: Tabla 'historial_servicio' no existe

**Causa:** Falta migración  
**Solución:**
```bash
php artisan make:migration create_historial_servicio_table
# Copiar código de arriba
php artisan migrate
```

---

## ✅ Checklist Backend

- [ ] Modelo `HistorialMedico` tiene relación `servicios()` con `withPivot()`
- [ ] Accessor `getTotalServiciosAttribute()` implementado
- [ ] Controlador `index()` incluye `->with('servicios')`
- [ ] Controlador `show()` incluye `->with('servicios')`
- [ ] Tabla `historial_servicio` existe con columnas correctas
- [ ] Existen registros en `historial_servicio` para probar
- [ ] Endpoint devuelve JSON con servicios y pivot

---

## 🚀 Siguientes pasos

1. **Verificar backend** con los puntos de arriba
2. **Ejecutar app Flutter** y probar visualización
3. **Crear historial nuevo** con servicios y verificar que se liste correctamente
4. **Tocar badge de servicios** para ver diálogo con detalles

Si todo funciona, el flujo completo está listo:
✅ Crear historial con servicios  
✅ Listar historiales con servicios  
✅ Ver detalles de servicios aplicados
