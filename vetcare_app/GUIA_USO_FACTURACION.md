# 📘 Guía de Uso - Sistema de Facturación desde Historiales

## 🎯 Para Recepcionistas

### Crear una Factura desde Historiales Médicos

#### Opción 1: Desde la Gestión de Clientes (Recomendado)

1. **Navegar a Gestión de Clientes**
   - Desde el menú principal de recepcionista
   - Selecciona "Gestión de Clientes"

2. **Buscar el Cliente**
   - Usa la barra de búsqueda para encontrar al cliente
   - Puedes buscar por nombre, teléfono o email

3. **Abrir el Menú del Cliente**
   - Toca los tres puntos (⋮) en la tarjeta del cliente
   - Selecciona **"Crear Factura"** (icono de recibo en color verde)

4. **Seleccionar Historiales**
   - La pantalla cargará automáticamente todos los historiales sin facturar del cliente
   - Marca los checkboxes de los historiales que deseas incluir en la factura
   - Verás el total calculándose en tiempo real

5. **Completar Información de Factura**
   - **Método de pago**: Selecciona entre efectivo, tarjeta o transferencia
   - **Notas** (opcional): Agrega cualquier observación adicional

6. **Revisar Totales**
   - **Subtotal**: Suma de todos los servicios de los historiales seleccionados
   - **IVA 16%**: Impuesto calculado automáticamente
   - **TOTAL**: Monto final a cobrar

7. **Generar Factura**
   - Toca el botón "Generar Factura"
   - Espera la confirmación
   - Se mostrará el número de factura generado (ej: FAC-2025-00045)

#### ¿Qué pasa si un cliente no tiene historiales sin facturar?

- Verás un mensaje: "No hay historiales sin facturar"
- Esto significa que todos los servicios ya están facturados ✅
- Es normal y correcto

---

## 🩺 Para Veterinarios

### Registrar Consulta con Servicios

1. **Acceder a Registrar Consulta**
   - Desde el detalle de una cita o mascota
   - Selecciona "Registrar Consulta"

2. **Completar Datos Básicos**
   - **Fecha y hora**: Se pre-llena con la actual, puedes cambiarla
   - **Diagnóstico**: Describe el diagnóstico (requerido)
   - **Tratamiento**: Indica el tratamiento recetado
   - **Observaciones**: Notas adicionales

3. **Agregar Servicios Aplicados**
   - Verás la lista de servicios disponibles
   - Marca los checkboxes de los servicios que aplicaste

4. **Editar Detalles de Cada Servicio**
   - Toca el icono de editar (✏️) junto al servicio
   - **Cantidad**: Número de veces que se aplicó el servicio
   - **Precio unitario**: Se pre-llena, pero puedes ajustarlo
   - **Notas**: Detalles específicos (ej: "Aplicada en pata delantera")

5. **Verificar Total**
   - En la parte inferior verás el total calculado automáticamente
   - Ejemplo: 2 servicios × sus precios = Total

6. **Guardar Consulta**
   - Toca "Registrar Consulta"
   - Verás confirmación con el total de servicios

### Ver Historiales con Servicios

1. **Desde Detalle de Mascota**
   - Pestaña "Historial"
   - Los historiales con servicios mostrarán un badge verde
   - Ejemplo: "Servicios: 2 • S/. 100.00"

2. **Ver Desglose de Servicios**
   - Toca el badge de servicios
   - Se abrirá un diálogo con:
     - Lista de servicios aplicados
     - Cantidad y precio unitario de cada uno
     - Notas específicas
     - Total general

---

## 📊 Para Administradores

### Gestión de Catálogo de Servicios

**Nota**: Esta funcionalidad estará disponible en una actualización futura.

Por ahora, los servicios se gestionan desde el backend Laravel en:
```
/api/servicios (admin only)
```

### Ver Estadísticas de Facturación

1. **Dashboard de Recepción**
   - Verás resumen de facturas pendientes
   - Total facturado en el mes
   - Historiales sin facturar

---

## 💡 Casos Especiales

### ¿Qué pasa si selecciono historiales de diferentes mascotas?

- **No es posible**: El sistema solo muestra historiales del cliente seleccionado
- Todas las mascotas del cliente pueden estar en la misma factura
- Esto es correcto y esperado

### ¿Puedo facturar el mismo historial dos veces?

- **NO**: Una vez que un historial es facturado, se marca automáticamente
- No aparecerá en futuras selecciones
- Esto previene doble facturación

### ¿Puedo editar una factura ya creada?

- Actualmente **NO** se pueden editar facturas creadas
- Si hay un error, contacta al administrador
- Próxima actualización incluirá cancelación de facturas

### ¿Cómo sé si un historial ya está facturado?

En el detalle de historial verás:
- ✅ **Facturado** + Número de factura
- ⏳ **Sin facturar** (disponible para facturación)

---

## 🔧 Solución de Problemas

### Error: "No se pueden cargar los historiales"

**Posibles causas:**
1. Problema de conexión con el servidor
2. Cliente no tiene historiales registrados

**Solución:**
- Verifica tu conexión a internet
- Recarga la pantalla
- Si persiste, contacta soporte

### Error: "Error al crear factura"

**Posibles causas:**
1. No se seleccionó ningún historial
2. Problema con el servidor

**Solución:**
- Asegúrate de marcar al menos un historial
- Verifica que todos los datos estén completos
- Intenta nuevamente

### Los totales no coinciden

**Verifica:**
- Que todos los servicios tengan precio asignado
- Que las cantidades sean correctas
- El IVA se calcula como 16% del subtotal

---

## 📱 Atajos y Tips

### Para Recepcionistas

✨ **Búsqueda rápida**: Escribe cualquier parte del nombre o teléfono del cliente

✨ **Multi-selección**: Puedes seleccionar múltiples historiales de un mismo cliente

✨ **Total en vivo**: El total se actualiza inmediatamente al seleccionar/deseleccionar historiales

### Para Veterinarios

✨ **Precios editables**: Los precios se pre-llenan pero puedes ajustarlos si hay descuentos

✨ **Notas detalladas**: Usa las notas para registrar detalles importantes

✨ **Servicios múltiples**: Puedes agregar todos los servicios que aplicaste en una sola consulta

---

## 📈 Flujo Completo Ejemplo

### Caso Real: Consulta de Vacunación

1. **Veterinario registra consulta** (10:00 AM)
   - Diagnóstico: "Control de vacunación anual"
   - Servicios:
     - Vacuna Antirrábica (1x S/. 50.00)
     - Desparasitante (1x S/. 30.00)
   - Total servicios: **S/. 80.00**
   - Estado: **Sin facturar** ⏳

2. **Cliente termina consulta y va a recepción** (10:30 AM)

3. **Recepcionista crea factura**
   - Busca cliente "María García"
   - Abre menú → "Crear Factura"
   - Sistema muestra: 1 historial sin facturar (S/. 80.00)
   - Selecciona el historial
   - Método de pago: "Efectivo"
   - Genera factura

4. **Sistema calcula automáticamente**
   - Subtotal: S/. 80.00
   - IVA 16%: S/. 12.80
   - **TOTAL: S/. 92.80**

5. **Factura generada** ✅
   - Número: FAC-2025-00123
   - El historial queda marcado como "Facturado"
   - Ya no aparecerá en futuras selecciones

---

## 🎓 Preguntas Frecuentes

**P: ¿Puedo ver el historial de facturas de un cliente?**  
R: Sí, desde la sección "Gestión de Facturas" puedes filtrar por cliente.

**P: ¿Se puede imprimir la factura?**  
R: Esta funcionalidad estará disponible en la próxima actualización (exportar a PDF).

**P: ¿Los clientes pueden ver sus facturas?**  
R: Actualmente no, pero se implementará en futuras versiones desde su perfil.

**P: ¿Qué pasa si aplico un servicio que no está en el catálogo?**  
R: Contacta al administrador para agregar el servicio al catálogo primero.

**P: ¿Puedo cambiar el porcentaje de IVA?**  
R: Por defecto es 16%, pero está configurado para ser modificable. Contacta al administrador.

---

## 📞 Soporte

Si tienes problemas o dudas adicionales:

1. **Consulta este documento** primero
2. **Revisa la sección de Solución de Problemas**
3. **Contacta al administrador del sistema**

---

**Última actualización:** 8 de noviembre de 2025  
**Versión:** 1.0.0  
**Sistema:** VetCare App - Facturación Integrada

