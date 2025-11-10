# ✅ Integración del Sistema de Facturación - COMPLETADA

## 📋 Resumen General

Se ha completado exitosamente la integración del **FacturaService** con el backend Laravel. El servicio ahora coincide exactamente con los endpoints y la lógica del `FacturaController` proporcionado.

---

## 🎯 Endpoints Backend (Laravel)

### 1. **Crear Factura desde Cita**
```
POST /api/facturas
```
**Parámetros requeridos:**
- `cita_id` (int, required) - ID de la cita existente
- `numero_factura` (string, required) - Número único de factura

**Parámetros opcionales:**
- `metodo_pago` (string) - efectivo|tarjeta|transferencia|otro
- `notas` (string) - Notas adicionales

**Validaciones backend:**
- ✅ Verifica que la cita exista
- ✅ Verifica que la cita no tenga factura previa
- ✅ Verifica que el número de factura sea único
- ✅ Calcula subtotal desde `cita_servicio.precio_momento`
- ✅ Aplica impuesto del 16% (configurable)
- ✅ Marca la cita como "completada"

**Respuesta:**
```json
{
  "message": "Factura creada exitosamente",
  "factura": {
    "id": 1,
    "cliente_id": 10,
    "cita_id": 25,
    "numero_factura": "FAC-2025-00001",
    "fecha_emision": "2025-06-15",
    "subtotal": 100.00,
    "impuestos": 16.00,
    "total": 116.00,
    "estado": "pendiente",
    "metodo_pago": "efectivo",
    "notas": "Pago al contado",
    "created_at": "2025-06-15T10:30:00Z",
    "updated_at": "2025-06-15T10:30:00Z"
  }
}
```

---

### 2. **Crear Factura desde Historiales Médicos**
```
POST /api/facturas/desde-historiales
```
**Parámetros requeridos:**
- `cliente_id` (int, required) - ID del cliente
- `historial_ids` (array, required) - Array de IDs de historiales médicos

**Parámetros opcionales:**
- `metodo_pago` (string)
- `notas` (string)
- `tasa_impuesto` (float, default: 16.0) - Porcentaje de impuesto

**Validaciones backend:**
- ✅ Verifica que los historiales existan
- ✅ Verifica que todos los historiales pertenezcan al mismo cliente
- ✅ Verifica que los historiales no estén previamente facturados
- ✅ Calcula subtotal desde `historial_servicio` (cantidad * precio_unitario)
- ✅ Auto-genera número de factura único (FAC-YYYY-00001)
- ✅ Marca historiales como `facturado = true`

**Respuesta:**
```json
{
  "message": "Factura creada exitosamente desde 3 historiales médicos",
  "factura": { ... },
  "total_historiales": 3
}
```

---

### 3. **Generar Número de Factura Automático**
```
GET /api/facturas/generateNumeroFactura
```
**Sin parámetros**

**Respuesta:**
```json
{
  "numero_factura": "FAC-2025-00042"
}
```

**Lógica:**
- Busca el último número de factura del año actual
- Incrementa el contador
- Formato: `FAC-{AÑO}-{SECUENCIA:5}`
- Ejemplo: FAC-2025-00001, FAC-2025-00002...

---

### 4. **Obtener Estadísticas de Facturación**
```
GET /api/facturas/estadisticas?fecha_desde=2025-01-01&fecha_hasta=2025-12-31
```
**Parámetros opcionales:**
- `fecha_desde` (date) - Filtro de fecha inicial
- `fecha_hasta` (date) - Filtro de fecha final

**Respuesta:**
```json
{
  "total_facturas": 150,
  "facturas_pendientes": 25,
  "facturas_pagadas": 120,
  "facturas_canceladas": 5,
  "monto_total": 45000.00,
  "monto_pendiente": 5000.00,
  "monto_cobrado": 40000.00
}
```

---

## 🔧 Métodos del FacturaService (Flutter)

### ✅ 1. `crearFacturaDesdeCita()`
```dart
Future<Factura> crearFacturaDesdeCita({
  required int citaId,
  required String numeroFactura,
  String? metodoPago,
  String? notas,
}) async
```
**Uso:**
```dart
final service = context.read<AuthProvider>().api;
final facturaService = FacturaService(service);

// Generar número automático
final numero = await facturaService.generarNumeroFactura();

// Crear factura
final factura = await facturaService.crearFacturaDesdeCita(
  citaId: 25,
  numeroFactura: numero,
  metodoPago: 'efectivo',
  notas: 'Pago al contado',
);
```

---

### ✅ 2. `createFacturaDesdeHistoriales()`
```dart
Future<Factura> createFacturaDesdeHistoriales({
  required int clienteId,
  required List<int> historialIds,
  String? metodoPago,
  String? notas,
  double? tasaImpuesto, // default 16%
}) async
```
**Uso:**
```dart
final factura = await facturaService.createFacturaDesdeHistoriales(
  clienteId: 10,
  historialIds: [101, 102, 103],
  metodoPago: 'tarjeta',
  tasaImpuesto: 16.0, // Opcional, default es 16%
);
```

---

### ✅ 3. `generarNumeroFactura()`
```dart
Future<String> generarNumeroFactura() async
```
**Retorna:** `"FAC-2025-00042"`

---

### ✅ 4. `getEstadisticas()`
```dart
Future<Map<String, dynamic>> getEstadisticas({
  String? fechaDesde,
  String? fechaHasta,
}) async
```
**Uso:**
```dart
final stats = await facturaService.getEstadisticas(
  fechaDesde: '2025-01-01',
  fechaHasta: '2025-12-31',
);

print('Total facturas: ${stats['total_facturas']}');
print('Monto total: \$${stats['monto_total']}');
```

---

## 📊 Modelo Factura

El modelo `Factura` incluye todos los campos que el backend retorna:

```dart
class Factura {
  final int? id;
  final int clienteId;
  final int? citaId;
  final String? numeroFactura;
  final DateTime? fechaEmision;
  final double subtotal;
  final double impuestos;
  final double total;
  final String estado; // pendiente|pagada|cancelada
  final String? metodoPago;
  final String? notas;
  final Map<String, dynamic>? detalles;
  final List<HistorialMedico>? historiales;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

---

## 🧪 Pruebas Recomendadas

### Test 1: Crear factura desde cita
```dart
// 1. Obtener número automático
final numero = await facturaService.generarNumeroFactura();
print('Número generado: $numero'); // FAC-2025-00042

// 2. Crear factura
final factura = await facturaService.crearFacturaDesdeCita(
  citaId: 25,
  numeroFactura: numero,
  metodoPago: 'efectivo',
);
print('Factura creada: ${factura.id}');
print('Total: \$${factura.total}');
```

### Test 2: Crear factura desde historiales
```dart
final factura = await facturaService.createFacturaDesdeHistoriales(
  clienteId: 10,
  historialIds: [101, 102, 103],
  metodoPago: 'tarjeta',
);
print('Factura desde ${factura.historiales?.length} historiales');
print('Total: \$${factura.total}');
```

### Test 3: Estadísticas
```dart
final stats = await facturaService.getEstadisticas(
  fechaDesde: '2025-01-01',
  fechaHasta: '2025-12-31',
);
print('Total facturas: ${stats['total_facturas']}');
print('Pendientes: ${stats['facturas_pendientes']}');
print('Monto total: \$${stats['monto_total']}');
```

---

## 🔒 Validaciones Implementadas

### Backend (Laravel):
1. ✅ Verificación de existencia de citas/historiales
2. ✅ Prevención de duplicados (facturado flag)
3. ✅ Unicidad de número de factura
4. ✅ Validación de pertenencia al mismo cliente
5. ✅ Transacciones DB para consistencia
6. ✅ Auto-marcado de estados (completada/facturado)

### Frontend (Flutter):
1. ✅ Parseo correcto de respuesta {message, factura}
2. ✅ Manejo de respuesta envuelta del backend
3. ✅ Debug logging para seguimiento
4. ✅ Tipos tipados con modelo Factura

---

## 📱 Pantallas Existentes

Ya existen pantallas para el sistema de facturación:

1. **`manage_invoices_screen.dart`**
   - Lista de todas las facturas
   - Filtrado por estado y cliente
   - Vista de detalles

2. **`crear_factura_historiales_screen.dart`**
   - Flujo de creación desde historiales
   - Selección múltiple de historiales
   - Ya usa `createFacturaDesdeHistoriales()`

3. **Pendiente:** Pantalla para crear facturas desde citas
   - Botón "Crear Factura" en detalle de cita
   - Usa `crearFacturaDesdeCita()`

---

## 🎨 Flujo de Usuario Recomendado

### Desde Citas (Recepción):
1. Usuario completa una cita en la agenda
2. Clic en botón "Generar Factura" en el detalle de la cita
3. Sistema auto-genera número de factura
4. Usuario confirma método de pago
5. Sistema crea factura y marca cita como "completada"

### Desde Historiales (Veterinario/Admin):
1. Usuario selecciona múltiples historiales médicos de un paciente
2. Clic en "Crear Factura" (pantalla ya existe)
3. Sistema valida que todos sean del mismo cliente
4. Sistema calcula subtotal de servicios
5. Usuario confirma y sistema crea factura

---

## ⚠️ Consideraciones Importantes

1. **Número de Factura:**
   - Siempre usar `generarNumeroFactura()` antes de crear
   - El backend valida unicidad

2. **Método de Pago:**
   - Valores permitidos: `efectivo`, `tarjeta`, `transferencia`, `otro`
   - Opcional al crear, obligatorio al marcar como "pagada"

3. **Estados de Factura:**
   - `pendiente` - Creada pero no pagada
   - `pagada` - Pago confirmado
   - `cancelada` - Anulada

4. **Cálculo de Totales:**
   - Subtotal: Suma de precios de servicios
   - Impuestos: subtotal * (tasa_impuesto / 100)
   - Total: subtotal + impuestos

5. **Prevención de Duplicados:**
   - Backend valida que citas no tengan facturas previas
   - Backend valida que historiales no estén facturados

---

## 🚀 Próximos Pasos

1. ✅ **COMPLETADO:** Alinear endpoints con backend
2. ✅ **COMPLETADO:** Parsear respuesta envuelta {message, factura}
3. ✅ **COMPLETADO:** Agregar debug logging
4. ✅ **COMPLETADO:** Verificar modelo Factura con campos backend

5. 🔜 **Pendiente:** Agregar botón "Crear Factura" en detalle de cita
6. 🔜 **Pendiente:** Implementar flujo de pago (cambiar estado a "pagada")
7. 🔜 **Pendiente:** Agregar reporte PDF de factura
8. 🔜 **Pendiente:** Implementar envío por email/WhatsApp

---

## 📝 Notas Técnicas

- **Formato de Fecha:** Backend usa `Y-m-d` (2025-06-15)
- **Formato de Moneda:** Siempre 2 decimales (100.00)
- **Timezone:** Considerar zona horaria al mostrar fechas
- **Paginación:** Backend retorna facturas paginadas (15 por página)
- **Soft Deletes:** Backend usa soft deletes para facturas

---

## 🔗 Archivos Relacionados

- `lib/services/factura_service.dart` - Servicio principal ✅
- `lib/models/factura.dart` - Modelo de datos ✅
- `lib/screens/admin/manage_invoices_screen.dart` - Lista de facturas ✅
- `lib/screens/admin/crear_factura_historiales_screen.dart` - Crear desde historiales ✅
- **Backend:** `app/Http/Controllers/FacturaController.php` - Controller Laravel

---

## ✅ Estado Final

**INTEGRACIÓN COMPLETADA CON ÉXITO** 🎉

Todos los métodos del `FacturaService` ahora coinciden exactamente con el backend Laravel:
- ✅ Endpoints correctos
- ✅ Parámetros requeridos/opcionales alineados
- ✅ Parseo de respuestas envueltas
- ✅ Debug logging agregado
- ✅ Sin errores de compilación
- ✅ Modelo Factura completo con todos los campos

**Listo para pruebas end-to-end!** 🚀
