import 'package:flutter/material.dart';
import 'package:vetcare_app/models/historial_medico.dart';
import 'package:vetcare_app/theme/app_theme.dart';

/// Widget read-only para mostrar la lista de servicios aplicados en un historial
class ServiciosAplicadosList extends StatelessWidget {
  final List<HistorialServicio> servicios;
  final bool showTotal;

  const ServiciosAplicadosList({
    Key? key,
    required this.servicios,
    this.showTotal = true,
  }) : super(key: key);

  double get total {
    return servicios.fold(0.0, (sum, s) => sum + (s.pivot.cantidad * s.pivot.precioUnitario));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (servicios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Center(
          child: Text(
            'No hay servicios registrados',
            style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textLight),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...servicios.map((servicio) => _ServicioItem(servicio: servicio, isDark: isDark)),
        if (showTotal) ...[
          const SizedBox(height: 8),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Servicios:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'S/. ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ServicioItem extends StatelessWidget {
  final HistorialServicio servicio;
  final bool isDark;

  const _ServicioItem({required this.servicio, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final subtotal = servicio.pivot.cantidad * servicio.pivot.precioUnitario;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.medical_services, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servicio.nombre,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${servicio.pivot.cantidad} × S/. ${servicio.pivot.precioUnitario.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'S/. ${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          if (servicio.pivot.notas != null && servicio.pivot.notas!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes,
                    size: 16,
                    color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      servicio.pivot.notas!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

