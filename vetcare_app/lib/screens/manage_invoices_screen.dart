// ...existing code...
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/models/factura.dart';
import 'package:vetcare_app/models/client_model.dart';
import 'package:vetcare_app/models/historial_medico.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/services/factura_service.dart';
import 'package:vetcare_app/services/client_service.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ManageInvoicesScreen extends StatefulWidget {
  final String? prefilledClientId;
  final HistorialMedico? prefilledHistorial;
  final bool openFormDirectly;
  final ApiService? apiService;

  const ManageInvoicesScreen({
    super.key,
    this.prefilledClientId,
    this.prefilledHistorial,
    this.openFormDirectly = false,
    this.apiService,
  });

  @override
  State<ManageInvoicesScreen> createState() => _ManageInvoicesScreenState();
}

class _ManageInvoicesScreenState extends State<ManageInvoicesScreen> {
  List<Factura> _filteredFacturas = [];
  bool _isLoading = true;
  String _filterStatus = 'todas';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _clienteNombreController = TextEditingController();
  final TextEditingController _mascotaNombreController = TextEditingController();
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  bool _showAdvancedFilters = false;

  Map<String, dynamic> _estadisticas = {
    'total': 0.0,
    'pagadas': 0,
    'pendientes': 0,
    'anuladas': 0,
  };

  bool _didChangeDependenciesRun = false;

  @override
  void initState() {
    super.initState();
    
    // Si se debe abrir el formulario directamente, hacerlo después de que se construya el widget
    if (widget.openFormDirectly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _abrirFormularioConDatos();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didChangeDependenciesRun) {
      _didChangeDependenciesRun = true;
      _loadFacturas();
  _loadEstadisticas();
    }
  }
  
  Future<void> _abrirFormularioConDatos() async {
    debugPrint('📋 Abriendo formulario con datos pre-llenados');
    debugPrint('   - Cliente ID: ${widget.prefilledClientId}');
    debugPrint('   - Historial: ${widget.prefilledHistorial?.id}');
    
    final auth = context.read<AuthProvider>();
    final apiService = widget.apiService ?? auth.api;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FacturaFormScreen(
          clienteId: widget.prefilledClientId != null
              ? int.tryParse(widget.prefilledClientId!)
              : null,
          historialMedico: widget.prefilledHistorial,
          apiService: apiService,
        ),
      ),
    );
    
    if (result == true) {
      _loadFacturas();
      // _loadEstadisticas();
      // Cerrar la pantalla y devolver true al padre (PetDetailScreen)
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      // Si se canceló, solo cerrar esta pantalla
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }

  Future<void> _loadFacturas() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final facturaService = FacturaService(auth.api);
      final facturas = await facturaService.getFacturas(
        estado: _filterStatus != 'todas' ? _filterStatus : null,
        fechaDesde: _fechaDesde != null ? DateFormat('yyyy-MM-dd').format(_fechaDesde!) : null,
        fechaHasta: _fechaHasta != null ? DateFormat('yyyy-MM-dd').format(_fechaHasta!) : null,
        clienteNombre: _clienteNombreController.text.trim().isNotEmpty ? _clienteNombreController.text.trim() : null,
        mascotaNombre: _mascotaNombreController.text.trim().isNotEmpty ? _mascotaNombreController.text.trim() : null,
        numeroFactura: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      setState(() {
        _filteredFacturas = facturas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al cargar facturas: $e')),
            );
          }
        });
      }
    }
  }

  Future<void> _loadEstadisticas() async {
    try {
      final auth = context.read<AuthProvider>();
      final facturaService = FacturaService(auth.api);
      final stats = await facturaService.getEstadisticas();
      setState(() => _estadisticas = stats);
    } catch (e) {
      // Error silencioso
    }
  }

  void _filterByStatus(String status) {
    setState(() {
      _filterStatus = status;
    });
    _loadFacturas();
  }

  void _searchFacturas(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadFacturas();
  }
  
  void _applyAdvancedFilters() {
  _loadFacturas();
  }
  
  void _clearAdvancedFilters() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
      _clienteNombreController.clear();
      _mascotaNombreController.clear();
    });
    _loadFacturas();
  }
  
  
  Future<void> _selectFechaDesde() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaDesde ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _fechaDesde = picked);
    }
  }
  
  Future<void> _selectFechaHasta() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaHasta ?? DateTime.now(),
      firstDate: _fechaDesde ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _fechaHasta = picked);
    }
  }

  Future<void> _deleteFactura(Factura factura) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar la factura #${factura.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final auth = context.read<AuthProvider>();
        final facturaService = FacturaService(auth.api);
        await facturaService.eliminarFactura(factura.id.toString());
        _loadFacturas();
        // _loadEstadisticas();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Factura eliminada exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar factura: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Estadísticas
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Pagadas',
                        value: _estadisticas['pagadas']?.toString() ?? '0',
                        icon: Icons.check_circle,
                        color: AppTheme.successColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Pendientes',
                        value: _estadisticas['pendientes']?.toString() ?? '0',
                        icon: Icons.pending,
                        color: AppTheme.warningColor,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Total Recaudado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'S/. ${(_estadisticas['total'] ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filtros
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
            child: Column(
              children: [
                // Búsqueda
                TextField(
                  controller: _searchController,
                  onChanged: _searchFacturas,
                  decoration: InputDecoration(
                    hintText: 'Buscar por ID o cliente...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchFacturas('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkBackground
                        : AppTheme.lightBackground,
                  ),
                ),
                const SizedBox(height: 12),
                // Filtros de estado
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Todas',
                        isSelected: _filterStatus == 'todas',
                        onTap: () => _filterByStatus('todas'),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pagadas',
                        isSelected: _filterStatus == 'pagado',
                        onTap: () => _filterByStatus('pagado'),
                        color: AppTheme.successColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pendientes',
                        isSelected: _filterStatus == 'pendiente',
                        onTap: () => _filterByStatus('pendiente'),
                        color: AppTheme.warningColor,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Anuladas',
                        isSelected: _filterStatus == 'anulado',
                        onTap: () => _filterByStatus('anulado'),
                        color: AppTheme.errorColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Botón de filtros avanzados
                InkWell(
                  onTap: () => setState(() => _showAdvancedFilters = !_showAdvancedFilters),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showAdvancedFilters ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showAdvancedFilters ? 'Ocultar filtros avanzados' : 'Mostrar filtros avanzados',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Filtros avanzados
                if (_showAdvancedFilters) ...[
                  const SizedBox(height: 16),
                  // Filtro por cliente
                  TextField(
                    controller: _clienteNombreController,
                    decoration: InputDecoration(
                      hintText: 'Nombre del cliente...',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filtro por mascota
                  TextField(
                    controller: _mascotaNombreController,
                    decoration: InputDecoration(
                      hintText: 'Nombre de la mascota...',
                      prefixIcon: const Icon(Icons.pets),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filtros de fecha
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectFechaDesde,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _fechaDesde != null
                                        ? 'Desde: ${DateFormat('dd/MM/yyyy').format(_fechaDesde!)}'
                                        : 'Fecha desde',
                                    style: TextStyle(
                                      color: _fechaDesde != null
                                          ? (isDark ? AppTheme.textPrimary : AppTheme.textDark)
                                          : (isDark ? AppTheme.textSecondary : AppTheme.textLight),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: _selectFechaHasta,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _fechaHasta != null
                                        ? 'Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaHasta!)}'
                                        : 'Fecha hasta',
                                    style: TextStyle(
                                      color: _fechaHasta != null
                                          ? (isDark ? AppTheme.textPrimary : AppTheme.textDark)
                                          : (isDark ? AppTheme.textSecondary : AppTheme.textLight),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Botones de aplicar y limpiar filtros
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _applyAdvancedFilters,
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Aplicar Filtros'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearAdvancedFilters,
                          icon: const Icon(Icons.clear),
                          label: const Text('Limpiar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: BorderSide(color: AppTheme.errorColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Lista de facturas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFacturas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty && _filterStatus == 'todas'
                                  ? 'No hay facturas registradas'
                                  : 'No se encontraron facturas',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? AppTheme.textSecondary
                                    : AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _loadFacturas();
                          // await _loadEstadisticas();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredFacturas.length,
                          itemBuilder: (context, index) {
                            final factura = _filteredFacturas[index];
                            return _FacturaCard(
                              factura: factura,
                              isDark: isDark,
                              onTap: () => _showFacturaDetails(factura),
                              onEdit: () => _showFacturaForm(factura: factura),
                              onDelete: () => _deleteFactura(factura),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFacturaForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Factura'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showFacturaDetails(Factura factura) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FacturaDetailsSheet(factura: factura),
    );
  }

  void _showFacturaForm({Factura? factura}) async {
    final auth = context.read<AuthProvider>();
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FacturaFormScreen(
          factura: factura,
          apiService: auth.api,
        ),
      ),
    );
    if (result == true) {
      _loadFacturas();
      // _loadEstadisticas();
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor
              : (isDark ? AppTheme.darkBackground : AppTheme.lightBackground),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? chipColor
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? AppTheme.textPrimary : AppTheme.textDark),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _FacturaCard extends StatelessWidget {
  final Factura factura;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FacturaCard({
    required this.factura,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: factura.estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: factura.estadoColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Factura #${factura.id ?? "N/A"}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: factura.estadoColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              factura.estado.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: factura.estadoColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        factura.totalFormateado,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: isDark
                                ? AppTheme.textSecondary
                                : AppTheme.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cliente ID: ${factura.clienteId}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                      if (factura.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.textLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(factura.createdAt!),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.textSecondary
                                    : AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Acciones
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: onEdit,
                      child: const Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 12),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: onDelete,
                      child: const Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                          SizedBox(width: 12),
                          Text('Eliminar', style: TextStyle(color: AppTheme.errorColor)),
                        ],
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

class _FacturaDetailsSheet extends StatelessWidget {
  final Factura factura;

  const _FacturaDetailsSheet({required this.factura});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Factura #${factura.id ?? "N/A"}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: factura.estadoColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              factura.estado.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: factura.estadoColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Total
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        factura.totalFormateado,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Detalles
                Text(
                  'Detalles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.confirmation_number,
                  label: 'Número de Factura',
                  value: factura.numeroFactura ?? '',
                  isDark: isDark,
                ),
                _DetailRow(
                  icon: Icons.person,
                  label: 'Cliente ID',
                  value: factura.clienteId.toString(),
                  isDark: isDark,
                ),
                if (factura.citaId != null)
                  _DetailRow(
                    icon: Icons.event,
                    label: 'Cita ID',
                    value: factura.citaId.toString(),
                    isDark: isDark,
                  ),
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Fecha de Emisión',
                  value: factura.fechaEmision != null ? dateFormat.format(factura.fechaEmision!) : '',
                  isDark: isDark,
                ),
                _DetailRow(
                  icon: Icons.attach_money,
                  label: 'Subtotal',
                  value: factura.subtotalFormateado,
                  isDark: isDark,
                ),
                _DetailRow(
                  icon: Icons.receipt,
                  label: 'Impuestos',
                  value: factura.impuestosFormateado,
                  isDark: isDark,
                ),
                _DetailRow(
                  icon: Icons.monetization_on,
                  label: 'Total',
                  value: factura.totalFormateado,
                  isDark: isDark,
                ),
                _DetailRow(
                  icon: Icons.info,
                  label: 'Estado',
                  value: factura.estado,
                  isDark: isDark,
                ),
                if (factura.metodoPago != null)
                  _DetailRow(
                    icon: Icons.payment,
                    label: 'Método de Pago',
                    value: factura.metodoPago!,
                    isDark: isDark,
                  ),
                if (factura.notas != null && factura.notas!.isNotEmpty)
                  _DetailRow(
                    icon: Icons.note,
                    label: 'Notas',
                    value: factura.notas!,
                    isDark: isDark,
                  ),
                if (factura.detalles != null)
                  _DetailRow(
                    icon: Icons.list,
                    label: 'Detalles',
                    value: factura.detalles.toString(),
                    isDark: isDark,
                  ),


                // Mostrar servicios de historiales médicos
                if (factura.historiales != null && factura.historiales!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Servicios incluidos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...factura.historiales!.map((h) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Historial #${h.id ?? ""} - ${h.tipo}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ...h.servicios.map((s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(s.nombre)),
                            Text('Cant: ${s.pivot.cantidad}'),
                            Text('Unit: S/. ${s.pivot.precioUnitario.toStringAsFixed(2)}'),
                            Text('Subtotal: S/. ${(s.pivot.cantidad * s.pivot.precioUnitario).toStringAsFixed(2)}'),
                          ],
                        ),
                      )),
                      Divider(),
                    ],
                  )),
                ],
                if (factura.createdAt != null)
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'Fecha de Creación',
                    value: dateFormat.format(factura.createdAt!),
                    isDark: isDark,
                  ),
                if (factura.updatedAt != null)
                  _DetailRow(
                    icon: Icons.update,
                    label: 'Última Actualización',
                    value: dateFormat.format(factura.updatedAt!),
                    isDark: isDark,
                  ),
                // Detalles adicionales
                if (factura.detalles != null && factura.detalles!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Información Adicional',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: factura.detalles!.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.textSecondary
                                      : AppTheme.textLight,
                                ),
                              ),
                              Text(
                                entry.value.toString(),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Formulario de Factura
class _FacturaFormScreen extends StatefulWidget {
  final Factura? factura;
  final HistorialMedico? historialMedico; // Historial médico completo para pre-llenar
  final int? clienteId; // ID del cliente para pre-seleccionar
  final ApiService apiService; // Pasar ApiService desde el contexto padre

  const _FacturaFormScreen({
    this.factura,
    this.historialMedico,
    this.clienteId,
    required this.apiService,
  });

  @override
  State<_FacturaFormScreen> createState() => _FacturaFormScreenState();
}

class _FacturaFormScreenState extends State<_FacturaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _totalController;
  late TextEditingController _notasController;
  late TextEditingController _historialIdsController;
  String? _selectedClientId;
  String _selectedEstado = 'pendiente';
  String? _selectedMetodoPago;
  double _tasaImpuesto = 16.0;
  List<ClientModel> _clients = [];
  bool _isLoading = false;
  bool _isLoadingData = true;
  
  // Preview del cálculo del total
  double _subtotalPreview = 0.0;
  double _impuestoPreview = 0.0;
  double _totalPreview = 0.0;

  final List<String> _estados = ['pendiente', 'pagado', 'anulado'];
  // Métodos de pago aceptados por el backend (case-sensitive)
  final List<String> _metodosPago = ['efectivo', 'tarjeta', 'transferencia', 'otro'];

  bool _didChangeDependenciesRun = false;

  @override
  void initState() {
    super.initState();
    
    debugPrint('🏗️ _FacturaFormScreen initState');
    debugPrint('   - Historial: ${widget.historialMedico?.id}');
    debugPrint('   - Cliente ID: ${widget.clienteId}');
    
    _totalController = TextEditingController(
      text: widget.factura?.total.toStringAsFixed(2) ?? '',
    );
    _notasController = TextEditingController(
      text: widget.factura?.notas ?? '',
    );
    
    // Si viene desde historial médico, pre-llenar el ID
    _historialIdsController = TextEditingController(
      text: widget.historialMedico?.id.toString() ?? '',
    );
    
    _selectedEstado = widget.factura?.estado ?? 'pendiente';
    _selectedMetodoPago = widget.factura?.metodoPago;
    _tasaImpuesto = 16.0;
    
    // Si viene el clienteId desde el historial, pre-seleccionar
    if (widget.clienteId != null) {
      _selectedClientId = widget.clienteId.toString();
      debugPrint('   ✅ Cliente pre-seleccionado: $_selectedClientId');
    }
    
    // Calcular preview del total si viene con historial médico
    if (widget.historialMedico != null) {
      _calculatePreview();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didChangeDependenciesRun) {
      _didChangeDependenciesRun = true;
      _loadClients();
    }
  }
  
  void _calculatePreview() {
    if (widget.historialMedico == null) return;
    
    // Calcular subtotal desde los servicios del historial
    _subtotalPreview = widget.historialMedico!.totalServicios;
    
    // Calcular impuesto
    _impuestoPreview = _subtotalPreview * (_tasaImpuesto / 100);
    
    // Calcular total
    _totalPreview = _subtotalPreview + _impuestoPreview;
    
    debugPrint('💰 Preview calculado:');
    debugPrint('   Subtotal: S/. ${_subtotalPreview.toStringAsFixed(2)}');
    debugPrint('   Impuesto (${_tasaImpuesto}%): S/. ${_impuestoPreview.toStringAsFixed(2)}');
    debugPrint('   Total: S/. ${_totalPreview.toStringAsFixed(2)}');
  }

  Future<void> _loadClients() async {
    debugPrint('📋 Cargando clientes...');
    try {
      final clientService = ClientService(widget.apiService);
      final clients = await clientService.getClients();
      
      debugPrint('✅ Clientes cargados: ${clients.length}');
      
      if (mounted) {
        setState(() {
          _clients = clients;
          if (widget.factura != null) {
            _selectedClientId = widget.factura!.clienteId.toString();
          }
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error al cargar clientes: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
        // Mostrar error después del frame actual
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al cargar clientes: $e')),
            );
          }
        });
      }
    }
  }

  Future<void> _saveFactura() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un cliente')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final facturaService = FacturaService(widget.apiService);

      if (widget.factura == null) {
        // Crear nueva factura - requiere historial_ids y cliente_id
        if (_selectedClientId == null) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selecciona un cliente'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return;
        }

        final historialIdsText = _historialIdsController.text.trim();
        if (historialIdsText.isEmpty) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ingresa al menos un ID de historial médico'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return;
        }

        // Parsear IDs de historiales (separados por comas)
        List<int> historialIds;
        try {
          historialIds = historialIdsText
              .split(',')
              .map((id) => int.parse(id.trim()))
              .toList();
        } catch (e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Los IDs de historial deben ser números separados por comas'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return;
        }
        
        // Crear factura desde historiales
        try {
          await facturaService.createFacturaDesdeHistoriales(
            clienteId: int.parse(_selectedClientId!),
            historialIds: historialIds,
            metodoPago: _selectedMetodoPago,
            notas: _notasController.text.trim().isNotEmpty 
                ? _notasController.text.trim() 
                : null,
            tasaImpuesto: _tasaImpuesto,
          );
        } on ApiException catch (apiErr) {
          // Si el backend responde con validación 422 sobre el método de pago,
          // intentamos un fallback automático a 'efectivo' una sola vez para
          // mejorar la experiencia del usuario.
          if (apiErr.statusCode == 422 && apiErr.message.toLowerCase().contains('metodo')) {
            debugPrint('⚠️ Método de pago inválido según backend, aplicando fallback a "efectivo" y reintentando');
            setState(() => _selectedMetodoPago = 'efectivo');
            // Reintentar una vez con efectivo
            await facturaService.createFacturaDesdeHistoriales(
              clienteId: int.parse(_selectedClientId!),
              historialIds: historialIds,
              metodoPago: _selectedMetodoPago,
              notas: _notasController.text.trim().isNotEmpty 
                  ? _notasController.text.trim() 
                  : null,
              tasaImpuesto: _tasaImpuesto,
            );
            if (mounted) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Método de pago inválido: se usó EFECTIVO como fallback')),
                );
              });
            }
          } else {
            rethrow;
          }
        }
      } else {
        // Actualizar factura existente
        final data = {
          'cliente_id': int.parse(_selectedClientId!),
          'total': double.parse(_totalController.text.trim()),
          'estado': _selectedEstado,
          if (_selectedMetodoPago != null) 'metodo_pago': _selectedMetodoPago,
          if (_notasController.text.trim().isNotEmpty) 
            'notas': _notasController.text.trim(),
        };

        await facturaService.actualizarFactura(
          widget.factura!.id.toString(),
          data,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.factura == null
                  ? 'Factura creada exitosamente'
                  : 'Factura actualizada exitosamente',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(widget.factura == null ? 'Nueva Factura' : 'Editar Factura'),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Cliente
                  DropdownButtonFormField<String>(
                    value: _selectedClientId,
                    decoration: InputDecoration(
                      labelText: 'Cliente *',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _clients.map((client) {
                      return DropdownMenuItem(
                        value: client.id,
                        child: Text(client.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedClientId = value);
                    },
                    validator: (value) {
                      if (value == null) return 'Selecciona un cliente';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // IDs de Historiales (solo para crear nueva factura)
                  if (widget.factura == null) ...[
                    TextFormField(
                      controller: _historialIdsController,
                      decoration: InputDecoration(
                        labelText: 'IDs de Historiales Médicos *',
                        prefixIcon: const Icon(Icons.medical_services),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Ingresa los IDs separados por comas (ej: 101, 102, 103)',
                      ),
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Los IDs de historial son requeridos';
                        }
                        // Validar formato (números separados por comas)
                        final ids = value.split(',');
                        for (var id in ids) {
                          if (int.tryParse(id.trim()) == null) {
                            return 'Usa números separados por comas';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Tasa de impuesto
                    TextFormField(
                      initialValue: _tasaImpuesto.toString(),
                      decoration: InputDecoration(
                        labelText: 'Tasa de Impuesto (%)',
                        prefixIcon: const Icon(Icons.percent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Porcentaje de impuesto (default: 16%)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        final tasa = double.tryParse(value.trim());
                        if (tasa != null) {
                          setState(() {
                            _tasaImpuesto = tasa;
                            _calculatePreview(); // Recalcular preview cuando cambia la tasa
                          });
                        }
                      },
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (double.tryParse(value.trim()) == null) {
                            return 'Ingresa un número válido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Preview del cálculo (solo si viene desde historial médico)
                    if (widget.historialMedico != null && _totalPreview > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.receipt_long, color: AppTheme.primaryColor, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Resumen de la Factura',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildPreviewRow('Subtotal (servicios)', _subtotalPreview),
                            const SizedBox(height: 8),
                            _buildPreviewRow('Impuesto (${_tasaImpuesto.toStringAsFixed(1)}%)', _impuestoPreview),
                            const Divider(height: 16),
                            _buildPreviewRow(
                              'Total a Pagar',
                              _totalPreview,
                              isBold: true,
                              isLarge: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Detalle de servicios (líneas de factura) cuando venga desde historial
                    if (widget.historialMedico != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Historial Médico', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...(widget.historialMedico!.citaId != null
                              ? [Text('Cita asociada: #${widget.historialMedico!.citaId}', style: const TextStyle(fontWeight: FontWeight.bold))]
                              : [Text('Sin cita asociada', style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textLight))]),
                            const SizedBox(height: 8),
                            Text('Servicios facturados:', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (widget.historialMedico!.servicios.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('No hay servicios asociados a este historial.', style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textLight)),
                              )
                            else
                              ...widget.historialMedico!.servicios.map((s) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: _buildServicioRow(s),
                                  )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                  // Total (solo editable si es actualización)
                  TextFormField(
                    controller: _totalController,
                    enabled: widget.factura != null,
                    decoration: InputDecoration(
                      labelText: widget.factura != null ? 'Total *' : 'Total (calculado automáticamente)',
                      prefixIcon: const Icon(Icons.attach_money),
                      prefixText: 'S/. ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: widget.factura == null 
                          ? 'El total se calculará desde los servicios de la cita'
                          : null,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: widget.factura != null 
                        ? (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El total es requerido';
                            }
                            if (double.tryParse(value.trim()) == null) {
                              return 'Ingresa un número válido';
                            }
                            return null;
                          }
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Estado
                  DropdownButtonFormField<String>(
                    value: _selectedEstado,
                    decoration: InputDecoration(
                      labelText: 'Estado *',
                      prefixIcon: const Icon(Icons.info),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _estados.map((estado) {
                      return DropdownMenuItem(
                        value: estado,
                        child: Text(estado.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedEstado = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Método de pago
                  DropdownButtonFormField<String>(
                    value: _selectedMetodoPago,
                    decoration: InputDecoration(
                      labelText: 'Método de Pago',
                      prefixIcon: const Icon(Icons.payment),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _metodosPago.map((metodo) {
                      return DropdownMenuItem(
                        value: metodo,
                        child: Text(metodo.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedMetodoPago = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Notas
                  TextFormField(
                    controller: _notasController,
                    decoration: InputDecoration(
                      labelText: 'Notas',
                      prefixIcon: const Icon(Icons.note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Información adicional sobre la factura',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveFactura,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.factura == null
                                  ? 'Crear Factura'
                                  : 'Guardar Cambios',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildPreviewRow(String label, double amount, {bool isBold = false, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          'S/. ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isLarge ? 18 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isBold ? AppTheme.primaryColor : null,
          ),
        ),
      ],
    );
  }

  Widget _buildServicioRow(HistorialServicio s) {
    final lineSubtotal = s.pivot.cantidad * s.pivot.precioUnitario;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Cant: ${s.pivot.cantidad}  ·  Precio unitario: S/. ${s.pivot.precioUnitario.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('S/. ${lineSubtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  @override
  void dispose() {
    _totalController.dispose();
    _notasController.dispose();
    _historialIdsController.dispose();
    super.dispose();
  }
}

