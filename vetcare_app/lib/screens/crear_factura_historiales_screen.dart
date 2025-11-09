import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/models/client_model.dart';
import 'package:vetcare_app/models/historial_medico.dart';
import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/services/client_service.dart';
import 'package:vetcare_app/services/historial_medico_service.dart';
import 'package:vetcare_app/services/factura_service.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Pantalla para que recepcionista cree facturas desde historiales médicos sin facturar
class CrearFacturaHistorialesScreen extends StatefulWidget {
  final ClientModel? clienteInicial;

  const CrearFacturaHistorialesScreen({Key? key, this.clienteInicial}) : super(key: key);

  @override
  State<CrearFacturaHistorialesScreen> createState() => _CrearFacturaHistorialesScreenState();
}

class _CrearFacturaHistorialesScreenState extends State<CrearFacturaHistorialesScreen> {
  ClientModel? _clienteSeleccionado;
  List<HistorialMedico> _historiales = [];
  Set<int> _historialesSeleccionados = {};
  bool _isLoading = false;
  String? _metodoPago = 'efectivo';
  final TextEditingController _notasController = TextEditingController();
  final double _tasaImpuesto = 16.0;

  @override
  void initState() {
    super.initState();
    if (widget.clienteInicial != null) {
      _clienteSeleccionado = widget.clienteInicial;
      _loadHistoriales();
    }
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoriales() async {
    if (_clienteSeleccionado == null) return;

    setState(() => _isLoading = true);
    try {
      final apiService = context.read<ApiService>();
      final historialService = HistorialMedicoService(apiService);

      final clienteIdInt = int.tryParse(_clienteSeleccionado!.id) ?? 0;
      final historiales = await historialService.getHistorialesSinFacturar(clienteIdInt);

      setState(() {
        _historiales = historiales;
        _historialesSeleccionados.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historiales: $e')),
        );
      }
    }
  }

  Future<void> _seleccionarCliente() async {
    final apiService = context.read<ApiService>();
    final clientService = ClientService(apiService);

    try {
      final clientes = await clientService.getClients();

      if (!mounted) return;

      final cliente = await showDialog<ClientModel>(
        context: context,
        builder: (context) => _ClientSelectorDialog(clientes: clientes),
      );

      if (cliente != null) {
        setState(() {
          _clienteSeleccionado = cliente;
          _historiales = [];
          _historialesSeleccionados.clear();
        });
        _loadHistoriales();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar clientes: $e')),
        );
      }
    }
  }

  void _toggleHistorial(int historialId) {
    setState(() {
      if (_historialesSeleccionados.contains(historialId)) {
        _historialesSeleccionados.remove(historialId);
      } else {
        _historialesSeleccionados.add(historialId);
      }
    });
  }

  double get _subtotal {
    return _historiales
        .where((h) => h.id != null && _historialesSeleccionados.contains(h.id))
        .fold(0.0, (sum, h) => sum + h.totalServicios);
  }

  double get _impuestos {
    return _subtotal * (_tasaImpuesto / 100);
  }

  double get _total {
    return _subtotal + _impuestos;
  }

  Future<void> _crearFactura() async {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un cliente')),
      );
      return;
    }

    if (_historialesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos un historial')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = context.read<ApiService>();
      final facturaService = FacturaService(apiService);

      final clienteIdInt = int.tryParse(_clienteSeleccionado!.id) ?? 0;

      final factura = await facturaService.createFacturaDesdeHistoriales(
        clienteId: clienteIdInt,
        historialIds: _historialesSeleccionados.toList(),
        metodoPago: _metodoPago,
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
        tasaImpuesto: _tasaImpuesto,
      );

      if (mounted) {
        Navigator.pop(context, factura);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Factura ${factura.numeroFactura ?? factura.id} creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear factura: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Factura desde Historiales'),
        actions: [
          if (_clienteSeleccionado != null)
            IconButton(
              icon: const Icon(Icons.person_search),
              onPressed: _seleccionarCliente,
              tooltip: 'Cambiar cliente',
            ),
        ],
      ),
      body: Column(
        children: [
          // Selector de cliente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
            ),
            child: _clienteSeleccionado == null
                ? Center(
                    child: ElevatedButton.icon(
                      onPressed: _seleccionarCliente,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Seleccionar Cliente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _clienteSeleccionado!.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _clienteSeleccionado!.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_clienteSeleccionado!.phone != null)
                              Text(
                                _clienteSeleccionado!.phone!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _seleccionarCliente,
                      ),
                    ],
                  ),
          ),

          // Lista de historiales
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _clienteSeleccionado == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Seleccione un cliente para ver sus historiales',
                              style: TextStyle(
                                color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _historiales.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No hay historiales sin facturar',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Todos los historiales están facturados',
                                  style: TextStyle(
                                    color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _historiales.length,
                            itemBuilder: (context, index) {
                              final historial = _historiales[index];
                              final isSelected = historial.id != null &&
                                  _historialesSeleccionados.contains(historial.id);

                              return _HistorialCheckCard(
                                historial: historial,
                                isSelected: isSelected,
                                isDark: isDark,
                                onToggle: () => _toggleHistorial(historial.id!),
                              );
                            },
                          ),
          ),

          // Resumen y botones
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Método de pago
                DropdownButtonFormField<String>(
                  initialValue: _metodoPago,
                  decoration: const InputDecoration(
                    labelText: 'Método de pago',
                    prefixIcon: Icon(Icons.payment),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                    DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                    DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                  ],
                  onChanged: (value) => setState(() => _metodoPago = value),
                ),
                const SizedBox(height: 12),

                // Notas
                TextField(
                  controller: _notasController,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Resumen de totales
                _buildTotalesResumen(isDark),
                const SizedBox(height: 16),

                // Botón crear factura
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _historialesSeleccionados.isEmpty || _isLoading
                        ? null
                        : _crearFactura,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.receipt),
                    label: Text(
                      _isLoading ? 'Generando...' : 'Generar Factura',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalesResumen(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal:', _subtotal, isDark, false),
          const SizedBox(height: 8),
          _buildTotalRow('IVA ($_tasaImpuesto%):', _impuestos, isDark, false),
          const Divider(height: 16),
          _buildTotalRow('TOTAL:', _total, isDark, true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double valor, bool isDark, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? null : (isDark ? AppTheme.textSecondary : AppTheme.textLight),
          ),
        ),
        Text(
          'S/. ${valor.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppTheme.primaryColor : null,
          ),
        ),
      ],
    );
  }
}

class _HistorialCheckCard extends StatelessWidget {
  final HistorialMedico historial;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onToggle;

  const _HistorialCheckCard({
    required this.historial,
    required this.isSelected,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggle(),
                  activeColor: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            historial.tipoIcon,
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            historial.tipo.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(historial.fecha),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (historial.diagnostico != null && historial.diagnostico!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          historial.diagnostico!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: 14,
                            color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${historial.servicios.length} servicio(s)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'S/. ${historial.totalServicios.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientSelectorDialog extends StatefulWidget {
  final List<ClientModel> clientes;

  const _ClientSelectorDialog({required this.clientes});

  @override
  State<_ClientSelectorDialog> createState() => _ClientSelectorDialogState();
}

class _ClientSelectorDialogState extends State<_ClientSelectorDialog> {
  List<ClientModel> _filteredClientes = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredClientes = widget.clientes;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterClientes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClientes = widget.clientes;
      } else {
        _filteredClientes = widget.clientes.where((c) {
          final nameLower = c.name.toLowerCase();
          final phoneLower = c.phone?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return nameLower.contains(searchLower) || phoneLower.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Cliente'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filterClientes,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredClientes.length,
                itemBuilder: (context, index) {
                  final cliente = _filteredClientes[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        cliente.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                    title: Text(cliente.name),
                    subtitle: Text(cliente.phone ?? 'Sin teléfono'),
                    onTap: () => Navigator.pop(context, cliente),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
