# 🏥 Flujo de Facturación Walk-In (Sin Cita Previa)

## 📋 Caso de Uso: Cliente Nuevo sin Cita

### Escenario:
> Una persona llega con su mascota sin cita previa (walk-in). El veterinario atiende al paciente y crea historiales médicos. Después se genera la factura desde esos historiales.

---

## 🔄 Flujo Completo

### 1️⃣ **Registro del Cliente y Mascota** (Recepción)
```
👤 Cliente nuevo llega sin cita
   ↓
📝 Recepcionista registra:
   - Datos del cliente (nombre, teléfono, email)
   - Datos de la mascota (nombre, especie, raza, edad)
   ↓
✅ Sistema asigna IDs:
   - Cliente ID: 25
   - Mascota ID: 50
```

### 2️⃣ **Atención Veterinaria** (Veterinario)
```
🩺 Veterinario atiende a la mascota
   ↓
📋 Crea historiales médicos:
   - Historial #101: Consulta general + Examen físico
   - Historial #102: Vacuna antirrábica
   - Historial #103: Desparasitación
   ↓
💰 Cada historial tiene servicios con precios:
   - Historial #101: Consulta (S/. 50) + Examen (S/. 30)
   - Historial #102: Vacuna (S/. 45)
   - Historial #103: Desparasitante (S/. 25)
```

### 3️⃣ **Generación de Factura** (Recepción/Admin)
```
🧾 Recepcionista genera factura
   ↓
📱 Pantalla "Nueva Factura":
   - Selecciona Cliente: "Juan Pérez" (ID: 25)
   - Ingresa IDs de Historiales: "101, 102, 103"
   - Tasa de Impuesto: 16% (default)
   - Método de Pago: "Efectivo"
   - Notas: "Pago al contado"
   ↓
⚙️ Backend procesa:
   ✓ Valida que historiales existan
   ✓ Valida que todos sean del mismo cliente (ID: 25)
   ✓ Verifica que no estén facturados previamente
   ✓ Calcula subtotal desde pivot table historial_servicio:
     • Historial #101: S/. 80 (50 + 30)
     • Historial #102: S/. 45
     • Historial #103: S/. 25
     • Subtotal: S/. 150.00
   ✓ Calcula impuesto: S/. 150.00 × 16% = S/. 24.00
   ✓ Total: S/. 174.00
   ✓ Auto-genera número: "FAC-2025-00042"
   ✓ Marca historiales como facturados (facturado = true)
   ↓
✅ Factura creada exitosamente
   - Número: FAC-2025-00042
   - Total: S/. 174.00
   - Estado: Pendiente
```

---

## 🎯 Ventajas de este Flujo

### ✅ **Flexibilidad Total**
- ❌ **NO requiere cita previa**
- ✅ **SÍ permite atención walk-in**
- ✅ Cliente llega → Se atiende → Se factura

### ✅ **Control de Inventario**
- Los historiales médicos quedan registrados
- Se puede hacer seguimiento del paciente
- Historial clínico completo desde el primer día

### ✅ **Prevención de Duplicados**
- Backend valida que historiales no estén previamente facturados
- No se puede facturar dos veces el mismo servicio

### ✅ **Cálculo Automático**
- Subtotal calculado desde servicios del historial
- Impuesto configurable (default 16%)
- Número de factura auto-generado

---

## 📱 Ejemplo de Uso en la App

### Pantalla "Nueva Factura"
```
┌─────────────────────────────────────┐
│  Nueva Factura                      │
├─────────────────────────────────────┤
│                                     │
│  👤 Cliente *                       │
│  ┌─────────────────────────────┐   │
│  │ Juan Pérez ▼                │   │
│  └─────────────────────────────┘   │
│                                     │
│  🏥 IDs de Historiales Médicos *    │
│  ┌─────────────────────────────┐   │
│  │ 101, 102, 103               │   │
│  └─────────────────────────────┘   │
│  ℹ️ Ingresa los IDs separados por   │
│     comas (ej: 101, 102, 103)      │
│                                     │
│  📊 Tasa de Impuesto (%)           │
│  ┌─────────────────────────────┐   │
│  │ 16.0                        │   │
│  └─────────────────────────────┘   │
│  ℹ️ Porcentaje de impuesto         │
│     (default: 16%)                 │
│                                     │
│  💰 Total (calculado automáticamente)│
│  ┌─────────────────────────────┐   │
│  │ S/. 174.00 [deshabilitado]  │   │
│  └─────────────────────────────┘   │
│  ℹ️ El total se calculará desde     │
│     los servicios de los historiales│
│                                     │
│  📋 Estado *                        │
│  ┌─────────────────────────────┐   │
│  │ PENDIENTE ▼                 │   │
│  └─────────────────────────────┘   │
│                                     │
│  💳 Método de Pago                 │
│  ┌─────────────────────────────┐   │
│  │ EFECTIVO ▼                  │   │
│  └─────────────────────────────┘   │
│                                     │
│  📝 Notas                          │
│  ┌─────────────────────────────┐   │
│  │ Pago al contado             │   │
│  │                             │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│  ℹ️ Información adicional           │
│                                     │
│  ┌─────────────────────────────┐   │
│  │    🧾 Crear Factura         │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## 🔧 Validaciones Implementadas

### Frontend (Flutter):
1. ✅ Cliente es obligatorio
2. ✅ IDs de historiales son obligatorios
3. ✅ Formato de IDs validado (números separados por comas)
4. ✅ Tasa de impuesto debe ser número válido
5. ✅ Total calculado automáticamente en backend

### Backend (Laravel):
1. ✅ Verifica existencia de cliente
2. ✅ Verifica existencia de todos los historiales
3. ✅ Valida que todos los historiales pertenezcan al mismo cliente
4. ✅ Verifica que historiales no estén previamente facturados
5. ✅ Calcula subtotal desde pivot table `historial_servicio`
6. ✅ Aplica tasa de impuesto (default 16%)
7. ✅ Auto-genera número único de factura
8. ✅ Marca historiales como `facturado = true`
9. ✅ Transacción DB para consistencia

---

## 💡 Casos de Uso Adicionales

### Caso 1: Cliente Recurrente Walk-In
```
Cliente: María López (ya registrada, ID: 10)
Mascota: "Firulais" (ya registrada, ID: 20)
   ↓
Veterinario crea nuevos historiales:
   - Historial #201: Control de peso
   - Historial #202: Aplicación de tratamiento
   ↓
Recepción genera factura:
   - Cliente ID: 10
   - Historiales: "201, 202"
   ↓
✅ Factura generada con historial completo
```

### Caso 2: Múltiples Servicios en una Visita
```
Cliente walk-in con emergencia
   ↓
Veterinario atiende:
   - Historial #301: Consulta de emergencia (S/. 100)
   - Historial #302: Radiografía (S/. 150)
   - Historial #303: Medicamentos (S/. 80)
   - Historial #304: Hospitalización 1 día (S/. 200)
   ↓
Recepción factura todo junto:
   - Historiales: "301, 302, 303, 304"
   - Subtotal: S/. 530.00
   - Impuesto (16%): S/. 84.80
   - Total: S/. 614.80
```

### Caso 3: Factura con Cita (Opcional)
```
Si el cliente SÍ tiene cita programada:
   ↓
Opción 1: Crear factura desde CITA
   - Usa endpoint: POST /api/facturas
   - Requiere: cita_id
   - Calcula desde: cita_servicio pivot table
   ↓
Opción 2: Crear factura desde HISTORIALES
   - Usa endpoint: POST /api/facturas/desde-historiales
   - Requiere: historial_ids
   - Calcula desde: historial_servicio pivot table
   
✅ Ambas opciones válidas, tú decides según el flujo
```

---

## 🎨 Flujo Visual Completo

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  👥 CLIENTE WALK-IN                                 │
│     (Sin cita previa)                               │
│                                                     │
└─────────────────┬───────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────────┐
│  📝 RECEPCIÓN                                       │
│  ✓ Registra cliente (si es nuevo)                  │
│  ✓ Registra mascota (si es nueva)                  │
└─────────────────┬───────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────────┐
│  🩺 VETERINARIO                                     │
│  ✓ Atiende al paciente                             │
│  ✓ Crea historiales médicos                        │
│  ✓ Agrega servicios a cada historial               │
│     (consulta, vacunas, exámenes, etc.)            │
└─────────────────┬───────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────────┐
│  🧾 FACTURACIÓN                                     │
│  ✓ Selecciona cliente                              │
│  ✓ Ingresa IDs de historiales                      │
│  ✓ Configura método de pago                        │
│  ✓ Sistema calcula total automáticamente           │
│  ✓ Genera factura                                  │
└─────────────────┬───────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────────┐
│  ✅ FACTURA GENERADA                                │
│  • Número: FAC-2025-00042                          │
│  • Total calculado con impuestos                   │
│  • Historiales marcados como facturados            │
│  • Lista para imprimir/enviar                      │
└─────────────────────────────────────────────────────┘
```

---

## 📊 Comparación: Cita vs Walk-In

| Característica | Con Cita | Walk-In |
|---|---|---|
| **Registro previo** | ✅ Sí (agendada) | ❌ No necesario |
| **Cliente nuevo** | Puede ser | Puede ser |
| **Historiales médicos** | Se crean después | Se crean en el momento |
| **Facturación** | Desde cita O historiales | Desde historiales |
| **Método de pago** | Al momento de pagar | Al momento de pagar |
| **Flexibilidad** | Media | Alta |

---

## 🚀 Próximos Pasos Recomendados

1. **Agregar búsqueda de historiales:**
   - Pantalla para ver historiales del cliente
   - Selección visual (checkboxes) en lugar de IDs manuales

2. **Mejorar UX:**
   - Mostrar preview de servicios antes de confirmar
   - Calcular y mostrar total estimado en tiempo real

3. **Reportes:**
   - Reporte de atenciones walk-in vs con cita
   - Estadísticas de facturación por tipo de servicio

4. **Integración con impresora:**
   - Imprimir factura automáticamente
   - Enviar por email/WhatsApp al cliente

---

## ✅ Estado Actual

**FLUJO WALK-IN COMPLETAMENTE FUNCIONAL** 🎉

- ✅ Cliente puede llegar sin cita
- ✅ Se crea historial médico
- ✅ Se genera factura desde historiales
- ✅ Cálculo automático de totales
- ✅ Prevención de duplicados
- ✅ Número de factura único
- ✅ Validaciones completas

**¡Listo para atender clientes walk-in!** 🏥
