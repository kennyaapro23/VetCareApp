# ✅ CHECKLIST DE PRUEBAS - Sistema de Facturación

## 🧪 Pruebas de Funcionalidad

### FASE 1: Verificar Modelos (Backend → Flutter)

#### Test 1.1: Modelo Servicio
```dart
// Probar que el modelo parsea correctamente
GET /api/servicios

Respuesta esperada:
[
  {
    "id": 1,
    "codigo": "VAC001",
    "nombre": "Vacuna Antirrábica",
    "tipo": "vacuna",
    "precio": 50.00,
    ...
  }
]

✅ Verificar: El modelo Servicio.fromJson() parsea sin errores
```

#### Test 1.2: Modelo HistorialMedico con Servicios
```dart
GET /api/historial-medico/{id}

Respuesta esperada:
{
  "id": 10,
  "mascota_id": 4,
  "facturado": false,
  "factura_id": null,
  "servicios": [
    {
      "id": 1,
      "nombre": "Vacuna Antirrábica",
      "pivot": {
        "cantidad": 1,
        "precio_unitario": "50.00",
        "notas": "Aplicada en pata delantera"
      }
    }
  ],
  "total_servicios": 50.00
}

✅ Verificar: 
- servicios[] se parsea correctamente
- totalServicios tiene el valor correcto
- facturado = false por defecto
```

#### Test 1.3: Modelo Factura con Historiales
```dart
GET /api/facturas/{id}

Respuesta esperada:
{
  "id": 45,
  "numero_factura": "FAC-2025-00045",
  "subtotal": 100.00,
  "impuestos": 16.00,
  "total": 116.00,
  "historiales": [...]
}

✅ Verificar: Todos los campos nuevos se parsean correctamente
```

---

### FASE 2: Pruebas de Servicios HTTP

#### Test 2.1: ServicioService
```
1. Abrir la app
2. Como VETERINARIO, ir a "Registrar Consulta"
3. Verificar que la lista de servicios se carga

✅ Debe mostrar: Lista de servicios disponibles
❌ Error si: Lista vacía o error de red
```

#### Test 2.2: HistorialMedicoService - Sin Facturar
```
1. Como RECEPCIONISTA, ir a "Gestión de Clientes"
2. Seleccionar un cliente que tenga historiales
3. Menú → "Crear Factura"
4. Verificar que carga solo historiales sin facturar

✅ Debe mostrar: Solo historiales con facturado = false
❌ Error si: Muestra historiales ya facturados
```

#### Test 2.3: FacturaService - Crear desde Historiales
```
1. Seleccionar cliente con historiales sin facturar
2. Marcar 2 historiales
3. Método de pago: "Efectivo"
4. Click "Generar Factura"

✅ Debe:
- Crear factura exitosamente
- Mostrar número de factura
- Marcar historiales como facturados
- Regresar a la pantalla anterior

❌ Error si:
- No se crea la factura
- Los historiales siguen sin facturar
```

---

### FASE 3: Pruebas de UI/UX

#### Test 3.1: Widget ServiciosAplicadosList
```
1. Como VETERINARIO o CLIENTE, ir a detalle de mascota
2. Pestaña "Historial"
3. Buscar un historial con servicios
4. Tocar el badge "Servicios: N • S/. XXX"

✅ Debe mostrar:
- Lista de servicios con iconos
- Cantidad × Precio unitario
- Subtotal por servicio
- Notas (si existen)
- Total general al final

❌ Error si: No se muestran los servicios o totales incorrectos
```

#### Test 3.2: Pantalla CrearFacturaHistorialesScreen
```
CASO A: Cliente sin historiales sin facturar
1. Ir a "Gestión de Clientes"
2. Cliente → "Crear Factura"
3. Seleccionar cliente que ya tiene todo facturado

✅ Debe mostrar: "No hay historiales sin facturar" con icono verde ✓

CASO B: Selección múltiple
1. Cliente con 3 historiales sin facturar
2. Marcar los 3
3. Verificar cálculo de totales

✅ Debe:
- Borde azul en historiales seleccionados
- Subtotal = Suma de los 3 totales
- IVA = Subtotal × 0.16
- Total actualizado en tiempo real

CASO C: Deseleccionar
1. Marcar 3 historiales
2. Desmarcar 1
3. Verificar totales

✅ Debe: Recalcular automáticamente

CASO D: Búsqueda de cliente
1. Click "Seleccionar Cliente"
2. Escribir parte del nombre

✅ Debe: Filtrar en tiempo real
```

---

### FASE 4: Flujos Completos End-to-End

#### Test 4.1: Flujo Veterinario → Recepcionista
```
PASO 1: VETERINARIO REGISTRA CONSULTA
1. Login como veterinario
2. Ir a una cita pendiente
3. "Registrar Consulta"
4. Llenar datos:
   - Diagnóstico: "Test de integración"
   - Tratamiento: "Test"
5. Seleccionar servicios:
   - Vacuna (1x S/. 50.00)
   - Desparasitante (1x S/. 30.00)
6. Guardar

✅ Verificar: Mensaje "Consulta registrada • Total servicios: S/. 80.00"

PASO 2: VERIFICAR HISTORIAL
1. Ir a detalle de la mascota
2. Pestaña "Historial"
3. Buscar la consulta recién creada

✅ Verificar:
- Aparece el historial
- Badge "Servicios: 2 • S/. 80.00"
- Estado: Sin facturar ⏳

PASO 3: RECEPCIONISTA CREA FACTURA
1. Logout veterinario, login recepcionista
2. "Gestión de Clientes"
3. Buscar el cliente del test
4. Menú → "Crear Factura"

✅ Verificar:
- Aparece el historial del Test (S/. 80.00)
- Estado: Sin facturar

5. Marcar el historial
6. Método de pago: "Efectivo"
7. "Generar Factura"

✅ Verificar:
- Subtotal: S/. 80.00
- IVA 16%: S/. 12.80
- Total: S/. 92.80
- Mensaje: "Factura FAC-2025-XXXXX creada exitosamente"

PASO 4: VERIFICAR ESTADO FINAL
1. Volver a "Crear Factura" con el mismo cliente

✅ Verificar:
- El historial del test YA NO APARECE
- Mensaje: "No hay historiales sin facturar" (si no hay otros)

2. Ir a detalle de mascota → Historial

✅ Verificar:
- El historial ahora muestra: "Facturado ✅"
- Tiene número de factura asociado
```

#### Test 4.2: Flujo con Múltiples Historiales
```
1. Crear 3 consultas diferentes para el mismo cliente
   - Consulta 1: S/. 50.00
   - Consulta 2: S/. 75.00
   - Consulta 3: S/. 100.00

2. Como recepcionista, crear factura
3. Marcar solo Consulta 1 y 3

✅ Verificar:
- Subtotal: S/. 150.00 (50 + 100)
- IVA: S/. 24.00
- Total: S/. 174.00

4. Generar factura

✅ Verificar:
- Consulta 1: Facturada ✅
- Consulta 2: Sin facturar ⏳ (no se seleccionó)
- Consulta 3: Facturada ✅

5. Crear nueva factura con el mismo cliente

✅ Verificar:
- Solo aparece Consulta 2 (S/. 75.00)
```

---

### FASE 5: Pruebas de Validación y Errores

#### Test 5.1: Validación Cliente Requerido
```
1. Ir a "Crear Factura" directamente (sin cliente)
2. Click "Generar Factura"

✅ Debe mostrar: "Seleccione un cliente"
```

#### Test 5.2: Validación Historial Requerido
```
1. Seleccionar cliente
2. NO marcar ningún historial
3. Click "Generar Factura"

✅ Debe mostrar: "Seleccione al menos un historial"
```

#### Test 5.3: Manejo de Error de Red
```
1. Desconectar internet (Modo avión)
2. Intentar crear factura

✅ Debe mostrar: "Error al crear factura: [detalle]"
❌ NO debe: Crashear la app
```

#### Test 5.4: Conversión de IDs
```
Backend: cliente_id es int
Flutter: client.id es String

✅ Verificar: La conversión String → int funciona correctamente
❌ Error si: "The argument type 'String' can't be assigned to 'int'"
```

---

### FASE 6: Pruebas de Performance

#### Test 6.1: Cliente con Muchos Historiales
```
1. Cliente con 50+ historiales sin facturar
2. Abrir "Crear Factura"

✅ Debe:
- Cargar en menos de 3 segundos
- Scroll suave en la lista
- Cálculos instantáneos al seleccionar

❌ Problemas si:
- Tarda más de 5 segundos
- Lag al hacer scroll
- Cálculos lentos
```

#### Test 6.2: Selección Masiva
```
1. Cliente con 20 historiales
2. Marcar todos (20 checkboxes)
3. Verificar cálculo de totales

✅ Debe: Calcular instantáneamente
❌ Problema si: Demora más de 1 segundo
```

---

### FASE 7: Pruebas de Tema Claro/Oscuro

#### Test 7.1: Cambio de Tema
```
1. Configurar tema CLARO
2. Ir a "Crear Factura"

✅ Verificar:
- Fondo blanco
- Texto oscuro
- Bordes grises claros

3. Cambiar a tema OSCURO

✅ Verificar:
- Fondo oscuro
- Texto claro
- Bordes grises oscuros
- Colores primarios se mantienen
```

---

## 📋 CHECKLIST FINAL

### Antes de Producción
- [ ] Todos los tests de Fase 1 pasaron
- [ ] Todos los tests de Fase 2 pasaron
- [ ] Todos los tests de Fase 3 pasaron
- [ ] Test 4.1 (End-to-End completo) pasó
- [ ] Test 4.2 (Múltiples historiales) pasó
- [ ] Todas las validaciones de Fase 5 funcionan
- [ ] Performance aceptable (Fase 6)
- [ ] Tema claro/oscuro correcto (Fase 7)

### Verificaciones Adicionales
- [ ] Sin errores en consola de Flutter
- [ ] Sin warnings críticos
- [ ] Textos en español correctos
- [ ] Formato de moneda correcto (S/. XX.XX)
- [ ] Fechas en formato DD/MM/YYYY
- [ ] Iconos apropiados en toda la UI

### Backend
- [ ] Migraciones ejecutadas
- [ ] Endpoints respondiendo correctamente
- [ ] Validaciones del backend funcionando
- [ ] Generación de número de factura automática
- [ ] Marca de historiales como facturados funciona

---

## 🐛 Reporte de Bugs

Si encuentras un bug durante las pruebas, documenta:

1. **Descripción del bug**
2. **Pasos para reproducir**
3. **Resultado esperado**
4. **Resultado actual**
5. **Logs de error** (si hay)
6. **Screenshots** (si aplica)

---

## 📊 Resultados de Pruebas

### Completado por: _______________
### Fecha: _______________

| Test | Estado | Notas |
|------|--------|-------|
| 1.1 Modelo Servicio | ⬜ Pass / ⬜ Fail | |
| 1.2 Historial con Servicios | ⬜ Pass / ⬜ Fail | |
| 1.3 Factura con Historiales | ⬜ Pass / ⬜ Fail | |
| 2.1 Cargar Servicios | ⬜ Pass / ⬜ Fail | |
| 2.2 Historiales sin Facturar | ⬜ Pass / ⬜ Fail | |
| 2.3 Crear Factura API | ⬜ Pass / ⬜ Fail | |
| 3.1 Widget Servicios | ⬜ Pass / ⬜ Fail | |
| 3.2 Pantalla Facturación | ⬜ Pass / ⬜ Fail | |
| 4.1 Flujo Completo E2E | ⬜ Pass / ⬜ Fail | |
| 4.2 Múltiples Historiales | ⬜ Pass / ⬜ Fail | |
| 5.1-5.4 Validaciones | ⬜ Pass / ⬜ Fail | |
| 6.1-6.2 Performance | ⬜ Pass / ⬜ Fail | |
| 7.1 Temas | ⬜ Pass / ⬜ Fail | |

### Resultado General: ⬜ APROBADO / ⬜ RECHAZADO

---

**Última actualización:** 8 de noviembre de 2025  
**Versión:** 1.0.0

