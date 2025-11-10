import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vetcare_app/models/historial_medico.dart';
import 'package:vetcare_app/theme/app_theme.dart';

class HistorialDetailScreen extends StatelessWidget {
  final HistorialMedico historial;

  const HistorialDetailScreen({super.key, required this.historial});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Historial Médico'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${historial.tipo.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(historial.fecha)}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    if (historial.facturado)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                            const SizedBox(width: 6),
                            const Text('Facturado', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (historial.diagnostico != null || historial.tratamiento != null || historial.observaciones != null)
              SizedBox(
                width: double.infinity,
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (historial.diagnostico != null) ...[
                          const Text('Diagnóstico', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(historial.diagnostico!),
                        ],
                        if (historial.tratamiento != null) ...[
                          const SizedBox(height: 8),
                          const Text('Tratamiento', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(historial.tratamiento!),
                        ],
                        if (historial.observaciones != null) ...[
                          const SizedBox(height: 8),
                          const Text('Observaciones', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(historial.observaciones!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Información adicional', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Veterinario ID: ${historial.realizadoPor != null ? historial.realizadoPor.toString() : '-'}'),
                      const SizedBox(height: 6),
                      if (historial.citaId != null) Text('Cita asociada: ${historial.citaId}'),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text('Servicios aplicados', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...historial.servicios.map((s) {
              final subtotal = s.pivot.cantidad * s.pivot.precioUnitario;
              return SizedBox(
                width: double.infinity,
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(s.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cantidad: ${s.pivot.cantidad}'),
                        Text('Precio unitario: ${NumberFormat.simpleCurrency(locale: 'es').format(s.pivot.precioUnitario)}'),
                        if (s.pivot.notas != null && s.pivot.notas!.isNotEmpty) Text('Notas: ${s.pivot.notas}'),
                      ],
                    ),
                    trailing: Text(NumberFormat.simpleCurrency(locale: 'es').format(subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),

            Builder(builder: (context) {
              final computedTotal = historial.servicios.fold<double>(0.0, (acc, s) => acc + (s.pivot.cantidad * s.pivot.precioUnitario));
              if (computedTotal <= 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total servicios', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(NumberFormat.simpleCurrency(locale: 'es').format(computedTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
