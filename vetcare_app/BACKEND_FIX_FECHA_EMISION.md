# Fix Backend: Missing `fecha_emision` Column

## Problem
The backend is failing when creating invoices with this SQL error:
```
SQLSTATE[42S22]: Column not found: 1054 Unknown column 'fecha_emision' in 'where clause'
SQL: select * from `facturas` where year(`fecha_emision`) = 2025 order by `numero_factura` desc limit 1
```

This happens because the backend code is querying the `fecha_emision` column but it doesn't exist in the `facturas` table.

## Solution: Add the Missing Column

### Step 1: Create Migration

In your Laravel backend project, run:

```bash
php artisan make:migration add_fecha_emision_to_facturas_table --table=facturas
```

### Step 2: Edit the Migration File

Open the newly created migration file in `database/migrations/` and add this code:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('facturas', function (Blueprint $table) {
            // Add fecha_emision column (invoice issue date)
            $table->date('fecha_emision')->nullable()->after('numero_factura');
            
            // Optionally add an index for faster queries by year
            $table->index('fecha_emision');
        });
        
        // Backfill existing records: set fecha_emision = created_at date
        DB::table('facturas')->whereNull('fecha_emision')->update([
            'fecha_emision' => DB::raw('DATE(created_at)')
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('facturas', function (Blueprint $table) {
            $table->dropIndex(['fecha_emision']);
            $table->dropColumn('fecha_emision');
        });
    }
};
```

### Step 3: Run the Migration

```bash
php artisan migrate
```

### Step 4: Update Factura Model (if needed)

Make sure your `app/Models/Factura.php` includes `fecha_emision` in the `$fillable` array:

```php
protected $fillable = [
    'numero_factura',
    'fecha_emision',  // Add this
    'cliente_id',
    'cita_id',
    'total',
    'subtotal',
    'impuesto',
    'estado',
    'metodo_pago',
    'notas',
    // ... other fields
];

protected $casts = [
    'fecha_emision' => 'date',  // Add this
    // ... other casts
];
```

### Step 5: Update Invoice Creation Code

Find the code that creates invoices (likely in `app/Http/Controllers/FacturaController.php` or similar) and ensure it sets `fecha_emision`:

```php
// When creating a new factura
$factura = Factura::create([
    'numero_factura' => $numeroFactura,
    'fecha_emision' => now()->toDateString(),  // Add this line
    'cliente_id' => $request->cliente_id,
    'total' => $total,
    'estado' => 'pendiente',
    'metodo_pago' => $request->metodo_pago,
    // ... other fields
]);
```

## Alternative Quick Fix (Not Recommended)

If you can't add the column right now, you can temporarily change the query to use `created_at` instead:

Find the code that generates invoice numbers (the line causing the error) and change:

```php
// OLD (causes error)
$last = Factura::whereYear('fecha_emision', now()->year)
    ->orderBy('numero_factura', 'desc')
    ->first();

// NEW (temporary fix)
$last = Factura::whereYear('created_at', now()->year)
    ->orderBy('numero_factura', 'desc')
    ->first();
```

**Note:** This is just a temporary workaround. Adding the proper column is the correct solution.

## Testing

After applying the fix:

1. Restart your Laravel server if needed
2. In the Flutter app, try creating an invoice from a medical history again
3. Check the logs - you should see a 201 success response instead of 500

## Payment Methods Issue

The logs also show that 'yape' is not a valid payment method according to the backend. Check your backend validation rules for `metodo_pago`. 

Common valid values might be:
- efectivo
- tarjeta
- transferencia

Update the frontend's `_metodosPago` list in `manage_invoices_screen.dart` to match exactly what the backend accepts (case-sensitive).
